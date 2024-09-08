package tunnel

import (
	"fmt"

	"github.com/metacubex/mihomo/component/mmdb"
	"github.com/oschwald/maxminddb-golang"
)

func InstallSideloadGeoip(block []byte) error {
	if block == nil {
		mmdb.InstallOverride(nil)
		return nil
	}

	db, err := maxminddb.FromBytes(block)
	if err != nil {
		return fmt.Errorf("load sideload geoip mmdb: %s", err.Error())
	}

	mmdb.InstallOverride(db)

	return nil
}
