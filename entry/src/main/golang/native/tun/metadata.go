package tun

import (
	"net"

	C "github.com/metacubex/mihomo/constant"
)

func createMetadata(lAddr, rAddr *net.TCPAddr) *C.Metadata {
	return &C.Metadata{
		NetWork:    C.TCP,
		Type:       C.SOCKS5,
		SrcIP:      lAddr.AddrPort().Addr(),
		DstIP:      rAddr.AddrPort().Addr(),
		SrcPort:    uint16(lAddr.Port),
		DstPort:    uint16(rAddr.Port),
		Host:       "",
		RawSrcAddr: lAddr,
		RawDstAddr: rAddr,
	}
}
