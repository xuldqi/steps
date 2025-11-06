import { router } from '@kit.ArkUI'
import { CommonTitleView } from '../view/CommonTitleView'
import { BarChartView } from '../view/BarChartView'
import { AppDataManager, DataCallback } from '../tools/AppDataManager'
import { SportModel } from '../appdata/Model'
import { DateUtils } from '../tools/DateUtils'
import { Utils } from '../tools/Utils'

interface ExerciseType {
  id: number
  name: string
}

@Entry
@Component
struct ExerciseRecordPage {
  @State currentType: number = 0 // 0表示全部运动
  @State currentViewType: string = '运动时长'
  @State timeRange: string = '周'
  @State exerciseData: Array<SportModel> = []
  @State totalDuration: number = 0
  @State totalCount: number = 0
  @State totalCalories: number = 0
  @State chartLabels: Array<string> = []
  @State chartData: Array<number> = []
  @State topRange: string = ''

  private dates: Array<string> = []
  private readonly exerciseTypes: Array<ExerciseType> = [
    { id: 0, name: '全部运动' },
    { id: 1, name: '室内跑' },
    { id: 2, name: '室外跑' },
    { id: 3, name: '健走' },
    { id: 4, name: '徒步' },
    { id: 5, name: '登山' },
    { id: 6, name: '骑行' }
  ]

  private exerciseCallback: DataCallback<SportModel> = {
    onDataResult: (type: number, result: SportModel[], isReturnFirstData: boolean): void => {
      this.exerciseData = result
      this.refreshVisualData()
    }
  }

  onPageShow() {
    this.loadData()
  }

  private loadData() {
    if (this.timeRange === '周') {
      this.loadWeekData()
    } else if (this.timeRange === '月') {
      this.loadMonthData()
    } else {
      this.loadYearData()
    }
  }

  private loadWeekData() {
    this.dates.length = 0
    for (let i = 6; i >= 0; i--) {
      this.dates.push(DateUtils.getYMD_(i))
    }
    this.topRange = DateUtils.getYMDCH(6) + ' - ' + DateUtils.getYMDCH(0)
    AppDataManager.getInstance().findSportByType(this.currentType, this.exerciseCallback, false)
  }

  private loadMonthData() {
    const now = new Date()
    const year = now.getFullYear()
    const month = now.getMonth()
    const daysInMonth = new Date(year, month + 1, 0).getDate()
    this.dates.length = 0
    for (let i = daysInMonth - 1; i >= 0; i--) {
      this.dates.push(DateUtils.getYMD_(daysInMonth - 1 - i))
    }
    this.topRange = `${year}年${month + 1}月`
    AppDataManager.getInstance().findSportByType(this.currentType, this.exerciseCallback, false)
  }

  private loadYearData() {
    const now = new Date()
    this.dates.length = 0
    for (let i = 11; i >= 0; i--) {
      const date = new Date(now.getFullYear(), now.getMonth() - i, 1)
      this.dates.push(`${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`)
    }
    this.topRange = `${now.getFullYear()}年`
    AppDataManager.getInstance().findSportByType(this.currentType, this.exerciseCallback, false)
  }

  private refreshVisualData() {
    this.recalculateStatistics()
    this.updateChartData()
  }

  private recalculateStatistics() {
    this.totalDuration = 0
    this.totalCount = this.exerciseData.length
    this.totalCalories = 0

    for (const record of this.exerciseData) {
      this.totalDuration += record.use_time
      this.totalCalories += parseFloat(record.cal) || 0
    }
  }

  private updateChartData() {
    const dataByDate: Map<string, number> = new Map()
    
    for (const record of this.exerciseData) {
      const date = DateUtils.timeToDateNoYM2(record.start_time)
      let value = 0
      
      if (this.currentViewType === '运动时长') {
        value = Math.floor(record.use_time / 60) // 分钟
      } else if (this.currentViewType === '运动次数') {
        value = 1
      } else if (this.currentViewType === '消耗热量') {
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

  private getChartTitle(): string {
    if (this.currentViewType === '运动时长') {
      return '分钟'
    } else if (this.currentViewType === '运动次数') {
      return '次'
    } else {
      return '千卡'
    }
  }

  private formatExerciseDuration(seconds: number): string {
    const hours = Math.floor(seconds / 3600)
    const minutes = Math.floor((seconds % 3600) / 60)
    if (hours > 0) {
      return `${hours}小时${minutes}分钟`
    }
    return `${minutes}分钟`
  }

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: this.exerciseTypes.find(t => t.id === this.currentType)?.name || '全部运动' },
        cancel: () => {
          router.back()
        },
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

            // 指标选择胶囊（居中）
            Row() {
              Button('运动时长')
                .backgroundColor(this.currentViewType === '运动时长' ? '#0cc291' : '#EEEEEE')
                .fontColor(this.currentViewType === '运动时长' ? '#FFFFFF' : '#333333')
                .fontWeight(this.currentViewType === '运动时长' ? FontWeight.Medium : FontWeight.Normal)
                .height(32)
                .padding({ left: 12, right: 12 })
                .borderRadius(16)
                .margin({ left: 4, right: 4 })
                .onClick(() => {
                  this.currentViewType = '运动时长'
                  this.updateChartData()
                })
              Button('运动次数')
                .backgroundColor(this.currentViewType === '运动次数' ? '#0cc291' : '#EEEEEE')
                .fontColor(this.currentViewType === '运动次数' ? '#FFFFFF' : '#333333')
                .fontWeight(this.currentViewType === '运动次数' ? FontWeight.Medium : FontWeight.Normal)
                .height(32)
                .padding({ left: 12, right: 12 })
                .borderRadius(16)
                .margin({ left: 4, right: 4 })
                .onClick(() => {
                  this.currentViewType = '运动次数'
                  this.updateChartData()
                })
              Button('消耗热量')
                .backgroundColor(this.currentViewType === '消耗热量' ? '#0cc291' : '#EEEEEE')
                .fontColor(this.currentViewType === '消耗热量' ? '#FFFFFF' : '#333333')
                .fontWeight(this.currentViewType === '消耗热量' ? FontWeight.Medium : FontWeight.Normal)
                .height(32)
                .padding({ left: 12, right: 12 })
                .borderRadius(16)
                .margin({ left: 4, right: 4 })
                .onClick(() => {
                  this.currentViewType = '消耗热量'
                  this.updateChartData()
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
                Text('总时长')
                  .fontSize(12)
                  .fontColor('#666666')
                Text(`${Math.floor(this.totalDuration / 60)}`)
                  .fontWeight(600)
                  .fontSize(30)
                  .margin({ top: 6 })
                Text('分钟')
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .layoutWeight(1)
              Column() {
                Text('活动次数')
                  .fontSize(12)
                  .fontColor('#666666')
                Text(`${this.totalCount}`)
                  .fontWeight(600)
                  .fontSize(30)
                  .margin({ top: 6 })
                Text('次')
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .layoutWeight(1)
            }
            .width('100%')
            .margin({ top: 12 })

            Row() {
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

          // 运动记录列表
          Column() {
            Text('运动记录')
              .fontSize(16)
              .fontWeight(500)
              .fontColor('#333333')
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 12 })

            if (this.exerciseData.length === 0) {
              Text('暂无运动记录')
                .fontSize(14)
                .fontColor('#999999')
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding(40)
            } else {
              ForEach(this.exerciseData, (exercise: SportModel) => {
                Row() {
                  Image(Utils.getSportRecordIcon(exercise.type))
                    .width(30)
                    .height(30)
                    .margin({ right: 12 })

                  Column() {
                    Text(Utils.getSportRecordName(exercise.type))
                      .fontSize(16)
                      .fontWeight(500)
                      .fontColor('#333333')
                      .alignSelf(ItemAlign.Start)
                    
                    Text(DateUtils.timeToDateNoYM(exercise.start_time))
                      .fontSize(12)
                      .fontColor('#666666')
                      .alignSelf(ItemAlign.Start)
                      .margin({ top: 4 })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  Column() {
                    Text(this.formatExerciseDuration(exercise.use_time))
                      .fontSize(14)
                      .fontColor('#333333')
                      .alignSelf(ItemAlign.End)
                    
                    Text(Utils.getDistanceByStep(exercise.steps) + '公里')
                      .fontSize(12)
                      .fontColor('#666666')
                      .alignSelf(ItemAlign.End)
                      .margin({ top: 4 })
                  }
                  .alignItems(HorizontalAlign.End)
                }
                .width('100%')
                .padding({ top: 12, bottom: 12 })
                .border({ width: { bottom: 1 }, color: '#F0F0F0' })
              })
            }
          }
          .width('92%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .padding(16)
          .margin({ bottom: 16 })
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

