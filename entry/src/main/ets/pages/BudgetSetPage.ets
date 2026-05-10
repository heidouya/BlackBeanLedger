import { promptAction, router } from '@kit.ArkUI';
import { BudgetPreferences } from '../utils/BudgetPreferences';

/**
 * 预算设置页 —— 用户可以设置/修改月度支出预算
 */
@Entry
@Component
struct BudgetSetPage {
  @State budgetInput: string = '';
  private prefs: BudgetPreferences = BudgetPreferences.getInstance();

  aboutToAppear(): void {
    this.loadBudget();
  }

  private loadBudget(): void {
    const current: number = this.prefs.getBudgetSync();
    this.budgetInput = current > 0 ? current.toString() : '';
  }

  private async onSave(): Promise<void> {
    const value: number = parseFloat(this.budgetInput);
    if (isNaN(value) || value <= 0) {
      promptAction.showToast({ message: '请输入有效的预算金额', duration: 2000 });
      return;
    }
    await this.prefs.putBudget(value);
    promptAction.showToast({ message: '预算已保存', duration: 1500 });
    router.back();
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

        Text('预算设置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center);

        Button() {
          Text('保存')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.accent_blue'));
        }
        .backgroundColor(Color.Transparent)
        .padding({ left: 8, right: 8 })
        .onClick(() => { this.onSave(); });
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 8 })
      .backgroundColor($r('app.color.card_background'));

      // 预算输入区
      Column() {
        Text('每月支出预算')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 10 });

        Row() {
          Text('¥')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .margin({ right: 8 });

          TextInput({ placeholder: '0.00', text: this.budgetInput })
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .type(InputType.Number)
            .layoutWeight(1)
            .backgroundColor(Color.Transparent)
            .border({ width: { bottom: 2 }, color: $r('app.color.accent_blue') })
            .placeholderColor($r('app.color.text_secondary'))
            .onChange((value: string) => { this.budgetInput = value; });
        }
        .alignItems(VerticalAlign.Center);

        Text('设为零或不填表示不限制')
          .fontSize(12)
          .fontColor($r('app.color.text_light'))
          .margin({ top: 12 });
      }
      .width('100%')
      .padding(20)
      .backgroundColor($r('app.color.card_background'))
      .borderRadius(12)
      .margin(16);
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'));
  }
}
