// 数据管理器（Android 版本，先用假数据，后续可切换为 Room/AGC）
import { SportModel, PerStepModel, BodyRecordModel } from '../appdata/Model'
import { DataCallback } from './DataCallback'
import { DateUtils } from './DateUtils'

class AppDataManager {
  private static instance: AppDataManager
  // 假数据存储（后续替换为真实数据库）
  private mockSportData: Array<SportModel> = []

  private constructor() {
    this.initMockData()
  }

  static getInstance(): AppDataManager {
    if (!AppDataManager.instance) {
      AppDataManager.instance = new AppDataManager()
    }
    return AppDataManager.instance
  }

  /**
   * 初始化假数据（用于测试）
   */
  private initMockData() {
    const now = Date.now()
    const today = DateUtils.getYMD()
    
    // 生成最近7天的假数据
    for (let i = 0; i < 7; i++) {
      const date = new Date()
      date.setDate(date.getDate() - i)
      const dateStr = DateUtils.getYMD_(i)
      
      // 每天生成1-3条运动记录
      const recordCount = Math.floor(Math.random() * 3) + 1
      for (let j = 0; j < recordCount; j++) {
        const type = Math.floor(Math.random() * 5) + 1 // 1-5
        const startTime = date.getTime() + j * 3600000 // 每小时一条
        const useTime = (Math.floor(Math.random() * 60) + 15) * 60 // 15-75分钟
        const steps = Math.floor(Math.random() * 5000) + 1000 // 1000-6000步
        const cal = (Math.floor(Math.random() * 200) + 50).toString() // 50-250千卡

        this.mockSportData.push({
          id: this.mockSportData.length + 1,
          type: type,
          sub_type: 0,
          start_time: startTime,
          use_time: useTime,
          steps: steps,
          cal: cal
        })
      }
    }
  }

  /**
   * 根据运动类型查询数据
   * @param type 运动类型：0-全部, 1-室内跑, 2-室外跑, 3-健走, 4-徒步, 5-登山
   * @param callback 回调函数
   * @param isReturnFirstData 是否只返回第一条数据
   */
  findSportByType(type: number, callback: DataCallback<SportModel>, isReturnFirstData: boolean) {
    // 模拟异步查询
    setTimeout(() => {
      let results: Array<SportModel> = []
      
      if (type === 0) {
        // 查询所有类型
        results = [...this.mockSportData]
      } else {
        // 查询指定类型
        results = this.mockSportData.filter(item => item.type === type)
      }
      
      // 按时间倒序排序
      results.sort((a, b) => b.start_time - a.start_time)
      
      // 如果只需要第一条，只返回第一条
      if (isReturnFirstData && results.length > 0) {
        results = [results[0]]
      }
      
      callback.onDataResult(type, results, isReturnFirstData)
    }, 100) // 模拟100ms延迟
  }

  /**
   * 获取指定日期范围内的数据
   */
  getSportDataByDateRange(startDate: string, endDate: string, type: number = 0): Array<SportModel> {
    const start = new Date(startDate).getTime()
    const end = new Date(endDate).getTime() + 86400000 - 1 // 包含当天结束时间
    
    let results = this.mockSportData.filter(item => {
      const matchType = type === 0 || item.type === type
      const matchDate = item.start_time >= start && item.start_time <= end
      return matchType && matchDate
    })
    
    return results.sort((a, b) => b.start_time - a.start_time)
  }

  // 主卡片相关方法
  getMainCardSubStr(type: number): string {
    switch (type) {
      case 1:
        return '今日'
      case 2:
        return '今日'
      case 3:
        return '当前'
      case 4:
        return '秒表计时'
      case 5:
        return '身高'
      case 6:
        return '当前'
    }
    return '运动记录'
  }

  getMainCardSubData(type: number): string {
    switch (type) {
      case 1:
        return '1.5公里'
      case 2:
        return '70千卡'
      case 3:
        return '5公里'
      case 4:
        return '倒计时'
      case 5:
        return '围度'
      case 6:
        return '70公斤'
    }
    return ''
  }

  getMainCardSubDataSize(type: number): number {
    switch (type) {
      case 1:
      case 2:
      case 3:
      case 6:
        return 16
      case 4:
      case 5:
        return 13
    }
    return 15
  }

  getMainCardSubDataWeight(type: number): number {
    switch (type) {
      case 1:
      case 2:
      case 3:
      case 6:
        return 500
      case 4:
      case 5:
        return 300
    }
    return 300
  }

  hasMainCardLastData(type: number): boolean {
    switch (type) {
      case 1:
      case 2:
      case 3:
      case 6:
        return true
      case 4:
      case 5:
        return false
    }
    return true
  }

  getMainCardLastTitle(type: number): string {
    switch (type) {
      case 1:
      case 2:
        return '昨天'
      case 3:
      case 6:
        return '上次'
      case 4:
      case 5:
        return ''
    }
    return ''
  }

  getMainCardLastData(type: number): string {
    switch (type) {
      case 1:
      case 2:
      case 3:
      case 6:
        return '无数据'
      case 4:
      case 5:
        return ''
    }
    return ''
  }

  /**
   * 获取指定日期范围内的步数数据
   */
  getStepPerDayWeekList3(dates: string[], callback: DataCallback<PerStepModel>, isReturnFirstData: boolean) {
    // 模拟异步数据加载
    setTimeout(() => {
      const mockPerStepData: PerStepModel[] = dates.map((date, index) => ({
        id: index,
        state: 0,
        date: date,
        steps: Math.floor(Math.random() * 8000) + 1000, // 1000-9000 steps
        backup: '',
        time: new Date(date).getTime(),
      }));
      callback.onDataResult(0, mockPerStepData, isReturnFirstData);
    }, 100);
  }

  /**
   * 根据类型查找身体记录数据
   */
  findBodyRecordByType(type: number, callback: DataCallback<BodyRecordModel>, isReturnFirstData: boolean) {
    // 模拟异步数据加载
    setTimeout(() => {
      const mockBodyRecords: BodyRecordModel[] = []
      // 生成最近30天的模拟体重数据
      for (let i = 0; i < 30; i++) {
        const date = new Date()
        date.setDate(date.getDate() - i)
        mockBodyRecords.push({
          id: i,
          time: date.getTime(),
          type: type,
          data: (60 + Math.random() * 20).toFixed(1), // 60-80公斤
          unit: '公斤'
        })
      }
      callback.onDataResult(type, mockBodyRecords, isReturnFirstData)
    }, 100)
  }

  // 常量定义
  static readonly TYPE_WEIGHT = 1
  static readonly TYPE_HEIGHT = 2
  static readonly TYPE_XW = 3
  static readonly TYPE_YW = 4
  static readonly TYPE_TW = 5
  static readonly TYPE_SBW = 6
  static readonly TYPE_DTW = 7
  static readonly TYPE_XTW = 8
}

// 导出单例
export default AppDataManager.getInstance()

