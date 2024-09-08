import {  VpnExtensionAbility } from '@kit.NetworkKit';
import { Want } from '@kit.AbilityKit';
import { ClashVpnService } from '../entryability/ClashVpnService';
import { ClashStubService } from './ClashStubService';
import { ProfileViewModel } from '../entryability/ProfileViewModel';
import logger from '../pages/logs';


export default class ClashVpnAbility extends VpnExtensionAbility {
  profileViewModel = new ProfileViewModel()
  clashVpnService:ClashVpnService | undefined
  clashStubService = new ClashStubService("ClashVpnAbility")
  constructor() {
    super();
  }
  async  onCreate(want: Want) {
    try {
      await this.profileViewModel.init(this.context)
      logger.log("ClashVPN", "后台vpn服务(ClashVpnAbility) 加载成功");
      const clashVpnService = new ClashVpnService(await this.profileViewModel.getHome());
      this.clashVpnService = clashVpnService
      const profile = await this.profileViewModel.getActive()
      if (profile != undefined){
        let configPath = await this.profileViewModel.getConfigPath(profile)
        clashVpnService.StartVpn(configPath, this.context)
      }else{
        logger.log("ClashVPN", `配置文件 没有加载 `);
      }
    } catch (e) {
      logger.log("ClashVPN", `启用VPN失败 ${e.message} ${e.stack}`);
    }
  }
  onConnect(want: Want) {
    logger.log("ClashVPN", `RPC远程服务开启 ${JSON.stringify(want)}`);
    return this.clashStubService;
  }
  onDestroy(){
    logger.log("ClashVPN", `后台vpn服务(ClashVpnAbility) 退出`);
    this.clashVpnService?.stopVpn(this.context);
  }
};




