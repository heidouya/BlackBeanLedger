import { relationalStore } from '@kit.ArkData';
import { Record, InsertRecord, MonthStats } from '../model/RecordModel';

const DB_NAME: string = 'AccountBook.db';
const TABLE_NAME: string = 'records';

const SQL_CREATE_TABLE: string = `
  CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    amount REAL NOT NULL,
    type TEXT CHECK(type IN ('income', 'expense')) NOT NULL,
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

  static getInstance(): RecordDatabase {
    if (!RecordDatabase.instance) {
      RecordDatabase.instance = new RecordDatabase();
    }
    return RecordDatabase.instance;
  }

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

  async insertRecord(record: InsertRecord): Promise<number> {
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

  async getAllRecords(): Promise<Record[]> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }
    const predicates: relationalStore.RdbPredicates =
      new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.orderByDesc('timestamp');
    return this.executeQuery(predicates);
  }

  async getMonthStats(year: number, month: number): Promise<MonthStats> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }
    const monthStr: string = `${year}-${String(month).padStart(2, '0')}`;

    const incomePredicates: relationalStore.RdbPredicates =
      new relationalStore.RdbPredicates(TABLE_NAME);
    incomePredicates.equalTo('type', 'income');
    incomePredicates.like('date', `${monthStr}%`);
    const incomeRecords: Record[] = await this.executeQuery(incomePredicates);
    const totalIncome: number = incomeRecords.reduce((sum: number, r: Record) => sum + r.amount, 0);

    const expensePredicates: relationalStore.RdbPredicates =
      new relationalStore.RdbPredicates(TABLE_NAME);
    expensePredicates.equalTo('type', 'expense');
    expensePredicates.like('date', `${monthStr}%`);
    const expenseRecords: Record[] = await this.executeQuery(expensePredicates);
    const totalExpense: number = expenseRecords.reduce((sum: number, r: Record) => sum + r.amount, 0);

    const stats: MonthStats = new MonthStats();
    stats.totalIncome = totalIncome;
    stats.totalExpense = totalExpense;
    return stats;
  }

  async queryByMonth(year: number, month: number): Promise<Record[]> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }
    const monthStr: string = `${year}-${String(month).padStart(2, '0')}`;
    const predicates: relationalStore.RdbPredicates =
      new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.like('date', `${monthStr}%`);
    predicates.orderByDesc('timestamp');
    return this.executeQuery(predicates);
  }

  async queryByTypeAndMonth(type: 'income' | 'expense', year: number, month: number): Promise<Record[]> {
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

  private async executeQuery(predicates: relationalStore.RdbPredicates): Promise<Record[]> {
    const resultSet: relationalStore.ResultSet =
      await this.rdbStore!.query(predicates, ['id', 'amount', 'type', 'category', 'note', 'date', 'timestamp']);
    const records: Record[] = [];
    while (resultSet.goToNextRow()) {
      const record: Record = {
        id: resultSet.getLong(resultSet.getColumnIndex('id')),
        amount: resultSet.getDouble(resultSet.getColumnIndex('amount')),
        type: resultSet.getString(resultSet.getColumnIndex('type')) as 'income' | 'expense',
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
