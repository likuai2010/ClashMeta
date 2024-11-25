import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import profileViewModel from '../entryability/ProfileViewModel';
import { vpnExtension } from '@kit.NetworkKit';
import SocketProxyService from '../rpc/SocketProxyService';
import { Dns, OverrideSlot, Sniffer } from './ClashViewModel';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
    this.init()
  }
  async  init(){
    await profileViewModel.init(this.context)
    try {
      await vpnExtension.startVpnExtensionAbility({
        deviceId: "",
        bundleName: "com.xiaobai.clash",
        abilityName: "ClashVpnAbility",
      });
    } catch (e) {
      console.error("init vpn service", e.message | e)
      this.context.terminateSelf()
    }
    setTimeout(()=>{
       this.patch()
    }, 500)
  }
  async patch(){
    let config = await SocketProxyService.queryOverride(OverrideSlot.Persist)
    config.dns = {
      enable: true,
      "use-hosts": true
    } as Dns
    config.sniffer = {
      enable: true,
      "force-dns-mapping": true,
      "parse-pure-ip": true,
      "override-destination": true,
      "sniff":{
        "HTTP": {
          ports:["80","8080-8880"],
          "override-destination":true
        },
        "TLS": {
          ports:["443","8443"]
        },
        "QUIC":{
          ports:["443","8443"]
        }
      },
    } as Sniffer
    SocketProxyService.patchOverride(OverrideSlot.Persist, config)
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  async  onWindowStageCreate(windowStage: window.WindowStage):  Promise<void> {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    await profileViewModel.initGeoIp()
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      PersistentStorage.persistProp('lastGroupName', "");
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }
};
