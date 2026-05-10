import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { RecordModel } from '../model/RecordModel';
import { RecordDatabase } from '../database/RecordDatabase';
import { DateUtil } from '../utils/DateUtil';
import { CategoryItem, getCategoriesByType } from '../constants/CategoryConstants';

@Entry
@Component
struct AddRecordPage {
  @State currentType: number = 0; // 0=支出, 1=收入
  @State amountStr: string = '0';
  @State selectedCategory: string = '';
  @State note: string = '';
  @State selectedDate: Date = new Date();
  @State dateStr: string = DateUtil.formatDate(new Date());
  @State tabIndicatorOffset: number = 0;
  private db: RecordDatabase = RecordDatabase.getInstance();

  /**
   * 键盘布局
   */
  private keypadKeys: string[][] = [
    ['1', '2', '3', '←'],
    ['4', '5', '6', '清空'],
    ['7', '8', '9', '.'],
    ['0', '确定']
  ];

  /**
   * 处理键盘输入
   */
  private onKeyPress(key: string): void {
    if (key === '←') {
      // 删除最后一位
      if (this.amountStr.length > 1) {
        this.amountStr = this.amountStr.substring(0, this.amountStr.length - 1);
      } else {
        this.amountStr = '0';
      }
    } else if (key === '清空') {
      this.amountStr = '0';
    } else if (key === '确定') {
      this.saveRecord();
    } else if (key === '.') {
      // 只允许一个小数点
      if (this.amountStr.indexOf('.') === -1) {
        this.amountStr += '.';
      }
    } else {
      // 数字键
      if (this.amountStr === '0') {
        this.amountStr = key;
      } else {
        // 限制小数点后两位
        const dotIndex: number = this.amountStr.indexOf('.');
        if (dotIndex !== -1 && this.amountStr.length - dotIndex > 2) {
          return;
        }
        // 限制总长度
        if (this.amountStr.replace('.', '').length >= 9) {
          return;
        }
        this.amountStr += key;
      }
    }
  }

  /**
   * 获取当前金额数值
   */
  private getAmount(): number {
    return parseFloat(this.amountStr) || 0;
  }

  /**
   * Tab 切换
   */
  private switchTab(type: number): void {
    this.currentType = type;
    this.selectedCategory = '';
    // 动画切换指示条位置
    animateTo({ duration: 200, curve: Curve.EaseInOut }, () => {
      this.tabIndicatorOffset = type === 0 ? 0 : 1;
    });
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
        this.dateStr = DateUtil.formatDate(value);
      }
    });
  }

  /**
   * 保存记录
   */
  private async saveRecord(): Promise<void> {
    const amount: number = this.getAmount();

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
      const record: RecordModel = {
        id: 0,
        amount: amount,
        type: this.currentType,
        category: this.selectedCategory,
        note: this.note,
        date: this.dateStr,
        timestamp: DateUtil.getDateTimestamp(this.dateStr)
      };

      await this.db.insertRecord(record);
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

      // Tab 切换
      this.buildTabs();

      // 金额显示
      this.buildAmountDisplay();

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

      // 键盘
      this.buildKeypad();

      // 保存按钮
      this.buildSaveButton();
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }

  /**
   * 导航栏
   */
  @Builder
  buildNavBar() {
    Row() {
      Button() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(20)
          .fontColor(['#212121']);
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

      // 占位保持居中
      Blank().width(40).height(40);
    }
    .width('100%')
    .height(56)
    .padding({ left: 8, right: 8 })
    .backgroundColor(Color.White)
  }

  /**
   * Tab 切换（支出/收入）
   */
  @Builder
  buildTabs() {
    Stack({ alignContent: Alignment.Bottom }) {
      Row() {
        Text('支出')
          .fontSize(16)
          .fontWeight(this.currentType === 0 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.currentType === 0 ? '#007AFF' : '#9E9E9E')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .padding({ top: 12, bottom: 12 })
          .onClick(() => this.switchTab(0));

        Text('收入')
          .fontSize(16)
          .fontWeight(this.currentType === 1 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.currentType === 1 ? '#007AFF' : '#9E9E9E')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .padding({ top: 12, bottom: 12 })
          .onClick(() => this.switchTab(1));
      }
      .width('100%')
      .backgroundColor(Color.White);

      // 指示条
      Row()
        .width('50%')
        .height(2)
        .backgroundColor('#007AFF')
        .borderRadius(1)
        .position({ x: this.tabIndicatorOffset === 0 ? 0 : '50%', y: '100%' })
        .animation({ duration: 200, curve: Curve.EaseInOut });
    }
    .width('100%')
  }

  /**
   * 金额显示
   */
  @Builder
  buildAmountDisplay() {
    Row() {
      Text('¥')
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor('#212121')
        .margin({ right: 4 });

      Text(this.amountStr)
        .fontSize(48)
        .fontWeight(FontWeight.Bold)
        .fontColor('#212121')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis });
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 16, bottom: 16 })
    .backgroundColor(Color.White)
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 分类宫格
   */
  @Builder
  buildCategoryGrid() {
    Column() {
      Grid() {
        ForEach(getCategoriesByType(this.currentType), (item: CategoryItem, index: number) => {
          GridItem() {
            this.buildCategoryItem(item);
          }
        }, (item: CategoryItem) => item.name)
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsGap(8)
      .columnsGap(8)
      .padding(16)
      .width('100%')
      .backgroundColor(Color.White)
    }
  }

  @Builder
  buildCategoryItem(item: CategoryItem) {
    Column() {
      Stack() {
        SymbolGlyph(item.icon)
          .fontSize(28)
          .fontColor([this.selectedCategory === item.name ? Color.White : '#616161']);
      }
      .width(52)
      .height(52)
      .borderRadius(26)
      .backgroundColor(this.selectedCategory === item.name ? '#007AFF' : '#F5F5F5');

      Text(item.name)
        .fontSize(12)
        .fontColor('#424242')
        .margin({ top: 6 });
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(12)
    .onClick(() => {
      this.selectCategory(item.name);
    })
  }

  /**
   * 备注输入
   */
  @Builder
  buildNoteInput() {
    Row() {
      Text('备注')
        .fontSize(15)
        .fontColor('#424242')
        .margin({ right: 12 });

      TextInput({ placeholder: '添加备注...', text: this.note })
        .fontSize(15)
        .layoutWeight(1)
        .maxLength(50)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.note = value;
        });
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 日期选择
   */
  @Builder
  buildDatePicker() {
    Row() {
      Text('日期')
        .fontSize(15)
        .fontColor('#424242');

      Blank();

      Text(this.dateStr)
        .fontSize(15)
        .fontColor('#212121')
        .margin({ right: 8 });

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor(['#9E9E9E']);
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
   * 计算器式数字键盘
   */
  @Builder
  buildKeypad() {
    Column() {
      ForEach(this.keypadKeys, (row: string[], rowIndex: number) => {
        Row() {
          ForEach(row, (key: string, colIndex: number) => {
            if (key === '确定') {
              // "确定"按钮占两列
              Button(key)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.White)
                .width('48%')
                .height(52)
                .borderRadius(26)
                .backgroundColor('#007AFF')
                .onClick(() => this.onKeyPress(key));
            } else {
              Button(key)
                .fontSize(key === '←' || key === '清空' ? 16 : 22)
                .fontWeight(FontWeight.Medium)
                .fontColor('#212121')
                .width('22%')
                .height(52)
                .borderRadius(26)
                .backgroundColor(key === '←' || key === '清空' ? '#E0E0E0' : Color.White)
                .onClick(() => this.onKeyPress(key));
            }
          }, (key: string) => `${rowIndex}_${key}`)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
        .margin({ top: rowIndex === 0 ? 0 : 6, bottom: rowIndex === this.keypadKeys.length - 1 ? 0 : 0 });
      }, (row: string[]) => row.join('_'))
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#F0F0F0')
  }

  /**
   * 保存按钮（键盘中已有确定按钮，此处可保留作为备选）
   */
  @Builder
  buildSaveButton() {
    // 键盘中的"确定"按钮已承担保存功能，此处不再重复添加
    Column()
      .height(0)
      .width('100%');
  }
}
