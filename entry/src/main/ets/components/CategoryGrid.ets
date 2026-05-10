import { CategoryItem } from '../constants/CategoryConstants';

/**
 * 分类宫格选择器（4 列）
 */
@Component
export struct CategoryGrid {
  @Prop categories: CategoryItem[] = [];
  @Link selectedCategory: string;

  build() {
    Column() {
      Grid() {
        ForEach(this.categories, (item: CategoryItem) => {
          GridItem() {
            this.buildItem(item);
          }
        }, (item: CategoryItem) => item.name)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(12)
      .columnsGap(8)
      .padding(16)
      .width('100%')
      .backgroundColor($r('app.color.card_background'))
    }
  }

  @Builder
  buildItem(item: CategoryItem) {
    Column() {
      Text(item.icon)
        .fontSize(30);

      Text(item.name)
        .fontSize(13)
        .fontColor(this.selectedCategory === item.name ?
          $r('app.color.category_text_selected') :
          $r('app.color.category_text_unselected'))
        .fontWeight(this.selectedCategory === item.name ? FontWeight.Medium : FontWeight.Normal)
        .margin({ top: 8 });
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(12)
    .backgroundColor(this.selectedCategory === item.name ?
      $r('app.color.category_bg_selected') :
      $r('app.color.page_background'))
    .border({
      width: this.selectedCategory === item.name ? 1.5 : 0,
      color: $r('app.color.accent_orange')
    })
    .onClick(() => {
      this.selectedCategory = item.name;
    });
  }
}
