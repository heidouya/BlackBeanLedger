/**
 * 记账分类常量定义（含系统图标映射）
 */

/** 分类项接口 */
export interface CategoryItem {
  name: string;
  icon: Resource;
}

/** 支出分类列表 */
export const EXPENSE_CATEGORIES: CategoryItem[] = [
  { name: '餐饮', icon: $r('sys.symbol.fork_knife') },
  { name: '交通', icon: $r('sys.symbol.car') },
  { name: '购物', icon: $r('sys.symbol.bag') },
  { name: '娱乐', icon: $r('sys.symbol.gamecontroller') },
  { name: '医疗', icon: $r('sys.symbol.cross_case') },
  { name: '其他', icon: $r('sys.symbol.ellipsis_circle') }
];

/** 收入分类列表 */
export const INCOME_CATEGORIES: CategoryItem[] = [
  { name: '工资', icon: $r('sys.symbol.creditcard') },
  { name: '奖金', icon: $r('sys.symbol.gift') },
  { name: '理财', icon: $r('sys.symbol.repeat') },
  { name: '其他', icon: $r('sys.symbol.ellipsis_circle') }
];

/**
 * 根据类型获取分类列表
 * @param type 0=支出, 1=收入
 */
export function getCategoriesByType(type: number): CategoryItem[] {
  return type === 0 ? EXPENSE_CATEGORIES : INCOME_CATEGORIES;
}
