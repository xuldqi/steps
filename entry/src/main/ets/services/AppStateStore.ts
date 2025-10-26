/**
 * 应用状态管理中心
 * 统一管理用户登录状态、数据同步、云存储
 * 适配StepSportszc项目
 */
import { AppState, CoinHistoryItem, SignRecord, StepSnapshot, TaskReward, UserProfile } from '../models/AppModels';
import { HuaweiAuthService } from './HuaweiAuthService';
import { UserDataSyncService } from './UserDataSyncService';
import { CloudDBService } from './CloudDBService';

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
  
  private authService = HuaweiAuthService.getInstance();
  private syncService = UserDataSyncService.getInstance();
  private cloudDB = CloudDBService.getInstance();
  
  private isLoggedIn: boolean = false;

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
    return this.state.user?.id || null;
  }

  /**
   * 用户登录
   */
  async login(): Promise<void> {
    try {
      // 执行华为账号登录
      const huaweiUser = await this.authService.login();
      
      if (!huaweiUser || !huaweiUser.unionID) {
        throw new Error('登录失败');
      }

      // 检查云端是否存在用户数据
      let cloudUser = await this.cloudDB.getUser(huaweiUser.unionID);
      
      if (!cloudUser) {
        // 首次登录，创建用户数据
        console.info('[AppStateStore] 首次登录，创建用户数据');
        cloudUser = await this.syncService.onFirstLogin(huaweiUser);
      }

      // 从云端加载完整的用户数据
      const appState = await this.syncService.loadUserData(huaweiUser.unionID);
      
      // 更新本地状态
      this.state = appState;
      this.isLoggedIn = true;
      this.emit();

      console.info('[AppStateStore] 用户登录成功:', huaweiUser.displayName);
    } catch (error) {
      console.error('[AppStateStore] 登录失败:', JSON.stringify(error));
      throw error;
    }
  }

  /**
   * 静默登录（自动登录）
   */
  async autoLogin(): Promise<boolean> {
    try {
      // 尝试静默登录
      const huaweiUser = await this.authService.silentLogin();
      
      if (!huaweiUser || !huaweiUser.unionID) {
        return false;
      }

      // 从云端加载用户数据
      const appState = await this.syncService.loadUserData(huaweiUser.unionID);
      
      // 更新本地状态
      this.state = appState;
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
      await this.authService.logout();
      
      // 重置为默认状态
      this.state = buildDefaultState();
      this.isLoggedIn = false;
      this.emit();

      console.info('[AppStateStore] 用户已登出');
    } catch (error) {
      console.error('[AppStateStore] 登出失败:', JSON.stringify(error));
      throw error;
    }
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
    
    // 自动同步到云端
    if (this.getUserId()) {
      this.syncService.syncTodaySteps(this.getUserId()!, nextSnapshot);
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
      // 同步到云端
      await this.syncService.signIn(this.getUserId()!, reward);

      // 更新本地状态
      const signRecords = this.state.signRecords.map((record) =>
        record.date === date ? { ...record, completed: true, reward } : record
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

      // 添加金币流水
      const coinHistory = [{
        id: `coin_${Date.now()}`,
        title: '每日签到',
        amount: reward,
        type: 'income' as const,
        createdAt: new Date().toISOString()
      }, ...this.state.coinHistory];

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
      // 同步到云端
      await this.syncService.claimTaskReward(this.getUserId()!, taskId, task.reward, task.title);

      // 更新本地状态
      const tasks = this.state.tasks.map((t) => {
        if (t.id !== taskId) {
          return t;
        }
        return { ...t, status: 'claimed' as const };
      });

      const user = {
        ...this.state.user,
        balance: this.state.user.balance + task.reward,
        totalCoins: this.state.user.totalCoins + task.reward
      };

      // 添加金币流水
      const coinHistory = [{
        id: `coin_${Date.now()}`,
        title: task.title,
        amount: task.reward,
        type: 'income' as const,
        createdAt: new Date().toISOString()
      }, ...this.state.coinHistory];

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
  async syncSportRecord(sportType: string, beginTime: string, endTime: string, 
                         duration: number, steps: number, distance: number, calories: number): Promise<void> {
    if (!this.getUserId()) {
      console.warn('[AppStateStore] 未登录，无法同步运动记录');
      return;
    }

    try {
      await this.syncService.syncSportRecord(
        this.getUserId()!,
        sportType,
        beginTime,
        endTime,
        duration,
        steps,
        distance,
        calories
      );
      console.info('[AppStateStore] 运动记录同步成功');
    } catch (error) {
      console.error('[AppStateStore] 同步运动记录失败:', JSON.stringify(error));
    }
  }

  /**
   * 同步身体数据到云端
   */
  async syncBodyRecord(recordTime: string, height: number, weight: number,
                        bust: number, waistline: number, hipline: number,
                        systolicPressure: number, diastolicPressure: number, heartRate: number): Promise<void> {
    if (!this.getUserId()) {
      console.warn('[AppStateStore] 未登录，无法同步身体数据');
      return;
    }

    try {
      await this.syncService.syncBodyRecord(
        this.getUserId()!,
        recordTime,
        height,
        weight,
        bust,
        waistline,
        hipline,
        systolicPressure,
        diastolicPressure,
        heartRate
      );
      console.info('[AppStateStore] 身体数据同步成功');
    } catch (error) {
      console.error('[AppStateStore] 同步身体数据失败:', JSON.stringify(error));
    }
  }
}







