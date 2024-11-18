package main

/*
#cgo LDFLAGS: -lhilog_ndk.z

#include "bridge.h"

*/
import "C"

import (
	"runtime"

	"cfa/native/config"
	"cfa/native/delegate"
	"cfa/native/tunnel"

	"github.com/metacubex/mihomo/log"
)

import (
"os"
)

//export coreInit
func coreInit(home, versionName C.c_string, sdkVersion C.int) {

	h := C.GoString(home)
	v := C.GoString(versionName)
	s := int(sdkVersion)

	delegate.Init(h, v, s)

	reset()
}

//export coreTest
func coreTest() C.int {

	return 1
}

//export reset
func reset() {

	config.LoadDefault()
	tunnel.ResetStatistic()
	tunnel.CloseAllConnections()

	runtime.GC()
}

//export forceGc
func forceGc() {
    log.Infoln("[APP] os.Exit")
    os.Exit(0)
	go func() {
		log.Infoln("[APP] request force GC")

		runtime.GC()
	}()
}


func main() {
	panic("Stub!")
}