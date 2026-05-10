/**
 * 记账记录数据模型
 */
export interface Record {
  id: number;
  amount: number;
  type: 'income' | 'expense';
  category: string;
  note: string;
  date: string; // 格式 "YYYY-MM-DD HH:mm"
  timestamp: number; // 毫秒时间戳，用于排序
}

/**
 * 插入记录所需字段（不含id）
 */
export class InsertRecord {
  amount: number = 0;
  type: 'income' | 'expense' = 'expense';
  category: string = '';
  note: string = '';
  date: string = '';
  timestamp: number = 0;
}

/**
 * 月度统计结果
 */
export class MonthStats {
  totalIncome: number = 0;
  totalExpense: number = 0;
}
