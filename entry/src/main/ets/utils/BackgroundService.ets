import { Context, WantAgent, wantAgent } from "@kit.AbilityKit";
import { backgroundTaskManager } from "@kit.BackgroundTasksKit";
import { notificationManager } from "@kit.NotificationKit";
import { BusinessError } from "@kit.BasicServicesKit";
import SocketProxyService from "../rpc/SocketProxyService";
import { http } from "@kit.NetworkKit";


export class BackgroundService{
  client = http.createHttp()
  notificationId?: number = undefined
  ping: number = 0
  notice:number = 0
  async start(context:Context){
    if(this.notificationId)
      return
    let id = await this.startContinuousTask(context)
    this.notificationId = id;
    clearInterval(this.ping)
    clearInterval(this.notice)
    this.ping = setInterval(async ()=>{
      this.client.request("http://localhost")
    },30000)
    this.updateTraffic()
    this.notice = setInterval(async ()=> {
      this.updateTraffic()
    }, 5000)
  }
  async updateTraffic(): Promise<void>{
    let now = await SocketProxyService.queryTrafficNow()
    let result = await SocketProxyService.queryTrafficTotal()
    let message = `${now.trafficUpload()}s↑\t${now.trafficDownload()}s↓`
    console.log("updateProcess ", message);
    this.updateProcess(this.notificationId ?? 0, message )
  }

  stop(context:Context){
    this.notificationId = undefined
    clearInterval(this.ping)
    clearInterval(this.notice)
    backgroundTaskManager.stopBackgroundRunning(context)
  }
  updateProcess(id: number, message:string){
    let downLoadTemplate: notificationManager.NotificationTemplate = {
      name: 'downloadTemplate', // 当前只支持downloadTemplate，保持不变
      data: {
        title: '正在运行', // 必填。
        fileName: message, // 必填。
        progressValue: (Math.random() * 100), // 应用更新进度值，自定义。
      }
    };
    let request: notificationManager.NotificationRequest = {
      content: {
        // 系统实况类型，保持不变
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_SYSTEM_LIVE_VIEW,
        systemLiveView: {
          typeCode: 8, // 上传下载类型需要填写 8，当前仅支持此类型。保持不变
          title: "clash", // 应用自定义
          text: "clash", // 应用自定义
        },
      },
      id: id, // 必须是申请长时任务返回的id，否则应用更新通知失败。
      notificationSlotType: notificationManager.SlotType.LIVE_VIEW, // 实况窗类型，保持不变
      template: downLoadTemplate,
    };
    try {
      notificationManager.publish(request).then(() => {
        console.info("publish success, id= " + id);
      }).catch((err: BusinessError) => {
        console.error(`publish fail: ${JSON.stringify(err)}`);
      });
    } catch (err) {
      console.error(`publish fail: ${JSON.stringify(err)}`);
    }
  }


  async startContinuousTask(context:Context): Promise<number>{
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
}

export default  new BackgroundService()