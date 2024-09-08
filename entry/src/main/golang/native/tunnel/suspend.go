package tunnel

import "github.com/metacubex/mihomo/adapter/provider"

func Suspend(s bool) {
	provider.Suspend(s)
}
