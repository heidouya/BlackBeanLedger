import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import { ThemePreferences } from '../utils/ThemePreferences';

/** 模式选项 */
class ModeOption {
  label: string = '';
  desc: string = '';
  mode: string = '';
}

/**
 * 深色模式设置页 —— 单选：普通模式 / 深色模式 / 跟随系统
 */
@Entry
@Component
struct DarkModePage {
  @State selectedMode: string = 'system';
  private options: ModeOption[] = [
    { label: '普通模式', desc: '始终使用浅色外观', mode: 'light' },
    { label: '深色模式', desc: '始终使用深色外观', mode: 'dark' },
    { label: '跟随系统', desc: '跟随系统深浅色设置自动切换', mode: 'system' }
  ];
  private prefs: ThemePreferences = ThemePreferences.getInstance();

  aboutToAppear(): void {
    this.selectedMode = this.prefs.getColorModeSync();
  }

  private async onSelect(mode: string): Promise<void> {
    this.selectedMode = mode;
    const ctx: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const appCtx: common.ApplicationContext = ctx.getApplicationContext();

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

    await this.prefs.putColorMode(mode);
    promptAction.showToast({ message: '已切换', duration: 1000 });
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Button() {
          Text('←').fontSize(22).fontColor('#212121');
        }
        .type(ButtonType.Circle)
        .backgroundColor(Color.Transparent)
        .width(40).height(40)
        .onClick(() => { router.back(); });

        Text('深色模式')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#212121')
          .layoutWeight(1)
          .textAlign(TextAlign.Center);

        Blank().width(40).height(40);
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 8 })
      .backgroundColor(Color.White);

      // 选项列表
      List() {
        ForEach(this.options, (option: ModeOption, index: number) => {
          ListItem() {
            Row() {
              Column() {
                Text(option.label)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#212121');

                Text(option.desc)
                  .fontSize(12)
                  .fontColor('#9E9E9E')
                  .margin({ top: 4 });
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1);

              // 选中标记
              Text(this.selectedMode === option.mode ? '✓' : '')
                .fontSize(20)
                .fontColor('#007AFF')
                .margin({ left: 12 });
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 16 });
          }
          .onClick(() => { this.onSelect(option.mode); });
        }, (option: ModeOption) => option.mode);

        ListItem() {
          Row()
            .width('100%')
            .height(0.5)
            .backgroundColor('#F0F0F0')
            .margin({ left: 16 });
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor(Color.White)
      .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 16 });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5');
  }
}
