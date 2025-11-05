/**
 * 用户数据统一管理服务
 * 统一管理用户的身体数据（身高、体重、年龄、性别等）
 * 确保数据修改后所有页面能同步更新
 */
import preferencesUtil from '../tools/DataPreUtils'
import { Log } from '../tools/Logger'

export interface UserMetrics {
  height: number        // 身高（厘米）
  weight: number        // 体重（公斤）
  age: number           // 年龄（岁）
  gender: string        // 性别：'male' | 'female'
  targetWeight?: number // 目标体重（公斤）
}

type MetricsChangeListener = (metrics: UserMetrics) => void

export class UserDataManager {
  private static instance: UserDataManager
  private listeners: Set<MetricsChangeListener> = new Set()
  private cachedMetrics: UserMetrics | null = null

  private constructor() {}

  static getInstance(): UserDataManager {
    if (!UserDataManager.instance) {
      UserDataManager.instance = new UserDataManager()
    }
    return UserDataManager.instance
  }

  /**
   * 订阅数据变化
   */
  subscribe(listener: MetricsChangeListener): () => void {
    this.listeners.add(listener)
    // 立即通知当前数据
    if (this.cachedMetrics) {
      listener(this.cachedMetrics)
    }
    return () => this.listeners.delete(listener)
  }

  /**
   * 通知所有监听者数据已更新
   */
  private emit(metrics: UserMetrics): void {
    this.cachedMetrics = metrics
    this.listeners.forEach(listener => {
      try {
        listener(metrics)
      } catch (error) {
        Log.e('[UserDataManager] 通知监听者失败: ' + JSON.stringify(error))
      }
    })
  }

  /**
   * 加载用户身体数据
   */
  async loadMetrics(): Promise<UserMetrics> {
    // preferences 应该在 EntryAbility 中初始化，这里只检查是否已加载
    if (!preferencesUtil.preferencesMap.has('steps_ohos')) {
      Log.i('[UserDataManager] preferences尚未初始化，可能影响数据读取')
    }

    const height = await preferencesUtil.getPreferenceValue('steps_ohos', 'height', 0) as number
    const weight = await preferencesUtil.getPreferenceValue('steps_ohos', 'weight', 0) as number
    const age = await preferencesUtil.getPreferenceValue('steps_ohos', 'age', 0) as number
    const gender = await preferencesUtil.getPreferenceValue('steps_ohos', 'gender', 'male') as string
    const targetWeight = await preferencesUtil.getPreferenceValue('steps_ohos', 'weight_target', 0) as number

    const metrics: UserMetrics = {
      height,
      weight,
      age,
      gender,
      targetWeight: targetWeight > 0 ? targetWeight : undefined
    }

    this.cachedMetrics = metrics
    return metrics
  }

  private async updateAndEmit(patch: Partial<UserMetrics>): Promise<void> {
    const metrics = await this.loadMetrics()
    const nextMetrics: UserMetrics = {
      height: patch.height ?? metrics.height ?? 0,
      weight: patch.weight ?? metrics.weight ?? 0,
      age: patch.age ?? metrics.age ?? 0,
      gender: patch.gender ?? metrics.gender ?? 'male',
      targetWeight: patch.targetWeight ?? metrics.targetWeight
    }
    Log.i('[UserDataManager] updateAndEmit patch=' + JSON.stringify(patch) + ', merged=' + JSON.stringify(nextMetrics))
    this.cachedMetrics = nextMetrics
    this.emit(nextMetrics)
  }

  /**
   * 更新身高
   */
  async updateHeight(height: number): Promise<void> {
    await preferencesUtil.putPreferenceValue('steps_ohos', 'height', height)
    await this.updateAndEmit({ height })
  }

  /**
   * 更新体重
   */
  async updateWeight(weight: number): Promise<void> {
    await preferencesUtil.putPreferenceValue('steps_ohos', 'weight', weight)
    await this.updateAndEmit({ weight })
  }

  /**
   * 更新年龄
   */
  async updateAge(age: number): Promise<void> {
    await preferencesUtil.putPreferenceValue('steps_ohos', 'age', age)
    await this.updateAndEmit({ age })
  }

  /**
   * 更新性别
   */
  async updateGender(gender: string): Promise<void> {
    await preferencesUtil.putPreferenceValue('steps_ohos', 'gender', gender)
    await this.updateAndEmit({ gender })
  }

  /**
   * 更新目标体重
   */
  async updateTargetWeight(targetWeight: number): Promise<void> {
    await preferencesUtil.putPreferenceValue('steps_ohos', 'weight_target', targetWeight)
    await preferencesUtil.putPreferenceValue('steps_ohos', 'weight_target_update_time', Date.now())
    await this.updateAndEmit({ targetWeight })
  }

  /**
   * 批量更新数据
   */
  async updateMetrics(updates: Partial<UserMetrics>): Promise<void> {
    const updatesList: Array<Promise<void>> = []

    if (updates.height !== undefined) {
      updatesList.push(preferencesUtil.putPreferenceValue('steps_ohos', 'height', updates.height))
    }
    if (updates.weight !== undefined) {
      updatesList.push(preferencesUtil.putPreferenceValue('steps_ohos', 'weight', updates.weight))
    }
    if (updates.age !== undefined) {
      updatesList.push(preferencesUtil.putPreferenceValue('steps_ohos', 'age', updates.age))
    }
    if (updates.gender !== undefined) {
      updatesList.push(preferencesUtil.putPreferenceValue('steps_ohos', 'gender', updates.gender))
    }
    if (updates.targetWeight !== undefined) {
      updatesList.push(preferencesUtil.putPreferenceValue('steps_ohos', 'weight_target', updates.targetWeight))
      updatesList.push(preferencesUtil.putPreferenceValue('steps_ohos', 'weight_target_update_time', Date.now()))
    }

    await Promise.all(updatesList)
    await this.updateAndEmit(updates)
  }

  /**
   * 刷新数据并通知所有监听者
   */
  async refreshMetrics(): Promise<void> {
    const metrics = await this.loadMetrics()
    this.emit(metrics)
    Log.i('[UserDataManager] 数据已刷新: ' + JSON.stringify(metrics))
  }

  /**
   * 计算BMI
   */
  calculateBMI(height: number, weight: number): { value: number; status: string } {
    if (height <= 0 || weight <= 0) {
      return { value: 0, status: '--' }
    }

    const heightInMeters = height / 100
    const bmiValue = weight / (heightInMeters * heightInMeters)
    const value = parseFloat(bmiValue.toFixed(1))

    let status: string
    if (value < 18.5) {
      status = '过轻'
    } else if (value < 24) {
      status = '正常'
    } else if (value < 28) {
      status = '偏胖'
    } else {
      status = '肥胖'
    }

    return { value, status }
  }

  /**
   * 计算基础代谢率
   */
  calculateBMR(height: number, weight: number, age: number, gender: string): number {
    if (height <= 0 || weight <= 0 || age <= 0) {
      return 0
    }

    let baseValue = 10 * weight + 6.25 * height - 5 * age
    baseValue += gender === 'male' ? 5 : -161
    return Math.round(baseValue)
  }
}

// 导出单例
export const userDataManager = UserDataManager.getInstance()
