import { relationalStore } from '@kit.ArkData';
import { RecordModel } from '../model/RecordModel';

const DB_NAME: string = 'BlackBeanLedger.db';
const TABLE_NAME: string = 'records';

const SQL_CREATE_TABLE: string = `
  CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    amount REAL NOT NULL,
    type INTEGER NOT NULL,
    category TEXT NOT NULL,
    note TEXT DEFAULT '',
    date TEXT NOT NULL,
    timestamp INTEGER NOT NULL
  )
`;

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: DB_NAME,
  securityLevel: relationalStore.SecurityLevel.S1
};

/**
 * 关系型数据库封装（单例模式）
 */
export class RecordDatabase {
  private static instance: RecordDatabase | null = null;
  private rdbStore: relationalStore.RdbStore | null = null;

  private constructor() {
  }

  /**
   * 获取数据库单例
   */
  static getInstance(): RecordDatabase {
    if (!RecordDatabase.instance) {
      RecordDatabase.instance = new RecordDatabase();
    }
    return RecordDatabase.instance;
  }

  /**
   * 初始化数据库，创建表
   */
  async initDatabase(context: Context): Promise<void> {
    try {
      this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
      await this.rdbStore.executeSql(SQL_CREATE_TABLE);
      console.info('RecordDatabase: 数据库初始化成功');
    } catch (err) {
      console.error(`RecordDatabase: 数据库初始化失败, ${JSON.stringify(err)}`);
      throw new Error('数据库初始化失败');
    }
  }

  /**
   * 插入一条记录，返回自增id
   */
  async insertRecord(record: RecordModel): Promise<number> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }
    const valueBucket: relationalStore.ValuesBucket = {
      'amount': record.amount,
      'type': record.type,
      'category': record.category,
      'note': record.note,
      'date': record.date,
      'timestamp': record.timestamp
    };
    try {
      const rowId: number = await this.rdbStore.insert(TABLE_NAME, valueBucket);
      console.info(`RecordDatabase: 插入记录成功, rowId=${rowId}`);
      return rowId;
    } catch (err) {
      console.error(`RecordDatabase: 插入记录失败, ${JSON.stringify(err)}`);
      throw new Error('插入记录失败');
    }
  }

  /**
   * 根据id删除记录
   */
  async deleteRecord(id: number): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }
    const predicates: relationalStore.RdbPredicates =
      new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.equalTo('id', id);
    try {
      await this.rdbStore.delete(predicates);
      console.info(`RecordDatabase: 删除记录成功, id=${id}`);
    } catch (err) {
      console.error(`RecordDatabase: 删除记录失败, ${JSON.stringify(err)}`);
      throw new Error('删除记录失败');
    }
  }

  /**
   * 查询全部记录，按timestamp降序排列
   */
  async queryAllRecords(): Promise<RecordModel[]> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }
    const predicates: relationalStore.RdbPredicates =
      new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.orderByDesc('timestamp');
    return this.executeQuery(predicates);
  }

  /**
   * 查询指定月份的记录
   * @param year 年份
   * @param month 月份 (1-12)
   */
  async queryByMonth(year: number, month: number): Promise<RecordModel[]> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }
    // 使用 date 字段的 LIKE 匹配 YYYY-MM 格式
    const monthStr: string = `${year}-${String(month).padStart(2, '0')}`;
    const predicates: relationalStore.RdbPredicates =
      new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.like('date', `${monthStr}%`);
    predicates.orderByDesc('timestamp');
    return this.executeQuery(predicates);
  }

  /**
   * 按类型和月份筛选记录
   * @param type 0=支出, 1=收入
   * @param year 年份
   * @param month 月份
   */
  async queryByTypeAndMonth(type: number, year: number, month: number): Promise<RecordModel[]> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }
    const monthStr: string = `${year}-${String(month).padStart(2, '0')}`;
    const predicates: relationalStore.RdbPredicates =
      new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.equalTo('type', type);
    predicates.like('date', `${monthStr}%`);
    return this.executeQuery(predicates);
  }

  /**
   * 执行查询，将ResultSet转换为RecordModel数组
   */
  private async executeQuery(predicates: relationalStore.RdbPredicates): Promise<RecordModel[]> {
    const resultSet: relationalStore.ResultSet =
      await this.rdbStore!.query(predicates, ['id', 'amount', 'type', 'category', 'note', 'date', 'timestamp']);
    const records: RecordModel[] = [];
    while (resultSet.goToNextRow()) {
      const record: RecordModel = {
        id: resultSet.getLong(resultSet.getColumnIndex('id')),
        amount: resultSet.getDouble(resultSet.getColumnIndex('amount')),
        type: resultSet.getLong(resultSet.getColumnIndex('type')),
        category: resultSet.getString(resultSet.getColumnIndex('category')),
        note: resultSet.getString(resultSet.getColumnIndex('note')),
        date: resultSet.getString(resultSet.getColumnIndex('date')),
        timestamp: resultSet.getLong(resultSet.getColumnIndex('timestamp'))
      };
      records.push(record);
    }
    resultSet.close();
    return records;
  }
}
