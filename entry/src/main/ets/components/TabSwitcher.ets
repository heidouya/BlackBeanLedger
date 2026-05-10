/**
 * 支出 / 收入 Tab 切换器
 */
@Component
export struct TabSwitcher {
  @Prop currentType: 'expense' | 'income' = 'expense';
  onChange?: (type: 'expense' | 'income') => void;

  build() {
    Row() {
      // 支出 Tab
      Column() {
        Text('支出')
          .fontSize(18)
          .fontWeight(this.currentType === 'expense' ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.currentType === 'expense' ?
            $r('app.color.text_primary') :
            $r('app.color.text_secondary'))
          .padding({ top: 16, bottom: 12 });
        if (this.currentType === 'expense') {
          Divider().width(28).height(3).color($r('app.color.accent_orange')).borderRadius(2);
        } else {
          Divider().width(28).height(3).color(Color.Transparent);
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => this.onChange?.('expense'));

      // 收入 Tab
      Column() {
        Text('收入')
          .fontSize(18)
          .fontWeight(this.currentType === 'income' ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.currentType === 'income' ?
            $r('app.color.income_green') :
            $r('app.color.text_secondary'))
          .padding({ top: 16, bottom: 12 });
        if (this.currentType === 'income') {
          Divider().width(28).height(3).color($r('app.color.income_green')).borderRadius(2);
        } else {
          Divider().width(28).height(3).color(Color.Transparent);
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => this.onChange?.('income'));
    }
    .width('100%')
    .backgroundColor($r('app.color.card_background'))
    .padding({ left: 40, right: 40 });
  }
}
