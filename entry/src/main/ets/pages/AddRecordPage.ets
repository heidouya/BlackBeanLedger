import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { Record } from '../model/RecordModel';
import { InsertRecord } from '../model/RecordModel';
import { RecordDatabase } from '../database/RecordDatabase';
import { DateUtil } from '../utils/DateUtil';
import { CategoryItem, getCategoriesByType } from '../constants/CategoryConstants';

@Entry
@Component
struct AddRecordPage {
  @State currentType: 'expense' | 'income' = 'expense';
  @State amountStr: string = '';
  @State selectedCategory: string = '';
  @State note: string = '';
  @State selectedDate: Date = new Date();
  @State displayDate: string = '今天';
  private db: RecordDatabase = RecordDatabase.getInstance();

  aboutToAppear(): void {
    this.displayDate = '今天';
  }

  /**
   * Tab 切换
   */
  private switchTab(type: 'expense' | 'income'): void {
    this.currentType = type;
    this.selectedCategory = '';
  }

  /**
   * 选择分类
   */
  private selectCategory(name: string): void {
    this.selectedCategory = name;
  }

  /**
   * 显示日期选择弹窗
   */
  private showDatePicker(): void {
    this.getUIContext().showDatePickerDialog({
      start: new Date('2000-1-1'),
      end: new Date('2100-12-31'),
      selected: this.selectedDate,
      onDateAccept: (value: Date) => {
        this.selectedDate = value;
        this.displayDate = DateUtil.formatMonthDay(value);
      }
    });
  }

  /**
   * 保存记录
   */
  private async saveRecord(): Promise<void> {
    const amount: number = parseFloat(this.amountStr) || 0;

    // 验证金额
    if (amount <= 0) {
      promptAction.showToast({ message: '请输入金额', duration: 2000 });
      return;
    }

    // 验证分类
    if (!this.selectedCategory) {
      promptAction.showToast({ message: '请选择分类', duration: 2000 });
      return;
    }

    try {
      const dateTime: string = DateUtil.formatDateTime(
        this.displayDate === '今天' ? new Date() : this.selectedDate
      );
      const timestamp: number = DateUtil.getTimestamp(dateTime);

      const newRec: InsertRecord = new InsertRecord();
      newRec.amount = amount;
      newRec.type = this.currentType;
      newRec.category = this.selectedCategory;
      newRec.note = this.note;
      newRec.date = dateTime;
      newRec.timestamp = timestamp;

      await this.db.insertRecord(newRec);

      promptAction.showToast({ message: '保存成功', duration: 2000 });
      router.back();
    } catch (err) {
      promptAction.showToast({ message: '保存失败', duration: 2000 });
      console.error(`保存记录失败: ${JSON.stringify(err)}`);
    }
  }

  build() {
    Column() {
      // 导航栏
      this.buildNavBar();

      // 滚动内容区域
      Scroll() {
        Column() {
          // Tab 切换
          this.buildTabs();

          // 金额输入
          this.buildAmountInput();

          // 分割线
          Divider().color('#F0F0F0').margin({ left: 16, right: 16 });

          // 分类宫格
          this.buildCategoryGrid();

          // 分割线
          Divider().color('#F0F0F0').margin({ left: 16, right: 16 });

          // 备注输入
          this.buildNoteInput();

          // 分割线
          Divider().color('#F0F0F0').margin({ left: 16, right: 16 });

          // 日期选择
          this.buildDatePicker();

          // 保存按钮
          this.buildSaveButton();

          // 底部安全区
          Blank().height(40);
        }
        .width('100%');
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  /**
   * 导航栏
   */
  @Builder
  buildNavBar() {
    Row() {
      Button() {
        Text('←')
          .fontSize(22)
          .fontColor('#212121');
      }
      .type(ButtonType.Circle)
      .backgroundColor(Color.Transparent)
      .width(40)
      .height(40)
      .onClick(() => {
        router.back();
      });

      Text('记一笔')
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
    .backgroundColor(Color.White)
  }

  /**
   * Tab 切换（支出/收入）
   * 支出黑字、收入绿字
   */
  @Builder
  buildTabs() {
    Row() {
      // 支出 Tab
      Column() {
        Text('支出')
          .fontSize(18)
          .fontWeight(this.currentType === 'expense' ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.currentType === 'expense' ? '#212121' : '#9E9E9E')
          .padding({ top: 16, bottom: 12 });

        // 底部指示条
        if (this.currentType === 'expense') {
          Divider()
            .width(28)
            .height(3)
            .color('#FF6F00')
            .borderRadius(2);
        } else {
          Divider()
            .width(28)
            .height(3)
            .color(Color.Transparent);
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => this.switchTab('expense'));

      // 收入 Tab
      Column() {
        Text('收入')
          .fontSize(18)
          .fontWeight(this.currentType === 'income' ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.currentType === 'income' ? '#4CAF50' : '#9E9E9E')
          .padding({ top: 16, bottom: 12 });

        // 底部指示条
        if (this.currentType === 'income') {
          Divider()
            .width(28)
            .height(3)
            .color('#4CAF50')
            .borderRadius(2);
        } else {
          Divider()
            .width(28)
            .height(3)
            .color(Color.Transparent);
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => this.switchTab('income'));
    }
    .width('100%')
    .backgroundColor(Color.White)
    .padding({ left: 40, right: 40 });
  }

  /**
   * 金额输入区
   * TextInput 隐藏边框，.type(InputType.Number) 唤起数字键盘
   */
  @Builder
  buildAmountInput() {
    Column() {
      Row() {
        Text('¥')
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor('#212121')
          .margin({ right: 4 });

        TextInput({ text: this.amountStr, placeholder: '0.00' })
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor('#212121')
          .type(InputType.Number)
          .placeholderColor('#BDBDBD')
          .backgroundColor(Color.Transparent)
          .borderRadius(0)
          .border({ width: 0, color: Color.Transparent })
          .padding(0)
          .maxLength(12)
          .textAlign(TextAlign.Start)
          .onChange((value: string) => {
            this.amountStr = value;
          });
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center);
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 20, bottom: 20 })
    .backgroundColor(Color.White)
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 分类宫格 - 4列
   */
  @Builder
  buildCategoryGrid() {
    Column() {
      Grid() {
        ForEach(getCategoriesByType(this.currentType), (item: CategoryItem) => {
          GridItem() {
            this.buildCategoryItem(item);
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
  buildCategoryItem(item: CategoryItem) {
    Column() {
      // Emoji 图标
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
      this.selectCategory(item.name);
    });
  }

  /**
   * 备注输入
   */
  @Builder
  buildNoteInput() {
    Row() {
      TextInput({ placeholder: '备注 (可选)', text: this.note })
        .fontSize(15)
        .layoutWeight(1)
        .maxLength(50)
        .backgroundColor(Color.Transparent)
        .borderRadius(0)
        .border({ width: 0, color: Color.Transparent })
        .padding(0)
        .placeholderColor('#9E9E9E')
        .onChange((value: string) => {
          this.note = value;
        });
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(Color.White)
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 日期选择 - 显示 "MM月DD日" 或 "今天"
   */
  @Builder
  buildDatePicker() {
    Row() {
      Text('日期')
        .fontSize(15)
        .fontColor('#424242');

      Blank();

      Text(this.displayDate)
        .fontSize(15)
        .fontColor('#212121')
        .margin({ right: 8 });

      Text('›')
        .fontSize(18)
        .fontColor('#9E9E9E');
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(Color.White)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.showDatePicker();
    })
  }

  /**
   * 保存按钮 - 橙色大按钮 "完成"
   */
  @Builder
  buildSaveButton() {
    Button('完成')
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .fontColor(Color.White)
      .width('90%')
      .height(50)
      .borderRadius(25)
      .backgroundColor('#FF6F00')
      .shadow({ radius: 8, color: '#40FF6F00', offsetY: 4 })
      .margin({ top: 32, bottom: 8 })
      .onClick(() => {
        this.saveRecord();
      });
  }
}
