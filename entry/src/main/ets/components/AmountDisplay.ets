/**
 * 金额展示区——表达式 + 计算结果预览
 */
@Component
export struct AmountDisplay {
  @Prop expression: string = '';
  @Prop preview: string = '';

  build() {
    Column() {
      Row() {
        Text('¥')
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor('#212121')
          .margin({ right: 4 });

        Text(this.expression || '0')
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor('#212121')
          .textAlign(TextAlign.Start)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
      }
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)
      .width('100%');

      if (this.preview !== '') {
        Text(`= ${this.preview}`)
          .fontSize(22)
          .fontColor('#9E9E9E')
          .width('100%')
          .padding({ top: 6 });
      }
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 20, bottom: 20 })
    .backgroundColor(Color.White)
    .alignItems(HorizontalAlign.Start)
  }
}
