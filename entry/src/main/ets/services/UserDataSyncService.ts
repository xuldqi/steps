/**
 * 用户数据同步服务
 * 负责本地数据与云端数据的同步
 * 适配StepSportszc项目的数据结构
 */
import { HuaweiAuthService, HuaweiUserInfo } from './HuaweiAuthService';
import { CloudDBService } from './CloudDBService';
import { CloudUser, CloudDailyStep, CloudSportRecord, CloudBodyRecord, CloudCoinHistory, CloudSignRecord } from '../cloud/CloudDBModels';
import { AppState, UserProfile, StepSnapshot, CoinHistoryItem, SignRecord } from '../models/AppModels';

export class UserDataSyncService {
  private static instance: UserDataSyncService;
  private authService = HuaweiAuthService.getInstance();
  private cloudDB = CloudDBService.getInstance();

  private constructor() {}

  static getInstance(): UserDataSyncService {
    if (!UserDataSyncService.instance) {
      UserDataSyncService.instance = new UserDataSyncService();
    }
    return UserDataSyncService.instance;
  }

  /**
   * 用户首次登录，创建云端用户数据
   */
  async onFirstLogin(huaweiUser: HuaweiUserInfo): Promise<CloudUser> {
    console.info('[UserDataSyncService] 首次登录，创建用户数据...');
    
    try {
      // 创建云端用户
      const cloudUser = await this.cloudDB.createNewUser(
        huaweiUser.unionID,
        huaweiUser.displayName,
        huaweiUser.avatarUri
      );

      console.info('[UserDataSyncService] 用户数据创建成功:', cloudUser.userId);
      return cloudUser;
    } catch (error) {
      console.error('[UserDataSyncService] 创建用户数据失败:', JSON.stringify(error));
      throw error;
    }
  }

  /**
   * 从云端加载用户数据
   */
  async loadUserData(userId: string): Promise<AppState> {
    console.info('[UserDataSyncService] 从云端加载用户数据...');
    
    try {
      // 获取用户信息
      const cloudUser = await this.cloudDB.getUser(userId);
      
      if (!cloudUser) {
        throw new Error('云端用户数据不存在');
      }

      // 转换为本地数据格式
      const userProfile: UserProfile = {
        id: cloudUser.userId,
        nickname: cloudUser.nickname,
        avatar: cloudUser.avatar,
        inviteCode: cloudUser.inviteCode,
        balance: cloudUser.balance,
        totalCoins: cloudUser.totalCoins,
        stepTarget: cloudUser.stepTarget,
        persistedDays: cloudUser.persistedDays,
        consecutiveSignDays: cloudUser.consecutiveSignDays
      };

      // 获取今日步数
      const today = new Date().toISOString().slice(0, 10);
      const todayStep = await this.cloudDB.getDailyStep(userId, today);
      
      const todaySnapshot: StepSnapshot = todayStep ? {
        date: todayStep.date,
        steps: todayStep.steps,
        calories: todayStep.calories,
        distanceKm: todayStep.distance / 1000, // 转换为千米
        durationMinutes: 0 // CloudDailyStep 没有时长字段，可以后续扩展
      } : {
        date: today,
        steps: 0,
        calories: 0,
        distanceKm: 0,
        durationMinutes: 0
      };

      // 获取7日趋势
      const weeklySteps = await this.cloudDB.getRecentDailySteps(userId, 7);
      const weeklyTrend: StepSnapshot[] = this.fillMissingDays(weeklySteps, 7);

      // 获取签到记录
      const cloudSignRecords = await this.cloudDB.getRecentSignRecords(userId, 7);
      const signRecords: SignRecord[] = cloudSignRecords.map(record => ({
        date: record.date,
        reward: record.reward,
        completed: record.completed
      }));

      // 获取金币流水
      const cloudCoinHistory = await this.cloudDB.getCoinHistory(userId, 50);
      const coinHistory: CoinHistoryItem[] = cloudCoinHistory.map(history => ({
        id: history.coinId,
        title: history.title,
        amount: history.amount,
        type: history.type as 'income' | 'expense',
        createdAt: history.createdAt.toISOString()
      }));

      // 构建默认任务列表
      const tasks = await this.buildTaskList(userId);

      const appState: AppState = {
        user: userProfile,
        todaySnapshot,
        weeklyTrend,
        signRecords,
        tasks,
        coinHistory
      };

      console.info('[UserDataSyncService] 用户数据加载成功');
      return appState;

    } catch (error) {
      console.error('[UserDataSyncService] 加载用户数据失败:', JSON.stringify(error));
      throw error;
    }
  }

  /**
   * 同步今日步数到云端
   */
  async syncTodaySteps(userId: string, snapshot: StepSnapshot): Promise<void> {
    try {
      const record = new CloudDailyStep();
      record.userId = userId;
      record.date = snapshot.date;
      record.steps = snapshot.steps;
      record.calories = snapshot.calories;
      record.distance = Math.round(snapshot.distanceKm * 1000); // 转换为米

      await this.cloudDB.saveDailyStep(record);
      console.info('[UserDataSyncService] 步数同步成功:', snapshot.steps);
    } catch (error) {
      console.error('[UserDataSyncService] 同步步数失败:', JSON.stringify(error));
    }
  }

  /**
   * 同步运动记录到云端
   */
  async syncSportRecord(userId: string, sportType: string, beginTime: string, endTime: string, 
                         duration: number, steps: number, distance: number, calories: number): Promise<void> {
    try {
      const record = new CloudSportRecord();
      record.userId = userId;
      record.sportType = sportType;
      record.beginTime = beginTime;
      record.endTime = endTime;
      record.duration = duration;
      record.steps = steps;
      record.distance = distance;
      record.calories = calories;

      await this.cloudDB.saveSportRecord(record);
      console.info('[UserDataSyncService] 运动记录同步成功');
    } catch (error) {
      console.error('[UserDataSyncService] 同步运动记录失败:', JSON.stringify(error));
    }
  }

  /**
   * 同步身体数据到云端
   */
  async syncBodyRecord(userId: string, recordTime: string, height: number, weight: number,
                        bust: number, waistline: number, hipline: number,
                        systolicPressure: number, diastolicPressure: number, heartRate: number): Promise<void> {
    try {
      const record = new CloudBodyRecord();
      record.userId = userId;
      record.recordTime = recordTime;
      record.height = height;
      record.weight = weight;
      record.bust = bust;
      record.waistline = waistline;
      record.hipline = hipline;
      record.systolicPressure = systolicPressure;
      record.diastolicPressure = diastolicPressure;
      record.heartRate = heartRate;

      await this.cloudDB.saveBodyRecord(record);
      console.info('[UserDataSyncService] 身体数据同步成功');
    } catch (error) {
      console.error('[UserDataSyncService] 同步身体数据失败:', JSON.stringify(error));
    }
  }

  /**
   * 用户签到
   */
  async signIn(userId: string, reward: number): Promise<void> {
    try {
      // 检查今天是否已签到
      const hasSigned = await this.cloudDB.checkTodaySign(userId);
      if (hasSigned) {
        throw new Error('今天已经签到过了');
      }

      const today = new Date().toISOString().slice(0, 10);

      // 保存签到记录
      const signRecord = new CloudSignRecord();
      signRecord.userId = userId;
      signRecord.date = today;
      signRecord.reward = reward;
      signRecord.completed = true;

      await this.cloudDB.saveSignRecord(signRecord);

      // 增加用户金币
      await this.cloudDB.updateUserBalance(userId, reward, true);

      // 更新连续签到天数
      const user = await this.cloudDB.getUser(userId);
      if (user) {
        user.consecutiveSignDays += 1;
        await this.cloudDB.upsertUser(user);
      }

      // 添加金币流水
      const coinHistory = new CloudCoinHistory();
      coinHistory.userId = userId;
      coinHistory.title = '每日签到';
      coinHistory.amount = reward;
      coinHistory.type = 'income';

      await this.cloudDB.addCoinHistory(coinHistory);

      console.info('[UserDataSyncService] 签到成功，奖励:', reward);
    } catch (error) {
      console.error('[UserDataSyncService] 签到失败:', JSON.stringify(error));
      throw error;
    }
  }

  /**
   * 领取任务奖励
   */
  async claimTaskReward(userId: string, taskId: number, reward: number, taskName: string): Promise<void> {
    try {
      // 更新用户金币
      await this.cloudDB.updateUserBalance(userId, reward, true);

      // 添加金币流水
      const coinHistory = new CloudCoinHistory();
      coinHistory.userId = userId;
      coinHistory.title = taskName;
      coinHistory.amount = reward;
      coinHistory.type = 'income';

      await this.cloudDB.addCoinHistory(coinHistory);

      console.info('[UserDataSyncService] 任务奖励领取成功:', taskName, reward);
    } catch (error) {
      console.error('[UserDataSyncService] 领取任务奖励失败:', JSON.stringify(error));
      throw error;
    }
  }

  /**
   * 填充缺失的日期数据
   */
  private fillMissingDays(records: CloudDailyStep[], days: number): StepSnapshot[] {
    const result: StepSnapshot[] = [];
    const today = new Date();
    const recordMap = new Map(records.map(r => [r.date, r]));

    for (let i = days - 1; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(today.getDate() - i);
      const dateStr = date.toISOString().slice(0, 10);

      const record = recordMap.get(dateStr);
      
      if (record) {
        result.push({
          date: record.date,
          steps: record.steps,
          calories: record.calories,
          distanceKm: record.distance / 1000,
          durationMinutes: 0
        });
      } else {
        result.push({
          date: dateStr,
          steps: 0,
          calories: 0,
          distanceKm: 0,
          durationMinutes: 0
        });
      }
    }

    return result;
  }

  /**
   * 构建任务列表（本地定义 + 云端状态）
   */
  private async buildTaskList(userId: string) {
    const defaultTasks = [
      {
        id: 2,
        title: '同步步数领奖励',
        description: '完成设备步数同步并领取金币',
        reward: 88,
        progress: 0,
        target: 1,
        type: 'step' as const,
        status: 'available' as const
      },
      {
        id: 5,
        title: '步数达标1500',
        description: '今日步数达到 1500 步可以领取奖励',
        reward: 66,
        progress: 0,
        target: 1500,
        type: 'step' as const,
        status: 'locked' as const
      },
      {
        id: 23,
        title: '步数达标3000',
        description: '今日步数达到 3000 步可以领取奖励',
        reward: 88,
        progress: 0,
        target: 3000,
        type: 'step' as const,
        status: 'locked' as const
      },
      {
        id: 24,
        title: '步数达标6000',
        description: '今日步数达到 6000 步可以领取奖励',
        reward: 128,
        progress: 0,
        target: 6000,
        type: 'step' as const,
        status: 'locked' as const
      },
      {
        id: 14,
        title: '签到奖励',
        description: '累计签到 7 天领取大奖',
        reward: 188,
        progress: 0,
        target: 7,
        type: 'daily' as const,
        status: 'available' as const
      }
    ];

    // 从云端加载任务状态
    for (const task of defaultTasks) {
      const cloudTask = await this.cloudDB.getTaskRecord(userId, task.id);
      if (cloudTask) {
        task.progress = cloudTask.progress;
        task.status = cloudTask.status as any;
      }
    }

    return defaultTasks;
  }
}







