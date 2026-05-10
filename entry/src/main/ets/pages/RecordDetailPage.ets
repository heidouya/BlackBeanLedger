import { promptAction, router } from '@kit.ArkUI';
import { Record } from '../model/RecordModel';
import { RecordDatabase } from '../database/RecordDatabase';
import { getCategoryIcon } from '../constants/CategoryConstants';
import { DateUtil } from '../utils/DateUtil';

/** 详情页路由参数 */
class DetailParams {
  id: number = 0;
}

/**
 * 明细详情页——展示单条记录完整信息，提供编辑/删除操作
 */
@Entry
@Component
struct RecordDetailPage {
  @State record: Record | null = null;
  private db: RecordDatabase = RecordDatabase.getInstance();

  aboutToAppear(): void {
    const params = router.getParams() as DetailParams;
    if (params && params.id) {
      this.loadRecord(params.id);
    }
  }

  private async loadRecord(id: number): Promise<void> {
    try {
      const result: Record | null = await this.db.getRecordById(id);
      if (result) {
        this.record = result;
      } else {
        promptAction.showToast({ message: '记录不存在', duration: 2000 });
        router.back();
      }
    } catch (err) {
      promptAction.showToast({ message: '加载失败', duration: 2000 });
      router.back();
    }
  }

  private onEdit(): void {
    if (this.record) {
      router.pushUrl({
        url: 'pages/AddRecordPage',
        params: { record: this.record }
      });
    }
  }

  private showDeleteDialog(): void {
    AlertDialog.show({
      title: '确认删除',
      message: '确定要删除这条记录吗？',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: '#FF5252',
        action: () => {
          this.deleteRecord();
        }
      }
    });
  }

  private async deleteRecord(): Promise<void> {
    if (!this.record) {
      return;
    }
    try {
      await this.db.deleteRecord(this.record.id);
      promptAction.showToast({ message: '删除成功', duration: 2000 });
      router.back();
    } catch (err) {
      promptAction.showToast({ message: '删除失败', duration: 2000 });
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

        Text('明细详情')
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

      if (this.record) {
        this.buildContent();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildContent() {
    Column() {
      // 信息卡片
      Column() {
        // 图标 + 类型
        Row() {
          Stack() {
            Text(getCategoryIcon(this.record!.category, this.record!.type))
              .fontSize(36);
          }
          .width(64)
          .height(64)
          .borderRadius(32)
          .backgroundColor(this.record!.type === 'expense' ? '#FFF0F0' : '#F0FFF0')
          .margin({ right: 16 });

          Column() {
            Text(this.record!.category)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#212121');
            Text(this.record!.type === 'expense' ? '支出' : '收入')
              .fontSize(13)
              .fontColor('#9E9E9E')
              .margin({ top: 4 });
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1);
        }
        .width('100%')
        .margin({ bottom: 24 });

        // 金额
        Text(`${this.record!.type === 'expense' ? '-' : '+'}¥${this.record!.amount.toFixed(2)}`)
          .fontSize(42)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.record!.type === 'expense' ? '#FF5252' : '#4CAF50')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 24 });

        // 分割线
        Divider().color('#F0F0F0').margin({ bottom: 20 });

        // 详情信息
        this.buildInfoRow('日期', DateUtil.formatDateDisplay(this.record!.date));
        this.buildInfoRow('时间', DateUtil.formatTimeDisplay(this.record!.date));

        if (this.record!.note) {
          this.buildInfoRow('备注', this.record!.note);
        }
      }
      .width('100%')
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .margin(16);

      Blank();

      // 底部操作按钮
      Row() {
        Button('编辑')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .layoutWeight(1)
          .height(48)
          .borderRadius(12)
          .backgroundColor('#4CAF50')
          .margin({ right: 6 })
          .onClick(() => { this.onEdit(); });

        Button('删除')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .layoutWeight(1)
          .height(48)
          .borderRadius(12)
          .backgroundColor('#FF5252')
          .margin({ left: 6 })
          .onClick(() => { this.showDeleteDialog(); });
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 24 });
    }
    .width('100%')
    .layoutWeight(1);
  }

  @Builder
  buildInfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#9E9E9E')
        .width(60);

      Text(value)
        .fontSize(14)
        .fontColor('#212121')
        .layoutWeight(1);
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 });
  }
}
