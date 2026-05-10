import { router } from '@kit.ArkUI';
import { Record } from '../model/RecordModel';
import { RecordDatabase } from '../database/RecordDatabase';
import { DateUtil } from '../utils/DateUtil';
import { getCategoriesByType, CategoryItem } from '../constants/CategoryConstants';

/** 分类统计 */
class CategoryStat {
  name: string = '';
  icon: string = '';
  amount: number = 0;
  percent: number = 0;
  color: string = '';
}

/** 环形图颜色 */
const RING_COLORS: string[] = [
  '#FF6F00', '#FF5252', '#FF4081', '#E040FB',
  '#7C4DFF', '#448AFF', '#00BCD4', '#4CAF50',
  '#CDDC39', '#FFC107'
];

/**
 * 统计页面内容组件（可在 Tab 中嵌入或独立使用）
 */
@Component
export struct StatsContent {
  @State totalExpense: number = 0;
  @State totalIncome: number = 0;
  @State categoryStats: CategoryStat[] = [];
  @State monthTitle: string = '';
  @State isLoading: boolean = true;
  private db: RecordDatabase = RecordDatabase.getInstance();
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ringContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  aboutToAppear(): void {
    this.loadStats();
  }

  onPageShow(): void {
    this.loadStats();
  }

  /**
   * 加载统计数据
   */
  async loadStats(): Promise<void> {
    this.isLoading = true;
    try {
      const currentYM = DateUtil.getCurrentYearMonth();
      const year: number = currentYM.year;
      const month: number = currentYM.month;
      this.monthTitle = `${year}年${String(month).padStart(2, '0')}月`;

      // 获取月度统计
      const stats = await this.db.getMonthStats(year, month);
      this.totalExpense = stats.totalExpense;
      this.totalIncome = stats.totalIncome;

      // 获取本月支出记录，按分类统计
      const expenseRecords: Record[] = await this.db.queryByTypeAndMonth('expense', year, month);
      this.categoryStats = this.buildCategoryStats(expenseRecords);

      // 绘制环形图
      setTimeout(() => {
        this.drawRingChart();
      }, 100);
    } catch (err) {
      console.error(`统计页数据加载失败: ${JSON.stringify(err)}`);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 构建分类统计数据
   */
  private buildCategoryStats(records: Record[]): CategoryStat[] {
    const categoryMap: Map<string, number> = new Map();
    let totalAll: number = 0;

    for (const record of records) {
      const current: number = categoryMap.get(record.category) || 0;
      categoryMap.set(record.category, current + record.amount);
      totalAll += record.amount;
    }

    const stats: CategoryStat[] = [];
    const expenseCategories: CategoryItem[] = getCategoriesByType('expense');
    let colorIndex: number = 0;

    categoryMap.forEach((amount: number, category: string) => {
      const catItem: CategoryItem | undefined = expenseCategories.find(c => c.name === category);
      const stat: CategoryStat = new CategoryStat();
      stat.name = category;
      stat.icon = catItem ? catItem.icon : '📋';
      stat.amount = amount;
      stat.percent = totalAll > 0 ? (amount / totalAll) * 100 : 0;
      stat.color = RING_COLORS[colorIndex % RING_COLORS.length];
      stats.push(stat);
      colorIndex++;
    });

    // 按金额降序排列
    stats.sort((a: CategoryStat, b: CategoryStat) => b.amount - a.amount);
    return stats;
  }

  /**
   * 绘制环形图
   */
  private drawRingChart(): void {
    const ctx: CanvasRenderingContext2D = this.ringContext;
    const centerX: number = 160;
    const centerY: number = 160;
    const outerRadius: number = 130;
    const innerRadius: number = 85;
    const lineWidth: number = outerRadius - innerRadius;

    // 如果没有支出数据，绘制灰色圆环
    if (this.categoryStats.length === 0) {
      ctx.clearRect(0, 0, 320, 320);
      ctx.beginPath();
      ctx.arc(centerX, centerY, (outerRadius + innerRadius) / 2, 0, 2 * Math.PI);
      ctx.strokeStyle = '#E0E0E0';
      ctx.lineWidth = lineWidth;
      ctx.lineCap = 'round';
      ctx.stroke();
      return;
    }

    ctx.clearRect(0, 0, 320, 320);
    ctx.lineCap = 'round';

    // 计算总金额用于比例
    let totalAll: number = 0;
    for (const stat of this.categoryStats) {
      totalAll += stat.amount;
    }

    let startAngle: number = -Math.PI / 2; // 从顶部开始

    for (let i: number = 0; i < this.categoryStats.length; i++) {
      const stat: CategoryStat = this.categoryStats[i];
      const sweepAngle: number = totalAll > 0 ? (stat.amount / totalAll) * 2 * Math.PI : 0;

      ctx.beginPath();
      ctx.arc(centerX, centerY, (outerRadius + innerRadius) / 2, startAngle, startAngle + sweepAngle);
      ctx.strokeStyle = stat.color;
      ctx.lineWidth = lineWidth;
      ctx.stroke();

      startAngle += sweepAngle;
    }
  }

  build() {
    Column() {
      // 滚动内容
      Scroll() {
        Column() {
          // 月度总览
          this.buildMonthlyOverview();

          // 环形图
          this.buildRingArea();

          // 分类排行榜
          this.buildCategoryRanking();

          Blank().height(32);
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
   * 月度总览卡片
   */
  @Builder
  buildMonthlyOverview() {
    Stack() {
      Column()
        .width('100%')
        .height(100)
        .borderRadius(16)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [['#2C2C2E', 0], ['#1C1C1E', 1]]
        });

      Row() {
        // 总支出
        Column() {
          Text('总支出')
            .fontSize(12)
            .fontColor('#AAFFFFFF')
            .margin({ bottom: 4 });
          Text('¥' + this.formatAmount(this.totalExpense))
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF5252');
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1);

        // 分隔线
        Divider()
          .vertical(true)
          .height(40)
          .color('#40FFFFFF');

        // 总收入
        Column() {
          Text('总收入')
            .fontSize(12)
            .fontColor('#AAFFFFFF')
            .margin({ bottom: 4 });
          Text('¥' + this.formatAmount(this.totalIncome))
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4CAF50');
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1);

        // 分隔线
        Divider()
          .vertical(true)
          .height(40)
          .color('#40FFFFFF');

        // 结余
        Column() {
          Text('结余')
            .fontSize(12)
            .fontColor('#AAFFFFFF')
            .margin({ bottom: 4 });
          Text('¥' + this.formatAmount(this.totalIncome - this.totalExpense))
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFFFF');
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1);
      }
      .width('100%')
      .height(100)
      .padding({ left: 12, right: 12 });
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 4 });
  }

  /**
   * 环形图区域
   */
  @Builder
  buildRingArea() {
    Column() {
      Text(this.monthTitle + ' 支出分布')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#212121')
        .margin({ top: 12, bottom: 8 });

      if (this.categoryStats.length === 0) {
        // 空状态
        Column() {
          Text('📊')
            .fontSize(48)
            .margin({ bottom: 8 });
          Text('本月暂无支出记录')
            .fontSize(14)
            .fontColor('#9E9E9E');
        }
        .width('100%')
        .height(220)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Color.White)
        .borderRadius(12);
      } else {
        Stack() {
          Canvas(this.ringContext)
            .width(320)
            .height(320)
            .backgroundColor(Color.Transparent);

          // 中心文字
          Column() {
            Text('总支出')
              .fontSize(12)
              .fontColor('#9E9E9E');
            Text('¥' + this.formatAmount(this.totalExpense))
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#212121')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
          }
          .width(140)
          .position({ x: '50%', y: '50%' })
          .markAnchor({ x: '50%', y: '50%' });
        }
        .width('100%')
        .height(320)
        .backgroundColor(Color.White)
        .borderRadius(12);
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 12 });
  }

  /**
   * 分类排行榜（带进度条）
   */
  @Builder
  buildCategoryRanking() {
    Column() {
      Text('分类排行')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#212121')
        .margin({ top: 4, bottom: 8 })
        .padding({ left: 2 });

      Column() {
        ForEach(this.categoryStats, (stat: CategoryStat, index: number) => {
          this.buildRankItem(stat, index);
        }, (stat: CategoryStat) => stat.name);

        if (this.categoryStats.length === 0) {
          Text('暂无数据')
            .fontSize(14)
            .fontColor('#9E9E9E')
            .width('100%')
            .padding({ top: 30, bottom: 30 })
            .textAlign(TextAlign.Center);
        }
      }
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius(12);
    }
    .width('100%')
    .padding({ left: 16, right: 16 });
  }

  /**
   * 排行单项
   */
  @Builder
  buildRankItem(stat: CategoryStat, index: number) {
    Row() {
      // 排名
      Text(`${index + 1}`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(index < 3 ? '#FF6F00' : '#9E9E9E')
        .width(24);

      // 图标
      Text(stat.icon)
        .fontSize(20)
        .margin({ left: 8, right: 10 });

      // 分类名 + 进度条
      Column() {
        Row() {
          Text(stat.name)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#212121');

          Blank();

          Text('¥' + stat.amount.toFixed(2))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#212121');
        }
        .width('100%')
        .margin({ bottom: 4 });

        // 进度条
        Stack() {
          // 背景条
          Row()
            .width('100%')
            .height(6)
            .borderRadius(3)
            .backgroundColor('#F0F0F0');

          // 进度条
          Row()
            .width(`${Math.min(stat.percent, 100)}%`)
            .height(6)
            .borderRadius(3)
            .backgroundColor(stat.color);
        }
        .width('100%');

        Text(stat.percent.toFixed(1) + '%')
          .fontSize(11)
          .fontColor('#9E9E9E')
          .margin({ top: 2 });
      }
      .layoutWeight(1);
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 });
  }

  /**
   * 格式化金额（千分位）
   */
  private formatAmount(amount: number): string {
    const absStr: string = Math.abs(amount).toFixed(2);
    const parts: string[] = absStr.split('.');
    parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    return parts.join('.');
  }
}

/**
 * 统计页面（独立路由入口，保留顶部导航栏 ← 返回按钮）
 */
@Entry
@Component
struct StatsPage {
  @State totalExpense: number = 0;
  @State totalIncome: number = 0;
  @State categoryStats: CategoryStat[] = [];
  @State monthTitle: string = '';
  @State isLoading: boolean = true;
  private db: RecordDatabase = RecordDatabase.getInstance();
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ringContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  aboutToAppear(): void {
    this.loadStats();
  }

  onPageShow(): void {
    this.loadStats();
  }

  async loadStats(): Promise<void> {
    this.isLoading = true;
    try {
      const currentYM = DateUtil.getCurrentYearMonth();
      const year = currentYM.year;
      const month = currentYM.month;
      this.monthTitle = `${year}年${String(month).padStart(2, '0')}月`;
      const stats = await this.db.getMonthStats(year, month);
      this.totalExpense = stats.totalExpense;
      this.totalIncome = stats.totalIncome;
      const expenseRecords = await this.db.queryByTypeAndMonth('expense', year, month);
      this.categoryStats = this.buildCategoryStats(expenseRecords);
      setTimeout(() => { this.drawRingChart(); }, 100);
    } catch (err) {
      console.error(`统计页数据加载失败: ${JSON.stringify(err)}`);
    } finally {
      this.isLoading = false;
    }
  }

  private buildCategoryStats(records: Record[]): CategoryStat[] {
    const categoryMap = new Map<string, number>();
    let totalAll = 0;
    for (const record of records) {
      categoryMap.set(record.category, (categoryMap.get(record.category) || 0) + record.amount);
      totalAll += record.amount;
    }
    const stats: CategoryStat[] = [];
    const expenseCategories = getCategoriesByType('expense');
    let colorIndex = 0;
    categoryMap.forEach((amount, category) => {
      const catItem = expenseCategories.find(c => c.name === category);
      const stat = new CategoryStat();
      stat.name = category;
      stat.icon = catItem ? catItem.icon : '📋';
      stat.amount = amount;
      stat.percent = totalAll > 0 ? (amount / totalAll) * 100 : 0;
      stat.color = RING_COLORS[colorIndex % RING_COLORS.length];
      stats.push(stat);
      colorIndex++;
    });
    stats.sort((a, b) => b.amount - a.amount);
    return stats;
  }

  private drawRingChart(): void {
    const ctx = this.ringContext;
    const centerX = 160, centerY = 160;
    const outerRadius = 130, innerRadius = 85;
    const lineWidth = outerRadius - innerRadius;
    if (this.categoryStats.length === 0) {
      ctx.clearRect(0, 0, 320, 320);
      ctx.beginPath();
      ctx.arc(centerX, centerY, (outerRadius + innerRadius) / 2, 0, 2 * Math.PI);
      ctx.strokeStyle = '#E0E0E0';
      ctx.lineWidth = lineWidth;
      ctx.lineCap = 'round';
      ctx.stroke();
      return;
    }
    ctx.clearRect(0, 0, 320, 320);
    ctx.lineCap = 'round';
    let totalAll = 0;
    for (const stat of this.categoryStats) totalAll += stat.amount;
    let startAngle = -Math.PI / 2;
    for (let i = 0; i < this.categoryStats.length; i++) {
      const stat = this.categoryStats[i];
      const sweepAngle = totalAll > 0 ? (stat.amount / totalAll) * 2 * Math.PI : 0;
      ctx.beginPath();
      ctx.arc(centerX, centerY, (outerRadius + innerRadius) / 2, startAngle, startAngle + sweepAngle);
      ctx.strokeStyle = stat.color;
      ctx.lineWidth = lineWidth;
      ctx.stroke();
      startAngle += sweepAngle;
    }
  }

  private formatAmount(amount: number): string {
    const absStr = Math.abs(amount).toFixed(2);
    const parts = absStr.split('.');
    parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    return parts.join('.');
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
        .width(40).height(40)
        .onClick(() => { router.back(); });

        Text('月度统计')
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

      Scroll() {
        Column() {
          // 月度总览
          Stack() {
            Column().width('100%').height(100).borderRadius(16)
              .linearGradient({ direction: GradientDirection.Bottom, colors: [['#2C2C2E', 0], ['#1C1C1E', 1]] });
            Row() {
              Column() {
                Text('总支出').fontSize(12).fontColor('#AAFFFFFF').margin({ bottom: 4 });
                Text('¥' + this.formatAmount(this.totalExpense)).fontSize(22).fontWeight(FontWeight.Bold).fontColor('#FF5252');
              }.alignItems(HorizontalAlign.Center).layoutWeight(1);
              Divider().vertical(true).height(40).color('#40FFFFFF');
              Column() {
                Text('总收入').fontSize(12).fontColor('#AAFFFFFF').margin({ bottom: 4 });
                Text('¥' + this.formatAmount(this.totalIncome)).fontSize(22).fontWeight(FontWeight.Bold).fontColor('#4CAF50');
              }.alignItems(HorizontalAlign.Center).layoutWeight(1);
              Divider().vertical(true).height(40).color('#40FFFFFF');
              Column() {
                Text('结余').fontSize(12).fontColor('#AAFFFFFF').margin({ bottom: 4 });
                Text('¥' + this.formatAmount(this.totalIncome - this.totalExpense)).fontSize(22).fontWeight(FontWeight.Bold).fontColor('#FFFFFFFF');
              }.alignItems(HorizontalAlign.Center).layoutWeight(1);
            }.width('100%').height(100).padding({ left: 12, right: 12 });
          }.width('100%').padding({ left: 16, right: 16, top: 16, bottom: 4 });

          // 环形图
          Column() {
            Text(this.monthTitle + ' 支出分布').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#212121').margin({ top: 12, bottom: 8 });
            if (this.categoryStats.length === 0) {
              Column() {
                Text('📊').fontSize(48).margin({ bottom: 8 });
                Text('本月暂无支出记录').fontSize(14).fontColor('#9E9E9E');
              }.width('100%').height(220).justifyContent(FlexAlign.Center).backgroundColor(Color.White).borderRadius(12);
            } else {
              Stack() {
                Canvas(this.ringContext).width(320).height(320).backgroundColor(Color.Transparent);
                Column() {
                  Text('总支出').fontSize(12).fontColor('#9E9E9E');
                  Text('¥' + this.formatAmount(this.totalExpense)).fontSize(20).fontWeight(FontWeight.Bold).fontColor('#212121').maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis });
                }.width(140).position({ x: '50%', y: '50%' }).markAnchor({ x: '50%', y: '50%' });
              }.width('100%').height(320).backgroundColor(Color.White).borderRadius(12);
            }
          }.width('100%').padding({ left: 16, right: 16, bottom: 12 });

          // 分类排行
          Column() {
            Text('分类排行').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#212121').margin({ top: 4, bottom: 8 }).padding({ left: 2 });
            Column() {
              ForEach(this.categoryStats, (stat: CategoryStat, index: number) => {
                Row() {
                  Text(`${index + 1}`).fontSize(14).fontWeight(FontWeight.Bold).fontColor(index < 3 ? '#FF6F00' : '#9E9E9E').width(24);
                  Text(stat.icon).fontSize(20).margin({ left: 8, right: 10 });
                  Column() {
                    Row() {
                      Text(stat.name).fontSize(15).fontWeight(FontWeight.Medium).fontColor('#212121');
                      Blank();
                      Text('¥' + stat.amount.toFixed(2)).fontSize(14).fontWeight(FontWeight.Medium).fontColor('#212121');
                    }.width('100%').margin({ bottom: 4 });
                    Stack() {
                      Row().width('100%').height(6).borderRadius(3).backgroundColor('#F0F0F0');
                      Row().width(`${Math.min(stat.percent, 100)}%`).height(6).borderRadius(3).backgroundColor(stat.color);
                    }.width('100%');
                    Text(stat.percent.toFixed(1) + '%').fontSize(11).fontColor('#9E9E9E').margin({ top: 2 });
                  }.layoutWeight(1);
                }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 });
              }, (stat: CategoryStat) => stat.name);
              if (this.categoryStats.length === 0) {
                Text('暂无数据').fontSize(14).fontColor('#9E9E9E').width('100%').padding({ top: 30, bottom: 30 }).textAlign(TextAlign.Center);
              }
            }.width('100%').backgroundColor(Color.White).borderRadius(12);
          }.width('100%').padding({ left: 16, right: 16 });

          Blank().height(32);
        }.width('100%');
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
