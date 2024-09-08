import { ActionLabel } from './compoments/common'
import { common, Want } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { rpc } from '@kit.IPCKit'


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
