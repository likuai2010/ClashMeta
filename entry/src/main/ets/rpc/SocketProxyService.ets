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
class Traffic {
  private value: number;

  constructor(value: number) {
    this.value = value;
  }

  trafficUpload(): string {
    return this.trafficString(this.scaleTraffic(this.value >>> 32));
  }

  trafficDownload(): string {
    return this.trafficString(this.scaleTraffic(this.value & 0xFFFFFFFF));
  }

  trafficTotal(): string {
    const upload = this.scaleTraffic(this.value >>> 32);
    const download = this.scaleTraffic(this.value & 0xFFFFFFFF);

    return this.trafficString(upload + download);
  }

  private trafficString(scaled: number): string {
    if (scaled > 1024 * 1024 * 1024 * 100) {
      const data = scaled / 1024 / 1024 / 1024;
      return `${(data / 100).toFixed(2)} GiB`;
    } else if (scaled > 1024 * 1024 * 100) {
      const data = scaled / 1024 / 1024;
      return `${(data / 100).toFixed(2)} MiB`;
    } else if (scaled > 1024 * 100) {
      const data = scaled / 1024;
      return `${(data / 100).toFixed(2)} KiB`;
    } else {
      return `${scaled} Bytes`;
    }
  }

  private scaleTraffic(value: number): number {
    const type = (value >>> 30) & 0x3;
    const data = value & 0x3FFFFFFF;

    switch (type) {
      case 0:
        return data;
      case 1:
        return data * 1024;
      case 2:
        return data * 1024 * 1024;
      case 3:
        return data * 1024 * 1024 * 1024;
      default:
        throw new Error("Invalid value type");
    }
  }
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

  async queryTrafficTotal(): Promise<Traffic> {
    let result = await this.sendMessageRequest(ClashRpcType.queryTrafficTotal)
    return new Traffic(result as number);
  }
  async queryTrafficNow(): Promise<Traffic> {
    let result = await this.sendMessageRequest(ClashRpcType.queryTrafficNow)
    return new Traffic(result as number);
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
    await this.sendMessageRequest(ClashRpcType.patchOverride,[ slot , JSON.stringify(configuration) ])
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
    return new Promise(async (resolve, reject)=>{
      let client: socket.LocalSocket = socket.constructLocalSocketInstance();
      let messageBuffer = ""
      client.on('message', async (value: socket.LocalSocketMessageInfo) => {
        let text = new util.TextDecoder()
        console.log("socketService proxy callack",  value.message.byteLength, value.size)
        let result = text.decodeToString(new Uint8Array(value.message))
        try {
          let json = JSON.parse(messageBuffer + result) as RpcResult
          resolve(json.result)
          client.close();
        } catch (e) {
          messageBuffer += result
        }
      })
      client.on("error", ()=>{
        console.log("socketService proxy error" )
        reject("失败")
      })
      const socketPath = this.context?.filesDir + '/ipc_socket'

      client.connect({address: { address: socketPath }, timeout:1000}).then(async ()=>{
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