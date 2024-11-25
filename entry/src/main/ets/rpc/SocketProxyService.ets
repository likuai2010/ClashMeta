import { socket } from '@kit.NetworkKit';
import {  RpcResult } from './RpcRequest';
import { JSON, util } from '@kit.ArkTS';
import { ClashRpcType, IClashManager, Provider, ProviderType } from '../ipc/IClashManager';
import { ConfigurationOverride,
  OverrideSlot,
  ProxyGroup, ProxySort, TunnelState } from '../entryability/ClashViewModel';
import { common } from '@kit.AbilityKit';

export class  SocketProxyService implements IClashManager{
  context?: common.Context
  init(context: common.Context) {
    this.context = context
  }
  async setLogObserver(observer: (message:string) => void): Promise<()=>void> {
    return this.callbackRequest(ClashRpcType.setLogObserver, [], observer)
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
    await this.sendMessageRequest(ClashRpcType.patchOverride,[slot as number,JSON.stringify(configuration) ])
    return
  }

  async clearOverride(slot: OverrideSlot): Promise<void> {
    await this.sendMessageRequest(ClashRpcType.clearOverride, [slot])
  }
  async vpnStarted():Promise<boolean>{
    let json = await this.sendMessageRequest(ClashRpcType.vpnStarted, [])
    return json as boolean
  }

  async sendMessageRequest(
    method: number,
    params: (string| number | boolean) [] = []
  ): Promise<string| number | boolean | undefined>{
    let client: socket.LocalSocket = socket.constructLocalSocketInstance();
    console.log("socketService sendMessageRequest" )
    return new Promise(async (resolve, reject)=>{
      client.on('message', (value: socket.LocalSocketMessageInfo) => {
        let text = new util.TextDecoder()
        let json = JSON.parse(text.decodeToString(new Uint8Array(value.message))) as RpcResult
        console.log("socketService proxy callack", json.result)
        resolve(json.result)
        client.close();
      })
      client.on("error", ()=>{
        console.log("socketService proxy error" )
        reject("失败")
      })
      const socketPath = this.context?.filesDir + '/ipc_socket'
      client.connect({address: { address: socketPath }, timeout:3000}).then(()=>{
        client.send({ data: JSON.stringify({method, params}) });
      }).catch((e:Error)=>{
        console.log("socketService error", e)
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
      tcp.on('error', () => {
        reject("失败")
      });
      const socketPath = this.context?.filesDir + '/ipc_socket'
      tcp.connect({address: { address: socketPath }, timeout:3000}).then(()=>{
        tcp.send({ data: JSON.stringify({method, params}) });
        resolve(()=>{
          tcp.close()
        })
      }).catch((e:Error)=>{
        console.log("socketService error", e)
        reject(e)
      });
    })
  }
}

export default new SocketProxyService()