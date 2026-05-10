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
      .backgroundColor(Color.White)
    }
  }

  @Builder
  buildItem(item: CategoryItem) {
    Column() {
      Text(item.icon)
        .fontSize(30);

      Text(item.name)
        .fontSize(13)
        .fontColor(this.selectedCategory === item.name ? '#FF6F00' : '#757575')
        .fontWeight(this.selectedCategory === item.name ? FontWeight.Medium : FontWeight.Normal)
        .margin({ top: 8 });
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(12)
    .backgroundColor(this.selectedCategory === item.name ? '#FFF3E0' : '#F5F5F5')
    .border({
      width: this.selectedCategory === item.name ? 1.5 : 0,
      color: '#FF6F00'
    })
    .onClick(() => {
      this.selectedCategory = item.name;
    });
  }
}
