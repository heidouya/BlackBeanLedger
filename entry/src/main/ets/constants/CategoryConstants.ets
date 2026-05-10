/**
 * 记账分类常量定义（使用 Emoji 图标）
 */

/** 分类项接口 */
export interface CategoryItem {
  name: string;
  icon: string; // Emoji 图标
}

/** 支出分类列表 */
export const EXPENSE_CATEGORIES: CategoryItem[] = [
  { name: '餐饮', icon: '🍔' },
  { name: '交通', icon: '🚗' },
  { name: '购物', icon: '🛍️' },
  { name: '娱乐', icon: '🎮' },
  { name: '医疗', icon: '🏥' },
  { name: '其他', icon: '➕' }
];

/** 收入分类列表 */
export const INCOME_CATEGORIES: CategoryItem[] = [
  { name: '工资', icon: '💼' },
  { name: '奖金', icon: '🏆' },
  { name: '理财', icon: '💰' },
  { name: '其他', icon: '➕' }
];

/**
 * 根据类型获取分类列表
 * @param type 类型
 */
export function getCategoriesByType(type: 'income' | 'expense'): CategoryItem[] {
  return type === 'expense' ? EXPENSE_CATEGORIES : INCOME_CATEGORIES;
}

/**
 * 根据分类名查找图标
 */
export function getCategoryIcon(category: string, type: 'income' | 'expense'): string {
  const categories: CategoryItem[] = getCategoriesByType(type);
  for (const cat of categories) {
    if (cat.name === category) {
      return cat.icon;
    }
  }
  return '📋';
}
