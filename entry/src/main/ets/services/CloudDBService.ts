/**
 * 华为云数据库服务
 * 当前使用本地 Preferences 模拟云存储
 * 后续集成真实 CloudDB 后替换实现
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { 
  CloudUser, 
  CloudDailyStep,
  CloudSportRecord, 
  CloudBodyRecord,
  CloudTaskRecord, 
  CloudCoinHistory, 
  CloudSignRecord,
  generateId,
  generateInviteCode 
} from '../cloud/CloudDBModels';

/**
 * 云数据库服务类
 */
export class CloudDBService {
  private static instance: CloudDBService;
  private context: common.UIAbilityContext | null = null;
  private preferencesStore: preferences.Preferences | null = null;
  private isInitialized: boolean = false;

  private constructor() {}

  static getInstance(): CloudDBService {
    if (!CloudDBService.instance) {
      CloudDBService.instance = new CloudDBService();
    }
    return CloudDBService.instance;
  }

  /**
   * 初始化云数据库
   */
  async init(context: common.UIAbilityContext): Promise<void> {
    this.context = context;
    
    try {
      // 初始化本地存储（模拟云数据库）
      this.preferencesStore = await preferences.getPreferences(context, 'cloud_db');
      this.isInitialized = true;
      console.info('[CloudDBService] 初始化成功');
    } catch (error) {
      console.error('[CloudDBService] 初始化失败:', JSON.stringify(error));
      throw error;
    }
  }

  /**
   * 检查是否已初始化
   */
  private checkInit(): void {
    if (!this.isInitialized || !this.preferencesStore) {
      throw new Error('CloudDBService 未初始化');
    }
  }

  // ==================== 用户相关操作 ====================

  /**
   * 创建或更新用户
   */
  async upsertUser(user: CloudUser): Promise<void> {
    this.checkInit();
    
    try {
      const key = `user_${user.userId}`;
      user.updatedAt = new Date();
      
      await this.preferencesStore!.put(key, JSON.stringify(user));
      await this.preferencesStore!.flush();
      
      console.info('[CloudDBService] 用户数据保存成功:', user.userId);
    } catch (error) {
      console.error('[CloudDBService] 保存用户数据失败:', JSON.stringify(error));
      throw error;
    }
  }

  /**
   * 获取用户信息
   */
  async getUser(userId: string): Promise<CloudUser | null> {
    this.checkInit();
    
    try {
      const key = `user_${userId}`;
      const userStr = await this.preferencesStore!.get(key, '') as string;
      
      if (userStr) {
        const userData = JSON.parse(userStr);
        const user = new CloudUser();
        Object.assign(user, userData);
        return user;
      }
      
      return null;
    } catch (error) {
      console.error('[CloudDBService] 获取用户数据失败:', JSON.stringify(error));
      return null;
    }
  }

  /**
   * 创建新用户（首次登录）
   */
  async createNewUser(userId: string, nickname: string, avatar?: string): Promise<CloudUser> {
    const user = new CloudUser();
    user.userId = userId;
    user.nickname = nickname || '运动达人';
    user.avatar = avatar || '';
    user.inviteCode = generateInviteCode();
    user.balance = 0;
    user.totalCoins = 0;
    user.stepTarget = 10000;
    user.weightTarget = 65;
    user.persistedDays = 1;
    user.consecutiveSignDays = 0;
    user.createdAt = new Date();
    user.updatedAt = new Date();

    await this.upsertUser(user);
    return user;
  }

  /**
   * 更新用户金币
   */
  async updateUserBalance(userId: string, amount: number, isAdd: boolean = true): Promise<void> {
    const user = await this.getUser(userId);
    if (!user) {
      throw new Error('用户不存在');
    }

    if (isAdd) {
      user.balance += amount;
      user.totalCoins += amount;
    } else {
      user.balance -= amount;
    }

    await this.upsertUser(user);
  }

  // ==================== 每日步数记录相关操作 ====================

  /**
   * 保存每日步数记录
   */
  async saveDailyStep(record: CloudDailyStep): Promise<void> {
    this.checkInit();
    
    try {
      const key = `daily_step_${record.userId}_${record.date}`;
      record.recordId = record.recordId || generateId('step_');
      record.createdAt = new Date();
      
      await this.preferencesStore!.put(key, JSON.stringify(record));
      await this.preferencesStore!.flush();
      
      console.info('[CloudDBService] 每日步数保存成功:', record.date);
    } catch (error) {
      console.error('[CloudDBService] 保存每日步数失败:', JSON.stringify(error));
      throw error;
    }
  }

  /**
   * 获取指定日期的每日步数
   */
  async getDailyStep(userId: string, date: string): Promise<CloudDailyStep | null> {
    this.checkInit();
    
    try {
      const key = `daily_step_${userId}_${date}`;
      const recordStr = await this.preferencesStore!.get(key, '') as string;
      
      if (recordStr) {
        const recordData = JSON.parse(recordStr);
        const record = new CloudDailyStep();
        Object.assign(record, recordData);
        return record;
      }
      
      return null;
    } catch (error) {
      console.error('[CloudDBService] 获取每日步数失败:', JSON.stringify(error));
      return null;
    }
  }

  /**
   * 获取最近N天的步数记录
   */
  async getRecentDailySteps(userId: string, days: number): Promise<CloudDailyStep[]> {
    this.checkInit();
    
    const records: CloudDailyStep[] = [];
    const today = new Date();
    
    for (let i = 0; i < days; i++) {
      const date = new Date(today);
      date.setDate(today.getDate() - i);
      const dateStr = date.toISOString().slice(0, 10);
      
      const record = await this.getDailyStep(userId, dateStr);
      if (record) {
        records.push(record);
      }
    }
    
    return records.reverse(); // 从旧到新排序
  }

  // ==================== 运动记录相关操作 ====================

  /**
   * 保存运动记录
   */
  async saveSportRecord(record: CloudSportRecord): Promise<void> {
    this.checkInit();
    
    try {
      record.recordId = record.recordId || generateId('sport_');
      record.createdAt = new Date();
      
      const key = `sport_${record.recordId}`;
      await this.preferencesStore!.put(key, JSON.stringify(record));
      
      // 更新用户的运动记录列表
      const listKey = `sport_list_${record.userId}`;
      const listStr = await this.preferencesStore!.get(listKey, '[]') as string;
      const list = JSON.parse(listStr) as string[];
      list.unshift(record.recordId);
      
      await this.preferencesStore!.put(listKey, JSON.stringify(list));
      await this.preferencesStore!.flush();
      
      console.info('[CloudDBService] 运动记录保存成功');
    } catch (error) {
      console.error('[CloudDBService] 保存运动记录失败:', JSON.stringify(error));
      throw error;
    }
  }

  /**
   * 获取用户的运动记录列表
   */
  async getSportRecords(userId: string, limit: number = 100): Promise<CloudSportRecord[]> {
    this.checkInit();
    
    try {
      const listKey = `sport_list_${userId}`;
      const listStr = await this.preferencesStore!.get(listKey, '[]') as string;
      const recordIds = JSON.parse(listStr) as string[];
      
      const records: CloudSportRecord[] = [];
      
      for (let i = 0; i < Math.min(recordIds.length, limit); i++) {
        const key = `sport_${recordIds[i]}`;
        const recordStr = await this.preferencesStore!.get(key, '') as string;
        
        if (recordStr) {
          const recordData = JSON.parse(recordStr);
          const record = new CloudSportRecord();
          Object.assign(record, recordData);
          records.push(record);
        }
      }
      
      return records;
    } catch (error) {
      console.error('[CloudDBService] 获取运动记录失败:', JSON.stringify(error));
      return [];
    }
  }

  // ==================== 身体数据记录相关操作 ====================

  /**
   * 保存身体数据记录
   */
  async saveBodyRecord(record: CloudBodyRecord): Promise<void> {
    this.checkInit();
    
    try {
      record.recordId = record.recordId || generateId('body_');
      record.createdAt = new Date();
      
      const key = `body_${record.recordId}`;
      await this.preferencesStore!.put(key, JSON.stringify(record));
      
      // 更新用户的身体记录列表
      const listKey = `body_list_${record.userId}`;
      const listStr = await this.preferencesStore!.get(listKey, '[]') as string;
      const list = JSON.parse(listStr) as string[];
      list.unshift(record.recordId);
      
      // 只保留最近100条
      if (list.length > 100) {
        list.splice(100);
      }
      
      await this.preferencesStore!.put(listKey, JSON.stringify(list));
      await this.preferencesStore!.flush();
      
      console.info('[CloudDBService] 身体数据保存成功');
    } catch (error) {
      console.error('[CloudDBService] 保存身体数据失败:', JSON.stringify(error));
      throw error;
    }
  }

  /**
   * 获取用户的身体数据记录
   */
  async getBodyRecords(userId: string, limit: number = 50): Promise<CloudBodyRecord[]> {
    this.checkInit();
    
    try {
      const listKey = `body_list_${userId}`;
      const listStr = await this.preferencesStore!.get(listKey, '[]') as string;
      const recordIds = JSON.parse(listStr) as string[];
      
      const records: CloudBodyRecord[] = [];
      
      for (let i = 0; i < Math.min(recordIds.length, limit); i++) {
        const key = `body_${recordIds[i]}`;
        const recordStr = await this.preferencesStore!.get(key, '') as string;
        
        if (recordStr) {
          const recordData = JSON.parse(recordStr);
          const record = new CloudBodyRecord();
          Object.assign(record, recordData);
          records.push(record);
        }
      }
      
      return records;
    } catch (error) {
      console.error('[CloudDBService] 获取身体数据失败:', JSON.stringify(error));
      return [];
    }
  }

  // ==================== 任务记录相关操作 ====================

  /**
   * 保存任务记录
   */
  async saveTaskRecord(record: CloudTaskRecord): Promise<void> {
    this.checkInit();
    
    try {
      const key = `task_${record.userId}_${record.taskId}`;
      record.taskRecordId = record.taskRecordId || generateId('task_');
      record.createdAt = new Date();
      
      await this.preferencesStore!.put(key, JSON.stringify(record));
      await this.preferencesStore!.flush();
    } catch (error) {
      console.error('[CloudDBService] 保存任务记录失败:', JSON.stringify(error));
      throw error;
    }
  }

  /**
   * 获取用户的任务记录
   */
  async getTaskRecord(userId: string, taskId: number): Promise<CloudTaskRecord | null> {
    this.checkInit();
    
    try {
      const key = `task_${userId}_${taskId}`;
      const recordStr = await this.preferencesStore!.get(key, '') as string;
      
      if (recordStr) {
        const recordData = JSON.parse(recordStr);
        const record = new CloudTaskRecord();
        Object.assign(record, recordData);
        return record;
      }
      
      return null;
    } catch (error) {
      console.error('[CloudDBService] 获取任务记录失败:', JSON.stringify(error));
      return null;
    }
  }

  // ==================== 金币流水相关操作 ====================

  /**
   * 添加金币流水记录
   */
  async addCoinHistory(history: CloudCoinHistory): Promise<void> {
    this.checkInit();
    
    try {
      history.coinId = history.coinId || generateId('coin_');
      history.createdAt = new Date();
      
      // 保存单条记录
      const key = `coin_${history.coinId}`;
      await this.preferencesStore!.put(key, JSON.stringify(history));
      
      // 更新用户的流水列表
      const listKey = `coin_list_${history.userId}`;
      const listStr = await this.preferencesStore!.get(listKey, '[]') as string;
      const list = JSON.parse(listStr) as string[];
      list.unshift(history.coinId);
      
      // 只保留最近100条
      if (list.length > 100) {
        list.splice(100);
      }
      
      await this.preferencesStore!.put(listKey, JSON.stringify(list));
      await this.preferencesStore!.flush();
      
      console.info('[CloudDBService] 金币流水记录成功');
    } catch (error) {
      console.error('[CloudDBService] 保存金币流水失败:', JSON.stringify(error));
      throw error;
    }
  }

  /**
   * 获取用户的金币流水
   */
  async getCoinHistory(userId: string, limit: number = 50): Promise<CloudCoinHistory[]> {
    this.checkInit();
    
    try {
      const listKey = `coin_list_${userId}`;
      const listStr = await this.preferencesStore!.get(listKey, '[]') as string;
      const coinIds = JSON.parse(listStr) as string[];
      
      const histories: CloudCoinHistory[] = [];
      
      for (let i = 0; i < Math.min(coinIds.length, limit); i++) {
        const key = `coin_${coinIds[i]}`;
        const historyStr = await this.preferencesStore!.get(key, '') as string;
        
        if (historyStr) {
          const historyData = JSON.parse(historyStr);
          const history = new CloudCoinHistory();
          Object.assign(history, historyData);
          histories.push(history);
        }
      }
      
      return histories;
    } catch (error) {
      console.error('[CloudDBService] 获取金币流水失败:', JSON.stringify(error));
      return [];
    }
  }

  // ==================== 签到记录相关操作 ====================

  /**
   * 保存签到记录
   */
  async saveSignRecord(record: CloudSignRecord): Promise<void> {
    this.checkInit();
    
    try {
      const key = `sign_${record.userId}_${record.date}`;
      record.signId = record.signId || generateId('sign_');
      record.createdAt = new Date();
      
      await this.preferencesStore!.put(key, JSON.stringify(record));
      await this.preferencesStore!.flush();
      
      console.info('[CloudDBService] 签到记录保存成功:', record.date);
    } catch (error) {
      console.error('[CloudDBService] 保存签到记录失败:', JSON.stringify(error));
      throw error;
    }
  }

  /**
   * 获取最近N天的签到记录
   */
  async getRecentSignRecords(userId: string, days: number): Promise<CloudSignRecord[]> {
    this.checkInit();
    
    const records: CloudSignRecord[] = [];
    const today = new Date();
    
    for (let i = 0; i < days; i++) {
      const date = new Date(today);
      date.setDate(today.getDate() - i);
      const dateStr = date.toISOString().slice(0, 10);
      
      const key = `sign_${userId}_${dateStr}`;
      const recordStr = await this.preferencesStore!.get(key, '') as string;
      
      if (recordStr) {
        const recordData = JSON.parse(recordStr);
        const record = new CloudSignRecord();
        Object.assign(record, recordData);
        records.push(record);
      }
    }
    
    return records.reverse(); // 从旧到新排序
  }

  /**
   * 检查今天是否已签到
   */
  async checkTodaySign(userId: string): Promise<boolean> {
    const today = new Date().toISOString().slice(0, 10);
    const key = `sign_${userId}_${today}`;
    const recordStr = await this.preferencesStore!.get(key, '') as string;
    
    if (recordStr) {
      const record = JSON.parse(recordStr) as CloudSignRecord;
      return record.completed;
    }
    
    return false;
  }
}







