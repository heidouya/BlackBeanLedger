import { router } from '@kit.ArkUI';
import { ThemePreferences } from '../utils/ThemePreferences';

/** 模式显示名映射 */
function getModeLabel(mode: string): string {
  switch (mode) {
    case 'light':
      return '普通模式';
    case 'dark':
      return '深色模式';
    default:
      return '跟随系统';
  }
}

/**
 * 设置页 —— 提供深色模式等配置入口
 */
@Entry
@Component
struct SettingsPage {
  @State colorModeLabel: string = '跟随系统';
  private prefs: ThemePreferences = ThemePreferences.getInstance();

  aboutToAppear(): void {
    this.colorModeLabel = getModeLabel(this.prefs.getColorModeSync());
  }

  onPageShow(): void {
    this.colorModeLabel = getModeLabel(this.prefs.getColorModeSync());
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Button() {
          Text('←').fontSize(22).fontColor($r('app.color.text_primary'));
        }
        .type(ButtonType.Circle)
        .backgroundColor(Color.Transparent)
        .width(40).height(40)
        .onClick(() => { router.back(); });

        Text('设置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center);

        Blank().width(40).height(40);
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 8 })
      .backgroundColor($r('app.color.card_background'));

      // 设置项列表
      List() {
        // 深色模式设置项
        ListItem() {
          Row() {
            Text('深色模式')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'));

            Blank();

            Text(this.colorModeLabel)
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .margin({ right: 4 });

            Text('›')
              .fontSize(18)
              .fontColor($r('app.color.arrow_chevron'));
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 16 });
        }
        .onClick(() => {
          router.pushUrl({ url: 'pages/DarkModePage' });
        });
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.card_background'))
      .divider({ strokeWidth: 0.5, color: $r('app.color.divider'), startMargin: 16 });
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'));
  }
}
