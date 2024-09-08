import { hilog } from '@kit.PerformanceAnalysisKit';
import testNapi from 'libentry.so';
import { vpnExtension } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';

class Address {
  address: string;
  family: number;

  constructor(address: string, family: number) {
    this.address = address;
    this.family = family;
  }
}
class AddressWithPrefix {
  address: Address;
  prefixLength: number;
  constructor(address: Address, prefixLength: number) {
    this.address = address;
    this.prefixLength = prefixLength;
  }
}
class Config {
  addresses: AddressWithPrefix[];
  mtu: number;
  dnsAddresses: string[];
  constructor(
    tunIp: string,
    blockedAppName: string
  ) {
    this.addresses = [
      new AddressWithPrefix(new Address(tunIp, 1), 24)
    ];
    this.mtu = 1400;
    this.dnsAddresses = ["172.19.0.2"];
  }
}
@Entry
@Component
struct Index {
  private tunIp: string = '172.19.0.1';
  @State message: string = 'Hello World';
  vpnConnection = vpnExtension.createVpnConnection(getContext(this) as common.VpnExtensionContext);
  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
          .onClick(async () => {
            let config = new Config(this.tunIp, "");
            try {
              let tunFd = await this.vpnConnection.create(config)
              hilog.info(0x0000, 'testTag', 'start tun %{public}d', tunFd);
              testNapi.add(tunFd, 3, (fd:number)=>{
                hilog.info(0x0000, 'ClashMeta', 'protect tun %{public}d', fd);
                this.vpnConnection.protect(fd).catch((e:Error)=>{
                  hilog.info(0x0000, 'testTag', 'protect failed %{public}s', e.message);
                })
              })

            } catch (e) {
              this.vpnConnection.destroy()
              hilog.info(0x0000, 'testTag', 'vpn failure %{public}s', e.message);
            }


          })
      }
      .width('100%')
    }
    .height('100%')
  }
}
