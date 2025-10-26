/**
 * 华为账号认证服务 - OpenHarmony兼容版本
 */
import { util } from '@kit.ArkTS';
import { preferences } from '@kit.ArkData';

export interface HuaweiUserInfo {
  unionID: string;
  openID: string;
  displayName: string;
  avatarUri?: string;
  email?: string;
  anonymousPhone?: string;
}

export class HuaweiAuthService {
  private static instance: HuaweiAuthService;
  private context: any;
  private preferencesStore: preferences.Preferences | null = null;
  private currentUser: HuaweiUserInfo | null = null;

  private constructor() {}

  static getInstance(): HuaweiAuthService {
    if (!HuaweiAuthService.instance) {
      HuaweiAuthService.instance = new HuaweiAuthService();
    }
    return HuaweiAuthService.instance;
  }

  /**
   * 初始化服务
   */
  async init(context: any): Promise<void> {
    this.context = context;
    try {
      // 初始化 Preferences 存储
      this.preferencesStore = await preferences.getPreferences(context, 'user_auth');
      
      // 尝试从本地恢复用户信息
      await this.restoreUserFromLocal();
    } catch (error) {
      console.error('[HuaweiAuthService] init failed:', JSON.stringify(error));
    }
  }

  /**
   * 执行华为账号登录
   * 在OpenHarmony环境下，暂时返回模拟数据
   */
  async login(): Promise<HuaweiUserInfo> {
    if (!this.context) {
      throw new Error('HuaweiAuthService not initialized');
    }

    try {
      // 在OpenHarmony环境下，暂时返回模拟用户数据
      const userInfo: HuaweiUserInfo = {
        unionID: 'mock_union_id_' + Date.now(),
        openID: 'mock_open_id_' + Date.now(),
        displayName: '运动达人',
        avatarUri: '',
        email: '',
        anonymousPhone: ''
      };

      // 保存用户信息到本地
      await this.saveUserToLocal(userInfo);
      this.currentUser = userInfo;

      return userInfo;
    } catch (error) {
      console.error('[HuaweiAuthService] login failed:', JSON.stringify(error));
      throw error;
    }
  }

  /**
   * 静默登录
   */
  async silentLogin(): Promise<HuaweiUserInfo | null> {
    if (!this.context) {
      return null;
    }

    try {
      // 在OpenHarmony环境下，暂时返回null
      return null;
    } catch (error) {
      console.error('[HuaweiAuthService] silentLogin failed:', JSON.stringify(error));
      return null;
    }
  }

  /**
   * 登出
   */
  async logout(): Promise<void> {
    try {
      if (this.preferencesStore) {
        await this.preferencesStore.clear();
      }
      this.currentUser = null;
    } catch (error) {
      console.error('[HuaweiAuthService] logout failed:', JSON.stringify(error));
    }
  }

  /**
   * 获取当前用户
   */
  getCurrentUser(): HuaweiUserInfo | null {
    return this.currentUser;
  }

  /**
   * 检查是否已登录
   */
  isLoggedIn(): boolean {
    return this.currentUser !== null;
  }

  /**
   * 保存用户信息到本地
   */
  private async saveUserToLocal(userInfo: HuaweiUserInfo): Promise<void> {
    if (!this.preferencesStore) {
      return;
    }

    try {
      await this.preferencesStore.put('user_info', JSON.stringify(userInfo));
      await this.preferencesStore.flush();
    } catch (error) {
      console.error('[HuaweiAuthService] saveUserToLocal failed:', JSON.stringify(error));
    }
  }

  /**
   * 从本地恢复用户信息
   */
  private async restoreUserFromLocal(): Promise<void> {
    if (!this.preferencesStore) {
      return;
    }

    try {
      const userInfoStr = await this.preferencesStore.get('user_info', '') as string;
      if (userInfoStr) {
        this.currentUser = JSON.parse(userInfoStr) as HuaweiUserInfo;
      }
    } catch (error) {
      console.error('[HuaweiAuthService] restoreUserFromLocal failed:', JSON.stringify(error));
    }
  }
}




