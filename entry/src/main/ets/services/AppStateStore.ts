/**
 * 应用状态管理中心
 * 统一管理用户登录状态、数据同步、云存储
 * 适配StepSportszc项目
 */
import { AppState, CoinHistoryItem, StepSnapshot, UserProfile } from '../models/AppModels';
import { UserDataSyncService } from './UserDataSyncService';
import { CloudDBService } from './CloudDBService';
import preferencesUtil from '../tools/DataPreUtils';

const LAST_UNION_ID_KEY = 'last_union_id';

type Listener = (state: AppState) => void;

function buildDefaultState(): AppState {
  const today = new Date();
  const dateStr = today.toISOString().slice(0, 10);

  return {
    user: null,
    todaySnapshot: {
      date: dateStr,
      steps: 0,
      calories: 0,
      distanceKm: 0,
      durationMinutes: 0
    },
    weeklyTrend: [],
    signRecords: [],
    tasks: [],
    coinHistory: []
  };
}

export class AppStateStore {
  private static instance: AppStateStore;
  private state: AppState = buildDefaultState();
  private listeners: Set<Listener> = new Set();
  private syncService = UserDataSyncService.getInstance();
  private cloudDB = CloudDBService.getInstance();

  private isLoggedIn: boolean = false;
  private cachedUnionId: string | null = null;

  static getInstance(): AppStateStore {
    if (!AppStateStore.instance) {
      AppStateStore.instance = new AppStateStore();
    }
    return AppStateStore.instance;
  }

  getState(): AppState {
    return this.state;
  }

  subscribe(listener: Listener): () => void {
    this.listeners.add(listener);
    listener(this.state);
    return () => this.listeners.delete(listener);
  }

  private emit(): void {
    this.listeners.forEach((listener) => listener(this.state));
  }

  /**
   * 检查登录状态
   */
  isUserLoggedIn(): boolean {
    return this.isLoggedIn && this.state.user !== null;
  }

  /**
   * 获取当前用户ID
   */
  getUserId(): string | null {
    return this.state.user?.id || this.cachedUnionId;
  }

  /**
   * 使用 unionId 登录
   */
  async loginWithUnionId(unionId: string, options?: { nickname?: string; avatar?: string }): Promise<void> {
    if (!unionId) {
      throw new Error('unionId 不能为空');
    }

    const displayName = options?.nickname ?? '运动达人';
    const avatar = options?.avatar ?? '';

    // 写入本地缓存，便于下次自动登录
    try {
      await preferencesUtil.putPreferenceValue('steps_ohos', LAST_UNION_ID_KEY, unionId);
    } catch (error) {
      console.warn('[AppStateStore] 缓存登录信息失败:', JSON.stringify(error));
    }

    this.cachedUnionId = unionId;

    // 若云端不存在用户，则创建默认数据
    let cloudUser = await this.cloudDB.getUser(unionId);
    if (!cloudUser) {
      console.info('[AppStateStore] 首次登录，创建云端用户');
      cloudUser = await this.syncService.onFirstLogin(unionId, displayName, avatar);
    }

    // 拉取云端完整数据
    const appState = await this.syncService.loadUserData(unionId);
    this.state = appState;
    this.isLoggedIn = true;
    this.emit();

    console.info('[AppStateStore] 用户登录成功:', displayName);
  }

  /**
   * 静默登录（自动登录）
   */
  async autoLogin(): Promise<boolean> {
    try {
      const unionId = await preferencesUtil.getPreferenceValue('steps_ohos', LAST_UNION_ID_KEY, '') as string;
      if (!unionId) {
        return false;
      }
      const appState = await this.syncService.loadUserData(unionId);
      this.state = appState;
      this.cachedUnionId = unionId;
      this.isLoggedIn = true;
      this.emit();
      console.info('[AppStateStore] 自动登录成功');
      return true;
    } catch (error) {
      console.warn('[AppStateStore] 自动登录失败:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 用户登出
   */
  async logout(): Promise<void> {
    try {
      await preferencesUtil.deletePreferenceValue('steps_ohos', LAST_UNION_ID_KEY, '');
    } catch (error) {
      console.warn('[AppStateStore] 清理登录缓存失败:', JSON.stringify(error));
    }

    this.cachedUnionId = null;
    this.state = buildDefaultState();
    this.isLoggedIn = false;
    this.emit();

    console.info('[AppStateStore] 用户已登出');
  }

  /**
   * 更新用户信息
   */
  updateUser(partial: Partial<UserProfile>): void {
    if (!this.state.user) {
      return;
    }
    this.state = {
      ...this.state,
      user: { ...this.state.user, ...partial }
    };
    this.emit();
  }

  /**
   * 在未登录等场景下也需要触发订阅者刷新（例如本地昵称变更）。
   * 不修改任何状态，仅广播当前 state。
   */
  forceEmit(): void {
    this.emit();
  }

  /**
   * 更新今日步数快照
   */
  updateTodaySnapshot(partial: Partial<StepSnapshot>): void {
    if (!this.state.todaySnapshot) {
      return;
    }

    const nextSnapshot = {
      ...this.state.todaySnapshot,
      ...partial
    } as StepSnapshot;
    
    this.state = {
      ...this.state,
      todaySnapshot: nextSnapshot
    };
    
    this.recalculateTaskStatuses(nextSnapshot.steps);
    
    // 自动同步到云端（异步处理，捕获错误避免未处理的 Promise 拒绝）
    if (this.getUserId()) {
      this.syncService.syncTodaySteps(this.getUserId()!, nextSnapshot).catch((error) => {
        // 记录错误但不阻止状态更新
        console.error('[AppStateStore] 同步今日步数到云端失败:', error);
      });
    }
  }

  /**
   * 添加金币流水记录
   */
  pushCoinRecord(record: CoinHistoryItem): void {
    this.state = {
      ...this.state,
      coinHistory: [record, ...this.state.coinHistory]
    };
    this.emit();
  }

  /**
   * 用户签到
   */
  async markSign(date: string, reward: number): Promise<void> {
    if (!this.state.user || !this.getUserId()) {
      return;
    }

    try {
      await this.syncService.signIn(this.getUserId()!, reward);

      const signRecords = this.state.signRecords.map((record) =>
        record.date === date
          ? { ...record, completed: true, reward }
          : record
      );

      const consecutiveSignDays = this.state.user.consecutiveSignDays + 1;
      const balance = this.state.user.balance + reward;
      const totalCoins = this.state.user.totalCoins + reward;

      const user = {
        ...this.state.user,
        consecutiveSignDays,
        balance,
        totalCoins
      };

      const coinHistory = [
        {
          id: `coin_${Date.now()}`,
          title: '每日签到',
          amount: reward,
          type: 'income' as const,
          createdAt: new Date().toISOString()
        },
        ...this.state.coinHistory
      ];

      this.state = { ...this.state, signRecords, user, coinHistory };
      this.emit();
      console.info('[AppStateStore] 签到成功，奖励:', reward);
    } catch (error) {
      console.error('[AppStateStore] 签到失败:', JSON.stringify(error));
      throw error;
    }
  }

  /**
   * 更新任务进度
   */
  updateTaskProgress(taskId: number, progress: number): void {
    const tasks = this.state.tasks.map((task) => {
      if (task.id !== taskId) {
        return task;
      }
      const nextProgress = Math.min(progress, task.target);
      const isCompleted = nextProgress >= task.target;
      return {
        ...task,
        progress: nextProgress,
        status: (isCompleted ? 'completed' : task.status) as any
      };
    });

    this.state = { ...this.state, tasks };
    this.emit();
  }

  /**
   * 领取任务奖励
   */
  async claimTaskReward(taskId: number): Promise<void> {
    if (!this.state.user || !this.getUserId()) {
      return;
    }

    const task = this.state.tasks.find(t => t.id === taskId);
    if (!task || task.status !== 'completed') {
      return;
    }

    try {
      await this.syncService.claimTaskReward(this.getUserId()!, taskId, task.reward, task.title);

      const tasks = this.state.tasks.map((t) =>
        t.id === taskId ? { ...t, status: 'claimed' as const } : t
      );

      const user = {
        ...this.state.user,
        balance: this.state.user.balance + task.reward,
        totalCoins: this.state.user.totalCoins + task.reward
      };

      const coinHistory = [
        {
          id: `coin_${Date.now()}`,
          title: task.title,
          amount: task.reward,
          type: 'income' as const,
          createdAt: new Date().toISOString()
        },
        ...this.state.coinHistory
      ];

      this.state = { ...this.state, tasks, user, coinHistory };
      this.emit();
      console.info('[AppStateStore] 任务奖励领取成功:', task.title, task.reward);
    } catch (error) {
      console.error('[AppStateStore] 领取任务奖励失败:', JSON.stringify(error));
      throw error;
    }
  }

  /**
   * 重新计算任务状态（基于今日步数）
   */
  recalculateTaskStatuses(todaySteps: number): void {
    const tasks = this.state.tasks.map((task) => {
      if (task.type !== 'step') {
        return task;
      }
      const isCompleted = todaySteps >= task.target;
      const status = isCompleted ? 'completed' : todaySteps > 0 ? 'available' : task.status;
      return {
        ...task,
        progress: Math.min(todaySteps, task.target),
        status
      };
    });

    this.state = { ...this.state, tasks };
    this.emit();
  }

  /**
   * 同步运动记录到云端
   */
  async syncSportRecord(sportType: string, beginTime: string, endTime: string, duration: number, steps: number, distance: number, calories: number): Promise<void> {
    if (!this.getUserId()) {
      console.warn('[AppStateStore] 未登录，无法同步运动记录');
      return;
    }

    try {
      await this.syncService.syncSportRecord(this.getUserId()!, sportType, beginTime, endTime, duration, steps, distance, calories);
      console.info('[AppStateStore] 运动记录同步成功');
    } catch (error) {
      console.error('[AppStateStore] 同步运动记录失败:', JSON.stringify(error));
    }
  }

  /**
   * 同步身体数据到云端
   */
  async syncBodyRecord(recordTime: string, height: number, weight: number, bust: number, waistline: number, hipline: number, systolicPressure: number, diastolicPressure: number, heartRate: number): Promise<void> {
    if (!this.getUserId()) {
      console.warn('[AppStateStore] 未登录，无法同步身体数据');
      return;
    }

    try {
      await this.syncService.syncBodyRecord(this.getUserId()!, recordTime, height, weight, bust, waistline, hipline, systolicPressure, diastolicPressure, heartRate);
      console.info('[AppStateStore] 身体数据同步成功');
    } catch (error) {
      console.error('[AppStateStore] 同步身体数据失败:', JSON.stringify(error));
    }
  }
}

