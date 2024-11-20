import {  VpnExtensionAbility } from '@kit.NetworkKit';
import { Want } from '@kit.AbilityKit';
import { ClashVpnService } from '../entryability/ClashVpnService';
import { ClashStubService } from './ClashStubService';
import { ProfileViewModel } from '../entryability/ProfileViewModel';
import logger from '../pages/logs';
import { JSON } from '@kit.ArkTS';
import { SocketStubService } from '../rpc/SocketStubService';


export default class ClashVpnAbility extends VpnExtensionAbility {
  profileViewModel = new ProfileViewModel()
  clashVpnService:ClashVpnService | undefined
  clashStubService = new SocketStubService()

  constructor() {
    super();
  }
  async  onCreate(want: Want) {
    try {
      this.clashStubService.onConnect()
      await this.profileViewModel.init(this.context)
      logger.log("ClashVPN", "后台vpn服务(ClashVpnAbility) 加载成功");
      const clashVpnService = new ClashVpnService(await this.profileViewModel.getHome());
      this.clashVpnService = clashVpnService
      const profile = await this.profileViewModel.getActive()
      if (profile != undefined){
        let configPath = await this.profileViewModel.getConfigPath(profile)
        let selections = await this.profileViewModel.getSelection(profile.uuid)
        await clashVpnService.StartVpn(configPath, this.context, selections)
      }else{
        logger.log("ClashVPN", `配置文件 没有加载 `);
      }
    } catch (e) {
      logger.log("ClashVPN", `启用VPN失败 ${e.message} ${e.stack}`);
    }
  }
  // onConnect(want: Want) {
  //   logger.log("ClashVPN", `RPC远程服务开启 ${JSON.stringify(want)}`);
  //   return this.clashStubService;
  // }
  onDestroy(){
    logger.log("ClashVPN", `后台vpn服务(ClashVpnAbility) 退出`);
    this.clashVpnService?.stopVpn(this.context);
  }
};




