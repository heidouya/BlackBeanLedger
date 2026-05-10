/**
 * 日期格式化工具类
 * 日期格式: "YYYY-MM-DD HH:mm"
 */

/** 年月对象 */
class YearMonth {
  year: number = 0;
  month: number = 0;
}

export class DateUtil {
  /**
   * 将 Date 对象格式化为 "YYYY-MM-DD HH:mm" 字符串
   */
  static formatDateTime(date: Date): string {
    const year: number = date.getFullYear();
    const month: string = String(date.getMonth() + 1).padStart(2, '0');
    const day: string = String(date.getDate()).padStart(2, '0');
    const hours: string = String(date.getHours()).padStart(2, '0');
    const minutes: string = String(date.getMinutes()).padStart(2, '0');
    return `${year}-${month}-${day} ${hours}:${minutes}`;
  }

  /**
   * 将 Date 格式化为 "YYYY-MM-DD"（仅日期部分）
   */
  static formatDate(date: Date): string {
    const year: number = date.getFullYear();
    const month: string = String(date.getMonth() + 1).padStart(2, '0');
    const day: string = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  /**
   * 从日期字符串提取日期部分 "YYYY-MM-DD"
   */
  static extractDatePart(dateStr: string): string {
    return dateStr.substring(0, 10);
  }

  /**
   * 判断日期字符串是今天/昨天/其他，返回显示文本
   * 支持 "YYYY-MM-DD HH:mm" 和 "YYYY-MM-DD" 格式
   */
  static formatDateDisplay(dateStr: string): string {
    const datePart: string = DateUtil.extractDatePart(dateStr);
    if (DateUtil.isToday(datePart)) {
      return '今天';
    }
    if (DateUtil.isYesterday(datePart)) {
      return '昨天';
    }
    const parts: string[] = datePart.split('-');
    if (parts.length === 3) {
      return `${parseInt(parts[0])}年${parseInt(parts[1])}月${parseInt(parts[2])}日`;
    }
    return dateStr;
  }

  /**
   * 格式化为 "MM月DD日"（用于日期选择器显示）
   */
  static formatMonthDay(date: Date): string {
    const month: number = date.getMonth() + 1;
    const day: number = date.getDate();
    return `${month}月${day}日`;
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
   * 判断日期字符串（"YYYY-MM-DD"）是否为今天
   */
  static isToday(dateStr: string): boolean {
    const today: string = DateUtil.formatDate(new Date());
    return dateStr === today;
  }

  /**
   * 判断日期字符串（"YYYY-MM-DD"）是否为昨天
   */
  static isYesterday(dateStr: string): boolean {
    const now: Date = new Date();
    const yesterday: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1);
    const yesterdayStr: string = DateUtil.formatDate(yesterday);
    return dateStr === yesterdayStr;
  }

  /**
   * 将日期时间字符串转为时间戳（毫秒）
   */
  static getTimestamp(dateStr: string): number {
    // 将 "YYYY-MM-DD HH:mm" 转为 ISO 格式以便解析
    const normalized: string = dateStr.replace(' ', 'T') + ':00';
    const date: Date = new Date(normalized);
    return date.getTime();
  }

  /**
   * 从 "YYYY-MM-DD HH:mm" 格式提取时间部分显示 "HH:mm"
   */
  static formatTimeDisplay(dateStr: string): string {
    if (dateStr.includes(' ')) {
      return dateStr.split(' ')[1];
    }
    return '';
  }
}
