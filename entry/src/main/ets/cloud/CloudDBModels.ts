/**
 * 云数据库模型定义
 * 对应华为云数据库的对象类型
 * 适配StepSportszc项目的数据结构
 */

/**
 * 用户信息表
 */
export class CloudUser {
  userId: string = ''; // 主键，华为账号 unionID
  nickname: string = '';
  avatar: string = '';
  inviteCode: string = '';
  balance: number = 0; // 金币余额
  totalCoins: number = 0; // 累计金币
  stepTarget: number = 10000; // 步数目标
  weightTarget: number = 65; // 体重目标
  persistedDays: number = 0; // 坚持天数
  consecutiveSignDays: number = 0; // 连续签到天数
  createdAt: Date = new Date();
  updatedAt: Date = new Date();

  constructor() {}
}

/**
 * 每日步数记录表（对应 PerStepModel）
 */
export class CloudDailyStep {
  recordId: string = ''; // 主键
  userId: string = ''; // 用户ID
  date: string = ''; // 日期 YYYY-MM-DD
  steps: number = 0; // 步数
  calories: number = 0; // 卡路里
  distance: number = 0; // 距离（米）
  createdAt: Date = new Date();

  constructor() {}
}

/**
 * 运动记录表（对应 SportModel）
 */
export class CloudSportRecord {
  recordId: string = ''; // 主键
  userId: string = ''; // 用户ID
  sportType: string = ''; // 运动类型：'跑步', '骑行', '散步', '健身'
  beginTime: string = ''; // 开始时间
  endTime: string = ''; // 结束时间
  duration: number = 0; // 持续时间（秒）
  steps: number = 0; // 步数
  distance: number = 0; // 距离（米）
  calories: number = 0; // 卡路里
  createdAt: Date = new Date();

  constructor() {}
}

/**
 * 身体数据记录表（对应 BodyRecordModel）
 */
export class CloudBodyRecord {
  recordId: string = ''; // 主键
  userId: string = ''; // 用户ID
  recordTime: string = ''; // 记录时间
  height: number = 0; // 身高（cm）
  weight: number = 0; // 体重（kg）
  bust: number = 0; // 胸围（cm）
  waistline: number = 0; // 腰围（cm）
  hipline: number = 0; // 臀围（cm）
  systolicPressure: number = 0; // 收缩压
  diastolicPressure: number = 0; // 舒张压
  heartRate: number = 0; // 心率
  createdAt: Date = new Date();

  constructor() {}
}

/**
 * 签到记录表
 */
export class CloudSignRecord {
  signId: string = ''; // 主键
  userId: string = ''; // 用户ID
  date: string = ''; // 日期 YYYY-MM-DD
  reward: number = 0;
  completed: boolean = false;
  createdAt: Date = new Date();

  constructor() {}
}

/**
 * 金币流水表
 */
export class CloudCoinHistory {
  coinId: string = ''; // 主键
  userId: string = ''; // 用户ID
  title: string = '';
  amount: number = 0;
  type: string = 'income'; // income/expense
  createdAt: Date = new Date();

  constructor() {}
}

/**
 * 任务记录表
 */
export class CloudTaskRecord {
  taskRecordId: string = ''; // 主键
  userId: string = ''; // 用户ID
  taskId: number = 0;
  progress: number = 0;
  status: string = 'locked'; // locked/available/completed/claimed
  claimedAt?: Date;
  createdAt: Date = new Date();

  constructor() {}
}

/**
 * 云数据库表名常量
 */
export const CloudTableNames = {
  USER: 'User',
  DAILY_STEP: 'DailyStep',
  SPORT_RECORD: 'SportRecord',
  BODY_RECORD: 'BodyRecord',
  SIGN_RECORD: 'SignRecord',
  COIN_HISTORY: 'CoinHistory',
  TASK_RECORD: 'TaskRecord'
} as const;

/**
 * 生成唯一ID
 */
export function generateId(prefix: string = ''): string {
  const timestamp = Date.now();
  const random = Math.floor(Math.random() * 10000);
  return `${prefix}${timestamp}${random}`;
}

/**
 * 生成邀请码
 */
export function generateInviteCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = 'WB';
  for (let i = 0; i < 6; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}







