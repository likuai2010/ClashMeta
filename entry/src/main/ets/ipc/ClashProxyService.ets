import { common, Want } from '@kit.AbilityKit';
import { rpc } from '@kit.IPCKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ProxySort, OverrideSlot, ConfigurationOverride, TunnelState,
  ProxyGroup } from '../entryability/ClashViewModel';
import { ClashRpcType, IClashManager, ProviderList, ProviderType } from './IClashManager';
import { JSON } from '@kit.ArkTS';

let want: Want = {
  // 包名和组件名写实际的值
  bundleName: "com.xiaobai.clash",
  abilityName: "ClashVpnAbility",
};
let option = new rpc.MessageOption()

class ClashProxyService implements  IClashManager{
  async load(path: string): Promise<void> {
     await this.sendMessageRequest(ClashRpcType.load, (data)=>{
      data.writeString(path)
    }, (reply)=>{
      return reply.readString()
    })
  }

  async queryTunnelState(): Promise<TunnelState> {
    let result = await this.sendMessageRequest(ClashRpcType.queryTunnelState,()=>{}, (reply)=>{
      return reply.readString()
    })
    return result as TunnelState;
  }

  async queryTrafficTotal(): Promise<number> {
    let result = await this.sendMessageRequest(ClashRpcType.queryTrafficTotal,()=>{}, (reply)=>{
      return reply.readInt()
    })
    return result as number;
  }

  async queryProxyGroupNames(excludeNotSelectable: boolean): Promise<string[]> {
    let result = await this.sendMessageRequest(ClashRpcType.queryProxyGroupNames,(data)=>{
      data.writeBoolean(excludeNotSelectable)
    }, (reply)=>{
      return reply.readString()
    })
    return JSON.parse(result as string) as string[];
  }

  async queryProxyGroup(name: string, proxySort: ProxySort): Promise<ProxyGroup> {
    let result = await this.sendMessageRequest(ClashRpcType.queryProxyGroup,(data)=>{
      data.writeString(name)
      data.writeString(proxySort)
    }, (reply)=>{
      return reply.readString()
    })
    return JSON.parse(result as string) as ProxyGroup
  }

  async queryConfiguration(): Promise<string> {
    let result = await this.sendMessageRequest(ClashRpcType.queryConfiguration,(data)=>{
    }, (reply)=>{
      return reply.readString()
    })
    return result as string
  }

  queryProviders(): Promise<ProviderList> {
    throw new Error('Method not implemented.');
  }

  async patchSelector(group: string, name: string): Promise<boolean> {
    let result = await this.sendMessageRequest(ClashRpcType.patchSelector,(data)=>{
      data.writeString(group)
      data.writeString(name)
    }, (reply)=>{
      return reply.readBoolean()
    })
    return result as boolean
  }

  healthCheck(group: string): Promise<void> {
    throw new Error('Method not implemented.');
  }

  updateProvider(type: ProviderType, name: string): Promise<void> {
    throw new Error('Method not implemented.');
  }

  async queryOverride(slot: OverrideSlot): Promise<ConfigurationOverride> {
    let json = await this.sendMessageRequest(ClashRpcType.queryOverride,(data)=>{
      data.writeInt(slot)
    }, (reply)=>{
      return reply.readString()
    })
    return JSON.parse(json as string) as ConfigurationOverride
  }

  async patchOverride(slot: OverrideSlot, configuration: ConfigurationOverride): Promise<void> {
    await this.sendMessageRequest(ClashRpcType.patchOverride,(data)=>{
      data.writeInt(slot)
      data.writeString(JSON.stringify(configuration))
    }, (reply)=>{
      return reply.readString()
    })
    return
  }

  clearOverride(slot: OverrideSlot): Promise<void> {
    throw new Error('Method not implemented.');
  }

  async sendMessageRequest(
    code: number,
    buildParams: (data: rpc.MessageSequence) => void,
    buildData: ((reply: rpc.MessageSequence) => string | number | boolean) | undefined
  ): Promise<boolean | number | string | undefined> {
    let data: rpc.MessageSequence = rpc.MessageSequence.create()
    let reply: rpc.MessageSequence = rpc.MessageSequence.create()
    try {
      data.writeInterfaceToken("IClashManager")
      buildParams(data)
      let result = await this.proxy?.sendMessageRequest(code, data, reply, option)
      result?.reply.readException()
      if(buildData){
        return buildData(result?.reply ?? reply)
      }
    } catch (e) {
      console.error("ClashProxyService rpc error", e.message)
    }finally {
      data.reclaim()
      reply.reclaim()
    }
    return undefined
  }
  // common
  proxy?: rpc.IRemoteObject;
  connectId?: number;
  async start(context: common.UIAbilityContext): Promise<boolean>{
    return new Promise((resolve, reject)=>{
      let connectId = context.connectServiceExtensionAbility(want, {
        onConnect: (elementName, remoteProxy) => {
          hilog.info(0x0000, 'ClashProxyService', 'RpcClient: connected');
          this.proxy = remoteProxy;
          resolve(true)
        },
        onDisconnect: (elementName) => {
          hilog.info(0x0000, 'ClashProxyService', 'RpcClient: onDisconnect');
          reject('RpcClient: onDisconnect')
        },
        onFailed: () => {
          hilog.info(0x0000, 'ClashProxyService', 'RpcClient: onFailed');
          reject('RpcClient: onFailed')
        }
      });
      this.connectId = connectId
    })
  }
  stop(context: common.UIAbilityContext){
    context.disconnectServiceExtensionAbility(this.connectId)
  }

}

export default  new ClashProxyService();