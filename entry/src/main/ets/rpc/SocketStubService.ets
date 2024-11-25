import { socket } from '@kit.NetworkKit';
import { RpcRequest, RpcResult } from './RpcRequest';
import {  util } from '@kit.ArkTS';
import json from '@ohos.util.json';
import { ClashRpcType } from '../ipc/IClashManager';
import {
  nativeClearOverride,
  nativeHealthCheck,
  nativeLoad,
  nativePatchSelector,
  nativeQueryConfiguration,
  nativeQueryGroup, nativeQueryGroupNames,
  nativeQueryProviders,
  nativeQueryTrafficTotal, nativeQueryTunnelState,
  nativeReadOverride,
  nativeUpdateProvider,
  nativeWriteOverride} from 'libentry.so';
import { common } from '@kit.AbilityKit';


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
    console.log("socketService stub request", JSON.stringify(request))
    let result = await this.onRemoteMessage(code, params)
    let rpcResult = {
      result: result
    } as RpcResult
    console.log("socketService stub result", result)
    this.sendClient(client, json.stringify(rpcResult))
  }
  onRemoteMessage(code: number, data: (string | number| boolean)[]): Promise<string | number | boolean> {
    // 根据code处理客户端的请求
    return new Promise((resolve, reject)=>{
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
        case ClashRpcType.setLogObserver:{
          // data.readParcelable()
          // reply.writeString(set(data.readString(), data.readString()))
          resolve(true)
          break;
        }
        case ClashRpcType.queryConfiguration:{
          // data.readParcelable()
          resolve(nativeQueryConfiguration())
          break;
        }
        case ClashRpcType.load:{

          nativeLoad(data[0] as string, (e)=>{
            resolve(e)
          })
          break;
        }
      }
    })
  }
  async sendClient(client: socket.LocalSocketConnection, message: string){
    await client.send({data: message, encoding:"utf-8"})
  }
  async onConnect(context: common.Context){
    try {
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
}