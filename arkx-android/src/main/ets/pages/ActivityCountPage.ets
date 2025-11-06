import { CommonTitleView } from '../view/CommonTitleView'
import { BarChartView } from '../view/BarChartView'
import appDataManager from '../tools/AppDataManager'
import { DataCallback } from '../tools/DataCallback'
import { SportModel } from '../appdata/Model'
import { DateUtils } from '../tools/DateUtils'

@Entry
@Component
struct ActivityCountPage {
  @State curOffset: number = 0
  @State top_week: string = '本周'
  @State reward_str: string = '本周活动达标天数0天'
  @State allActivities: number = 0
  @State argActivities: number = 0
  @State targetActivities: number = 12
  @State currentActivities: number = 0
  // 图表数据
  @State chartLabels: Array<string> = ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
  @State chartData: Array<number> = [0, 0, 0, 0, 0, 0, 0]
  // 运动数据
  @State activityData: Array<SportModel> = []
  private dates: Array<string> = []

  private activityCallback: DataCallback<SportModel> = {
    onDataResult: (type: number, result: SportModel[], isReturnFirstData: boolean): void => {
      this.activityData = result
      this.calculateActivityStats()
    }
  }

  onPageShow(): void {
    this.showWeekActivityRecord(this.curOffset)
  }

  private showWeekActivityRecord(i: number) {
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
    appDataManager.findSportByType(1, this.activityCallback, false) // 室内跑
    appDataManager.findSportByType(2, this.activityCallback, false) // 室外跑
    appDataManager.findSportByType(3, this.activityCallback, false) // 健走
    appDataManager.findSportByType(4, this.activityCallback, false) // 徒步
    appDataManager.findSportByType(5, this.activityCallback, false) // 登山
  }

  private calculateActivityStats() {
    // 按日期聚合数据
    const dailyActivities: Map<string, number> = new Map()
    for (const item of this.activityData) {
      const itemDate = DateUtils.timeToDateNoYM2(item.start_time)
      const existing = dailyActivities.get(itemDate) ?? 0
      dailyActivities.set(itemDate, existing + 1)
    }

    // 计算总次数和平均次数
    this.allActivities = 0
    let rewardDays = 0
    for (const count of dailyActivities.values()) {
      this.allActivities = this.allActivities + count
      if (count >= this.targetActivities) {
        rewardDays = rewardDays + 1
      }
    }
    this.argActivities = this.allActivities / 7

    // 计算今日活动次数
    const todayDate = DateUtils.getYMD()
    this.currentActivities = dailyActivities.get(todayDate) ?? 0

    // 更新达标提示
    if (rewardDays > 0) {
      this.reward_str = "本周活动达标天数" + rewardDays + "天"
    } else {
      this.reward_str = "最近一周没有一天活动达标哦！"
    }

    // 更新图表数据
    let mm_datas = new Array<number>()
    let mm_dates = new Array<string>()
    for (let i = 0; i < this.dates.length; i++) {
      mm_dates.push(DateUtils.getWeek(this.dates[i]))
      mm_datas.push(dailyActivities.get(this.dates[i]) ?? 0)
    }
    this.chartLabels = mm_dates
    this.chartData = mm_datas
  }

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '活动次数统计' },
        cancel: () => {
          router.back()
        },
        useSafeTop: true
      })

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
                this.showWeekActivityRecord(this.curOffset)
              })
            Text(this.top_week)
              .fontSize(14)
            Image($r('app.media.right_btn'))
              .width(20)
              .height(20)
              .margin(5)
              .onClick(() => {
                this.curOffset = this.curOffset - 1
                this.showWeekActivityRecord(this.curOffset)
              })
          }
          .margin(7)

          // 达标提示
          Row() {
            Image($r('app.media.week_report_reward'))
              .width(18)
              .height(18)
            Text(this.reward_str)
              .fontSize(12)
              .fontColor('#3e3e3e')
          }

          // 柱状图白色卡片
          Column() {
            BarChartView({
              xAxisData: this.chartLabels,
              seriesData: this.chartData,
              barColor: '#C7C9CC',
              title: '次',
              titlePosition: 'right'
            })
            .height(200)
          }
          .width('92%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .padding(16)
          .margin({ top: 12 })

          // 目标进度白色卡片
          Column() {
            Text(`今日 ${this.currentActivities}/${this.targetActivities} 次`)
              .fontSize(16)
              .fontColor('#333')
          }
          .width('92%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .padding(16)
          .margin({ top: 12 })

          // 汇总信息白色卡片
          Row() {
            Column() {
              Text('总次数')
                .fontSize(12)
                .fontColor('#666666')
              Text(this.allActivities.toString())
                .fontWeight(600)
                .fontSize(30)
                .margin({ top: 6 })
              Text('次')
                .fontSize(12)
                .fontColor('#666666')
            }
            .layoutWeight(1)
            .borderRadius(15)
            .padding(15)
            .backgroundColor('#FFFFFF')

            Column() {
              Text('平均每日次数')
                .fontSize(12)
                .fontColor('#666666')
              Text(this.argActivities.toFixed(0))
                .fontWeight(600)
                .fontSize(30)
                .margin({ top: 6 })
              Text('次')
                .fontSize(12)
                .fontColor('#666666')
            }
            .layoutWeight(1)
            .margin({ left: 5 })
            .borderRadius(15)
            .padding(15)
            .backgroundColor('#FFFFFF')
          }
          .margin({ top: 10 })
          .width('92%')
        }
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
