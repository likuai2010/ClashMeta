package tun

import (
	"encoding/binary"
	"io"
	"net"
	"os"
	"time"

	"github.com/Kr328/tun2socket"

	"github.com/metacubex/mihomo/adapter/inbound"
	"github.com/metacubex/mihomo/common/pool"
	C "github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/log"
	"github.com/metacubex/mihomo/transport/socks5"
	"github.com/metacubex/mihomo/tunnel"
)

var _, ipv4LoopBack, _ = net.ParseCIDR("127.0.0.0/8")

func Start(fd int, gateway, portal, dns string) (io.Closer, error) {
	log.Debugln("TUN: fd = %d, gateway = %s, portal = %s, dns = %s", fd, gateway, portal, dns)

	device := os.NewFile(uintptr(fd), "/dev/tun")

	ip, network, err := net.ParseCIDR(gateway)
	if err != nil {
		panic(err.Error())
	} else {
		network.IP = ip
	}
	stack, err := tun2socket.StartTun2Socket(device, network, net.ParseIP(portal))
	if err != nil {
		_ = device.Close()

		return nil, err
	}

	dnsAddr := net.ParseIP(dns)

	tcp := func() {
		defer stack.TCP().Close()
		defer log.Debugln("TCP: closed")
        log.Debugln("TCP = %s", "start")
		for stack.TCP().SetDeadline(time.Time{}) == nil {
			conn, err := stack.TCP().Accept()
            log.Debugln("Accept TCP = %s", "conn")
			if err != nil {
				log.Debugln("Accept TCP connection: %v", err)
				continue
			}

			lAddr := conn.LocalAddr().(*net.TCPAddr)
			rAddr := conn.RemoteAddr().(*net.TCPAddr)

			if ipv4LoopBack.Contains(rAddr.IP) {
				conn.Close()

				continue
			}

			if shouldHijackDns(dnsAddr, rAddr.IP, rAddr.Port) {
				go func() {
					defer conn.Close()

					buf := pool.Get(pool.UDPBufferSize)
					defer pool.Put(buf)

					for {
						conn.SetReadDeadline(time.Now().Add(C.DefaultTCPTimeout))

						length := uint16(0)
						if err := binary.Read(conn, binary.BigEndian, &length); err != nil {
							return
						}

						if int(length) > len(buf) {
							return
						}

						n, err := conn.Read(buf[:length])
						if err != nil {
							return
						}

						msg, err := relayDns(buf[:n])
						if err != nil {
							return
						}

						_, _ = conn.Write(msg)
					}
				}()

				continue
			}

			go tunnel.Tunnel.HandleTCPConn(conn, createMetadata(lAddr, rAddr))
		}
	}

	udp := func() {
		defer stack.UDP().Close()
		defer log.Debugln("UDP: closed")

		for {
			buf := pool.Get(pool.UDPBufferSize)

			n, lRAddr, rRAddr, err := stack.UDP().ReadFrom(buf)

			if err != nil {
				return
			}

			raw := buf[:n]
			lAddr := lRAddr.(*net.UDPAddr)
			rAddr := rRAddr.(*net.UDPAddr)
            log.Debugln("Accept udp lAddr = %s => %s ", lAddr, rAddr)
			if ipv4LoopBack.Contains(rAddr.IP) {
				pool.Put(buf)

				continue
			}

			if shouldHijackDns(dnsAddr, rAddr.IP, rAddr.Port) {
			    log.Debugln("Accept udp shouldHijackDns = %s  %s => %s ",dnsAddr, lAddr, rAddr)
				go func() {
					defer pool.Put(buf)
					msg, err := relayDns(raw)
					if err != nil {
                       log.Debugln("Accept udp relayDns  %s ", err)
						return
					}

					_, _ = stack.UDP().WriteTo(msg, rAddr, lAddr)
				}()

				continue
			}

			pkt := &packet{
				local: lAddr,
				data:  raw,
				writeBack: func(b []byte, addr net.Addr) (int, error) {
					return stack.UDP().WriteTo(b, addr, lAddr)
				},
				drop: func() {
					pool.Put(buf)
				},
			}
            log.Debugln("Accept HandleUDPPacket ")
			tunnel.Tunnel.HandleUDPPacket(inbound.NewPacket(socks5.ParseAddrToSocksAddr(rAddr), pkt, C.SOCKS5))
		}
	}

	go tcp()
	go udp()
	go udp()

	return stack, nil
}
