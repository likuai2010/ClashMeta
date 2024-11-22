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
import { ClashVpnService } from '../entryability/ClashVpnService';


export class  SocketStubService{
  tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
  stub = new ClashStubService("SocketStubService")
  ipAddress: socket.NetAddress = {
    address: CommonConstants.IP_ADDRESS,
    port: CommonConstants.IP_PORT
  } as socket.NetAddress;

  clientPool: HashMap<string, socket.TCPSocketConnection>

  constructor() {
    this.clientPool = new HashMap()
  }
  async onRemoteMessageRequest( message: socket.SocketMessageInfo): Promise<void>{
    let decoder = new util.TextDecoder()
    let request = json.parse(decoder.decodeToString(new Uint8Array(message.message))) as RpcRequest
    let code = request.method
    let params = request.params
    const host: string = message.remoteInfo.address + message.remoteInfo.port


    console.log("SocketStubService request", host, JSON.stringify(request))
    if(code != ClashRpcType.setLogObserver){
      try {
        this.onRemoteMessage(code, params, host, (host, result) => {
          const client = this.clientPool.get(host)
          console.log("SocketStubService result", host,  result)
          this.sendClient(client, json.stringify({ result: result}))
        })
      } catch (e) {
        console.error("SocketStubService failure", e.message)
      }

    } else {
      // 订阅日志，需要持续输出
      nativeSubscribeLogcat((value)=>{
        const client = this.clientPool.get(host)
        this.sendClient(client, value)
      })
    }

  }
  // 闭包问题
  async onRemoteMessage(code: number, data: (string | number| boolean)[],host: string, resolve: (host: string, result:string | number | boolean)=> void ) {
    // 根据code处理客户端的请求
    switch (code){
      case ClashRpcType.queryTunnelState: {
        resolve(host, nativeQueryTunnelState())
        break;
      }
      case ClashRpcType.queryTrafficTotal:{
        resolve(host,nativeQueryTrafficTotal())
        break;
      }
      case ClashRpcType.queryProxyGroupNames:{
        resolve(host, nativeQueryGroupNames(data[0] as boolean))
        break;
      }
      case ClashRpcType.queryProxyGroup:{
        resolve(host, nativeQueryGroup(data[0] as string, data[1] as string))
        break;
      }
      case ClashRpcType.queryProxyGroup:{
        resolve(host, nativeQueryGroup(data[0] as string, data[1] as string))
        break;
      }
      case ClashRpcType.queryProviders:{
        resolve(host, nativeQueryProviders())
        break;
      }
      case ClashRpcType.patchSelector:{
        resolve(host, nativePatchSelector(data[0] as string, data[1] as string))
        break;
      }
      case ClashRpcType.healthCheck:{
        nativeHealthCheck(data[0] as string,(value)=>{
          resolve(host, value)
        })
        break;
      }
      case ClashRpcType.updateProvider:{
        await new Promise<boolean>((resovle)=>{
          nativeUpdateProvider(data[0] as string, data[1] as string, ()=>{
            console.debug("SocketStubService updateProvider finished")
            resovle(true)
          })
        })
        resolve(host, true)
        break;
      }
      case ClashRpcType.queryOverride:{
        resolve(host, nativeReadOverride(data[0] as number))
        break;
      }
      case ClashRpcType.patchOverride:{
        nativeWriteOverride(data[0] as number, data[1] as string)
        resolve(host, true)
        break;
      }
      case ClashRpcType.clearOverride:{
        nativeClearOverride(data[0] as number)
        resolve(host, true)
        break;
      }
      case ClashRpcType.queryConfiguration:{
        resolve(host, nativeQueryConfiguration())
        break;
      }
      case ClashRpcType.load:{
        nativeLoad(data[0] as string, (e)=>{
          resolve(host, e)
        })
        break;
      }
      case ClashRpcType.vpnStarted:{
        let timeout = true
        while (true){
          await sleepTime(100)
          if(this.vpnService?.running){
            timeout = false
            resolve(host, true)
            break;
          }
        }
        setTimeout(()=>{
          if (timeout)
            resolve(host,false)
        }, 2000)
        break;
      }
    }
  }
  async sendClient(client: socket.TCPSocketConnection, message: string){
    await client.send({data: message, encoding:"utf-8"})
  }
  vpnService?:ClashVpnService
  setVpnService(service:ClashVpnService){
    this.vpnService = service
  }
  onConnect(){
    this.tcpServer.listen(this.ipAddress, (err: BusinessError) => {
      if (err) {
        console.debug("SocketStubService listen failure ", err.message)
        return;
      }
      console.debug("SocketStubService listen finished ")
      this.tcpServer.on('connect', async (client: socket.TCPSocketConnection) => {
        const remote: socket.NetAddress = await client.getRemoteAddress()
        console.debug("SocketStubService connect ", remote.address + remote.port)
        this.clientPool.set(remote.address + remote.port, client);
        client.on("message", (value: socket.SocketMessageInfo) => {
          console.log("SocketStubService message", value.remoteInfo.address + value.remoteInfo.port)


          this.onRemoteMessageRequest(value)
        })
        client.on('close',async  () => {
          client.off("message")
          client.off("close")
          const remoteInfo: socket.NetAddress = await client.getRemoteAddress()
          console.debug("SocketStubService close ", remoteInfo.address + remoteInfo.port)

          this.clientPool.remove(remote.address + remoteInfo.port);
        });
      })
    })
  }
}
function sleepTime(timeout = 100): Promise<void>{
  return new Promise((resolve)=>{
    setTimeout(resolve, timeout)
  })
}