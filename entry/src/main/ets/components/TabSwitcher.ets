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
          .fontColor(this.currentType === 'expense' ? '#212121' : '#9E9E9E')
          .padding({ top: 16, bottom: 12 });
        if (this.currentType === 'expense') {
          Divider().width(28).height(3).color('#FF6F00').borderRadius(2);
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
          .fontColor(this.currentType === 'income' ? '#4CAF50' : '#9E9E9E')
          .padding({ top: 16, bottom: 12 });
        if (this.currentType === 'income') {
          Divider().width(28).height(3).color('#4CAF50').borderRadius(2);
        } else {
          Divider().width(28).height(3).color(Color.Transparent);
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => this.onChange?.('income'));
    }
    .width('100%')
    .backgroundColor(Color.White)
    .padding({ left: 40, right: 40 });
  }
}
