import { router } from '@kit.ArkUI'
import { CommonTitleView } from '../view/CommonTitleView'
import AppDataManager, { DataCallback } from '../tools/AppDataManager'
import { SportModel } from '../appdata/Model'
import { DateUtils } from '../tools/DateUtils'
import { Log } from '../tools/Logger'
import { Utils } from '../tools/Utils'

interface CalendarDay {
  date: string
  day: number
  isCurrentMonth: boolean
  isToday: boolean
  sportCount: number
  sportTypes: number[]
}

@Entry
@Component
struct SportCalendarPage {
  @State currentYear: number = new Date().getFullYear()
  @State currentMonth: number = new Date().getMonth() + 1
  @State calendarDays: Array<CalendarDay> = []
  @State sportRecords: Array<SportModel> = []
  @State selectedDate: string = DateUtils.getYMD()
  @State selectedDayRecords: Array<SportModel> = []

  private sportCallback: DataCallback<SportModel> = {
    onDataResult: (type: number, result: SportModel[], isReturnFirstData: boolean): void => {
      this.sportRecords = result
      this.updateCalendarDays()
      this.updateSelectedDayRecords()
    }
  }

  onPageShow() {
    this.loadSportRecords()
  }

  private loadSportRecords() {
    // 加载所有运动记录
    AppDataManager.findSportByType(0, this.sportCallback, false)
  }

  private updateCalendarDays() {
    const days: Array<CalendarDay> = []
    const firstDay = new Date(this.currentYear, this.currentMonth - 1, 1)
    const lastDay = new Date(this.currentYear, this.currentMonth, 0)
    const today = new Date()
    const todayStr = DateUtils.getYMD()

    // 获取上个月的最后几天
    const prevMonth = new Date(this.currentYear, this.currentMonth - 2, 0)
    const prevMonthLastDay = prevMonth.getDate()
    const firstDayOfWeek = firstDay.getDay()

    // 添加上个月的日期
    for (let i = firstDayOfWeek - 1; i >= 0; i--) {
      const day = prevMonthLastDay - i
      const date = `${this.currentYear}-${String(this.currentMonth - 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`
      days.push({
        date: date,
        day: day,
        isCurrentMonth: false,
        isToday: date === todayStr,
        sportCount: this.getSportCountForDate(date),
        sportTypes: this.getSportTypesForDate(date)
      })
    }

    // 添加当前月的日期
    for (let day = 1; day <= lastDay.getDate(); day++) {
      const date = `${this.currentYear}-${String(this.currentMonth).padStart(2, '0')}-${String(day).padStart(2, '0')}`
      days.push({
        date: date,
        day: day,
        isCurrentMonth: true,
        isToday: date === todayStr,
        sportCount: this.getSportCountForDate(date),
        sportTypes: this.getSportTypesForDate(date)
      })
    }

    // 添加下个月的前几天
    const remainingDays = 42 - days.length // 6行 x 7天 = 42天
    for (let day = 1; day <= remainingDays; day++) {
      const date = `${this.currentYear}-${String(this.currentMonth + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`
      days.push({
        date: date,
        day: day,
        isCurrentMonth: false,
        isToday: date === todayStr,
        sportCount: this.getSportCountForDate(date),
        sportTypes: this.getSportTypesForDate(date)
      })
    }

    this.calendarDays = days
  }

  private getSportCountForDate(date: string): number {
    return this.sportRecords.filter(record => {
      const recordDate = new Date(record.start_time).toISOString().split('T')[0]
      return recordDate === date
    }).length
  }

  private getSportTypesForDate(date: string): number[] {
    return this.sportRecords
      .filter(record => {
        const recordDate = new Date(record.start_time).toISOString().split('T')[0]
        return recordDate === date
      })
      .map(record => record.type)
  }

  private updateSelectedDayRecords() {
    this.selectedDayRecords = this.sportRecords.filter(record => {
      const recordDate = new Date(record.start_time).toISOString().split('T')[0]
      return recordDate === this.selectedDate
    })
  }

  private onDayClick(day: CalendarDay) {
    if (day.isCurrentMonth) {
      this.selectedDate = day.date
      this.updateSelectedDayRecords()
    }
  }

  private onPrevMonth() {
    if (this.currentMonth === 1) {
      this.currentYear--
      this.currentMonth = 12
    } else {
      this.currentMonth--
    }
    this.updateCalendarDays()
  }

  private onNextMonth() {
    if (this.currentMonth === 12) {
      this.currentYear++
      this.currentMonth = 1
    } else {
      this.currentMonth++
    }
    this.updateCalendarDays()
  }

  private getMonthName(month: number): string {
    const months = ['一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '十二月']
    return months[month - 1]
  }

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '运动日历' },
        cancel: () => {
          router.back()
        }
      })

      Scroll() {
        Column() {
          // 日历头部
          Row() {
            Image($r('app.media.back_btn_dark'))
              .width(20)
              .height(20)
              .onClick(() => {
                this.onPrevMonth()
              })

            Text(`${this.currentYear}年${this.getMonthName(this.currentMonth)}`)
              .fontSize(18)
              .fontWeight(500)
              .fontColor('#333333')
              .layoutWeight(1)
              .textAlign(TextAlign.Center)

            Image($r('app.media.right_btn'))
              .width(20)
              .height(20)
              .onClick(() => {
                this.onNextMonth()
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ bottom: 8 })

          // 星期标题
          Row() {
            ForEach(['日', '一', '二', '三', '四', '五', '六'], (weekDay: string) => {
              Text(weekDay)
                .fontSize(14)
                .fontColor('#666666')
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .padding(8)
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ bottom: 1 })

          // 日历网格
          Grid() {
            ForEach(this.calendarDays, (day: CalendarDay, index: number) => {
              GridItem() {
                Column() {
                  Text(day.day.toString())
                    .fontSize(14)
                    .fontColor(day.isCurrentMonth ? (day.isToday ? '#FFFFFF' : '#333333') : '#CCCCCC')
                    .fontWeight(day.isToday ? 600 : 400)

                  if (day.sportCount > 0) {
                    Row() {
                      ForEach(day.sportTypes.slice(0, 3), (_type: number) => {
                        Text('•')
                          .fontSize(10)
                          .fontColor('#0cc291')
                          .margin({ right: 2 })
                      })
                    }
                    .margin({ top: 2 })
                  }
                }
                .width('100%')
                .height(50)
                .justifyContent(FlexAlign.Center)
                .backgroundColor(day.isToday ? '#0cc291' : 'transparent')
                .borderRadius(day.isToday ? 25 : 0)
                .onClick(() => {
                  this.onDayClick(day)
                })
              }
            })
          }
          .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
          .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr')
          .width('100%')
          .height(300)
          .backgroundColor('#FFFFFF')
          .margin({ bottom: 16 })

          // 选中日期的运动记录
          if (this.selectedDayRecords.length > 0) {
            Column() {
              Text(`${DateUtils.getYMDCH(new Date(this.selectedDate).getTime())} 的运动记录`)
                .fontSize(16)
                .fontWeight(500)
                .fontColor('#333333')
                .alignSelf(ItemAlign.Start)
                .margin({ bottom: 12 })

              ForEach(this.selectedDayRecords, (record: SportModel) => {
                Row() {
                  Image(Utils.getSportRecordIcon(record.type))
                    .width(40)
                    .height(40)
                    .margin({ right: 12 })

                  Column() {
                    Text(Utils.getSportRecordName(record.type))
                      .fontSize(16)
                      .fontWeight(500)
                      .fontColor('#333333')
                      .alignSelf(ItemAlign.Start)

                    Text(`${DateUtils.getHM(new Date(record.start_time).getTime())} - ${Math.floor(record.use_time / 60)}分钟`)
                      .fontSize(14)
                      .fontColor('#666666')
                      .alignSelf(ItemAlign.Start)
                      .margin({ top: 4 })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  Column() {
                    Text(`${Math.round(parseFloat(Utils.getDistanceByStep(record.steps)) * 100) / 100}公里`)
                      .fontSize(14)
                      .fontColor('#0cc291')
                      .alignSelf(ItemAlign.End)

                    Text(`${Math.round(parseFloat(Utils.getDistanceByStep(record.steps)) * 50)}千卡`)
                      .fontSize(12)
                      .fontColor('#666666')
                      .alignSelf(ItemAlign.End)
                      .margin({ top: 2 })
                  }
                }
                .width('100%')
                .padding(16)
                .backgroundColor('#F8F8F8')
                .borderRadius(8)
                .margin({ bottom: 8 })
              })
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .margin({ bottom: 16 })
          } else {
            Column() {
              Text('该日期没有运动记录')
                .fontSize(14)
                .fontColor('#999999')
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .padding(40)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .margin({ bottom: 16 })
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
