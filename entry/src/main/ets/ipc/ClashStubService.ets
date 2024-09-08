import { hilog } from '@kit.PerformanceAnalysisKit';
import { rpc } from '@kit.IPCKit';
import { ClashRpcType } from './IClashManager';
import {
  nativeClearOverride,
  nativeHealthCheck,
  nativeLoad,
  nativePatchSelector,
  nativeQueryConfiguration,
  nativeQueryGroup,
  nativeQueryGroupNames,
  nativeQueryProviders,
  nativeQueryTrafficTotal,
  nativeQueryTunnelState,
  nativeReadOverride,
  nativeUpdateProvider,
  nativeWriteOverride} from 'libentry.so';


export class ClashStubService extends rpc.RemoteObject {
  constructor(descriptor: string) {
    super(descriptor);
  }

  onRemoteMessageRequest(code: number, data: rpc.MessageSequence, reply: rpc.MessageSequence, option: rpc.MessageOption): boolean | Promise<boolean> {
    // 根据code处理客户端的请求
    hilog.info(0x0000, 'testTag', `rpcServer  ${code}`, );
    if(!reply)
      return false;
    if(data.readInterfaceToken() != "IClashManager")
      return false;
    return new Promise((resolve, reject)=>{
      switch (code){
        case ClashRpcType.queryTunnelState: {
          reply.writeNoException()
          reply.writeString(nativeQueryTunnelState())
          resolve(true)
          break;
        }
        case ClashRpcType.queryTrafficTotal:{
          reply.writeNoException()
          reply.writeLong(nativeQueryTrafficTotal())
          resolve(true)
          break;
        }
        case ClashRpcType.queryProxyGroupNames:{
          reply.writeNoException()
          reply.writeString(nativeQueryGroupNames(data.readBoolean()))
          resolve(true)
          break;
        }
        case ClashRpcType.queryProxyGroup:{
          reply.writeNoException()
          reply.writeString(nativeQueryGroup(data.readString(), data.readString()))
          resolve(true)
          break;
        }
        case ClashRpcType.queryProxyGroup:{
          reply.writeNoException()
          reply.writeString(nativeQueryGroup(data.readString(), data.readString()))
          resolve(true)
          break;
        }
        case ClashRpcType.queryProviders:{
          reply.writeNoException()
          reply.writeString(nativeQueryProviders())
          resolve(true)
          break;
        }
        case ClashRpcType.patchSelector:{
          reply.writeNoException()
          reply.writeBoolean(nativePatchSelector(data.readString(), data.readString()))
          resolve(true)
          break;
        }
        case ClashRpcType.healthCheck:{
          reply.writeNoException()
          nativeHealthCheck(data.readString(),()=>{
            reply.writeString("")
            resolve(true)
          })
          break;
        }
        case ClashRpcType.updateProvider:{
          reply.writeNoException()
          nativeUpdateProvider(data.readString(),data.readString(),()=>{
            reply.writeString("")
            resolve(true)
          })
          break;
        }
        case ClashRpcType.queryOverride:{
          reply.writeNoException()
          reply.writeString(nativeReadOverride(data.readInt()))
          resolve(true)
          break;
        }
        case ClashRpcType.patchOverride:{
          reply.writeNoException()
          nativeWriteOverride(data.readInt(), data.readString())

          resolve(true)
          break;
        }
        case ClashRpcType.clearOverride:{
          reply.writeNoException()
          nativeClearOverride(data.readInt())
          resolve(true)
          break;
        }
        case ClashRpcType.setLogObserver:{
          reply.writeNoException()
          // data.readParcelable()
          // reply.writeString(set(data.readString(), data.readString()))
          resolve(true)
          break;
        }
        case ClashRpcType.queryConfiguration:{
          reply.writeNoException()
          // data.readParcelable()
          reply.writeString(nativeQueryConfiguration())
          resolve(true)
          break;
        }
        case ClashRpcType.load:{
          reply.writeNoException()
          nativeLoad(data.readString(), (e)=>{
            console.debug("onload", e)
            resolve(true)
          })
          break;
        }
      }
    })
  }
}
