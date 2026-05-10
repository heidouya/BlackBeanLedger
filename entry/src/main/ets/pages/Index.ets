import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { RecordModel } from '../model/RecordModel';
import { RecordDatabase } from '../database/RecordDatabase';
import { DateUtil } from '../utils/DateUtil';
import { CategoryItem, getCategoriesByType } from '../constants/CategoryConstants';

/** 分组后的记录结构 */
class RecordGroup {
  dateLabel: string = '';
  records: RecordModel[] = [];
}

@Entry
@Component
struct Index {
  @State monthTitle: string = '';
  @State monthlyIncome: number = 0;
  @State monthlyExpense: number = 0;
  @State monthlyBalance: number = 0;
  @State recordGroups: RecordGroup[] = [];
  @State isRefreshing: boolean = false;
  @State isLoading: boolean = true;
  private db: RecordDatabase = RecordDatabase.getInstance();

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

      // 计算本月收入
      const incomeRecords: RecordModel[] = await this.db.queryByTypeAndMonth(1, year, month);
      this.monthlyIncome = incomeRecords.reduce((sum: number, r: RecordModel) => sum + r.amount, 0);

      // 计算本月支出
      const expenseRecords: RecordModel[] = await this.db.queryByTypeAndMonth(0, year, month);
      this.monthlyExpense = expenseRecords.reduce((sum: number, r: RecordModel) => sum + r.amount, 0);

      // 计算结余
      this.monthlyBalance = this.monthlyIncome - this.monthlyExpense;

      // 加载全部记录并分组
      const allRecords: RecordModel[] = await this.db.queryAllRecords();
      this.recordGroups = this.groupRecordsByDate(allRecords);
    } catch (err) {
      console.error(`首页数据加载失败: ${JSON.stringify(err)}`);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 将记录按日期分组
   */
  private groupRecordsByDate(records: RecordModel[]): RecordGroup[] {
    const groupMap: Map<string, RecordModel[]> = new Map();
    for (const record of records) {
      const label: string = DateUtil.formatDateDisplay(record.date);
      if (!groupMap.has(label)) {
        groupMap.set(label, []);
      }
      groupMap.get(label)!.push(record);
    }
    const groups: RecordGroup[] = [];
    groupMap.forEach((recs: RecordModel[], label: string) => {
      const group: RecordGroup = new RecordGroup();
      group.dateLabel = label;
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
  async deleteRecord(record: RecordModel): Promise<void> {
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
  private showDeleteDialog(record: RecordModel): void {
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
        fontColor: '#C62828',
        action: () => {
          this.deleteRecord(record);
        }
      }
    });
  }

  /**
   * 根据分类名查找图标资源
   */
  private getCategoryIcon(category: string, type: number): Resource {
    const categories: CategoryItem[] = getCategoriesByType(type);
    for (const cat of categories) {
      if (cat.name === category) {
        return cat.icon;
      }
    }
    return $r('sys.symbol.ellipsis_circle');
  }

  build() {
    Stack() {
      Column() {
        // 月份标题
        Text(this.monthTitle)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .padding({ left: 16, top: 16, bottom: 8 })
          .textAlign(TextAlign.Start);

        // 统计卡片区
        this.buildStatsCards();

        // 记录列表
        Refresh({ refreshing: $$this.isRefreshing }) {
          List() {
            if (this.recordGroups.length === 0 && !this.isLoading) {
              ListItem() {
                this.buildEmptyState();
              }
            }
            ForEach(this.recordGroups, (group: RecordGroup, groupIndex: number) => {
              ListItemGroup({ header: this.buildGroupHeader(group.dateLabel) }) {
                ForEach(group.records, (record: RecordModel, recordIndex: number) => {
                  ListItem() {
                    this.buildRecordRow(record);
                  }
                  .bindContextMenu(this.buildContextMenu(record), ResponseType.LongPress, {
                    placement: Placement.BottomLeft
                  })
                }, (record: RecordModel) => record.id.toString())
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

        // 底部留白给浮动按钮
        Blank().height(80);
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F8F8F8')

      // 浮动"+"按钮
      Button() {
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize(28)
          .fontColor([Color.White])
      }
      .width(56)
      .height(56)
      .borderRadius(28)
      .backgroundColor('#007AFF')
      .shadow({ radius: 8, color: '#40007AFF', offsetY: 4 })
      .position({ x: '50%', y: '100%' })
      .markAnchor({ x: '50%', y: '100%' })
      .offset({ x: 0, y: -32 })
      .onClick(() => {
        router.pushUrl({ url: 'pages/AddRecordPage' });
      })
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 统计卡片
   */
  @Builder
  buildStatsCards() {
    Row() {
      // 本月收入
      this.buildStatCard('本月收入', this.monthlyIncome, '#E8F5E9', '#2E7D32');
      // 本月支出
      this.buildStatCard('本月支出', this.monthlyExpense, '#FFEBEE', '#C62828');
      // 本月结余
      this.buildStatCard('本月结余', this.monthlyBalance, '#E3F2FD', '#1565C0');
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 8 })
    .justifyContent(FlexAlign.SpaceEvenly)
  }

  @Builder
  buildStatCard(label: string, amount: number, bgColor: string, textColor: string) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontColor(textColor)
        .margin({ bottom: 4 });
      Text(`¥${amount.toFixed(2)}`)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(textColor)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis });
    }
    .width('30%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor(bgColor)
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 分组头部
   */
  @Builder
  buildGroupHeader(label: string) {
    Text(label)
      .fontSize(14)
      .fontColor('#757575')
      .fontWeight(FontWeight.Medium)
      .padding({ left: 16, top: 12, bottom: 4 })
      .backgroundColor('#F8F8F8')
  }

  /**
   * 单条记录行
   */
  @Builder
  buildRecordRow(record: RecordModel) {
    Row() {
      // 分类图标
      Stack() {
        SymbolGlyph(this.getCategoryIcon(record.category, record.type))
          .fontSize(24)
          .fontColor([record.type === 0 ? '#C62828' : '#2E7D32']);
      }
      .width(40)
      .height(40)
      .borderRadius(20)
      .backgroundColor('#F0F0F0')
      .margin({ right: 12 })

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
      .layoutWeight(1)

      // 金额
      Text(`${record.type === 0 ? '-' : '+'}¥${record.amount.toFixed(2)}`)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(record.type === 0 ? '#C62828' : '#2E7D32');
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 长按上下文菜单
   */
  @Builder
  buildContextMenu(record: RecordModel) {
    Menu() {
      MenuItem({
        content: '删除',
        labelInfo: '删除'
      })
        .onClick(() => {
          this.showDeleteDialog(record);
        })
    }
  }

  /**
   * 空状态
   */
  @Builder
  buildEmptyState() {
    Column() {
      SymbolGlyph($r('sys.symbol.ellipsis_circle'))
        .fontSize(64)
        .fontColor(['#BDBDBD']);
      Text('暂无记录，点击下方 + 开始记账')
        .fontSize(14)
        .fontColor('#9E9E9E')
        .margin({ top: 16 });
    }
    .width('100%')
    .height(300)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
