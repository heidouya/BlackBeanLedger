import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const STORE_NAME: string = 'app_settings';
const KEY_COLOR_MODE: string = 'color_mode';

/**
 * 应用设置首选项工具
 * 持久化颜色模式配置（浅色/深色/跟随系统）
 */
export class ThemePreferences {
  private static instance: ThemePreferences | null = null;
  private store: preferences.Preferences | null = null;

  private constructor() {
  }

  static getInstance(): ThemePreferences {
    if (!ThemePreferences.instance) {
      ThemePreferences.instance = new ThemePreferences();
    }
    return ThemePreferences.instance;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    this.store = await preferences.getPreferences(context, STORE_NAME);
  }

  /**
   * 保存颜色模式：'light' | 'dark' | 'system'
   */
  async putColorMode(mode: string): Promise<void> {
    await this.store?.put(KEY_COLOR_MODE, mode);
    await this.store?.flush();
  }

  /**
   * 读取颜色模式，默认跟随系统
   */
  getColorModeSync(): string {
    return this.store?.getSync(KEY_COLOR_MODE, 'system') as string ?? 'system';
  }

  /**
   * 获取颜色模式（异步）
   */
  async getColorMode(): Promise<string> {
    const mode = await this.store?.get(KEY_COLOR_MODE, 'system');
    return (mode as string) ?? 'system';
  }
}
