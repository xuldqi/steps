import { CommonTitleView } from '../view/CommonTitleView'
import { BarChartView } from '../view/BarChartView'
import appDataManager from '../tools/AppDataManager'
import { DataCallback } from '../tools/DataCallback'
import { SportModel } from '../appdata/Model'
import { DateUtils } from '../tools/DateUtils'

@Entry
@Component
struct ExerciseTimePage {
  @State curOffset: number = 0
  @State top_week: string = '本周'
  @State allMinutes: number = 0
  @State avgMinutes: number = 0
  @State targetMinutes: number = 25
  @State todayMinutes: number = 0
  // 图表数据
  @State chartLabels: Array<string> = ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
  @State chartData: Array<number> = [0, 0, 0, 0, 0, 0, 0]
  // 运动数据
  @State exerciseData: Array<SportModel> = []
  private dates: Array<string> = []

  private exerciseCallback: DataCallback<SportModel> = {
    onDataResult: (type: number, result: SportModel[], isReturnFirstData: boolean): void => {
      this.exerciseData = result
      this.calculateExerciseStats()
    }
  }

  onPageShow(): void {
    this.showWeekExerciseRecord(this.curOffset)
  }

  private showWeekExerciseRecord(i: number) {
    this.top_week = DateUtils.getYMDCH(6 + 7 * i) + ' - ' + DateUtils.getYMDCH(7 * i)
    this.dates.length = 0
    this.dates.push(DateUtils.getYMD_(6 + 7 * i))
    this.dates.push(DateUtils.getYMD_(5 + 7 * i))
    this.dates.push(DateUtils.getYMD_(4 + 7 * i))
    this.dates.push(DateUtils.getYMD_(3 + 7 * i))
    this.dates.push(DateUtils.getYMD_(2 + 7 * i))
    this.dates.push(DateUtils.getYMD_(1 + 7 * i))
    this.dates.push(DateUtils.getYMD_(7 * i))
    
    // 加载所有运动类型的数据
    this.loadAllSportTypes()
  }

  private loadAllSportTypes() {
    // 分别查询每种运动类型
    appDataManager.findSportByType(1, this.exerciseCallback, false) // 室内跑
    appDataManager.findSportByType(2, this.exerciseCallback, false) // 室外跑
    appDataManager.findSportByType(3, this.exerciseCallback, false) // 健走
    appDataManager.findSportByType(4, this.exerciseCallback, false) // 徒步
    appDataManager.findSportByType(5, this.exerciseCallback, false) // 登山
  }

  private calculateExerciseStats() {
    // 按日期聚合数据
    const dailyMinutes: Map<string, number> = new Map()
    for (const item of this.exerciseData) {
      const itemDate = DateUtils.timeToDateNoYM2(item.start_time)
      const minutes = Math.floor(item.use_time / 60)
      const existing = dailyMinutes.get(itemDate) ?? 0
      dailyMinutes.set(itemDate, existing + minutes)
    }

    // 计算总时长和平均时长
    this.allMinutes = 0
    for (const minutes of dailyMinutes.values()) {
      this.allMinutes = this.allMinutes + minutes
    }
    this.avgMinutes = this.allMinutes / 7

    // 计算今日锻炼时长
    const todayDate = DateUtils.getYMD()
    this.todayMinutes = dailyMinutes.get(todayDate) ?? 0

    // 更新图表数据
    let mm_datas = new Array<number>()
    let mm_dates = new Array<string>()
    for (let i = 0; i < this.dates.length; i++) {
      mm_dates.push(DateUtils.getWeek(this.dates[i]))
      mm_datas.push(dailyMinutes.get(this.dates[i]) ?? 0)
    }
    this.chartLabels = mm_dates
    this.chartData = mm_datas
  }

  build() {
    Column() {
      CommonTitleView({ data1: { str1: '锻炼时长统计' }, cancel: () => router.back(), useSafeTop: true })

      Scroll() {
        Column() {
          // 日期范围选择器
          Row() {
            Image($r('app.media.back_btn_dark'))
              .width(20)
              .height(20)
              .margin(5)
              .onClick(() => {
                this.curOffset = this.curOffset + 1
                this.showWeekExerciseRecord(this.curOffset)
              })
            Text(this.top_week)
              .fontSize(14)
            Image($r('app.media.right_btn'))
              .width(20)
              .height(20)
              .margin(5)
              .onClick(() => {
                this.curOffset = this.curOffset - 1
                this.showWeekExerciseRecord(this.curOffset)
              })
          }
          .margin(7)

          // 柱状图白色卡片
          Column() {
            BarChartView({
              xAxisData: this.chartLabels,
              seriesData: this.chartData,
              barColor: '#FFB950',
              title: '分钟',
              titlePosition: 'right'
            })
            .height(200)
          }
          .width('92%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .padding(16)
          .margin({ top: 8 })

          // 目标进度白色卡片
          Column() {
            Text(`今日 ${this.todayMinutes}/${this.targetMinutes} 分钟`)
              .fontSize(16)
              .fontColor('#333')
          }
          .width('92%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .padding(16)
          .margin({ top: 12 })

          // 汇总信息白色卡片
          Column() {
            Row() {
              Column() {
                Text('总时长')
                  .fontSize(12)
                  .fontColor('#666666')
                Text(`${this.allMinutes}`)
                  .fontWeight(600)
                  .fontSize(30)
                  .margin({ top: 6 })
                Text('分钟')
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .layoutWeight(1)

              Column() {
                Text('平均每日时长')
                  .fontSize(12)
                  .fontColor('#666666')
                Text(`${this.avgMinutes.toFixed(0)}`)
                  .fontWeight(600)
                  .fontSize(30)
                  .margin({ top: 6 })
                Text('分钟')
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .layoutWeight(1)
            }
          }
          .width('92%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .padding(16)
          .margin({ top: 10, bottom: 16 })
        }
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
