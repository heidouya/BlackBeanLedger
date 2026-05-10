import { promptAction } from '@kit.ArkUI';
import { Record } from '../model/RecordModel';
import { RecordDatabase } from '../database/RecordDatabase';
import { DateUtil } from '../utils/DateUtil';
import { getCategoryIcon } from '../constants/CategoryConstants';
import { AddRecordContent } from './AddRecordPage';
import { StatsContent } from './StatsPage';

/** 分组后的记录结构 */
class RecordGroup {
  dateLabel: string = '';
  records: Record[] = [];
}

/** LazyForEach 数据源 */
class RecordGroupDataSource implements IDataSource {
  private groups: RecordGroup[] = [];
  private listeners: DataChangeListener[] = [];

  totalCount(): number {
    return this.groups.length;
  }

  getData(index: number): RecordGroup {
    return this.groups[index];
  }

  setData(groups: RecordGroup[]): void {
    this.groups = groups;
    this.notifyDataReload();
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos: number = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }

  notifyDataReload(): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataReloaded();
    });
  }

  notifyDataChange(index: number): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataChanged(index);
    });
  }
}

@Entry
@Component
struct Index {
  @State monthTitle: string = '';
  @State monthlyIncome: number = 0;
  @State monthlyExpense: number = 0;
  @State monthlyBalance: number = 0;
  @State isRefreshing: boolean = false;
  @State isEmpty: boolean = false;
  @State currentTabIndex: number = 0;
  private db: RecordDatabase = RecordDatabase.getInstance();
  private dataSource: RecordGroupDataSource = new RecordGroupDataSource();
  private tabTitles: string[] = ['明细', '记账', '统计'];

  aboutToAppear(): void {
    this.loadData();
  }

  onPageShow(): void {
    this.loadData();
  }

  /**
   * 加载统计数据与记录列表
   */
  async loadData(): Promise<void> {
    try {
      const currentYM = DateUtil.getCurrentYearMonth();
      const year: number = currentYM.year;
      const month: number = currentYM.month;
      this.monthTitle = `${year}年${String(month).padStart(2, '0')}月`;

      // 使用 getMonthStats 一次性获取月度统计
      const stats = await this.db.getMonthStats(year, month);
      this.monthlyIncome = stats.totalIncome;
      this.monthlyExpense = stats.totalExpense;
      this.monthlyBalance = this.monthlyIncome - this.monthlyExpense;

      // 加载全部记录并分组
      const allRecords: Record[] = await this.db.getAllRecords();
      const groups: RecordGroup[] = this.groupRecordsByDate(allRecords);
      this.dataSource.setData(groups);
      this.isEmpty = groups.length === 0;
    } catch (err) {
      console.error(`首页数据加载失败: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 将记录按日期分组
   */
  private groupRecordsByDate(records: Record[]): RecordGroup[] {
    const groupMap: Map<string, Record[]> = new Map();
    for (const record of records) {
      const datePart: string = DateUtil.extractDatePart(record.date);
      if (!groupMap.has(datePart)) {
        groupMap.set(datePart, []);
      }
      groupMap.get(datePart)!.push(record);
    }
    const groups: RecordGroup[] = [];
    groupMap.forEach((recs: Record[], datePart: string) => {
      const group: RecordGroup = new RecordGroup();
      group.dateLabel = DateUtil.formatDateDisplay(datePart);
      group.records = recs;
      groups.push(group);
    });
    return groups;
  }

  /**
   * 下拉刷新
   */
  async onRefresh(): Promise<void> {
    this.isRefreshing = true;
    await this.loadData();
    setTimeout(() => {
      this.isRefreshing = false;
    }, 500);
  }

  /**
   * 删除记录
   */
  async deleteRecord(record: Record): Promise<void> {
    try {
      await this.db.deleteRecord(record.id);
      promptAction.showToast({ message: '删除成功', duration: 2000 });
      await this.loadData();
    } catch (err) {
      promptAction.showToast({ message: '删除失败', duration: 2000 });
    }
  }

  /**
   * 弹出删除确认弹窗
   */
  private showDeleteDialog(record: Record): void {
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
          this.deleteRecord(record);
        }
      }
    });
  }

  build() {
    Tabs({ index: this.currentTabIndex }) {
      // Tab 0: 明细
      TabContent() {
        Column() {
          // 月份标题
          Row() {
            Text(this.monthTitle)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#212121')
              .layoutWeight(1);
          }
          .width('100%')
          .padding({ left: 16, top: 16, bottom: 12 });

          // 黑色统计卡片
          this.buildStatsCard();

          // 记录列表
          Refresh({ refreshing: $$this.isRefreshing }) {
            List() {
              if (this.isEmpty) {
                ListItem() {
                  this.buildEmptyState();
                }
              }
              LazyForEach(this.dataSource, (group: RecordGroup, groupIndex: number) => {
                ListItemGroup({ header: this.buildGroupHeader(group.dateLabel) }) {
                  ForEach(group.records, (record: Record, recordIndex: number) => {
                    ListItem() {
                      this.buildRecordRow(record);
                    }
                    .gesture(
                      LongPressGesture()
                        .onAction(() => {
                          this.showDeleteDialog(record);
                        })
                    )
                  }, (record: Record) => record.id.toString())
                }
              }, (group: RecordGroup, groupIndex: number) => groupIndex.toString())
            }
            .width('100%')
            .layoutWeight(1)
            .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 60 })
          }
          .onRefreshing(() => {
            this.onRefresh();
          })
          .refreshOffset(64)
          .layoutWeight(1)
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F5F5F5')
      }
      .tabBar('📋 明细')

      // Tab 1: 记账
      TabContent() {
        AddRecordContent({
          onSaved: () => {
            this.currentTabIndex = 0;
          }
        })
      }
      .tabBar('✏️ 记账')

      // Tab 2: 统计
      TabContent() {
        StatsContent()
      }
      .tabBar('📊 统计')
    }
    .barWidth('100%')
    .barHeight(56)
    .barPosition(BarPosition.End)
    .vertical(false)
    .width('100%')
    .height('100%')
  }

  /**
   * 黑色渐变统计卡片
   * 背景色 #1C1C1E，圆角 16vp
   */
  @Builder
  buildStatsCard() {
    Stack() {
      // 渐变背景
      Column()
        .width('100%')
        .height(140)
        .borderRadius(16)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [['#2C2C2E', 0], ['#1C1C1E', 1]]
        });

      // 内容层
      Column() {
        // 本月结余 - 大号数字
        Text('¥' + this.formatAmount(this.monthlyBalance))
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFFFF')
          .fontFamily('HarmonyOS Sans')
          .margin({ bottom: 12 });

        // 收入支出行
        Row() {
          // 本月收入
          Column() {
            Text('收入')
              .fontSize(12)
              .fontColor('#AAFFFFFF')
              .margin({ bottom: 2 });
            Text('¥' + this.formatAmount(this.monthlyIncome))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4CAF50');
          }
          .alignItems(HorizontalAlign.Start);

          Blank();

          // 本月支出
          Column() {
            Text('支出')
              .fontSize(12)
              .fontColor('#AAFFFFFF')
              .margin({ bottom: 2 });
            Text('¥' + this.formatAmount(this.monthlyExpense))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF5252');
          }
          .alignItems(HorizontalAlign.End);
        }
        .width('100%');
      }
      .width('100%')
      .height(140)
      .padding({ left: 20, right: 20, top: 20, bottom: 16 })
      .justifyContent(FlexAlign.Center);
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 12 })
  }

  /**
   * 分组头部
   */
  @Builder
  buildGroupHeader(label: string) {
    Text(label)
      .fontSize(13)
      .fontColor('#9E9E9E')
      .fontWeight(FontWeight.Medium)
      .padding({ left: 16, top: 14, bottom: 6 })
      .backgroundColor('#F5F5F5')
  }

  /**
   * 单条记录行
   */
  @Builder
  buildRecordRow(record: Record) {
    Row() {
      // 分类图标（Emoji）
      Stack() {
        Text(getCategoryIcon(record.category, record.type))
          .fontSize(22);
      }
      .width(42)
      .height(42)
      .borderRadius(21)
      .backgroundColor(record.type === 'expense' ? '#FFF0F0' : '#F0FFF0')
      .margin({ right: 12 });

      // 分类名和备注
      Column() {
        Text(record.category)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#212121');
        if (record.note) {
          Text(record.note)
            .fontSize(12)
            .fontColor('#9E9E9E')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 2 });
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1);

      // 金额
      Text(`${record.type === 'expense' ? '-' : '+'}¥${record.amount.toFixed(2)}`)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(record.type === 'expense' ? '#FF5252' : '#4CAF50');
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 空状态
   */
  @Builder
  buildEmptyState() {
    Column() {
      Text('📋')
        .fontSize(56)
        .margin({ bottom: 16 });
      Text('暂无记录')
        .fontSize(16)
        .fontColor('#9E9E9E')
        .margin({ bottom: 4 });
      Text('点击底部记账 Tab 开始记账')
        .fontSize(14)
        .fontColor('#BDBDBD');
    }
    .width('100%')
    .height(300)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 格式化金额（千分位）
   */
  private formatAmount(amount: number): string {
    const absAmount: number = Math.abs(amount);
    const parts: string[] = absAmount.toFixed(2).split('.');
    parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    const sign: string = amount < 0 ? '-' : '';
    return sign + parts.join('.');
  }
}
