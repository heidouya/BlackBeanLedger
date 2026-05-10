import { promptAction } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';
import { InsertRecord } from '../model/RecordModel';
import { RecordDatabase } from '../database/RecordDatabase';
import { DateUtil } from '../utils/DateUtil';
import { getCategoriesByType } from '../constants/CategoryConstants';
import { TabSwitcher } from '../components/TabSwitcher';
import { AmountDisplay } from '../components/AmountDisplay';
import { CategoryGrid } from '../components/CategoryGrid';
import { CustomKeypad } from '../components/CustomKeypad';

/**
 * 记账表单内容组件（在弹窗中使用）
 */
@Component
export struct AddRecordContent {
  @State currentType: 'expense' | 'income' = 'expense';
  @State amountStr: string = '';
  @State amountExpression: string = '';
  @State computedPreview: string = '';
  @State selectedCategory: string = '';
  @State note: string = '';
  @State selectedDate: Date = new Date();
  @State displayDate: string = '今天';
  private db: RecordDatabase = RecordDatabase.getInstance();
  onSaved?: () => void;

  aboutToAppear(): void {
    this.displayDate = '今天';
  }

  private resetForm(): void {
    this.amountStr = '';
    this.amountExpression = '';
    this.computedPreview = '';
    this.selectedCategory = '';
    this.note = '';
    this.displayDate = '今天';
    this.selectedDate = new Date();
  }

  private switchTab(type: 'expense' | 'income'): void {
    this.currentType = type;
    this.selectedCategory = '';
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
      this.resetForm();
      this.onSaved?.();
    } catch (err) {
      promptAction.showToast({ message: '保存失败', duration: 2000 });
      console.error(`保存记录失败: ${JSON.stringify(err)}`);
    }
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          // Tab 切换
          TabSwitcher({
            currentType: this.currentType,
            onChange: (type: 'expense' | 'income') => this.switchTab(type)
          });

          // 金额展示
          AmountDisplay({
            expression: this.amountExpression,
            preview: this.computedPreview
          });

          Divider().color('#F0F0F0').margin({ left: 16, right: 16 });

          // 分类宫格
          CategoryGrid({
            categories: getCategoriesByType(this.currentType),
            selectedCategory: $selectedCategory
          });

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

          Blank().height(20);
        }
        .width('100%');
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      // 自定义键盘
      CustomKeypad({
        expression: $amountExpression,
        preview: $computedPreview,
        onComplete: (value: number) => {
          this.amountStr = value.toString();
          this.saveRecord();
        }
      });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

/**
 * 记账页面（独立路由入口）
 */
@Entry
@Component
struct AddRecordPage {
  @State currentType: 'expense' | 'income' = 'expense';
  @State amountStr: string = '';
  @State amountExpression: string = '';
  @State computedPreview: string = '';
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
    this.amountExpression = '';
    this.computedPreview = '';
    this.selectedCategory = '';
    this.note = '';
    this.displayDate = '今天';
    this.selectedDate = new Date();
  }

  private switchTab(type: 'expense' | 'income'): void {
    this.currentType = type;
    this.selectedCategory = '';
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
      this.resetForm();
      router.back();
    } catch (err) {
      promptAction.showToast({ message: '保存失败', duration: 2000 });
      console.error(`保存记录失败: ${JSON.stringify(err)}`);
    }
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Button() {
          Text('←').fontSize(22).fontColor('#212121');
        }
        .type(ButtonType.Circle)
        .backgroundColor(Color.Transparent)
        .width(40)
        .height(40)
        .onClick(() => { router.back(); });

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
          TabSwitcher({
            currentType: this.currentType,
            onChange: (type: 'expense' | 'income') => this.switchTab(type)
          });

          // 金额展示
          AmountDisplay({
            expression: this.amountExpression,
            preview: this.computedPreview
          });

          Divider().color('#F0F0F0').margin({ left: 16, right: 16 });

          // 分类宫格
          CategoryGrid({
            categories: getCategoriesByType(this.currentType),
            selectedCategory: $selectedCategory
          });

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

          Blank().height(20);
        }
        .width('100%');
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      // 自定义键盘
      CustomKeypad({
        expression: $amountExpression,
        preview: $computedPreview,
        onComplete: (value: number) => {
          this.amountStr = value.toString();
          this.saveRecord();
        }
      });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
