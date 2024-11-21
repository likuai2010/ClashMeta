import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { CommonConstants, RpcResult } from './RpcRequest';
import { JSON, util } from '@kit.ArkTS';
import { ClashRpcType, IClashManager, ProviderList, ProviderType } from '../ipc/IClashManager';
import { ConfigurationOverride,
  OverrideSlot,
  ProxyGroup, ProxySort, TunnelState } from '../entryability/ClashViewModel';


export class  SocketProxyService implements IClashManager{
  private ipAddress: socket.NetAddress = {
    address: CommonConstants.IP_ADDRESS,
    port: CommonConstants.IP_PORT
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

  queryProviders(): Promise<ProviderList> {
    throw new Error('Method not implemented.');
  }

  async patchSelector(group: string, name: string): Promise<boolean> {
    let result = await this.sendMessageRequest(ClashRpcType.patchSelector,[group, name])
    return result as boolean
  }

  async healthCheck(group: string): Promise<void> {
    await this.sendMessageRequest(ClashRpcType.healthCheck, [group])
  }

  updateProvider(type: ProviderType, name: string): Promise<void> {
    throw new Error('Method not implemented.');
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
  async sendMessageRequest(
    method: number,
    params: (string| number | boolean) [] = []
  ): Promise<string| number | boolean | undefined>{
    let tcp: socket.TCPSocket = socket.constructTCPSocketInstance();

    return new Promise(async (resolve, reject)=>{
      tcp.on('message', (value: socket.SocketMessageInfo) => {
        let text = new util.TextDecoder()
        let json = JSON.parse(text.decodeToString(new Uint8Array(value.message))) as RpcResult
        console.log("SocketProxyService callack", json.result)
        resolve(json.result)
        tcp.close();
      })
      tcp.on("error", ()=>{
        console.log("SocketProxyService error" )
      })
      tcp.on('connect', () => {
        let tcpSendOptions: socket.TCPSendOptions = {} as socket.TCPSendOptions;
        tcpSendOptions.data = "";
        tcp.send({ data: JSON.stringify({method, params}) });
      });
      tcp.on('close', () => {});
      await tcp.bind(this.ipAddress)
      tcp.connect({address:this.ipAddress, timeout: CommonConstants.TCP_CONNECT_TIMEOUT}, (err: BusinessError) => {
        if (err) {
          reject()
          return;
        }
      });
    })
  }
}

export default new SocketProxyService()