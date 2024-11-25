import {  VpnExtensionAbility } from '@kit.NetworkKit';
import { Want } from '@kit.AbilityKit';
import logger from '../pages/logs';
import { SocketStubService } from '../rpc/SocketStubService';


export default class ClashVpnAbility extends VpnExtensionAbility {

  clashStubService = new SocketStubService()
  constructor() {
    super();
  }
  async  onCreate(want: Want) {
    try {
      await this.clashStubService.onConnect(this.context)
    } catch (e) {
      logger.log("ClashVPN", `启用VPN失败 ${e.message} ${e.stack}`);
    }
  }
  onDestroy(){
    logger.log("ClashVPN", `后台vpn服务(ClashVpnAbility) 退出`);
    this.clashStubService?.stopVpn();
  }
};




