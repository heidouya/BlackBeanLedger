import { AbilityConstant, common, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { RecordDatabase } from '../database/RecordDatabase';
import { ThemePreferences } from '../utils/ThemePreferences';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 先初始化偏好设置，再根据保存的模式切换深浅色
    ThemePreferences.getInstance().init(this.context).then(() => {
      const mode: string = ThemePreferences.getInstance().getColorModeSync();
      try {
        const appCtx: common.ApplicationContext = this.context.getApplicationContext();
        switch (mode) {
          case 'light':
            appCtx.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
            break;
          case 'dark':
            appCtx.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
            break;
          default:
            appCtx.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
            break;
        }
      } catch (err) {
        hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
      }
    }).catch((err: Error) => {
      hilog.error(DOMAIN, 'testTag', 'ThemePreferences init failed: %{public}s', err.message);
    });
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 先初始化数据库，完成后再加载页面（onCreate不支持async，必须在此等待）
    RecordDatabase.getInstance().initDatabase(this.context).then(() => {
      hilog.info(DOMAIN, 'testTag', '数据库初始化成功');
      windowStage.loadContent('pages/Index', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
      });
    }).catch((err: Error) => {
      hilog.error(DOMAIN, 'testTag', '数据库初始化失败: %{public}s', err.message);
      // 即使DB失败也尝试加载页面（Index内部有错误处理）
      windowStage.loadContent('pages/Index', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
      });
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
