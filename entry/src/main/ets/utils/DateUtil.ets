/**
 * 日期格式化工具类
 */

/** 年月对象 */
class YearMonth {
  year: number = 0;
  month: number = 0;
}

export class DateUtil {
  /**
   * 将 Date 对象格式化为 YYYY-MM-DD 字符串
   */
  static formatDate(date: Date): string {
    const year: number = date.getFullYear();
    const month: string = String(date.getMonth() + 1).padStart(2, '0');
    const day: string = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  /**
   * 判断日期字符串是今天/昨天/其他，返回显示文本
   */
  static formatDateDisplay(dateStr: string): string {
    if (DateUtil.isToday(dateStr)) {
      return '今天';
    }
    if (DateUtil.isYesterday(dateStr)) {
      return '昨天';
    }
    const parts: string[] = dateStr.split('-');
    if (parts.length === 3) {
      return `${parseInt(parts[1])}月${parseInt(parts[2])}日`;
    }
    return dateStr;
  }

  /**
   * 获取当前年月
   */
  static getCurrentYearMonth(): YearMonth {
    const now: Date = new Date();
    const result: YearMonth = new YearMonth();
    result.year = now.getFullYear();
    result.month = now.getMonth() + 1;
    return result;
  }

  /**
   * 判断日期字符串是否为今天
   */
  static isToday(dateStr: string): boolean {
    const today: string = DateUtil.formatDate(new Date());
    return dateStr === today;
  }

  /**
   * 判断日期字符串是否为昨天
   */
  static isYesterday(dateStr: string): boolean {
    const now: Date = new Date();
    const yesterday: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1);
    const yesterdayStr: string = DateUtil.formatDate(yesterday);
    return dateStr === yesterdayStr;
  }

  /**
   * 将 YYYY-MM-DD 日期字符串转为时间戳（毫秒，当天 00:00:00）
   */
  static getDateTimestamp(dateStr: string): number {
    const date: Date = new Date(dateStr);
    return date.getTime();
  }
}
