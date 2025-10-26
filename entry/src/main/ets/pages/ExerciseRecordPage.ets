import { router } from '@kit.ArkUI'
import { CommonTitleView } from '../view/CommonTitleView'
import { SportModel } from '../appdata/Model'
import AppDataManager, { DataCallback } from '../tools/AppDataManager'
import { DateUtils } from '../tools/DateUtils'
import { Log } from '../tools/Logger'
import { Utils } from '../tools/Utils'
import { McBarChart, Options } from '@mcui/mccharts'

interface ExerciseType {
  id: number
  name: string
  icon: Resource
}

interface ExerciseProportion {
  name: string
  count: number
  percentage: number
}

@Entry
@Component
struct ExerciseRecordPage {
  @State currentType: number = 0 // 0表示全部运动
  @State currentViewType: string = '运动次数' // 运动时长、运动次数、消耗热量
  @State timeRange: string = '周' // 周、月、年
  @State curOffset: number = 0
  @State top_week: string = ''
  @State showTypeDialog: boolean = false
  
  @State exerciseData: Array<SportModel> = new Array<SportModel>()
  @State totalDuration: number = 0 // 总时长（小时）
  @State totalCount: number = 0 // 总次数
  @State totalCalories: number = 0 // 总热量
  
  private dates: Array<string> = new Array<string>()
  
  @State seriesRadiusOption: Options = new Options({
    title: { show: true, text: '最近七天的运动统计', right: 20, top: 30 },
    xAxis: { data: ['周一', '周二', '周三', '周四', '周五', '周六', '周日']},
    series: [{ name: '运动次数', barStyle: { 
          width: 10,
          color:'#0cc291',
          borderRadius: [4, 4] },
        data: [0, 0, 0, 0, 0, 0, 0] }]
  })

  private exerciseTypes: Array<ExerciseType> = [
    { id: 0, name: '全部运动', icon: $r('app.media.sport_run') },
    { id: 1, name: '室内跑步', icon: $r('app.media.sport_indoor_run') },
    { id: 2, name: '室外跑步', icon: $r('app.media.sport_run') },
    { id: 3, name: '骑行', icon: $r('app.media.sport_run') },
    { id: 4, name: '健走', icon: $r('app.media.sport_go_walk') },
    { id: 5, name: '爬山', icon: $r('app.media.sport_climb') }
    // 隐藏瑜伽和跳绳
  ]

  private exerciseCallback: DataCallback<SportModel> = {
    onDataResult: (type: number, result: SportModel[], isReturnFirstData: boolean): void => {
      this.exerciseData = result
      this.calculateStatistics()
      this.updateChart()
    }
  }

  onPageShow(): void {
    this.loadExerciseData()
  }

  private loadExerciseData() {
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
    
    // 获取运动数据
    if (this.currentType === 0) {
      // 获取所有运动数据
      this.loadAllSportTypes()
    } else {
      AppDataManager.findSportByType(this.currentType, this.exerciseCallback, false)
    }
  }

  private loadAllSportTypes() {
    // 分别查询每种运动类型
    AppDataManager.findSportByType(1, this.exerciseCallback, false) // 室内跑
    AppDataManager.findSportByType(2, this.exerciseCallback, false) // 室外跑
    AppDataManager.findSportByType(3, this.exerciseCallback, false) // 健走
    AppDataManager.findSportByType(4, this.exerciseCallback, false) // 徒步
    AppDataManager.findSportByType(5, this.exerciseCallback, false) // 登山
  }

  private calculateStatistics() {
    this.totalDuration = 0
    this.totalCount = this.exerciseData.length
    this.totalCalories = 0

    for (let item of this.exerciseData) {
      this.totalDuration = this.totalDuration + item.use_time
      this.totalCalories = this.totalCalories + parseFloat(item.cal || '0')
    }
    
    // 转换为小时
    this.totalDuration = Math.round(this.totalDuration / 3600 * 10) / 10
  }

  private updateChart() {
    let mm_datas = new Array<number>()
    let mm_dates = new Array<string>()
    
    for (let i = 0; i < this.dates.length; i++) {
      mm_dates.push(DateUtils.getWeek(this.dates[i]))
      
      let dayValue = 0
      for (let item of this.exerciseData) {
        const itemDate = new Date(item.start_time).toISOString().split('T')[0]
        if (this.dates[i] === itemDate) {
          if (this.currentViewType === '运动次数') {
            dayValue = dayValue + 1
          } else if (this.currentViewType === '运动时长') {
            dayValue = dayValue + Math.floor(item.use_time / 60) // 分钟
          } else if (this.currentViewType === '消耗热量') {
            dayValue = dayValue + parseFloat(item.cal || '0')
          }
        }
      }
      mm_datas.push(dayValue)
    }
    
    this.seriesRadiusOption.setVal({
      title: { show: true, text: `最近七天的${this.currentViewType}`, right: 20, top: 30 },
      xAxis: { data: mm_dates },
      series: [{ name: this.currentViewType, barStyle: { 
            width: 10,
            color:'#0cc291',
            borderRadius: [4, 4] }, data: mm_datas }]
    })
  }

  private onExerciseTypeChange(type: number) {
    this.currentType = type
    this.loadExerciseData()
  }

  private onViewTypeChange(viewType: string) {
    this.currentViewType = viewType
    this.updateChart()
  }

  private onTimeRangeChange(range: string) {
    this.timeRange = range
    // 这里可以根据时间范围调整数据加载逻辑
  }

  private openAddExercise() {
    router.pushUrl({ url: 'pages/AddExercisePage' })
  }

  private openExerciseDetail(exercise: SportModel) {
    router.pushUrl({ 
      url: 'pages/ExerciseDetailPage',
      params: { exercise: exercise }
    })
  }

  build() {
    Stack() {
      Column() {
        // 标题栏
        Row() {
          Image($r('app.media.back_btn_dark'))
            .width(24)
            .height(24)
            .onClick(() => {
              router.back()
            })
          
          Row() {
            Text(this.exerciseTypes.find(t => t.id === this.currentType)?.name || '全部运动')
              .fontSize(18)
              .fontWeight(500)
              .fontColor('#333333')
            
            Text('▼')
              .fontSize(12)
              .fontColor('#666666')
              .margin({ left: 4 })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.showTypeDialog = true
          })
          
          Text('运动日历>')
            .fontSize(14)
            .fontColor('#0cc291')
            .onClick(() => {
              // 跳转到运动日历页面
            })
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#FFFFFF')
        .alignItems(VerticalAlign.Center)

        Scroll() {
          Column() {
            // 趋势查看
            this.buildTrendView()
            
            // 信息概览
            this.buildInfoOverview()
            
            // 运动占比（仅全部运动时显示）
            if (this.currentType === 0) {
              this.buildExerciseProportion()
            }
            
            // 运动记录列表
            this.buildExerciseList()
            
            // 添加运动按钮
            this.buildAddExerciseButton()
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')

      // 运动类型选择弹窗
      if (this.showTypeDialog) {
        this.buildTypeSelectDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder buildTypeSelectDialog() {
    Stack() {
      // 背景遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .onClick(() => {
          this.showTypeDialog = false
        })

      // 弹窗内容
      Column() {
        Text('运动类型')
          .fontSize(16)
          .fontWeight(500)
          .fontColor('#333333')
          .margin({ bottom: 16 })

        Grid() {
          ForEach(this.exerciseTypes, (type: ExerciseType) => {
            GridItem() {
              Column() {
                Image(type.icon)
                  .width(32)
                  .height(32)
                  .margin({ bottom: 6 })
                Text(type.name)
                  .fontSize(11)
                  .fontColor(this.currentType === type.id ? '#0cc291' : '#666666')
              }
              .width('100%')
              .padding(8)
              .backgroundColor(this.currentType === type.id ? '#E8F5E8' : '#F8F8F8')
              .borderRadius(6)
              .onClick(() => {
                this.onExerciseTypeChange(type.id)
                this.showTypeDialog = false
              })
            }
          })
        }
        .columnsTemplate('1fr 1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
      }
      .width('90%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .align(Alignment.Bottom)
    }
    .width('100%')
    .height('100%')
  }

  @Builder buildTrendView() {
    Column() {
      Row() {
        Text('趋势查看')
          .fontSize(16)
          .fontWeight(500)
          .fontColor('#333333')
          .layoutWeight(1)
        
        // 时间范围切换
        Row() {
          ForEach(['周', '月', '年'], (range: string) => {
            Text(range)
              .fontSize(14)
              .fontColor(this.timeRange === range ? '#0cc291' : '#666666')
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(this.timeRange === range ? '#E8F5E8' : 'transparent')
              .borderRadius(4)
              .onClick(() => {
                this.onTimeRangeChange(range)
              })
          })
        }
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 日期范围
      Row() {
        Image($r('app.media.back_btn_dark'))
          .width(20)
          .height(20)
          .onClick(() => {
            this.curOffset = this.curOffset + 1
            this.showWeekExerciseRecord(this.curOffset)
          })
        
        Text(this.top_week)
          .fontSize(14)
          .fontColor('#666666')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        Image($r('app.media.right_btn'))
          .width(20)
          .height(20)
          .onClick(() => {
            this.curOffset = this.curOffset - 1
            this.showWeekExerciseRecord(this.curOffset)
          })
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 视图类型切换
      Row() {
        ForEach(['运动时长', '运动次数', '消耗热量'], (viewType: string) => {
          Text(viewType)
            .fontSize(14)
            .fontColor(this.currentViewType === viewType ? '#0cc291' : '#666666')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(this.currentViewType === viewType ? '#E8F5E8' : '#F8F8F8')
            .borderRadius(6)
            .margin({ right: 8 })
            .onClick(() => {
              this.onViewTypeChange(viewType)
            })
        })
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 图表
      Row() {
        McBarChart({
          options: this.seriesRadiusOption
        })
      }
      .height(200)
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 16 })
  }

  @Builder buildInfoOverview() {
    Column() {
      Text('信息概览')
        .fontSize(16)
        .fontWeight(500)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 16 })

      Row() {
        Column() {
          Text(this.totalDuration.toString())
            .fontSize(24)
            .fontWeight(600)
            .fontColor('#0cc291')
          Text('运动时长(小时)')
            .fontSize(12)
            .fontColor('#666666')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Text(this.totalCount.toString())
            .fontSize(24)
            .fontWeight(600)
            .fontColor('#0cc291')
          Text('运动次数(次)')
            .fontSize(12)
            .fontColor('#666666')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Text(this.totalCalories.toString())
            .fontSize(24)
            .fontWeight(600)
            .fontColor('#0cc291')
          Text('消耗热量(千卡)')
            .fontSize(12)
            .fontColor('#666666')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 16 })
  }

  @Builder buildExerciseProportion() {
    Column() {
      Text('运动次数占比')
        .fontSize(16)
        .fontWeight(500)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 16 })

      ForEach(this.getExerciseProportion(), (item: ExerciseProportion) => {
        Row() {
          Text(item.name)
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)
          
          Text(`${item.count}次`)
            .fontSize(14)
            .fontColor('#666666')
            .margin({ right: 8 })
          
          Text(`${item.percentage.toFixed(1)}%`)
            .fontSize(14)
            .fontColor('#0cc291')
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        .border({ width: { bottom: 1 }, color: '#F0F0F0' })
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 16 })
  }

  @Builder buildExerciseList() {
    Column() {
      Text('运动记录')
        .fontSize(16)
        .fontWeight(500)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 16 })

      if (this.exerciseData.length > 0) {
        ForEach(this.exerciseData, (exercise: SportModel) => {
          this.buildExerciseItem(exercise)
        })
      } else {
        Text('暂无运动记录')
          .fontSize(14)
          .fontColor('#999999')
          .padding(20)
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 16 })
  }

  @Builder buildExerciseItem(exercise: SportModel) {
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
        Text(DateUtils.convertCountTime(exercise.use_time))
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
    .onClick(() => {
      this.openExerciseDetail(exercise)
    })
  }

  @Builder buildAddExerciseButton() {
    Button('添加运动')
      .fontSize(16)
      .fontColor('#FFFFFF')
      .backgroundColor('#0cc291')
      .borderRadius(8)
      .width('100%')
      .height(48)
      .onClick(() => {
        this.openAddExercise()
      })
  }

  private getExerciseProportion(): Array<ExerciseProportion> {
    const proportion: Array<ExerciseProportion> = []
    const typeCount: Map<number, number> = new Map()

    // 统计各类型运动次数
    for (let exercise of this.exerciseData) {
      const count = typeCount.get(exercise.type) || 0
      typeCount.set(exercise.type, count + 1)
    }

    // 计算占比
    for (let type of typeCount.keys()) {
      const count = typeCount.get(type) || 0
      const percentage = this.totalCount > 0 ? (count / this.totalCount) * 100 : 0
      proportion.push({
        name: Utils.getSportRecordName(type),
        count: count,
        percentage: percentage
      })
    }

    return proportion.sort((a, b) => b.count - a.count)
  }
}
