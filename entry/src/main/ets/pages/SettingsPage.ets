import { ActionLabel } from './compoments/common'
import { common, Want } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { rpc } from '@kit.IPCKit'
import SocketProxyService from '../rpc/SocketProxyService'
import { Dns, OverrideSlot, Sniffer } from '../entryability/ClashViewModel'
import { JSON } from '@kit.ArkTS'


@Component
export struct NetworkSettingsPage {
  @Consume('router') routerInfos: NavPathStack
  build() {
    NavDestination() {
      Column() {
        ActionLabel({ title:"自动路由系统流量", subTitle:"通过VpnService 自动路由所有系统流量", isSwitch: true, icon:"ic_baseline_vpn_lock", click:()=>{
        }})
        ActionLabel({ title:"绕过私有网络", subTitle:"绕过是由网络地址", isSwitch: true, icon:"", click:()=>{
        }})
        ActionLabel({ title:"DNS 劫持", subTitle:"处理所有DNS数据包", isSwitch: true, icon:"", click:()=>{
        }})
        ActionLabel({ title:"允许应用过绕过", subTitle:"允许其他应用绕过VPN", isSwitch: true, icon:"", click:()=>{
        }})
      }.width('100%').height('100%')
    }.title("网络")
  }
}



@Component
export struct SettingsPage {
  @Consume('router') routerInfos: NavPathStack
  async aboutToAppear(): Promise<void> {
    // let configs = await SocketProxyService.queryConfiguration()
    // console.log("SettingsPage ", configs)
    let config = await SocketProxyService.queryOverride(OverrideSlot.Persist)
    config.dns = {
      enable: true,
      "use-hosts": true
    } as Dns
    config.sniffer = {
      enable: true,
      forceDnsMapping: true,
      parsePureIp: true,
      overrideDestination: true,
    } as Sniffer
    console.log("SettingsPage queryOverride", JSON.stringify(config))
    SocketProxyService.patchOverride(OverrideSlot.Persist, config)

  }
  build() {
    NavDestination() {
      Column() {
        ActionLabel({ title:"应用", icon:"ic_baseline_settings", click:()=>{
          // this.routerInfos.pushPath({name:"network-settings"})

        }})
        ActionLabel({ title:"网络", icon:"ic_baseline_dns", click:()=>{
          //this.routerInfos.pushPath({name:"network-settings"})
        }})
        ActionLabel({ title:"覆写", icon:"ic_baseline_extension", click:()=>{
          this.routerInfos.pushPath({name:"network-settings"})
        }})
        ActionLabel({ title:"Meta Features", icon:"ic_baseline_meta", click:()=>{
          this.routerInfos.pushPath({name:"network-settings"})
        }})
      }.width('100%').height('100%')
    }.title("设置")
  }
}
