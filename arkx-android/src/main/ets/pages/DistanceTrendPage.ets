import { CommonTitleView } from '../view/CommonTitleView'
import { router } from '@kit.ArkUI'
import { BarChartView } from '../view/BarChartView'
import { AppDataManager, DataCallback } from '../tools/AppDataManager'
import { PerStepModel } from '../appdata/Model'
import { DateUtils } from '../tools/DateUtils'
import preferencesUtil from '../tools/PreferencesUtil'

// 步数转换为距离的系数：0.6米/步
const STEPS_TO_DISTANCE_RATIO = 0.6

@Entry
@Component
struct DistanceTrendPage {
  @State viewMode: 'week' | 'month' | 'year' = 'week'
  @State topRange: string = ''
  @State allDistance: number = 0 // 总距离（米）
  @State avgDistance: number = 0 // 平均每日距离（米）
  @State targetDistance: number = 3000 // 目标距离（米）
  @State currentDistance: number = 0 // 今日距离（米）
  @State chartLabels: Array<string> = ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
  @State chartData: Array<number> = [0, 0, 0, 0, 0, 0, 0]
  private dates: Array<string> = []

  private stepCallback: DataCallback<PerStepModel> = {
    onDataResult: (type: number, result: PerStepModel[], isReturnFirstData: boolean): void => {
      this.calculateDistanceStats(result)
    }
  }

  async onPageShow() {
    await this.loadTargetDistance()
    this.loadByViewMode()
  }

  private async loadTargetDistance() {
    const target = await preferencesUtil.getPreferenceValue('steps_ohos', 'distance_target', '3000')
    this.targetDistance = parseInt(target) || 3000
  }

  private loadByViewMode() {
    this.dates.length = 0
    const now = new Date()
    
    if (this.viewMode === 'week') {
      for (let i = 6; i >= 0; i--) {
        this.dates.push(DateUtils.getYMD_(i))
      }
      this.topRange = DateUtils.getYMDCH(6) + ' - ' + DateUtils.getYMDCH(0)
    } else if (this.viewMode === 'month') {
      const year = now.getFullYear()
      const month = now.getMonth()
      const daysInMonth = new Date(year, month + 1, 0).getDate()
      for (let i = daysInMonth - 1; i >= 0; i--) {
        this.dates.push(DateUtils.getYMD_(daysInMonth - 1 - i))
      }
      this.topRange = `${year}年${month + 1}月`
    } else {
      for (let i = 11; i >= 0; i--) {
        const date = new Date(now.getFullYear(), now.getMonth() - i, 1)
        this.dates.push(`${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`)
      }
      this.topRange = `${now.getFullYear()}年`
    }
    
    AppDataManager.getInstance().getStepPerDayWeekList3(this.dates, this.stepCallback, false)
  }

  private calculateDistanceStats(stepData: Array<PerStepModel>) {
    const distanceByDate: Map<string, number> = new Map()
    for (const item of stepData) {
      const distance = item.steps * STEPS_TO_DISTANCE_RATIO // 转换为米
      const existing = distanceByDate.get(item.date) ?? 0
      distanceByDate.set(item.date, existing + distance)
    }

    this.allDistance = 0
    for (const distance of distanceByDate.values()) {
      this.allDistance += distance
    }
    this.avgDistance = this.dates.length > 0 ? Math.floor(this.allDistance / this.dates.length) : 0

    const todayDate = DateUtils.getYMD()
    this.currentDistance = Math.floor(distanceByDate.get(todayDate) ?? 0)

    const mm_datas: Array<number> = []
    const mm_dates: Array<string> = []
    
    for (let i = 0; i < this.dates.length; i++) {
      const distance = distanceByDate.get(this.dates[i]) ?? 0
      const distanceKm = parseFloat((distance / 1000).toFixed(1)) // 转换为公里，保留1位小数
      mm_datas.push(distanceKm)
      
      if (this.viewMode === 'week') {
        mm_dates.push(DateUtils.getWeek(this.dates[i]))
      } else if (this.viewMode === 'month') {
        const parts = this.dates[i].split('-')
        mm_dates.push(`${parts[1]}/${parts[2]}`)
      } else {
        const parts = this.dates[i].split('-')
        mm_dates.push(`${parts[0]}年${parts[1]}月`)
      }
    }
    
    this.chartLabels = mm_dates
    this.chartData = mm_datas
  }

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '走路距离' },
        cancel: () => {
          router.back()
        },
        useSafeTop: true
      })

      Scroll() {
        Column() {
          // 控制区域和图表区域
          Column() {
            // 第一排：左"趋势查看"，右侧 周/月/年 胶囊（右对齐）
            Row() {
              Text('趋势查看')
                .fontSize(16)
                .fontWeight(500)
                .fontColor('#333333')
                .layoutWeight(1)

              Row() {
                Button('周')
                  .backgroundColor(this.viewMode === 'week' ? '#0cc291' : '#EEEEEE')
                  .fontColor(this.viewMode === 'week' ? '#FFFFFF' : '#333333')
                  .fontWeight(this.viewMode === 'week' ? FontWeight.Medium : FontWeight.Normal)
                  .height(32)
                  .padding({ left: 12, right: 12 })
                  .borderRadius(16)
                  .onClick(() => {
                    this.viewMode = 'week'
                    this.loadByViewMode()
                  })
                Button('月')
                  .backgroundColor(this.viewMode === 'month' ? '#0cc291' : '#EEEEEE')
                  .fontColor(this.viewMode === 'month' ? '#FFFFFF' : '#333333')
                  .fontWeight(this.viewMode === 'month' ? FontWeight.Medium : FontWeight.Normal)
                  .height(32)
                  .padding({ left: 12, right: 12 })
                  .borderRadius(16)
                  .margin({ left: 8 })
                  .onClick(() => {
                    this.viewMode = 'month'
                    this.loadByViewMode()
                  })
                Button('年')
                  .backgroundColor(this.viewMode === 'year' ? '#0cc291' : '#EEEEEE')
                  .fontColor(this.viewMode === 'year' ? '#FFFFFF' : '#333333')
                  .fontWeight(this.viewMode === 'year' ? FontWeight.Medium : FontWeight.Normal)
                  .height(32)
                  .padding({ left: 12, right: 12 })
                  .borderRadius(16)
                  .margin({ left: 8 })
                  .onClick(() => {
                    this.viewMode = 'year'
                    this.loadByViewMode()
                  })
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 12 })

            // 日期范围
            Text(this.topRange)
              .fontSize(14)
              .fontColor('#666666')
              .width('100%')
              .padding({ left: 16, right: 16, bottom: 12 })

            // 图表
            BarChartView({
              xAxisData: this.chartLabels,
              seriesData: this.chartData,
              barColor: '#0cc291',
              title: '公里',
              titlePosition: 'right'
            })
            .height(200)
            .width('100%')
          }
          .width('92%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .padding(16)
          .margin({ top: 8 })

          // 目标进度
          Column() {
            Text(`今日 ${(this.currentDistance / 1000).toFixed(2)}/${(this.targetDistance / 1000).toFixed(2)} 公里`)
              .fontSize(16)
              .fontColor('#333')
          }
          .width('92%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .padding(16)
          .margin({ top: 12 })

          // 汇总
          Column() {
            Row() {
              Column() {
                Text('总距离')
                  .fontSize(12)
                  .fontColor('#666666')
                Text(`${(this.allDistance / 1000).toFixed(2)}`)
                  .fontWeight(600)
                  .fontSize(30)
                  .margin({ top: 6 })
                Text('公里')
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .layoutWeight(1)
              Column() {
                Text('平均每日距离')
                  .fontSize(12)
                  .fontColor('#666666')
                Text(`${(this.avgDistance / 1000).toFixed(2)}`)
                  .fontWeight(600)
                  .fontSize(30)
                  .margin({ top: 6 })
                Text('公里')
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
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

