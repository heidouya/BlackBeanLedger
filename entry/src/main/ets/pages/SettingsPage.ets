import { router } from '@kit.ArkUI';
import { ThemePreferences } from '../utils/ThemePreferences';
import { BudgetPreferences } from '../utils/BudgetPreferences';

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
 * 设置页 —— 提供预算设置、深色模式等配置入口
 */
@Entry
@Component
struct SettingsPage {
  @State colorModeLabel: string = '跟随系统';
  @State budgetLabel: string = '未设置';
  private themePrefs: ThemePreferences = ThemePreferences.getInstance();
  private budgetPrefs: BudgetPreferences = BudgetPreferences.getInstance();

  aboutToAppear(): void {
    this.refreshLabels();
  }

  onPageShow(): void {
    this.refreshLabels();
  }

  private refreshLabels(): void {
    this.colorModeLabel = getModeLabel(this.themePrefs.getColorModeSync());
    const budget: number = this.budgetPrefs.getBudgetSync();
    this.budgetLabel = budget > 0 ? `¥${budget}` : '未设置';
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
        // 预算设置项
        ListItem() {
          Row() {
            Text('每月预算')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'));

            Blank();

            Text(this.budgetLabel)
              .fontSize(14)
              .fontColor(this.budgetLabel === '未设置' ?
                $r('app.color.text_secondary') :
                $r('app.color.accent_orange'))
              .margin({ right: 4 });

            Text('›')
              .fontSize(18)
              .fontColor($r('app.color.arrow_chevron'));
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 16 });
        }
        .onClick(() => {
          router.pushUrl({ url: 'pages/BudgetSetPage' });
        });

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
