package tun

import (
	"net"

	"github.com/metacubex/mihomo/dns"
	"github.com/metacubex/mihomo/log"
	D "github.com/miekg/dns"
)

func shouldHijackDns(dns net.IP, target net.IP, targetPort int) bool {
	if targetPort != 53 {
		return false
	}

	return net.IPv4zero.Equal(dns) || target.Equal(dns)
}

func relayDns(payload []byte) ([]byte, error) {
	msg := &D.Msg{}
	if err := msg.Unpack(payload); err != nil {
		log.Debugln("relayDns  %s", err)
		return nil, err
	}

	r, err := dns.ServeDNSWithDefaultServer(msg)
	if err != nil {
		log.Debugln("ServeDNSWithDefaultServer %s", err)
		return nil, err
	}

	r.SetRcode(msg, r.Rcode)

	return r.Pack()
}
