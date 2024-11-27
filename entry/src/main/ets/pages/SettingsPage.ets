import { ActionLabel } from './compoments/common'
import SocketProxyService from '../rpc/SocketProxyService'
import { Dns, OverrideSlot, Sniff, Sniffer } from '../entryability/ClashViewModel'
import { JSON } from '@kit.ArkTS'
import { emitter } from '@kit.BasicServicesKit'
import { EventIds } from '../rpc/EventConstants'


@Component
export struct NetworkSettingsPage {
  @Consume('router') routerInfos: NavPathStack
  build() {
    NavDestination() {
      Column() {
        ActionLabel({ title:"自动路由系统流量", subTitle:"通过VpnService 自动路由所有系统流量", isSwitch: true, icon:"ic_baseline_vpn_lock", change:()=>{
        }})
        ActionLabel({ title:"绕过私有网络", subTitle:"绕过是由网络地址", isSwitch: true, icon:"", change:()=>{
        }})
        ActionLabel({ title:"DNS 劫持", subTitle:"处理所有DNS数据包", isSwitch: true, icon:"", change:()=>{
        }})
        ActionLabel({ title:"允许应用过绕过", subTitle:"允许其他应用绕过VPN", isSwitch: true, icon:"", change:()=>{
        }})
      }.width('100%').height('100%')
    }.title("网络")
  }
}
@Component
export struct BaseSettingsPage {
  @Consume('router') routerInfos: NavPathStack
  build() {
    NavDestination() {
      Column() {
        ActionLabel({ title:"自动路由系统流量", subTitle:"通过VpnService 自动路由所有系统流量", isSwitch: true, icon:"ic_baseline_vpn_lock", change:()=>{
        }})
        ActionLabel({ title:"绕过私有网络", subTitle:"绕过是由网络地址", isSwitch: true, icon:"", change:()=>{
        }})
        ActionLabel({ title:"DNS 劫持", subTitle:"处理所有DNS数据包", isSwitch: true, icon:"", change:()=>{
        }})
        ActionLabel({ title:"允许应用过绕过", subTitle:"允许其他应用绕过VPN", isSwitch: true, icon:"", change:()=>{
        }})
      }.width('100%').height('100%')
    }.title("网络")
  }
}
export class  ConfigItem{
  key: string
  name: string
  type: number
  value: string | string[] | boolean | number | Record<string, Sniff> | undefined
  constructor(key:string, name: string,  value: string | string[] | boolean | number | Record<string, Sniff> | undefined, type: number = 0) {
    this.key = key
    this.name = name
    this.value = value
    this.type = type
  }
}
export enum ConfigItemType{
  Bool,
  String,
  Number,
  StringArray,
  Map,
}


@Component
struct ConfigItemBox{
  @Consume('router') routerInfos: NavPathStack
  @Prop item: ConfigItem
  onChange?: (item: ConfigItem)=>void
  @State showMenu: boolean = false
  @Builder
  changeMenu() {
    Menu() {
      if(this.item.type == 0){
        MenuItem({ content: "不修改" }).onClick(()=>{
          this.item.value = undefined
        })
        MenuItem({ content: "已启用" }).onClick(()=>{
          this.item.value = true
        })
        MenuItem({ content: "已禁用" }).onClick(()=>{
          this.item.value = false
        })
      }
    }.onDisAppear(()=>{
      this.onChange?.(this.item)
      this.showMenu = false
    })
  }
  aboutToAppear(): void {
    emitter.on({eventId: EventIds.ConfigItemEdit}, (data)=>{
      let key = data?.data?.["key"] as string
      if(this.item.key == key){
        this.item.value = data?.data?.["value"]
        this.onChange?.(this.item)
      }
    })
  }
  build() {
    Row(){
      Blank().width(20)
      Column(){
          Text(this.item.name)
          Blank().height(5)
          Text(this.convertValue(this.item.value)).fontSize(12)
        }.padding(10).alignItems(HorizontalAlign.Start).layoutWeight(1)
    }.alignItems(VerticalAlign.Center).margin({left:10, right: 10, top:5, bottom:5})
    .onClick(()=>{
      if(this.item.type != 0){
        this.showMenu = false
        this.routerInfos.pushPath({name:"ConfigItemEdit", param: JSON.stringify(this.item,)})
      }else{
        this.showMenu = true
      }
    }).bindMenu(this.showMenu, this.changeMenu)
  }
  convertValue(value: string | string[] | boolean | number | Record<string, Sniff> | undefined):string{
    let result :string = "不修改"
    if(value != undefined){
      let type = typeof value
      console.log("convertValue", type);
      if(typeof value == "boolean"){
        return value ? "已启用" : "已禁用"
      }
      if(typeof value == "string"){
        return value
      }
      if(typeof value == "object"){
        if(Array.isArray(value)){
          return value.length + "条目"
        }else{
          return Object.keys(value).toString()
        }
      }
      if(typeof value == "number"){
        return value.toString()
      }
    }
    return result
  }
}

@Component
export struct MetaFeaturesPage {
  @Consume('router') routerInfos: NavPathStack
  @State snifferItems: ConfigItem[] = []
  @StorageLink('compatibilityModel') compatibilityModel: boolean = false
  sniffer: Sniffer |undefined

  async aboutToAppear(): Promise<void> {
    this.fetchConfigList()
  }
  async  fetchConfigList(){
    let sniffer: Sniffer |undefined
    try {
      let config = await SocketProxyService.queryOverride(OverrideSlot.Persist)
      sniffer = config.sniffer
      this.sniffer = sniffer
    } catch (e) {
    }
    this.snifferItems = [
      new ConfigItem("enable", "策略", sniffer?.enable),
      new ConfigItem("force-dns-mapping","Force DNS Mapping", sniffer?.['force-dns-mapping']),
      new ConfigItem(
        "parse-pure-ip","Parse Pure Ip", sniffer?.['parse-pure-ip']),
      new ConfigItem('override-destination', "Override Destination", sniffer?.['override-destination']),
      new ConfigItem("force-domain", "Force Domain", sniffer?.['force-domain'], ConfigItemType.StringArray),
      new ConfigItem("skip-domain","Skip Domain", sniffer?.['skip-domain'], ConfigItemType.StringArray),
      new ConfigItem("sniff", "Sniff", sniffer?.sniff, ConfigItemType.Map)
    ]
  }
  @Builder
  ConfigItemBuilder(item: ConfigItem){
    ConfigItemBox({item, onChange:(item)=>{
      if(this.sniffer){
        this.sniffer[item.key] = item.value
      }
    }})
  }

  build() {
    NavDestination() {
      Column() {
        ActionLabel({ title:"兼容模式", subTitle:"强制开启Sniffer", isSwitch: this.compatibilityModel, icon:"ic_baseline_vpn_lock", change: async (result)=>{
          console.log("testTag 兼容模式", result);
          if (result  == true){
            this.sniffer = defaultSniffer
          } else {
            this.sniffer = {}
          }
          this.compatibilityModel = result ?? false
          let config = await SocketProxyService.queryOverride(OverrideSlot.Persist)
          config.sniffer = this.sniffer
          SocketProxyService.patchOverride(OverrideSlot.Persist, config)
          this.fetchConfigList()
        }})
        Text("Sniffer Setting").padding({left:20, right:20, bottom: 20})
        ForEach(this.snifferItems, (item:ConfigItem)=>{
          this.ConfigItemBuilder(item)
        }, (d: ConfigItem)=> JSON.stringify(d))
      }.alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.Start).width('100%').height('100%')
    }.title("网络")
  }
}


@Component
export struct SettingsPage {
  @Consume('router') routerInfos: NavPathStack
  @StorageLink('backgroundModel') backgroundModel: boolean = true
  async aboutToAppear(): Promise<void> {
    // let configs = await SocketProxyService.queryConfiguration()
    // console.log("SettingsPage ", configs)
    let config = await SocketProxyService.queryOverride(OverrideSlot.Persist)
    config.dns = {
      enable: true,
      "use-hosts": true
    } as Dns
    console.log("SettingsPage queryOverride", JSON.stringify(config))

  }
  build() {
    NavDestination() {
      Column() {
        ActionLabel({ title:"后台运行", subTitle:"通过模拟下载来实现后台运行", isSwitch: this.backgroundModel, icon:"ic_baseline_vpn_lock", change: async (result)=>{
          this.backgroundModel = result ?? false
        }})
        ActionLabel({ title:"Meta Features", icon:"ic_baseline_meta", change:()=>{
          this.routerInfos.pushPath({name:"MetaFeaturesPage"})
        }})
      }.width('100%').height('100%')
    }.title("设置")
  }
}

const defaultSniffer: Sniffer = {
  enable: true,
  "force-dns-mapping": true,
  "parse-pure-ip": true,
  "override-destination": true,
  "sniff":{
    "HTTP": {
      ports:["80","8080-8880"],
      "override-destination":true
    },
    "TLS": {
      ports:["443","8443"]
    },
    "QUIC":{
      ports:["443","8443"]
    }
  },
} as Sniffer
export async function patchSniffer(compatibilityModel: boolean){
  let config = await SocketProxyService.queryOverride(OverrideSlot.Persist)
  if(config.dns == undefined && compatibilityModel){
    config.dns = {
      enable: true,
      "use-hosts": true
    } as Dns
  }
  if(config.sniffer == undefined && compatibilityModel){
    config.sniffer = defaultSniffer
  }
   SocketProxyService.patchOverride(OverrideSlot.Persist, config)
}