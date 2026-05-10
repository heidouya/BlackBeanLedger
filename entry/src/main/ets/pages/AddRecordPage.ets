import { promptAction } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';
import { Record } from '../model/RecordModel';
import { InsertRecord } from '../model/RecordModel';
import { RecordDatabase } from '../database/RecordDatabase';
import { DateUtil } from '../utils/DateUtil';
import { CategoryItem, getCategoriesByType } from '../constants/CategoryConstants';

/**
 * 记账表单内容组件（可在 Tab 中嵌入或独立使用）
 */
@Component
export struct AddRecordContent {
  @State currentType: 'expense' | 'income' = 'expense';
  @State amountStr: string = '';
  @State amountExpression: string = ''; // 含运算符的原始表达式
  @State computedPreview: string = ''; // 实时计算结果预览
  @State selectedCategory: string = '';
  @State note: string = '';
  @State selectedDate: Date = new Date();
  @State displayDate: string = '今天';
  private db: RecordDatabase = RecordDatabase.getInstance();
  /** 保存成功后回调（嵌入模式：切换 Tab；独立模式：router.back） */
  onSaved?: () => void;

  aboutToAppear(): void {
    this.displayDate = '今天';
  }

  /**
   * 重置表单
   */
  private resetForm(): void {
    this.amountStr = '';
    this.amountExpression = '';
    this.computedPreview = '';
    this.selectedCategory = '';
    this.note = '';
    this.displayDate = '今天';
    this.selectedDate = new Date();
  }

  /**
   * Tab 切换（支出/收入）
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
      this.resetForm();
      this.onSaved?.();
    } catch (err) {
      promptAction.showToast({ message: '保存失败', duration: 2000 });
      console.error(`保存记录失败: ${JSON.stringify(err)}`);
    }
  }

  build() {
    Column() {
      // 滚动内容区域
      Scroll() {
        Column() {
          // Tab 切换（支出/收入）
          this.buildTabs();

          // 金额展示（无系统键盘）
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

          // 底部留白
          Blank().height(20);
        }
        .width('100%');
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      // 自定义数字键盘（固定在底部）
      this.buildKeypad();
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  /**
   * Tab 切换（支出/收入）
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
   * 金额展示区（无 TextInput，由自定义键盘控制）
   */
  @Builder
  buildAmountDisplay() {
    Column() {
      Row() {
        Text('¥')
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor('#212121')
          .margin({ right: 4 });

        Text(this.amountExpression || '0')
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

      if (this.computedPreview !== '') {
        Text(`= ${this.computedPreview}`)
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
   * 日期选择
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
  // ==================== 自定义数字键盘 ====================

  /**
   * 自定义键盘（0-9、小数点、删除、加减、完成）
   */
  @Builder
  buildKeypad() {
    Column() {
      // 第 1 行: 1 2 3 ⌫
      Row() {
        this.buildKey('1', () => this.onDigit('1'))
        this.buildKey('2', () => this.onDigit('2'))
        this.buildKey('3', () => this.onDigit('3'))
        this.buildKey('⌫', () => this.onDelete(), '#D1D5DB')
      }
      // 第 2 行: 4 5 6 +
      Row() {
        this.buildKey('4', () => this.onDigit('4'))
        this.buildKey('5', () => this.onDigit('5'))
        this.buildKey('6', () => this.onDigit('6'))
        this.buildKey('+', () => this.onOperator('+'), '#D1D5DB')
      }
      // 第 3 行: 7 8 9 -
      Row() {
        this.buildKey('7', () => this.onDigit('7'))
        this.buildKey('8', () => this.onDigit('8'))
        this.buildKey('9', () => this.onDigit('9'))
        this.buildKey('-', () => this.onOperator('-'), '#D1D5DB')
      }
      // 第 4 行: . 0 完成(×2)
      Row() {
        this.buildKey('.', () => this.onDecimal())
        this.buildKey('0', () => this.onDigit('0'))
        Button('完成')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .layoutWeight(2)
          .height(52)
          .margin(4)
          .borderRadius(8)
          .backgroundColor('#1C1C1E')
          .onClick(() => this.onDone())
      }
    }
    .width('100%')
    .backgroundColor('#E8E8EA')
    .padding({ top: 8, bottom: 16, left: 8, right: 8 })
  }

  @Builder
  buildKey(label: string, onClick: () => void, bgColor: string = '#FFFFFF') {
    Button(label)
      .fontSize(24)
      .fontWeight(FontWeight.Medium)
      .fontColor('#212121')
      .layoutWeight(1)
      .height(52)
      .margin(4)
      .borderRadius(8)
      .backgroundColor(bgColor)
      .onClick(onClick)
  }

  // ==================== 键盘事件处理 ====================

  /**
   * 输入数字
   */
  private onDigit(digit: string): void {
    this.amountExpression += digit;
    this.updatePreview();
  }

  /**
   * 输入运算符
   */
  private onOperator(op: string): void {
    if (this.amountExpression === '') {
      return;
    }
    const lastChar = this.amountExpression[this.amountExpression.length - 1];
    if (lastChar === '+' || lastChar === '-') {
      // 替换上一个运算符
      this.amountExpression = this.amountExpression.substring(0, this.amountExpression.length - 1) + op;
    } else if (lastChar === '.') {
      // 去掉尾部小数点再追加运算符
      this.amountExpression = this.amountExpression.substring(0, this.amountExpression.length - 1) + op;
    } else {
      this.amountExpression += op;
    }
    this.computedPreview = '';
  }

  /**
   * 输入小数点
   */
  private onDecimal(): void {
    // 找到最后一个运算符之后的部分
    let lastOpIndex = -1;
    for (let i = this.amountExpression.length - 1; i >= 0; i--) {
      if (this.amountExpression[i] === '+' || this.amountExpression[i] === '-') {
        lastOpIndex = i;
        break;
      }
    }
    const currentNum = this.amountExpression.substring(lastOpIndex + 1);
    // 当前数字已有小数点则忽略
    if (currentNum.includes('.')) {
      return;
    }
    if (currentNum === '') {
      this.amountExpression += '0.';
    } else {
      this.amountExpression += '.';
    }
    this.computedPreview = '';
  }

  /**
   * 删除最后一位
   */
  private onDelete(): void {
    if (this.amountExpression.length > 0) {
      this.amountExpression = this.amountExpression.substring(0, this.amountExpression.length - 1);
      this.updatePreview();
    }
  }

  /**
   * 点击"完成"：求值并保存
   */
  private onDone(): void {
    let expr = this.amountExpression;
    if (expr === '') {
      return;
    }
    // 去掉末尾运算符或小数点
    while (expr.endsWith('+') || expr.endsWith('-') || expr.endsWith('.')) {
      expr = expr.substring(0, expr.length - 1);
    }
    if (expr === '') {
      return;
    }
    const result = this.evaluateExpression(expr);
    this.amountStr = result.toString();
    this.saveRecord();
  }

  /**
   * 简单加减表达式求值
   */
  private evaluateExpression(expr: string): number {
    let result = 0;
    let currentNum = '';
    let currentOp = '+';

    for (let i = 0; i <= expr.length; i++) {
      const ch = i < expr.length ? expr[i] : '';
      if (ch === '+' || ch === '-' || i === expr.length) {
        const num = parseFloat(currentNum) || 0;
        if (currentOp === '+') {
          result += num;
        } else if (currentOp === '-') {
          result -= num;
        }
        currentOp = ch;
        currentNum = '';
      } else {
        currentNum += ch;
      }
    }
    return result;
  }

  /**
   * 实时更新计算结果预览
   */
  private updatePreview(): void {
    const expr = this.amountExpression;
    if (expr === '' || expr.endsWith('+') || expr.endsWith('-') || expr.endsWith('.')) {
      this.computedPreview = '';
      return;
    }
    // 只有包含运算符时才显示预览
    if (expr.includes('+') || expr.includes('-')) {
      const result = this.evaluateExpression(expr);
      this.computedPreview = this.formatAmount(result);
    } else {
      this.computedPreview = '';
    }
  }

  /**
   * 格式化金额显示（去掉尾部多余零）
   */
  private formatAmount(n: number): string {
    let s = n.toFixed(2);
    if (s.includes('.')) {
      s = s.replace(/\.?0+$/, '');
    }
    return s;
  }
}

/**
 * 记账页面（独立路由入口，保留顶部导航栏 ← 返回按钮）
 */
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

  private resetForm(): void {
    this.amountStr = '';
    this.selectedCategory = '';
    this.note = '';
    this.displayDate = '今天';
    this.selectedDate = new Date();
  }

  private switchTab(type: 'expense' | 'income'): void {
    this.currentType = type;
    this.selectedCategory = '';
  }

  private selectCategory(name: string): void {
    this.selectedCategory = name;
  }

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

  private async saveRecord(): Promise<void> {
    const amount: number = parseFloat(this.amountStr) || 0;
    if (amount <= 0) {
      promptAction.showToast({ message: '请输入金额', duration: 2000 });
      return;
    }
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
    }
  }

  build() {
    Column() {
      // 导航栏
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
      .backgroundColor(Color.White);

      // 表单内容
      Scroll() {
        Column() {
          // Tab 切换
          Row() {
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
            .onClick(() => this.switchTab('expense'));

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
            .onClick(() => this.switchTab('income'));
          }
          .width('100%')
          .backgroundColor(Color.White)
          .padding({ left: 40, right: 40 });

          // 金额输入
          Column() {
            Row() {
              Text('¥').fontSize(36).fontWeight(FontWeight.Bold).fontColor('#212121').margin({ right: 4 });
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
                .onChange((value: string) => { this.amountStr = value; });
            }
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center);
          }
          .width('100%')
          .padding({ left: 24, right: 24, top: 20, bottom: 20 })
          .backgroundColor(Color.White)
          .alignItems(HorizontalAlign.Center);

          Divider().color('#F0F0F0').margin({ left: 16, right: 16 });

          // 分类宫格
          Column() {
            Grid() {
              ForEach(getCategoriesByType(this.currentType), (item: CategoryItem) => {
                GridItem() {
                  Column() {
                    Text(item.icon).fontSize(30);
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
                  .border({ width: this.selectedCategory === item.name ? 1.5 : 0, color: '#FF6F00' })
                  .onClick(() => { this.selectCategory(item.name); });
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

          Divider().color('#F0F0F0').margin({ left: 16, right: 16 });

          // 备注
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
              .onChange((value: string) => { this.note = value; });
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .backgroundColor(Color.White)
          .alignItems(VerticalAlign.Center);

          Divider().color('#F0F0F0').margin({ left: 16, right: 16 });

          // 日期
          Row() {
            Text('日期').fontSize(15).fontColor('#424242');
            Blank();
            Text(this.displayDate).fontSize(15).fontColor('#212121').margin({ right: 8 });
            Text('›').fontSize(18).fontColor('#9E9E9E');
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .backgroundColor(Color.White)
          .alignItems(VerticalAlign.Center)
          .onClick(() => { this.showDatePicker(); });

          // 保存按钮
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
            .onClick(() => { this.saveRecord(); });

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
}
