// 日期工具类（简化版，用于 Android 版本）

export class DateUtils {
  /**
   * 获取当前日期字符串 yyyy-MM-dd
   */
  static getYMD(): string {
    const now = new Date()
    const year = now.getFullYear()
    const month = String(now.getMonth() + 1).padStart(2, '0')
    const day = String(now.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  /**
   * 时间戳转日期字符串 yyyy-MM-dd
   */
  static timeToDateNoYM2(timestamp: number): string {
    const date = new Date(timestamp)
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  /**
   * 获取星期几（周一、周二...）
   */
  static getWeek(dateStr: string): string {
    const date = new Date(dateStr)
    const day = date.getDay()
    const weekDays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    return weekDays[day]
  }

  /**
   * 获取日期范围字符串（用于显示）
   */
  static getYMDCH(offsetDays: number): string {
    const date = new Date()
    date.setDate(date.getDate() - offsetDays)
    const year = date.getFullYear()
    const month = date.getMonth() + 1
    const day = date.getDate()
    return `${year}年${month}月${day}日`
  }

  /**
   * 获取日期字符串 yyyy-MM-dd（用于查询）
   */
  static getYMD_(offsetDays: number): string {
    const date = new Date()
    date.setDate(date.getDate() - offsetDays)
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  /**
   * 时间戳转日期字符串 yyyy年MM月dd日
   */
  static timeToDate(timestamp: number): string {
    const date = new Date(timestamp)
    const year = date.getFullYear()
    const month = date.getMonth() + 1
    const day = date.getDate()
    return `${year}年${month}月${day}日`
  }

  /**
   * 时间戳转日期字符串 MM月dd日
   */
  static timeToDateNoYM(timestamp: number): string {
    const date = new Date(timestamp)
    const month = date.getMonth() + 1
    const day = date.getDate()
    const hour = String(date.getHours()).padStart(2, '0')
    const minute = String(date.getMinutes()).padStart(2, '0')
    return `${month}月${day}日 ${hour}:${minute}`
  }
}

