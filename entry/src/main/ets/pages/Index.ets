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
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import http from '@ohos.net.http';
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
    if(result){
      let id = await this.startContinuousTask()
      this.updateProcess(id)
      console.log("updateProcess ", result);
      let htt = http.createHttp()
      clearInterval(this.job)
      this.job = setInterval(async ()=> {
        let now = await clashProxyService.queryTrafficNow()
        let result = await clashProxyService.queryTrafficTotal()
        console.log("updateProcess ", now.trafficUpload(), now.trafficDownload());
        htt.request("https://baidu.com")
        this.updateProcess(id)
      }, 30000)
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
    backgroundTaskManager.stopBackgroundRunning(getContext(this))
  }
  async  startContinuousTask(): Promise<number>{
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      // 点击通知后，将要执行的动作列表
      // 添加需要被拉起应用的bundleName和abilityName
      wants: [
        {
          bundleName: "com.xiaobai.clash",
          abilityName: "EntryAbility"
        }
      ],
      // 指定点击通知栏消息后的动作是拉起ability
      actionType: wantAgent.OperationType.START_ABILITY,
      // 使用者自定义的一个私有值
      requestCode: 0,
      // 点击通知后，动作执行属性
      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };
    // 通过wantAgent模块下getWantAgent方法获取WantAgent对象
    try {
      let wantAgentObj: WantAgent =  await wantAgent.getWantAgent(wantAgentInfo)
      let list: Array<string> = ["dataTransfer"];
      let res: backgroundTaskManager.ContinuousTaskNotification = await backgroundTaskManager.startBackgroundRunning(getContext(this), list, wantAgentObj)
      return res.notificationId
    } catch (err) {
      console.error(`Failed to operation startBackgroundRunning. Code is ${err.code}, message is ${err.message}`);
      return -1
    }
  }
  updateProcess(id: number){
    let downLoadTemplate: notificationManager.NotificationTemplate = {
      name: 'downloadTemplate', // 当前只支持downloadTemplate，保持不变
      data: {
        title: '正在运行', // 必填。
        fileName: (Math.random() * 100).toFixed(2)+ ' bytes', // 必填。
        progressValue: (Math.random() * 100), // 应用更新进度值，自定义。
      }
    };
    let request: notificationManager.NotificationRequest = {
      content: {
        // 系统实况类型，保持不变
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_SYSTEM_LIVE_VIEW,
        systemLiveView: {
          typeCode: 8, // 上传下载类型需要填写 8，当前仅支持此类型。保持不变
          title: "test", // 应用自定义
          text: "test", // 应用自定义
        }
      },
      id: id, // 必须是申请长时任务返回的id，否则应用更新通知失败。
      notificationSlotType: notificationManager.SlotType.LIVE_VIEW, // 实况窗类型，保持不变
      template: downLoadTemplate // 应用需要设置的模版名称
    };
    try {
      notificationManager.publish(request).then(() => {
        console.info("publish success, id= " + this.id);
      }).catch((err: BusinessError) => {
        console.error(`publish fail: ${JSON.stringify(err)}`);
      });
    } catch (err) {
      console.error(`publish fail: ${JSON.stringify(err)}`);
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
