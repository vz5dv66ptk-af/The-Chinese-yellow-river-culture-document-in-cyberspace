import { abilityAccessCtrl, ConfigurationConstant, Permissions, UIAbility } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { store } from '../models/store';

const HILOG_DOMAIN = 0x0000;
const TAG = '[EntryAbility]';

export default class EntryAbility extends UIAbility {
  onCreate() {
    store.init(this.context);
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(HILOG_DOMAIN, TAG, 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(HILOG_DOMAIN, TAG, '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(HILOG_DOMAIN, TAG, '%{public}s', 'Ability onDestroy');
  }

  //收藏和笔记要跨设备同步，需要用户授权分布式数据同步权限
  private requestSyncPermission(): void {
    let perms: Permissions[] = ['ohos.permission.DISTRIBUTED_DATASYNC'];
    let at: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    at.requestPermissionsFromUser(this.context, perms).then(() => {
      hilog.info(HILOG_DOMAIN, TAG, '%{public}s', '分布式同步权限已就绪');
    }).catch((err: Error) => {
      hilog.warn(HILOG_DOMAIN, TAG, 'request sync permission failed: %{public}s', JSON.stringify(err));
    });
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(HILOG_DOMAIN, TAG, '%{public}s', 'Ability onWindowStageCreate');
    this.requestSyncPermission();

    windowStage.loadContent('pages/login', (err) => {
      if (err.code) {
        hilog.error(HILOG_DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(HILOG_DOMAIN, TAG, 'Succeeded in loading the content.');
      // 平板/2in1 上默认是悬浮小窗，主动最大化铺满屏幕（手机上本来就是全屏，无影响）
      try {
        windowStage.getMainWindowSync().maximize();
      } catch (e) {
        hilog.warn(HILOG_DOMAIN, TAG, 'maximize not supported: %{public}s', JSON.stringify(e));
      }
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(HILOG_DOMAIN, TAG, '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(HILOG_DOMAIN, TAG, '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(HILOG_DOMAIN, TAG, '%{public}s', 'Ability onBackground');
  }
}
