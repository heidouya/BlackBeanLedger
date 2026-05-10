import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const STORE_NAME: string = 'app_settings';
const KEY_BUDGET: string = 'monthly_budget';

/**
 * 预算首选项工具
 * 复用 app_settings 存储，仅管理月度预算相关读写
 */
export class BudgetPreferences {
  private static instance: BudgetPreferences | null = null;
  private store: preferences.Preferences | null = null;

  private constructor() {
  }

  static getInstance(): BudgetPreferences {
    if (!BudgetPreferences.instance) {
      BudgetPreferences.instance = new BudgetPreferences();
    }
    return BudgetPreferences.instance;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    this.store = await preferences.getPreferences(context, STORE_NAME);
  }

  /**
   * 保存月度预算（元）
   */
  async putBudget(amount: number): Promise<void> {
    await this.store?.put(KEY_BUDGET, amount);
    await this.store?.flush();
  }

  /**
   * 读取月度预算，默认 0 表示未设置
   */
  getBudgetSync(): number {
    return (this.store?.getSync(KEY_BUDGET, 0) as number) ?? 0;
  }

  /**
   * 读取月度预算（异步）
   */
  async getBudget(): Promise<number> {
    const val = await this.store?.get(KEY_BUDGET, 0);
    return (val as number) ?? 0;
  }
}
