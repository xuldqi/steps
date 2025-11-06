import { CommonTitleView } from '../view/CommonTitleView'
import { router } from '@kit.ArkUI'
import { BarChartView } from '../view/BarChartView'
import { AppDataManager, DataCallback } from '../tools/AppDataManager'
import { BodyRecordModel } from '../appdata/Model'
import { DateUtils } from '../tools/DateUtils'
import preferencesUtil from '../tools/PreferencesUtil'

type ViewMode = 'week' | 'month' | 'year'

@Entry
@Component
struct WeightTrendPage {
  @State viewMode: ViewMode = 'week'
  @State topRange: string = ''
  @State chartLabels: Array<string> = []
  @State chartData: Array<number> = []
  
  @State initialWeight: number = 0
  @State currentWeight: number = 0
  @State targetWeight: number = 0
  @State statDays: number = 0
  @State statMax: string = '--'
  @State statMin: string = '--'
  @State statAvg: string = '--'

  private allWeights: Array<BodyRecordModel> = []
  private dates: Array<string> = []

  private weightCallback: DataCallback<BodyRecordModel> = {
    onDataResult: (type: number, result: BodyRecordModel[], isReturnFirstData: boolean): void => {
      this.allWeights = result || []
      this.refreshAll()
    }
  }

  async onPageShow() {
    await this.loadTargetWeight()
    this.loadByViewMode()
  }

  private async loadTargetWeight() {
    const target = await preferencesUtil.getPreferenceValue('steps_ohos', 'targetWeight', 0)
    this.targetWeight = Number(target) || 0
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
    
    AppDataManager.getInstance().findBodyRecordByType(AppDataManager.TYPE_WEIGHT, this.weightCallback, false)
  }

  private refreshAll() {
    this.computeStatistics()
    this.updateChartData()
  }

  private computeStatistics() {
    if (this.allWeights.length === 0) {
      this.statDays = 0
      this.statMax = '--'
      this.statMin = '--'
      this.statAvg = '--'
      this.currentWeight = 0
      this.initialWeight = 0
      return
    }

    this.statDays = this.allWeights.length
    
    const weights = this.allWeights.map(w => parseFloat(w.data) || 0).filter(w => w > 0)
    if (weights.length > 0) {
      this.statMax = Math.max(...weights).toFixed(1)
      this.statMin = Math.min(...weights).toFixed(1)
      const sum = weights.reduce((a, b) => a + b, 0)
      this.statAvg = (sum / weights.length).toFixed(1)
      
      // 最新体重
      const latest = this.allWeights.sort((a, b) => b.time - a.time)[0]
      this.currentWeight = parseFloat(latest.data) || 0
      
      // 最早体重
      const earliest = this.allWeights.sort((a, b) => a.time - b.time)[0]
      this.initialWeight = parseFloat(earliest.data) || 0
    }
  }

  private updateChartData() {
    const weightByDate: Map<string, number> = new Map()
    
    for (const record of this.allWeights) {
      const date = DateUtils.timeToDateNoYM2(record.time)
      const weight = parseFloat(record.data) || 0
      if (weight > 0) {
        weightByDate.set(date, weight)
      }
    }

    const labels: Array<string> = []
    const values: Array<number> = []
    
    for (let i = 0; i < this.dates.length; i++) {
      const date = this.dates[i]
      const weight = weightByDate.get(date) || 0
      values.push(weight)
      
      if (this.viewMode === 'week') {
        labels.push(DateUtils.getWeek(date))
      } else if (this.viewMode === 'month') {
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

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '体重趋势' },
        cancel: () => {
          router.back()
        },
        useSafeTop: true
      })

      Scroll() {
        Column() {
          // 进度信息
          Column() {
            Row() {
              Column() {
                Text('初始体重')
                  .fontSize(12)
                  .fontColor('#666666')
                Text(this.initialWeight > 0 ? `${this.initialWeight.toFixed(1)}` : '--')
                  .fontWeight(600)
                  .fontSize(20)
                  .margin({ top: 6 })
                Text('公斤')
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .layoutWeight(1)
              Column() {
                Text('当前体重')
                  .fontSize(12)
                  .fontColor('#666666')
                Text(this.currentWeight > 0 ? `${this.currentWeight.toFixed(1)}` : '--')
                  .fontWeight(600)
                  .fontSize(20)
                  .margin({ top: 6 })
                Text('公斤')
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .layoutWeight(1)
              Column() {
                Text('目标体重')
                  .fontSize(12)
                  .fontColor('#666666')
                Text(this.targetWeight > 0 ? `${this.targetWeight.toFixed(1)}` : '--')
                  .fontWeight(600)
                  .fontSize(20)
                  .margin({ top: 6 })
                Text('公斤')
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
          .margin({ top: 8 })

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
              title: '公斤',
              titlePosition: 'right'
            })
            .height(200)
            .width('100%')
          }
          .width('92%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .padding(16)
          .margin({ top: 12 })

          // 统计信息
          Column() {
            Row() {
              Column() {
                Text('记录天数')
                  .fontSize(12)
                  .fontColor('#666666')
                Text(this.statDays > 0 ? `${this.statDays}` : '--')
                  .fontWeight(600)
                  .fontSize(20)
                  .margin({ top: 6 })
                Text('天')
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .layoutWeight(1)
              Column() {
                Text('平均体重')
                  .fontSize(12)
                  .fontColor('#666666')
                Text(this.statAvg !== '--' ? `${this.statAvg}` : '--')
                  .fontWeight(600)
                  .fontSize(20)
                  .margin({ top: 6 })
                Text('公斤')
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .layoutWeight(1)
            }
            .width('100%')
            .margin({ top: 12 })

            Row() {
              Column() {
                Text('最低体重')
                  .fontSize(12)
                  .fontColor('#666666')
                Text(this.statMin !== '--' ? `${this.statMin}` : '--')
                  .fontWeight(600)
                  .fontSize(20)
                  .margin({ top: 6 })
                Text('公斤')
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .layoutWeight(1)
              Column() {
                Text('最高体重')
                  .fontSize(12)
                  .fontColor('#666666')
                Text(this.statMax !== '--' ? `${this.statMax}` : '--')
                  .fontWeight(600)
                  .fontSize(20)
                  .margin({ top: 6 })
                Text('公斤')
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

