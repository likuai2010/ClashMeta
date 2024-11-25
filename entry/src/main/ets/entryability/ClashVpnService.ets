import { vpnExtension } from '@kit.NetworkKit';
import { common, Context } from '@kit.AbilityKit';
import { nativeInit, nativeLoad,
  nativeNotifyDnsChanged,
  nativePatchSelector, nativeStartTun, nativeStopTun } from 'libentry.so';
import logger from '../pages/logs';
import { Selection } from './SelectionRepo';

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
export  class ClashVpnService{
  noVpn: boolean = false // 模拟器开启
  private tunIp: string = '172.19.0.1';
  running: boolean = false
  vpnConnection : vpnExtension.VpnConnection | undefined
  public configPath: string = ""
  protectSocketPath: string = ""

  constructor(home: string) {
    logger.log("ClashVPN", `初始化Clash(golang)(${home})`)
    try {
      nativeInit(home,"1.0.0")
      logger.log("ClashVPN", `初始化Clash(golang) 完成`)
    } catch (e) {
      logger.log("ClashVPN", `初始化Clash(golang)失败`)
    }
  }
  async StartVpn(configPath: string, context: Context, selection: Selection[]): Promise<boolean> {
    let config = new Config(this.tunIp, "");
    let tunFd = -1
    try {
      if(!this.noVpn){
        this.vpnConnection = vpnExtension.createVpnConnection(context as common.VpnExtensionContext);
        tunFd = await this.vpnConnection.create(config)
      }
      logger.log("ClashVPN", `获取tunFd: ${tunFd}`)
      logger.log("ClashVPN", `加载配置文件(golang) ${configPath}`)
      nativeLoad(configPath, (type:string)=>{
        logger.log("ClashVPN", `加载配置文件(golang) ${!type?'成功':'失败'}`)
      })
      logger.log("ClashVPN", `开启Clash服务(golang)`)
      nativeStartTun(tunFd, (fd)=>{
        this.vpnConnection?.protect(fd)
      })
      setTimeout(()=>{
        // 默认节点
        if (selection) {
          selection.forEach((s)=>{
            nativePatchSelector(s.proxy, s.selected)
          })
        }
      }, 500)

      return true;
    } catch (error) {
      logger.log("ClashVPN", `Clash启动失败 ${error.message}=> ${error.stack}` )
      this.vpnConnection?.destroy()
      return false
    }
  }
  stopVpn(context: common.Context){
    nativeNotifyDnsChanged("8.8.8.8")
    nativeStopTun()
    if(this.vpnConnection == null){
      this.vpnConnection = vpnExtension.createVpnConnection(context as common.VpnExtensionContext);
    }
    logger.log("ClashVPN", `停止vpn服务` )
    this.vpnConnection?.destroy()

  }
}


