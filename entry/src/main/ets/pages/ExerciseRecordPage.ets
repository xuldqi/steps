import { router, window } from '@kit.ArkUI'
import { SportModel } from '../appdata/Model'
import AppDataManager, { DataCallback } from '../tools/AppDataManager'
import { DateUtils } from '../tools/DateUtils'
import { Log } from '../tools/Logger'
import { Utils } from '../tools/Utils'
import { McBarChart, Options } from '@mcui/mccharts'
import EntryAbility from '../entryability/EntryAbility'

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
  @State currentViewType: string = '运动时长' // 默认运动时长
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
    title: { show: false },
    legend: { show: false },
    xAxis: { data: ['周一', '周二', '周三', '周四', '周五', '周六', '周日']},
    series: [{ name: '', barStyle: { 
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

  private allSportTypesQueryCount: number = 0 // 用于跟踪所有类型查询的完成数量
  private allSportTypesData: Array<SportModel> = new Array<SportModel>() // 临时存储所有类型的数据
  private isLoadingAllTypes: boolean = false // 标记是否正在查询所有类型
  
  private exerciseCallback: DataCallback<SportModel> = {
    onDataResult: (type: number, result: SportModel[], isReturnFirstData: boolean): void => {
      if (this.isLoadingAllTypes) {
        // 查询全部运动时，累积所有类型的数据
        this.allSportTypesQueryCount++
        // 追加当前类型的数据
        for (const item of result) {
          this.allSportTypesData.push(item)
        }
        // 如果所有类型都查询完成（5种类型），更新数据
        if (this.allSportTypesQueryCount >= 5) {
          // 按 start_time 降序排序（最新的在前）
          const sorted = [...this.allSportTypesData].sort((a, b) => b.start_time - a.start_time)
          this.exerciseData = sorted
          this.allSportTypesData.length = 0 // 清空临时数组
          this.allSportTypesQueryCount = 0 // 重置计数器
          this.isLoadingAllTypes = false // 重置标志
          this.calculateStatistics()
          this.updateChart()
        }
      } else {
        // 查询单个类型时，按 start_time 降序排序（最新的在前）
        const sorted = result ? [...result].sort((a, b) => b.start_time - a.start_time) : []
        this.exerciseData = sorted
        this.calculateStatistics()
        this.updateChart()
      }
    }
  }

  onPageShow(): void {
    // 设置状态栏为灰色背景
    if (EntryAbility.myWindowClass) {
      const sysBarProps: window.SystemBarProperties = {
        statusBarColor: '#F5F5F5', // 灰色状态栏背景
        statusBarContentColor: '#000000' // 状态栏内容颜色为黑色
      }
      EntryAbility.myWindowClass.setWindowSystemBarProperties(sysBarProps)
    }
    
    // 检查数据是否有变更，如果有则刷新
    const status = AppDataManager.getSportDataStatus()
    if (status.isChange) {
      this.loadExerciseData()
      AppDataManager.resetSportDataStatus()
    } else {
      this.loadExerciseData()
    }
  }
  
  aboutToDisappear(): void {
    // 恢复默认状态栏设置（透明）
    if (EntryAbility.myWindowClass) {
      const sysBarProps: window.SystemBarProperties = {
        statusBarColor: '#00000000', // 透明状态栏
        statusBarContentColor: '#000000' // 状态栏内容颜色为黑色
      }
      EntryAbility.myWindowClass.setWindowSystemBarProperties(sysBarProps)
    }
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
    // 重置计数器和临时数组
    this.allSportTypesQueryCount = 0
    this.allSportTypesData.length = 0
    this.isLoadingAllTypes = true // 设置标志
    // 分别查询每种运动类型
    AppDataManager.findSportByType(1, this.exerciseCallback, false) // 室内跑
    AppDataManager.findSportByType(2, this.exerciseCallback, false) // 室外跑
    AppDataManager.findSportByType(3, this.exerciseCallback, false) // 骑行
    AppDataManager.findSportByType(4, this.exerciseCallback, false) // 健走
    AppDataManager.findSportByType(5, this.exerciseCallback, false) // 爬山
  }

  private calculateStatistics() {
    this.totalDuration = 0
    this.totalCount = this.exerciseData.length
    this.totalCalories = 0

    for (let item of this.exerciseData) {
      // use_time 是毫秒，需要除以 1000 得到秒，再除以 3600 得到小时
      this.totalDuration = this.totalDuration + item.use_time
      this.totalCalories = this.totalCalories + parseFloat(item.cal || '0')
    }
    
    // 转换为小时（use_time 是毫秒，所以除以 3600 * 1000）
    this.totalDuration = Math.round(this.totalDuration / (3600 * 1000) * 10) / 10
  }

  private updateChart() {
    let mm_datas = new Array<number>()
    let mm_dates = new Array<string>()
    
    for (let i = 0; i < this.dates.length; i++) {
      // 解析日期字符串 yyyy/MM/dd (DateUtils.getYMD_ 返回的是 yyyy/MM/dd 格式)
      const dateParts = this.dates[i].split('/')
      const year = parseInt(dateParts[0])
      const month = parseInt(dateParts[1])
      const day = parseInt(dateParts[2])
      
      // 创建 Date 对象用于获取星期几
      const dateObj = new Date(year, month - 1, day)
      const weekDayNum = dateObj.getDay()
      let weekDay = "周一"
      if (weekDayNum == 0) weekDay = "周日"
      else if (weekDayNum == 1) weekDay = "周一"
      else if (weekDayNum == 2) weekDay = "周二"
      else if (weekDayNum == 3) weekDay = "周三"
      else if (weekDayNum == 4) weekDay = "周四"
      else if (weekDayNum == 5) weekDay = "周五"
      else if (weekDayNum == 6) weekDay = "周六"
      
      // 获取月/日格式
      const monthDay = `${month}/${day.toString().padStart(2, '0')}`
      // 组合显示：星期几 + 月/日（使用换行符分隔）
      mm_dates.push(`${weekDay}\n${monthDay}`)
      
      let dayValue = 0
      for (let item of this.exerciseData) {
        const itemDate = DateUtils.timeToDateNoYM2(item.start_time) // yyyy/MM/dd
        // 直接比较日期字符串（都是 yyyy/MM/dd 格式）
        if (this.dates[i] === itemDate) {
          if (this.currentViewType === '运动次数') {
            dayValue = dayValue + 1
          } else if (this.currentViewType === '运动时长') {
            // use_time 是毫秒，转换为小时（保留1位小数）
            dayValue = dayValue + item.use_time / (3600 * 1000) // 小时
          } else if (this.currentViewType === '消耗热量') {
            dayValue = dayValue + parseFloat(item.cal || '0')
          }
        }
      }
      // 如果是运动时长，保留1位小数
      if (this.currentViewType === '运动时长') {
        dayValue = parseFloat(dayValue.toFixed(1))
      }
      mm_datas.push(dayValue)
    }
    
    // 根据当前视图类型设置单位
    let unitText = ''
    if (this.currentViewType === '运动时长') {
      unitText = '小时'
    } else if (this.currentViewType === '运动次数') {
      unitText = '次'
    } else if (this.currentViewType === '消耗热量') {
      unitText = '千卡'
    }
    
    this.seriesRadiusOption.setVal({
      title: { show: true, text: unitText, right: 20, top: 30 },
      legend: { show: false },
      xAxis: { data: mm_dates },
      series: [{ name: '', barStyle: { 
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
        // 标题栏（与首页保持一致的高度和布局）
        Column() {
          if (this.getSafeTopPadding() > 0) {
            Blank()
              .height(this.getSafeTopPadding())
              .backgroundColor('#F5F5F5')
          }
          
          Row() {
            Image($r('app.media.back_btn_dark'))
              .width(28)
              .height(28)
              .onClick(() => { router.back() })
            
            Row() {
              Text(this.exerciseTypes.find(t => t.id === this.currentType)?.name || '全部运动')
                .fontSize(18)
                .fontWeight(500)
                .fontColor('#333333')
                .onClick(() => { this.showTypeDialog = true })
              Text('▼')
                .fontSize(12)
                .fontColor('#666666')
                .margin({ left: 4 })
                .onClick(() => { this.showTypeDialog = true })
            }
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          }
          .width('100%')
          .height(56)
          .alignItems(VerticalAlign.Center)
          .padding({ left: 16, right: 16 })
        }
        .width('100%')
        .backgroundColor('#F5F5F5')

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
            
            // 添加运动按钮
            this.buildAddExerciseButton()
            
            // 运动记录列表
            this.buildExerciseList()
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

  private getSafeTopPadding(): number {
    if (!EntryAbility.myWindowClass) {
      return 0
    }
    const avoidArea = EntryAbility.myWindowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
    return Math.max(0, avoidArea.topRect.height - 80)
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
        Text('选择运动类型')
          .fontSize(18)
          .fontWeight(600)
          .fontColor('#333333')
          .margin({ bottom: 12 })

        Grid() {
          ForEach(this.exerciseTypes, (type: ExerciseType) => {
            GridItem() {
              Column() {
                Image(type.icon)
                  .width(32)
                  .height(32)
                  .margin({ bottom: 6 })
                Text(type.name)
                  .fontSize(12)
                  .fontColor(this.currentType === type.id ? '#0cc291' : '#666666')
              }
              .width('100%')
              .height(70)
              .padding(8)
              .backgroundColor(this.currentType === type.id ? '#E8F5E8' : '#F8F8F8')
              .borderRadius(16)
              .justifyContent(FlexAlign.Center)
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
      .width('80%')
      .height(260)
      .padding({ top: 16, bottom: 16, left: 20, right: 20 })
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .align(Alignment.Center)
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Center)
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
      }.justifyContent(FlexAlign.Center)
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
          Text('千卡')
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
      .margin({ bottom: 16 })
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

  private formatExerciseDuration(useTimeMs: number): string {
    // use_time 是毫秒，转换为分钟
    const totalMinutes = Math.floor(useTimeMs / (60 * 1000))
    const hours = Math.floor(totalMinutes / 60)
    const minutes = totalMinutes % 60
    
    if (hours > 0) {
      return `${hours}小时${minutes}分钟`
    } else {
      return `${minutes}分钟`
    }
  }
}
