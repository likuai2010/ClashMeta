import { socket } from '@kit.NetworkKit';
import { RpcRequest } from './RpcRequest';
import {  util } from '@kit.ArkTS';
import json from '@ohos.util.json';
import { ClashRpcType } from '../ipc/IClashManager';
import {
  nativeClearOverride,
  nativeFetchAndValid,
  nativeForceGc,
  nativeHealthCheck,
  nativeLoad,
  nativePatchSelector,
  nativeQueryConfiguration,
  nativeQueryGroup, nativeQueryGroupNames,
  nativeQueryProviders,
  nativeQueryTrafficTotal, nativeQueryTunnelState,
  nativeReadOverride,
  nativeReset,
  nativeSubscribeLogcat,
  nativeUpdateProvider,
  nativeWriteOverride} from 'libentry.so';
import { common } from '@kit.AbilityKit';
import { ProfileViewModel } from '../entryability/ProfileViewModel';
import { ClashVpnService } from '../entryability/ClashVpnService';
import { OverrideSlot } from '../entryability/ClashViewModel';

export class  SocketStubService{
  server: socket.LocalSocketServer = socket.constructLocalSocketServerInstance();
  clientPool: Map<number, socket.LocalSocketConnection>

  constructor() {
    this.clientPool = new Map()
  }
  async onRemoteMessageRequest(client: socket.LocalSocketConnection, message: socket.LocalSocketMessageInfo): Promise<void>{
    let decoder = new util.TextDecoder()
    let request = json.parse(decoder.decodeToString(new Uint8Array(message.message))) as RpcRequest
    let code = request.method
    let params = request.params
    console.debug("socketService stub request", JSON.stringify(request))
    if(code == ClashRpcType.setLogObserver){
      // 订阅日志，需要持续输出
      nativeSubscribeLogcat((value)=>{
        this.sendClient(client, value)
      })
    }  else if(code == ClashRpcType.fetchAndValid){
      nativeFetchAndValid(params[0] as string, params[1] as string, params[2] as boolean, (type:string, value: string)=>{
        console.debug("socketService stub result", type)
        this.sendClient(client, json.stringify({type:type, value: value}))
        if (type == "fetch_complete")
            client.close()
      })
    } else {
      let result = await this.onRemoteMessage(code, params)
      console.debug("socketService stub result", result)
      this.sendClient(client, json.stringify({ result: result}))
    }
  }
  onRemoteMessage(code: number, data: (string | number| boolean)[]): Promise<string | number | boolean> {
    // 根据code处理客户端的请求
    return new Promise(async (resolve, reject) => {
      switch (code){
        case ClashRpcType.queryTunnelState: {
          resolve(nativeQueryTunnelState())
          break;
        }
        case ClashRpcType.queryTrafficTotal:{
          resolve(nativeQueryTrafficTotal())
          break;
        }
        case ClashRpcType.queryProxyGroupNames:{
          resolve(nativeQueryGroupNames(data[0] as boolean))
          break;
        }
        case ClashRpcType.queryProxyGroup:{
          resolve(nativeQueryGroup(data[0] as string, data[1] as string))
          break;
        }
        case ClashRpcType.queryProxyGroup:{
          resolve(nativeQueryGroup(data[0] as string, data[1] as string))
          break;
        }
        case ClashRpcType.queryProviders:{
          resolve(nativeQueryProviders())
          break;
        }
        case ClashRpcType.patchSelector:{
          resolve(nativePatchSelector(data[0] as string, data[1] as string))
          break;
        }
        case ClashRpcType.healthCheck:{
          nativeHealthCheck(data[0] as string,(value)=>{
            resolve(value)
          })
          break;
        }
        case ClashRpcType.updateProvider:{
          nativeUpdateProvider(data[0] as string, data[1] as string,()=>{
            resolve(true)
          })
          break;
        }
        case ClashRpcType.queryOverride:{
          resolve(nativeReadOverride(data[0] as number))
          break;
        }
        case ClashRpcType.patchOverride:{
          nativeWriteOverride(data[0] as number, data[1] as string)
          resolve(true)
          break;
        }
        case ClashRpcType.clearOverride:{
          nativeClearOverride(data[0] as number)
          resolve(true)
          break;
        }
        case ClashRpcType.queryConfiguration:{
          resolve(nativeQueryConfiguration())
          break;
        }
        case ClashRpcType.load:{
          nativeLoad(data[0] as string, (e)=>{
            resolve(e)
          })
          break;
        }
        case ClashRpcType.reset:{

          resolve(true)
          break;
        }
        case ClashRpcType.startClash:{
          nativeReset()
          nativeClearOverride(OverrideSlot.Session)
          this.startVpn().then(()=>{
            resolve(true)
          }).catch((e:Error)=>{
            resolve(e.message)
          })
          break;
        }
        case ClashRpcType.stopClash:{
          this.stopVpn()
          resolve(true)
          break;
        }
      }
    })
  }
  async sendClient(client: socket.LocalSocketConnection, message: string){
    await client.send({data: message, encoding:"utf-8"})
  }
  profileViewModel: ProfileViewModel = new  ProfileViewModel()
  clashVpnService = new ClashVpnService();
  async onConnect(context: common.Context){
    try {
      this.profileViewModel.init(context)
      this.clashVpnService.init(await this.profileViewModel.getHome(), context)

      const socketPath = context.filesDir + '/ipc_socket'
      await this.server.listen({ address: socketPath})
      this.server.on('connect', (client: socket.LocalSocketConnection) => {
          this.clientPool.set(client.clientId, client);
          client.on("message", (value: socket.LocalSocketMessageInfo) => {
            this.onRemoteMessageRequest(client, value)
          })
          client.on('close', () => {
            client.off("message")
            client.off("close")
            this.clientPool.delete(client.clientId);
          });
      })
    } catch (e) {
      console.error("socketService", e.message)
    }
  }
  async startVpn(){
    const profile = await this.profileViewModel.getActive()
    if (profile != undefined){
      let configPath = await this.profileViewModel.getConfigPath(profile)
      let selections = await this.profileViewModel.getSelection(profile.uuid)
      await this.clashVpnService.StartVpn(configPath, selections)
    } else {
      console.log("ClashVPN", `配置文件 没有加载 `);
    }
  }
  stopVpn(){
    this.clashVpnService?.stopVpn()
  }
}
function sleepTime(timeout = 100): Promise<void>{
  return new Promise((resolve)=>{
    setTimeout(resolve, timeout)
  })
}