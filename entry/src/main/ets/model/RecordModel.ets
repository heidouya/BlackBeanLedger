/**
 * 记账记录数据模型
 */
export class RecordModel {
  id: number = 0;
  amount: number = 0;
  type: number = 0; // 0=支出, 1=收入
  category: string = '';
  note: string = '';
  date: string = ''; // YYYY-MM-DD
  timestamp: number = 0; // 毫秒时间戳
}
