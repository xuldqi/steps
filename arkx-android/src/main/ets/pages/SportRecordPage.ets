import { router } from '@kit.ArkUI'
import { CommonTitleView } from '../view/CommonTitleView'
import { BarChartView } from '../view/BarChartView'
import { AppDataManager, DataCallback } from '../tools/AppDataManager'
import { SportModel } from '../appdata/Model'
import { DateUtils } from '../tools/DateUtils'
import { Utils } from '../tools/Utils'

interface SportRouteParams {
  type?: number
  formData?: {
    type: number
    curTarget: string
    subTopTitle: string
    subTopData: string
    subBotData: string
  }
}

@Entry
@Component
struct SportRecordPage {
  @State currentType: number = 1
  @State data: Array<SportModel> = []
  
  @State selectedMetric: string = '运动时长'
  @State timeRange: string = '周'
  @State totalDistance: number = 0
  @State totalTime: number = 0
  @State totalActivities: number = 0
  @State totalCalories: number = 0
  
  @State chartLabels: Array<string> = ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
  @State chartData: Array<number> = [0, 0, 0, 0, 0, 0, 0]
  @State topRange: string = ''
  
  private dates: Array<string> = []
  private readonly metricOptions: Array<string> = ['运动时长', '运动次数', '消耗热量']

  private sportCallback: DataCallback<SportModel> = {
    onDataResult: (type: number, result: SportModel[], isReturnFirstData: boolean): void => {
      this.data = result
      this.refreshVisualData()
    }
  }

  aboutToAppear() {
    this.initTypeFromRoute()
  }

  private initTypeFromRoute() {
    const raw = router.getParams() as SportRouteParams | undefined
    if (raw) {
      if (typeof raw.type === 'number') {
        this.currentType = raw.type
      } else if (raw.formData && typeof raw.formData.type === 'number') {
        this.currentType = raw.formData.type
      }
    }
  }

  onPageShow() {
    this.selectedMetric = '运动时长'
    this.timeRange = '周'
    this.loadData()
  }

  private loadData() {
    if (this.timeRange === '周') {
      this.loadWeekData(0)
    } else if (this.timeRange === '月') {
      this.loadMonthData()
    } else {
      this.loadYearData()
    }
  }

  private loadWeekData(offset: number) {
    this.dates.length = 0
    for (let i = 6; i >= 0; i--) {
      this.dates.push(DateUtils.getYMD_(i))
    }
    this.topRange = DateUtils.getYMDCH(6) + ' - ' + DateUtils.getYMDCH(0)
    AppDataManager.getInstance().findSportByType(this.currentType === 0 ? 0 : this.currentType, this.sportCallback, false)
  }

  private loadMonthData() {
    const now = new Date()
    const year = now.getFullYear()
    const month = now.getMonth()
    const daysInMonth = new Date(year, month + 1, 0).getDate()
    this.dates.length = 0
    for (let i = daysInMonth - 1; i >= 0; i--) {
      const date = new Date(year, month, i + 1)
      this.dates.push(DateUtils.getYMD_(daysInMonth - 1 - i))
    }
    this.topRange = `${year}年${month + 1}月`
    AppDataManager.getInstance().findSportByType(this.currentType === 0 ? 0 : this.currentType, this.sportCallback, false)
  }

  private loadYearData() {
    const now = new Date()
    this.dates.length = 0
    for (let i = 11; i >= 0; i--) {
      const date = new Date(now.getFullYear(), now.getMonth() - i, 1)
      this.dates.push(`${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`)
    }
    this.topRange = `${now.getFullYear()}年`
    AppDataManager.getInstance().findSportByType(this.currentType === 0 ? 0 : this.currentType, this.sportCallback, false)
  }

  private refreshVisualData() {
    this.recalculateStatistics()
    this.updateChartData()
  }

  private recalculateStatistics() {
    this.totalDistance = 0
    this.totalTime = 0
    this.totalActivities = this.data.length
    this.totalCalories = 0

    for (const record of this.data) {
      this.totalTime += record.use_time
      this.totalCalories += parseFloat(record.cal) || 0
      // 距离计算：基于步数，假设每步0.6米
      this.totalDistance += record.steps * 0.6
    }
  }

  private updateChartData() {
    const dataByDate: Map<string, number> = new Map()
    
    for (const record of this.data) {
      const date = DateUtils.timeToDateNoYM2(record.start_time)
      let value = 0
      
      if (this.selectedMetric === '运动时长') {
        value = Math.floor(record.use_time / 60) // 分钟
      } else if (this.selectedMetric === '运动次数') {
        value = 1
      } else if (this.selectedMetric === '消耗热量') {
        value = Math.floor(parseFloat(record.cal) || 0)
      }
      
      const existing = dataByDate.get(date) ?? 0
      dataByDate.set(date, existing + value)
    }

    const labels: Array<string> = []
    const values: Array<number> = []
    
    for (let i = 0; i < this.dates.length; i++) {
      const date = this.dates[i]
      const value = dataByDate.get(date) ?? 0
      values.push(value)
      
      if (this.timeRange === '周') {
        labels.push(DateUtils.getWeek(date))
      } else if (this.timeRange === '月') {
        const parts = date.split('-')
        labels.push(`${parts[1]}/${parts[2]}`)
      } else {
        const parts = date.split('-')
        labels.push(`${parts[0]}年${parts[1]}月`)
      }
    }
    
    this.chartLabels = labels
    this.chartData = values
  }

  private getPageTitle(): string {
    if (this.currentType === 0) {
      return '全部运动'
    }
    return Utils.getSportRecordTitle(this.currentType)
  }

  private getChartTitle(): string {
    if (this.selectedMetric === '运动时长') {
      return '分钟'
    } else if (this.selectedMetric === '运动次数') {
      return '次'
    } else {
      return '千卡'
    }
  }

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: this.getPageTitle() },
        cancel: () => {
          router.back()
        },
        titleBackgroundColor: '#F5F5F5',
        useSafeTop: true
      })

      Scroll() {
        Column() {
          // 趋势查看区域
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
                  .backgroundColor(this.timeRange === '周' ? '#0cc291' : '#EEEEEE')
                  .fontColor(this.timeRange === '周' ? '#FFFFFF' : '#333333')
                  .fontWeight(this.timeRange === '周' ? FontWeight.Medium : FontWeight.Normal)
                  .height(32)
                  .padding({ left: 12, right: 12 })
                  .borderRadius(16)
                  .onClick(() => {
                    this.timeRange = '周'
                    this.loadData()
                  })
                Button('月')
                  .backgroundColor(this.timeRange === '月' ? '#0cc291' : '#EEEEEE')
                  .fontColor(this.timeRange === '月' ? '#FFFFFF' : '#333333')
                  .fontWeight(this.timeRange === '月' ? FontWeight.Medium : FontWeight.Normal)
                  .height(32)
                  .padding({ left: 12, right: 12 })
                  .borderRadius(16)
                  .margin({ left: 8 })
                  .onClick(() => {
                    this.timeRange = '月'
                    this.loadData()
                  })
                Button('年')
                  .backgroundColor(this.timeRange === '年' ? '#0cc291' : '#EEEEEE')
                  .fontColor(this.timeRange === '年' ? '#FFFFFF' : '#333333')
                  .fontWeight(this.timeRange === '年' ? FontWeight.Medium : FontWeight.Normal)
                  .height(32)
                  .padding({ left: 12, right: 12 })
                  .borderRadius(16)
                  .margin({ left: 8 })
                  .onClick(() => {
                    this.timeRange = '年'
                    this.loadData()
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

            // 指标选择胶囊（第二排，居中）
            Row() {
              ForEach(this.metricOptions, (metric: string) => {
                Button(metric)
                  .backgroundColor(this.selectedMetric === metric ? '#0cc291' : '#EEEEEE')
                  .fontColor(this.selectedMetric === metric ? '#FFFFFF' : '#333333')
                  .fontWeight(this.selectedMetric === metric ? FontWeight.Medium : FontWeight.Normal)
                  .height(32)
                  .padding({ left: 12, right: 12 })
                  .borderRadius(16)
                  .margin({ left: 4, right: 4 })
                  .onClick(() => {
                    this.selectedMetric = metric
                    this.updateChartData()
                  })
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ left: 16, right: 16, bottom: 12 })

            // 图表
            BarChartView({
              xAxisData: this.chartLabels,
              seriesData: this.chartData,
              barColor: '#0cc291',
              title: this.getChartTitle(),
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

          // 信息概览
          Column() {
            Row() {
              Column() {
                Text('总距离')
                  .fontSize(12)
                  .fontColor('#666666')
                Text(`${(this.totalDistance / 1000).toFixed(2)}`)
                  .fontWeight(600)
                  .fontSize(30)
                  .margin({ top: 6 })
                Text('公里')
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .layoutWeight(1)
              Column() {
                Text('总时长')
                  .fontSize(12)
                  .fontColor('#666666')
                Text(`${Math.floor(this.totalTime / 60)}`)
                  .fontWeight(600)
                  .fontSize(30)
                  .margin({ top: 6 })
                Text('分钟')
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .layoutWeight(1)
            }
            .width('100%')
            .margin({ top: 12 })

            Row() {
              Column() {
                Text('活动次数')
                  .fontSize(12)
                  .fontColor('#666666')
                Text(`${this.totalActivities}`)
                  .fontWeight(600)
                  .fontSize(30)
                  .margin({ top: 6 })
                Text('次')
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .layoutWeight(1)
              Column() {
                Text('消耗热量')
                  .fontSize(12)
                  .fontColor('#666666')
                Text(`${Math.floor(this.totalCalories)}`)
                  .fontWeight(600)
                  .fontSize(30)
                  .margin({ top: 6 })
                Text('千卡')
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .layoutWeight(1)
            }
            .width('100%')
            .margin({ top: 12 })
          }
          .width('92%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .padding(16)
          .margin({ top: 12, bottom: 16 })
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

