import { vpnExtension } from '@kit.NetworkKit';
import { bundleManager, common, Want, WantAgent, wantAgent } from '@kit.AbilityKit';
import { Icon } from './compoments/icons';
import { ActionCard,  ActionLabel } from './compoments/common';
import { ConfigItem, MetaFeaturesPage, NetworkSettingsPage, patchSniffer, SettingsPage } from './SettingsPage';
import { ConfigEditPage, ConfigsPage } from './ConfigEditPage';
import { ProxysPage } from './ProxyPage';
import profileViewModel, { ProfileViewModel } from '../entryability/ProfileViewModel';
import clashProxyService, { SocketProxyService } from '../rpc/SocketProxyService';
import { Profile } from '../entryability/ProfileRepo';
import { LogsPage } from './LogsPage';
import { promptAction } from '@kit.ArkUI';
import { ProviderPage } from './ProviderPage';
import { ConfigViewer } from './ConfigViewer';
import { ConfigItemEdit } from './ConfigItemEdit';
import { JSON } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import BackgroundService from '../utils/BackgroundService';

@Builder
function PageRouter(name: string, params:string) {
  if (name === "proxys") {
    ProxysPage()
  } else if (name === "settings") {
    SettingsPage()
  }
  else if (name === "network-settings") {
    NetworkSettingsPage()
  }
  else if (name === "configs") {
    ConfigsPage()
  }else if (name === "config-edit") {
    ConfigEditPage()
  }else if (name === "config-viewer") {
    ConfigViewer({configPath: params})
  } else if (name === "LogsPage") {
    LogsPage()
  } else if (name === "ProviderPage") {
    ProviderPage()
  }else if (name === "MetaFeaturesPage") {
    MetaFeaturesPage()
  }else if (name === "BaseSettingsPage") {
    MetaFeaturesPage()
  }
  else if (name === "ConfigItemEdit") {
    ConfigItemEdit({config: JSON.parse(params) as ConfigItem})
  }
}


@Entry
@Component
struct Index {
  @StorageLink('compatibilityModel') compatibilityModel: boolean = true
  @StorageLink('backgroundModel') backgroundModel: boolean = false
  vpnConnection = vpnExtension.createVpnConnection(getContext(this) as common.VpnExtensionContext);
  @Provide('router') routerInfos: NavPathStack = new NavPathStack()
  @State running: boolean = false;
  @State loading: boolean = false;
  @State profile: Profile | undefined = undefined
  @State version: string = ""
  async aboutToAppear(): Promise<void> {
    this.profile = await profileViewModel.getActive()
    clashProxyService.init(getContext(this))
    bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION).then((bundleInfo)=>{
      let versionName = bundleInfo.versionName;//应用版本名
      let versionNo = bundleInfo.versionCode;//应用版本号
      this.version = `${versionName}(${versionNo})`
    }).catch((error: BusinessError)=>{
      console.error("get bundleInfo failed,error is "+error)
    })
  }
  job: number = 0
  async startVpn(){
    let profile = await profileViewModel.getActive()
    this.profile = profile
    if(!profile){
      promptAction.showToast({message:"没有选择配置文件"})
      return
    }
    if(this.loading){
      return
    }
    this.loading = true
    let result = await clashProxyService.startClash()
    this.loading = false;
    this.running  = result
    profileViewModel.running = result
    if(result && this.backgroundModel){
      BackgroundService.start(getContext(this))
    }

  }
  async stopVpn(){
    if(this.loading){
      return
    }
    this.loading = true
    try {
      await clashProxyService.stopClash()
    } catch (e) {
      promptAction.showToast({message: e.message})
    }
    this.loading = false
    this.running = false
    profileViewModel.running = false
    if( this.backgroundModel){
      BackgroundService.stop(getContext(this))
    }

  }

  scroller: Scroller = new Scroller();

  build() {
    Navigation(this.routerInfos) {
      List() {
        ListItem() {
          Column() {
            Row(){
              Icon({icon:$r(`app.media.ic_baseline_meta`)})
              Text("Clash Meta For HarmonyOS").fontSize(20).fontWeight(FontWeight.Bold)
            }.padding({ top: 20 })
            if(!this.running){
              ActionCard({title:"已停止", value: "点击启动", loading: this.loading, isRunning: this.running, icon:"ic_outline_not_interested", click: async ()=>{
                await patchSniffer(this.compatibilityModel)
                this.startVpn()
              } })
            }else{
              ActionCard({title:"运行中", value: "已转发",loading: this.loading, isRunning: this.running,  icon:"ic_outline_check_circle", click: async ()=>{
                if(!this.loading){
                  this.stopVpn()
                }
              }})
              ActionCard({title:"代理", value: "规则模式", icon:"ic_baseline_apps", click: async ()=>{
                if(!this.loading){
                  this.routerInfos.pushPath({name:"proxys"})
                }
              }})
            }
            ActionCard({title:"配置", value: !this.profile ? "未选择": this.profile.name, icon:"ic_baseline_view_list", click:()=>{
              this.routerInfos.pushPath({name:"configs"})
            }})
            ActionLabel({title:"外部资源", icon:"ic_baseline_extension", change:()=>{
              if(!this.loading){
                this.routerInfos.pushPath({name:"ProviderPage"})
              }
            }})
            ActionLabel({title:"日志", icon:"ic_baseline_view_list", change:()=>{
              if(!this.loading){
                this.routerInfos.pushPath({name: "LogsPage"})
              }
            }})
            ActionLabel({title:"设置", icon:"ic_baseline_settings", change: async ()=>{
              await patchSniffer(this.compatibilityModel)
              this.routerInfos.pushPath({ name: "settings" })
            }})
            ActionLabel({title:"关于",subTitle:this.version, icon:"ic_baseline_info"})
            // Text(this.message)
            //   .fontSize(50)
            //   .fontWeight(FontWeight.Bold)
            //   .onClick(async () => {
            //     let config = new Config(this.tunIp, "");
            //     try {
            //       let tunFd = await this.vpnConnection.create(config)
            //       hilog.info(0x0000, 'testTag', 'start tun %{public}d', tunFd);
            //       testNapi.add(tunFd, 3, (fd:number)=>{
            //         hilog.info(0x0000, 'ClashMeta', 'protect tun %{public}d', fd);
            //         this.vpnConnection.protect(fd).catch((e:Error)=>{
            //           hilog.info(0x0000, 'testTag', 'protect failed %{public}s', e.message);
            //         })
            //       })
            //     } catch (e) {
            //       this.vpnConnection.destroy()
            //       hilog.info(0x0000, 'testTag', 'vpn failure %{public}s', e.message);
            //     }
            //   })
          }
        }
      }
      .height('100%')
    }.navDestination(PageRouter).mode(NavigationMode.Stack)
  }
}
