import { socket } from '@kit.NetworkKit';
import { CommonConstants, RpcRequest, RpcResult } from './RpcRequest';
import { BusinessError } from '@kit.BasicServicesKit';
import { HashMap, util } from '@kit.ArkTS';
import json from '@ohos.util.json';
import { ClashRpcType } from '../ipc/IClashManager';
import { rpc } from '@kit.IPCKit';
import { ClashStubService } from '../ipc/ClashStubService';
import { hilog } from '@kit.PerformanceAnalysisKit';
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
  nativeSubscribeLogcat,
  nativeUpdateProvider,
  nativeWriteOverride} from 'libentry.so';


export class  SocketStubService{
  tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
  stub = new ClashStubService("SocketStubService")
  ipAddress: socket.NetAddress = {
    address: CommonConstants.IP_ADDRESS,
    port: CommonConstants.IP_PORT
  } as socket.NetAddress;

  clientPool: HashMap<number, socket.TCPSocketConnection>

  constructor() {
    this.clientPool = new HashMap()
  }
  async onRemoteMessageRequest(client: socket.TCPSocketConnection, message: socket.SocketMessageInfo): Promise<void>{
    let decoder = new util.TextDecoder()
    let request = json.parse(decoder.decodeToString(new Uint8Array(message.message))) as RpcRequest
    let code = request.method
    let params = request.params
    console.log("SocketStubService request", JSON.stringify(request))
    if(code != ClashRpcType.setLogObserver){
      let result = await this.onRemoteMessage(code, params)
      console.log("SocketStubService result", result)
      this.sendClient(client, json.stringify({ result: result}))
    } else {
      // 订阅日志，需要持续输出
      nativeSubscribeLogcat((value)=>{
        this.sendClient(client, value)
      })
    }

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
          // reply.writeString(set(data.readString(), data.readString()))
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
      }
    })
  }
  async sendClient(client: socket.TCPSocketConnection, message: string){
    await client.send({data: message, encoding:"utf-8"})
  }
  onConnect(){
    this.tcpServer.listen(this.ipAddress, (err: BusinessError) => {

      if (err) {
        console.debug("SocketStubService listen failure ", err.message)
        return;
      }
      console.debug("SocketStubService listen finished ")
      this.tcpServer.on('connect', (client: socket.TCPSocketConnection) => {
        this.clientPool.set(client.clientId, client);
        client.on("message", (value: socket.SocketMessageInfo) => {
          this.onRemoteMessageRequest(client, value)
        })
        client.on('close', () => {
          client.off("message")
          client.off("close")
          this.clientPool.remove(client.clientId);
        });
      })
    })
  }
}