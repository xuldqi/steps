import preferencesUtil from './DataPreUtils'

export interface TargetValue {
  step_target: number
  calorie_target: number
  exercise_time_target: number
  activity_count_target: number
  distance_target: number
  weight_target: number
}

export class TargetManager {
  private static instance: TargetManager
  private targets: TargetValue = {
    step_target: 5000,
    calorie_target: 300,
    exercise_time_target: 25,
    activity_count_target: 12,
    distance_target: 3000,
    weight_target: 50
  }
  
  private listeners: Array<(targets: TargetValue) => void> = []

  static getInstance(): TargetManager {
    if (!TargetManager.instance) {
      TargetManager.instance = new TargetManager()
    }
    return TargetManager.instance
  }

  async loadTargets(): Promise<void> {
    try {
      this.targets.step_target = await preferencesUtil.getPreferenceValue('steps_ohos', 'step_target', 5000) as number
      this.targets.calorie_target = await preferencesUtil.getPreferenceValue('steps_ohos', 'calorie_target', 300) as number
      this.targets.exercise_time_target = await preferencesUtil.getPreferenceValue('steps_ohos', 'exercise_time_target', 25) as number
      this.targets.activity_count_target = await preferencesUtil.getPreferenceValue('steps_ohos', 'activity_count_target', 12) as number
      this.targets.distance_target = await preferencesUtil.getPreferenceValue('steps_ohos', 'distance_target', 3000) as number
      this.targets.weight_target = await preferencesUtil.getPreferenceValue('steps_ohos', 'weight_target', 50) as number
    } catch (error) {
      console.error('加载目标值失败:', error)
    }
  }

  async updateTarget(key: keyof TargetValue, value: number): Promise<void> {
    try {
      this.targets[key] = value
      await preferencesUtil.putPreferenceValue('steps_ohos', key, value)
      this.notifyListeners()
    } catch (error) {
      console.error('更新目标值失败:', error)
    }
  }

  async updateTargets(targets: Partial<TargetValue>): Promise<void> {
    try {
      for (const [key, value] of Object.entries(targets)) {
        if (value !== undefined) {
          this.targets[key as keyof TargetValue] = value
          await preferencesUtil.putPreferenceValue('steps_ohos', key, value)
        }
      }
      this.notifyListeners()
    } catch (error) {
      console.error('批量更新目标值失败:', error)
    }
  }

  getTarget(key: keyof TargetValue): number {
    return this.targets[key]
  }

  getAllTargets(): TargetValue {
    return { ...this.targets }
  }

  addListener(listener: (targets: TargetValue) => void): void {
    this.listeners.push(listener)
  }

  removeListener(listener: (targets: TargetValue) => void): void {
    const index = this.listeners.indexOf(listener)
    if (index > -1) {
      this.listeners.splice(index, 1)
    }
  }

  private notifyListeners(): void {
    this.listeners.forEach(listener => {
      try {
        listener(this.getAllTargets())
      } catch (error) {
        console.error('通知监听器失败:', error)
      }
    })
  }
}

export default TargetManager.getInstance()
