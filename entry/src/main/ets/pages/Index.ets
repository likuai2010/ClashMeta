import { vpnExtension } from '@kit.NetworkKit';
import { common, Want } from '@kit.AbilityKit';
import { Icon } from './compoments/icons';
import { ActionCard,  ActionLabel } from './compoments/common';
import { NetworkSettingsPage, SettingsPage } from './SettingsPage';
import { ConfigEditPage, ConfigsPage } from './ConfigEditPage';
import { ProxysPage } from './ProxyPage';
import profileViewModel, { ProfileViewModel } from '../entryability/ProfileViewModel';
import clashProxyService from '../ipc/ClashProxyService';
import { Profile } from '../entryability/ProfileRepo';
import { ConfigViewer } from './ConfigViewer';
import logger from '../pages/logs';
import { promptAction } from '@kit.ArkUI';
import { ClashVpnService } from '../entryability/ClashVpnService';
import { rpc } from '@kit.IPCKit';

let want: Want = {
  deviceId: "",
  bundleName: "com.xiaobai.clash",
  abilityName: "ClashVpnAbility",
};

@Builder
function PageRouter(name: string) {
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
  } else if (name === "config-viewer") {
    ConfigViewer()
  }
}


@Entry
@Component
struct Index {

  vpnConnection = vpnExtension.createVpnConnection(getContext(this) as common.VpnExtensionContext);
  @Provide('router') routerInfos: NavPathStack = new NavPathStack()
  @State running: boolean = false;
  @State profile: Profile | undefined = undefined
  async aboutToAppear(): Promise<void> {
    this.profile = await profileViewModel.getActive()
    // let result = await clashProxyService.start(getContext(this) as common.UIAbilityContext)
    // this.running = result
     //  clashViewModel.init(getContext(this))
     // clashViewModel.load()
    // this.routerInfos.setInterception({
    //   willShow: async (from: NavDestinationContext | "navBar", to: NavDestinationContext | "navBar",
    //     operation: NavigationOperation, animated: boolean) => {
    //   }
    // })
  }

  async startVpn(){
    logger.clear()
    logger.log("index","开启vpn后台服务")
    let profile = await profileViewModel.getActive()
    this.profile = profile
    if(!profile){
      promptAction.showToast({message:"没有选择配置文件"})
      return
    }
    await vpnExtension.startVpnExtensionAbility(want);
    this.running = true

  }
  async stopVpn(){
    this.running = false
    await vpnExtension.stopVpnExtensionAbility(want)
    clashProxyService.stop(getContext(this) as common.UIAbilityContext)
  }
  scroller: Scroller = new Scroller();

  async testVpn(){
    const clashVpnService = new ClashVpnService(await profileViewModel.getHome());
    const profile = await profileViewModel.getActive()
    if (profile != undefined){
      let configPath = await profileViewModel.getConfigPath(profile)
      clashVpnService.StartVpn(configPath, getContext(this), [])
    }else{
      logger.log("ClashVPN", `配置文件 没有加载 `);
    }
  }

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
              ActionCard({title:"已停止", value: "点击启动", isRunning: this.running, icon:"ic_outline_not_interested", click: async ()=>{
                this.startVpn()
              } })
            }else{
              ActionCard({title:"运行中", value: "已转发",  isRunning: this.running,  icon:"ic_outline_check_circle", click: async ()=>{
                this.stopVpn()
              }})
              ActionCard({title:"代理", value: "规则模式", icon:"ic_baseline_apps", click: async ()=>{
                try {
                  this.routerInfos.pushPath({name:"proxys"})
                } catch (e) {
                  promptAction.showToast({message:"rpc服务启动失败: " + e})
                }
              }})
            }
            ActionCard({title:"配置", value: !this.profile ? "未选择": this.profile.name, icon:"ic_baseline_view_list", click:()=>{
              this.routerInfos.pushPath({name:"configs"})
            }})
            ActionLabel({title:"日志", icon:"ic_baseline_view_list", click:()=>{
              this.routerInfos.pushPath({name: "config-viewer", param: "/data/storage/el2/base/haps/entry/files/log.txt"})
            }})
            ActionLabel({title:"设置", icon:"ic_baseline_settings", click:()=>{

              //this.routerInfos.pushPath({name:"settings"})
            }})
            // ActionLabel({title:"关于", icon:"ic_baseline_info"})
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

