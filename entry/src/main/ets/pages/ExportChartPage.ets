import { router, promptAction, componentSnapshot } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { Record } from '../model/RecordModel';
import { RecordDatabase } from '../database/RecordDatabase';
import { getCategoriesByType, CategoryItem } from '../constants/CategoryConstants';
import { ExportUtil } from '../utils/ExportUtil';
import { image } from '@kit.ImageKit';

/** 环形图颜色 */
const RING_COLORS: string[] = [
  '#FF6F00', '#FF5252', '#FF4081', '#E040FB',
  '#7C4DFF', '#448AFF', '#00BCD4', '#4CAF50',
  '#CDDC39', '#FFC107'
];

class ChartItem {
  name: string = '';
  icon: string = '';
  amount: number = 0;
  percent: number = 0;
  color: string = '';
}

/**
 * 图表导出页 —— 展示支出分类环形图，支持截图保存
 */
@Entry
@Component
struct ExportChartPage {
  @State chartItems: ChartItem[] = [];
  @State totalExpense: string = '0.00';
  @State isLoading: boolean = true;
  @State canvasReady: boolean = false;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ringContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private saveTargetId: string = 'export_chart_area';

  aboutToAppear(): void {
    this.loadChartData();
  }

  async loadChartData(): Promise<void> {
    this.isLoading = true;
    try {
      const db: RecordDatabase = RecordDatabase.getInstance();
      const records: Record[] = await db.getAllRecords();
      const categoryMap: Map<string, number> = new Map();
      for (const r of records) {
        if (r.type !== 'expense') {
          continue;
        }
        categoryMap.set(r.category, (categoryMap.get(r.category) ?? 0) + r.amount);
      }

      const expenseCats: CategoryItem[] = getCategoriesByType('expense');
      const items: ChartItem[] = [];
      let total: number = 0;
      categoryMap.forEach((v, k) => {
        const cat: CategoryItem | undefined = expenseCats.find(c => c.name === k);
        const item: ChartItem = new ChartItem();
        item.name = k;
        item.icon = cat ? cat.icon : '📋';
        item.amount = v;
        total += v;
        items.push(item);
      });
      items.sort((a, b) => b.amount - a.amount);

      for (let i: number = 0; i < items.length; i++) {
        items[i].percent = total > 0 ? (items[i].amount / total) * 100 : 0;
        items[i].color = RING_COLORS[i % RING_COLORS.length];
      }

      this.chartItems = items.slice(0, 10);
      this.totalExpense = total.toFixed(2);
      this.isLoading = false;

      // 等待 Canvas 就绪后绘制
      setTimeout(() => {
        this.canvasReady = true;
        setTimeout(() => { this.drawRingChart(); }, 50);
      }, 100);
    } catch (err) {
      console.error(`图表数据加载失败: ${JSON.stringify(err)}`);
      this.isLoading = false;
    }
  }

  private drawRingChart(): void {
    const ctx: CanvasRenderingContext2D = this.ringContext;
    const size: number = 320;
    ctx.clearRect(0, 0, size, size);

    if (this.chartItems.length === 0) {
      return;
    }

    const cx: number = size / 2;
    const cy: number = size / 2;
    const outerR: number = 130;
    const innerR: number = 85;
    const lineW: number = outerR - innerR;

    ctx.lineCap = 'round';
    let startAngle: number = -Math.PI / 2;
    const total: number = this.chartItems.reduce((s, item) => s + item.amount, 0);
    for (let i = 0; i < this.chartItems.length; i++) {
      const sweep: number = total > 0 ? (this.chartItems[i].amount / total) * 2 * Math.PI : 0;
      ctx.beginPath();
      ctx.arc(cx, cy, (outerR + innerR) / 2, startAngle, startAngle + sweep);
      ctx.strokeStyle = this.chartItems[i].color;
      ctx.lineWidth = lineW;
      ctx.stroke();
      startAngle += sweep;
    }
  }

  /** 截图并保存 */
  private async saveChartSnapshot(): Promise<void> {
    try {
      const pixelMap: image.PixelMap | undefined =
        await componentSnapshot.get(this.saveTargetId);
      if (!pixelMap) {
        promptAction.showToast({ message: '截图失败', duration: 1500 });
        return;
      }

      // 编码为 PNG
      const packer: image.ImagePacker = image.createImagePacker();
      const packOpts: image.PackingOption = { format: 'image/png', quality: 90 };
      const data: ArrayBuffer = await packer.packing(pixelMap, packOpts);
      packer.release();

      // 转换 ArrayBuffer 为文本并保存
      let str: string = '';
      const bytes: Uint8Array = new Uint8Array(data);
      for (let i = 0; i < bytes.length; i++) {
        str += String.fromCharCode(bytes[i]);
      }

      const ctx: common.UIAbilityContext =
        this.getUIContext().getHostContext() as common.UIAbilityContext;
      const ok: boolean = await ExportUtil.saveTextFile(ctx, str, '支出统计图.png');
      if (ok) {
        promptAction.showToast({ message: '图表已保存', duration: 1500 });
      }
    } catch (err) {
      console.error(`图表截图保存失败: ${JSON.stringify(err)}`);
      promptAction.showToast({ message: '保存失败', duration: 1500 });
    }
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Button() {
          Text('←').fontSize(22).fontColor($r('app.color.text_primary'));
        }
        .type(ButtonType.Circle)
        .backgroundColor(Color.Transparent)
        .width(40).height(40)
        .onClick(() => { router.back(); });

        Text('图表导出')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center);

        Button() {
          Text('保存')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.accent_blue'));
        }
        .backgroundColor(Color.Transparent)
        .padding({ left: 8, right: 8 })
        .onClick(() => { this.saveChartSnapshot(); });
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 8 })
      .backgroundColor($r('app.color.card_background'));

      if (this.isLoading) {
        Column() {
          Text('⏳')
            .fontSize(48)
            .margin({ bottom: 8 });
          Text('加载中…')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'));
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else if (this.chartItems.length === 0) {
        Column() {
          Text('📊')
            .fontSize(48)
            .margin({ bottom: 8 });
          Text('暂无支出数据')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'));
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else {
        Scroll() {
          Column() {
            // 图表区（截图目标）
            Column() {
              Stack() {
                Canvas(this.ringContext)
                  .width(320)
                  .height(320)
                  .backgroundColor(Color.Transparent);

                Column() {
                  Text('总支出')
                    .fontSize(12)
                    .fontColor($r('app.color.text_secondary'));
                  Text('¥' + this.totalExpense)
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.text_primary'));
                }
                .width(140)
                .position({ x: '50%', y: '50%' })
                .markAnchor({ x: '50%', y: '50%' });
              }
              .width('100%')
              .height(320)
              .alignContent(Alignment.Center);
            }
            .id(this.saveTargetId)
            .width('100%')
            .padding({ top: 16, bottom: 8 })
            .backgroundColor($r('app.color.card_background'))
            .borderRadius(12)
            .margin({ left: 16, right: 16, top: 16 });

            // 图例
            Column() {
              Text('分类明细')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .margin({ bottom: 10 });

              ForEach(this.chartItems, (item: ChartItem, index: number) => {
                Row() {
                  Row()
                    .width(16).height(16)
                    .borderRadius(4)
                    .backgroundColor(item.color)
                    .margin({ right: 10 });

                  Text(item.icon)
                    .fontSize(18)
                    .margin({ right: 6 });

                  Text(item.name)
                    .fontSize(14)
                    .fontColor($r('app.color.text_primary'))
                    .layoutWeight(1);

                  Text('¥' + item.amount.toFixed(2))
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))
                    .margin({ right: 6 });

                  Text(item.percent.toFixed(1) + '%')
                    .fontSize(12)
                    .fontColor($r('app.color.text_secondary'));
                }
                .width('100%')
                .padding({ top: 8, bottom: 8 });
              }, (item: ChartItem) => item.name);
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16, bottom: 16 })
            .backgroundColor($r('app.color.card_background'))
            .borderRadius(12)
            .margin({ left: 16, right: 16, top: 8, bottom: 32 });
          }
          .width('100%');
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off);
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'));
  }
}
