import { socket } from '@kit.NetworkKit';
import {  RpcResult } from './RpcRequest';
import { JSON, util } from '@kit.ArkTS';
import { ClashRpcType, IClashManager, Provider, ProviderType } from '../ipc/IClashManager';
import { ConfigurationOverride,
  OverrideSlot,
  ProxyGroup, ProxySort, TunnelState } from '../entryability/ClashViewModel';
import { common } from '@kit.AbilityKit';
import { FetchStatus } from '../entryability/ProfileViewModel';
import { promptAction } from '@kit.ArkUI';

interface FetchInfo{
  type: string
  value: string
}
export class  SocketProxyService implements IClashManager{
  context?: common.Context
  init(context: common.Context) {
    this.context = context
  }
  async setLogObserver(observer: (message:string) => void): Promise<()=>void> {
    return this.callbackRequest(ClashRpcType.setLogObserver, [], observer)
  }
  async fetchAndValid(configPath:string, url:string, force: boolean, callback: (type:string, value:string)=>void){
   return this.callbackRequest(ClashRpcType.fetchAndValid, [configPath, url, force], async (message:string)=>{
      console.debug("fetchAndValid", message)
      const json = JSON.parse(message) as FetchInfo
      callback(json.type, json.value)
    })
  }
  async load(path: string): Promise<void> {
    await this.sendMessageRequest(ClashRpcType.load, [path])
  }



  async queryTunnelState(): Promise<TunnelState> {
    let result = await this.sendMessageRequest(ClashRpcType.queryTunnelState, [])
    return result as TunnelState;
  }

  async queryTrafficTotal(): Promise<number> {
    let result = await this.sendMessageRequest(ClashRpcType.queryTrafficTotal)
    return result as number;
  }

  async queryProxyGroupNames(excludeNotSelectable: boolean): Promise<string[]> {
    let result = await this.sendMessageRequest(ClashRpcType.queryProxyGroupNames,[excludeNotSelectable])
    return JSON.parse(result as string) as string[];
  }

  async queryProxyGroup(name: string, proxySort: ProxySort): Promise<ProxyGroup> {
    let result = await this.sendMessageRequest(ClashRpcType.queryProxyGroup,[name, proxySort])
    return JSON.parse(result as string) as ProxyGroup
  }

  async queryConfiguration(): Promise<string> {
    let result = await this.sendMessageRequest(ClashRpcType.queryConfiguration)
    return result as string
  }

  async queryProviders(): Promise<Provider[]> {
    let result = await this.sendMessageRequest(ClashRpcType.queryProviders)
    return JSON.parse(result as string) as Provider[]
  }

  async patchSelector(group: string, name: string): Promise<boolean> {
    let result = await this.sendMessageRequest(ClashRpcType.patchSelector,[group, name])
    return result as boolean
  }

  async healthCheck(group: string): Promise<void> {
    await this.sendMessageRequest(ClashRpcType.healthCheck, [group])
  }

  async updateProvider(type: ProviderType, name: string): Promise<void> {
    await this.sendMessageRequest(ClashRpcType.updateProvider,[type, name])
    return
  }

  async queryOverride(slot: OverrideSlot): Promise<ConfigurationOverride> {
    let json = await this.sendMessageRequest(ClashRpcType.queryOverride, [slot])
    return JSON.parse(json as string) as ConfigurationOverride
  }

  async patchOverride(slot: OverrideSlot, configuration: ConfigurationOverride): Promise<void> {
    await this.sendMessageRequest(ClashRpcType.patchOverride,[ slot as numdber, JSON.stringify(configuration) ])
    return
  }

  async clearOverride(slot: OverrideSlot): Promise<void> {
    await this.sendMessageRequest(ClashRpcType.clearOverride, [slot])
  }
  async startClash():Promise<boolean>{
    let json = await this.sendMessageRequest(ClashRpcType.startClash, [])
    return json as boolean
  }
  async stopClash():Promise<boolean>{
    let json = await this.sendMessageRequest(ClashRpcType.stopClash, [])
    return json as boolean
  }
  async reset():Promise<boolean>{
    let json = await this.sendMessageRequest(ClashRpcType.reset, [])
    return json as boolean
  }

  async sendMessageRequest(
    method: number,
    params: (string| number | boolean) [] = []
  ): Promise<string| number | boolean | undefined>{
    let client: socket.LocalSocket = socket.constructLocalSocketInstance();
    console.log("socketService sendMessageRequest" )
    return new Promise(async (resolve, reject)=>{
      client.on('message', async (value: socket.LocalSocketMessageInfo) => {
        let text = new util.TextDecoder()
        console.log("socketService proxy callack", value.message.byteLength, value.size)
        let result = text.decodeToString(new Uint8Array(value.message))
        try {
          let json = JSON.parse(result) as RpcResult
          resolve(json.result)
          client.close();
        } catch (e) {
          console.log("socketService proxy callack", result)
          resolve("")
          promptAction.showToast({ message: e.message || e, duration: 2000})
        }
      })
      client.on("error", ()=>{
        console.log("socketService proxy error" )
        reject("失败")
      })
      const socketPath = this.context?.filesDir + '/ipc_socket'
      client.connect({address: { address: socketPath }, timeout:3000}).then(()=>{
        client.send({ data: JSON.stringify({method, params}) });
      }).catch((e:Error)=>{
        console.log("socketService error", e.message)
        reject(e)
      });
    })
  }
  async callbackRequest(
    method: number,
    params: (string| number | boolean) [] = [],
    callBack:(message:string)=>void
  ): Promise<()=>void>{
    return new Promise(async (resolve, reject)=>{
      let tcp: socket.LocalSocket = socket.constructLocalSocketInstance();
      tcp.on('message', (value: socket.LocalSocketMessageInfo) => {
        let text = new util.TextDecoder()
        callBack(text.decodeToString(new Uint8Array(value.message)))
      })
      tcp.on('error', (e:Error) => {
        console.log("socketService error", e.message)
        reject("失败")
      });
      const socketPath = this.context?.filesDir + '/ipc_socket'
      tcp.connect({address: { address: socketPath }, timeout:3000}).then(()=>{
        tcp.send({ data: JSON.stringify({method, params}) });
        resolve(()=>{
          tcp.close()
        })
      }).catch((e:Error)=>{
        console.log("socketService error", e.message)
        reject(e)
      });
    })
  }
}

export default new SocketProxyService()