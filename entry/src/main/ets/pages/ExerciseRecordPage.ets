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

interface TimeBucket {
  label: string
  start: number
  end: number
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
  
  private chartBuckets: Array<TimeBucket> = []
  private rangeStart: number = 0
  private rangeEnd: number = 0
  
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
    this.refreshExerciseRecords(this.curOffset)
  }

  private refreshExerciseRecords(offset: number) {
    this.curOffset = Math.max(0, offset)
    this.prepareRangeBuckets(this.curOffset)
    this.calculateStatistics()
    this.updateChart()

    if (this.currentType === 0) {
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
    if (this.rangeEnd <= this.rangeStart) {
      this.totalDuration = 0
      this.totalCount = 0
      this.totalCalories = 0
      return
    }

    let totalDurationMs = 0
    let totalCalories = 0
    let totalCount = 0

    for (let item of this.exerciseData) {
      if (item.start_time >= this.rangeStart && item.start_time <= this.rangeEnd) {
        totalCount = totalCount + 1
        totalDurationMs = totalDurationMs + item.use_time
        totalCalories = totalCalories + parseFloat(item.cal || '0')
      }
    }

    this.totalCount = totalCount
    this.totalDuration = Math.round(totalDurationMs / (3600 * 1000) * 10) / 10
    this.totalCalories = Math.round(totalCalories * 10) / 10
  }

  private updateChart() {
    const labels: Array<string> = []
    const values: Array<number> = []

    for (const bucket of this.chartBuckets) {
      labels.push(bucket.label)
      let bucketValue = 0
      for (const item of this.exerciseData) {
        if (item.start_time >= bucket.start && item.start_time <= bucket.end) {
          if (this.currentViewType === '运动次数') {
            bucketValue = bucketValue + 1
          } else if (this.currentViewType === '运动时长') {
            bucketValue = bucketValue + item.use_time / (3600 * 1000)
          } else if (this.currentViewType === '消耗热量') {
            bucketValue = bucketValue + parseFloat(item.cal || '0')
          }
        }
      }

      if (this.currentViewType === '运动时长') {
        bucketValue = parseFloat(bucketValue.toFixed(1))
      } else if (this.currentViewType === '运动次数') {
        bucketValue = Math.round(bucketValue)
      } else {
        bucketValue = Math.round(bucketValue * 10) / 10
      }

      values.push(bucketValue)
    }

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
      xAxis: { data: labels },
      series: [{ name: '', barStyle: { 
            width: 10,
            color:'#0cc291',
            borderRadius: [4, 4] }, data: values }]
    })
  }

  private prepareRangeBuckets(offset: number) {
    this.chartBuckets = []

    if (this.timeRange === '周') {
      const rangeStart = this.getDateByOffset(6 + 7 * offset)
      const rangeEnd = this.getDateByOffset(7 * offset)
      this.top_week = `${this.formatDateCN(rangeStart)} - ${this.formatDateCN(rangeEnd)}`
      for (let day = 6; day >= 0; day--) {
        const targetDate = this.getDateByOffset(day + 7 * offset)
        this.chartBuckets.push({
          label: `${this.getWeekLabel(targetDate)}\n${this.formatMonthDay(targetDate)}`,
          start: this.getStartOfDay(targetDate),
          end: this.getEndOfDay(targetDate)
        })
      }
    } else if (this.timeRange === '月') {
      const monthStart = this.getMonthStart(offset)
      const year = monthStart.getFullYear()
      const month = monthStart.getMonth()
      const daysInMonth = new Date(year, month + 1, 0).getDate()
      this.top_week = `${year}年${month + 1}月`
      for (let day = 1; day <= daysInMonth; day++) {
        const current = new Date(year, month, day)
        this.chartBuckets.push({
          label: `${day}日`,
          start: this.getStartOfDay(current),
          end: this.getEndOfDay(current)
        })
      }
    } else {
      const targetYear = this.getYearByOffset(offset)
      this.top_week = `${targetYear}年`
      for (let month = 0; month < 12; month++) {
        const startDate = new Date(targetYear, month, 1)
        const endDate = new Date(targetYear, month + 1, 0)
        this.chartBuckets.push({
          label: `${month + 1}月`,
          start: this.getStartOfDay(startDate),
          end: this.getEndOfDay(endDate)
        })
      }
    }

    if (this.chartBuckets.length > 0) {
      this.rangeStart = this.chartBuckets[0].start
      this.rangeEnd = this.chartBuckets[this.chartBuckets.length - 1].end
    } else {
      this.rangeStart = 0
      this.rangeEnd = 0
    }
  }

  private getDateByOffset(offsetDays: number): Date {
    const date = new Date()
    date.setHours(0, 0, 0, 0)
    date.setDate(date.getDate() - offsetDays)
    return date
  }

  private getMonthStart(offsetMonths: number): Date {
    const date = new Date()
    date.setHours(0, 0, 0, 0)
    date.setDate(1)
    date.setMonth(date.getMonth() - offsetMonths)
    return date
  }

  private getYearByOffset(offsetYears: number): number {
    const now = new Date()
    return now.getFullYear() - offsetYears
  }

  private getStartOfDay(date: Date): number {
    const copy = new Date(date)
    copy.setHours(0, 0, 0, 0)
    return copy.getTime()
  }

  private getEndOfDay(date: Date): number {
    const copy = new Date(date)
    copy.setHours(23, 59, 59, 999)
    return copy.getTime()
  }

  private formatDateCN(date: Date): string {
    return `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日`
  }

  private getWeekLabel(date: Date): string {
    const day = date.getDay()
    switch (day) {
      case 0:
        return '周日'
      case 1:
        return '周一'
      case 2:
        return '周二'
      case 3:
        return '周三'
      case 4:
        return '周四'
      case 5:
        return '周五'
      case 6:
        return '周六'
      default:
        return '周一'
    }
  }

  private formatMonthDay(date: Date): string {
    const month = date.getMonth() + 1
    const day = date.getDate().toString().padStart(2, '0')
    return `${month}/${day}`
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
    if (this.timeRange === range) {
      return
    }
    this.timeRange = range
    this.curOffset = 0
    this.refreshExerciseRecords(0)
  }

  private changeRangeOffset(delta: number) {
    const nextOffset = this.curOffset + delta
    if (nextOffset < 0) {
      return
    }
    this.refreshExerciseRecords(nextOffset)
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
                  .fontColor(this.currentType === type.id ? '#FFFFFF' : '#666666')
              }
              .width('100%')
              .height(70)
              .padding(8)
              .backgroundColor(this.currentType === type.id ? '#0cc291' : '#F8F8F8')
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
              .fontColor(this.timeRange === range ? '#FFFFFF' : '#333333')
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .backgroundColor(this.timeRange === range ? '#0cc291' : '#F5F5F5')
              .borderRadius(16)
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
            this.changeRangeOffset(1)
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
            this.changeRangeOffset(-1)
          })
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 视图类型切换
      Row() {
        ForEach(['运动时长', '运动次数', '消耗热量'], (viewType: string) => {
          Text(viewType)
            .fontSize(14)
            .fontColor(this.currentViewType === viewType ? '#FFFFFF' : '#333333')
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .backgroundColor(this.currentViewType === viewType ? '#0cc291' : '#F5F5F5')
            .borderRadius(16)
            .margin({ right: 8, bottom: 4 })
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
