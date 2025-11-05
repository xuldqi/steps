import { router, window } from '@kit.ArkUI'
import { CommonTitleView } from '../view/CommonTitleView'
import { SportModel } from '../appdata/Model'
import AppDataManager, { DataCallback } from '../tools/AppDataManager'
import { DateUtils } from '../tools/DateUtils'
import { Utils } from '../tools/Utils'
import EntryAbility from '../entryability/EntryAbility'
import { Log } from '../tools/Logger'
import { SportTypeSelectDialog } from '../view/SportTypeSelectDialog'

interface SportTypeFilter {
  id: number
  name: string
  icon: Resource
}

@Entry
@Component
struct MyDataPage {
  @State sportRecords: Array<SportModel> = []
  @State filteredRecords: Array<SportModel> = []
  
  // 筛选状态
  @State selectedSportType: number = 0 // 0表示全部
  @State selectedTimeRange: string = '全部' // 全部、今天、本周、本月、本年
  private typeFilterDialogController?: CustomDialogController = undefined
  
  // 统计数据
  @State totalCount: number = 0
  @State totalDuration: number = 0 // 毫秒
  @State totalDistance: number = 0 // 公里
  @State totalCalories: number = 0 // 千卡
  
  // 临时数据存储（用于查询所有类型）
  private allSportTypesQueryCount: number = 0
  private allSportTypesData: Array<SportModel> = []
  private isLoadingAllTypes: boolean = false
  
  private sportTypes: Array<SportTypeFilter> = [
    { id: 0, name: '全部运动', icon: $r('app.media.sport_run') },
    { id: 1, name: '室内跑步', icon: $r('app.media.sport_indoor_run') },
    { id: 2, name: '室外跑步', icon: $r('app.media.sport_run') },
    { id: 3, name: '健走', icon: $r('app.media.sport_go_walk') },
    { id: 4, name: '骑行', icon: $r('app.media.sport_run') },
    { id: 5, name: '爬山', icon: $r('app.media.sport_climb') }
  ]
  
  private getSportTypeName(typeId: number): string {
    return this.sportTypes.find(t => t.id === typeId)?.name || '全部运动'
  }
  
  private timeRanges: Array<string> = ['全部', '今天', '本周', '本月', '本年']
  
  private sportCallback: DataCallback<SportModel> = {
    onDataResult: (type: number, result: SportModel[], isReturnFirstData: boolean): void => {
      Log.i('[MyDataPage] sportCallback 收到数据: type=' + type + ', count=' + (result?.length || 0))
      if (this.isLoadingAllTypes) {
        this.allSportTypesQueryCount++
        for (const item of result) {
          this.allSportTypesData.push(item)
        }
        Log.i('[MyDataPage] 累积查询进度: ' + this.allSportTypesQueryCount + '/6, 总数据量=' + this.allSportTypesData.length)
        // 查询所有类型（1-6，共6种，不包括瑜伽和跳绳）
        if (this.allSportTypesQueryCount >= 6) {
          const sorted = [...this.allSportTypesData].sort((a, b) => b.start_time - a.start_time)
          this.sportRecords = sorted
          Log.i('[MyDataPage] 所有类型数据加载完成，共 ' + this.sportRecords.length + ' 条记录')
          this.allSportTypesData.length = 0
          this.allSportTypesQueryCount = 0
          this.isLoadingAllTypes = false
          this.applyFilters()
        }
      } else {
        const sorted = result ? [...result].sort((a, b) => b.start_time - a.start_time) : []
        this.sportRecords = sorted
        Log.i('[MyDataPage] 单个类型数据加载完成，共 ' + this.sportRecords.length + ' 条记录')
        this.applyFilters()
      }
    }
  }
  
  aboutToAppear(): void {
    Log.i('[MyDataPage] aboutToAppear 被调用')
    this.loadAllSportRecords()
  }
  
  onPageShow(): void {
    Log.i('[MyDataPage] onPageShow 被调用')
    const status = AppDataManager.getSportDataStatus()
    if (status.isChange) {
      Log.i('[MyDataPage] 检测到数据变更，重新加载')
      this.loadAllSportRecords()
      AppDataManager.resetSportDataStatus()
    } else {
      Log.i('[MyDataPage] 数据无变更，使用现有数据')
      // 如果数据已加载，确保筛选应用
      if (this.sportRecords.length > 0) {
        this.applyFilters()
      }
    }
  }
  
  private loadAllSportRecords() {
    Log.i('[MyDataPage] loadAllSportRecords 被调用, selectedSportType=' + this.selectedSportType)
    if (this.selectedSportType === 0) {
      // 加载所有类型（1-6，不包括瑜伽和跳绳）
      this.allSportTypesQueryCount = 0
      this.allSportTypesData.length = 0
      this.isLoadingAllTypes = true
      Log.i('[MyDataPage] 开始加载所有运动类型数据')
      for (let i = 1; i <= 6; i++) {
        AppDataManager.findSportByType(i, this.sportCallback, false)
      }
    } else {
      Log.i('[MyDataPage] 开始加载运动类型 ' + this.selectedSportType + ' 的数据')
      AppDataManager.findSportByType(this.selectedSportType, this.sportCallback, false)
    }
  }
  
  private applyFilters() {
    let filtered = [...this.sportRecords]
    
    // 时间范围筛选
    if (this.selectedTimeRange !== '全部') {
      const now = new Date()
      const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime()
      
      if (this.selectedTimeRange === '今天') {
        const todayEnd = todayStart + 24 * 60 * 60 * 1000 - 1
        filtered = filtered.filter(r => r.start_time >= todayStart && r.start_time <= todayEnd)
      } else if (this.selectedTimeRange === '本周') {
        const dayOfWeek = now.getDay()
        const weekStart = todayStart - (dayOfWeek === 0 ? 6 : dayOfWeek - 1) * 24 * 60 * 60 * 1000
        filtered = filtered.filter(r => r.start_time >= weekStart)
      } else if (this.selectedTimeRange === '本月') {
        const monthStart = new Date(now.getFullYear(), now.getMonth(), 1).getTime()
        filtered = filtered.filter(r => r.start_time >= monthStart)
      } else if (this.selectedTimeRange === '本年') {
        const yearStart = new Date(now.getFullYear(), 0, 1).getTime()
        filtered = filtered.filter(r => r.start_time >= yearStart)
      }
    }
    
    this.filteredRecords = filtered
    this.calculateStatistics()
  }
  
  private calculateStatistics() {
    this.totalCount = this.filteredRecords.length
    this.totalDuration = 0
    this.totalDistance = 0
    this.totalCalories = 0
    
    for (const record of this.filteredRecords) {
      this.totalDuration += record.use_time
      
      // 计算距离（从步数估算或从卡路里反推）
      const distance = parseFloat(Utils.getDistanceByStep(record.steps))
      this.totalDistance += distance
      
      // 计算卡路里
      const cal = parseFloat(record.cal || '0')
      this.totalCalories += cal > 0 ? cal : (distance * 50) // 如果没有卡路里，用距离估算
    }
  }
  
  private formatDuration(ms: number): string {
    const hours = Math.floor(ms / (3600 * 1000))
    const minutes = Math.floor((ms % (3600 * 1000)) / (60 * 1000))
    if (hours > 0) {
      return `${hours}小时${minutes}分钟`
    }
    return `${minutes}分钟`
  }
  
  private formatDistance(km: number): string {
    if (km >= 1) {
      return km.toFixed(2) + '公里'
    }
    return (km * 1000).toFixed(0) + '米'
  }
  
  private onSportTypeSelected(type: number) {
    this.selectedSportType = type
    this.loadAllSportRecords()
  }
  
  private showTypeFilterDialog() {
    // 每次打开时重新创建，确保选中状态正确
    this.typeFilterDialogController = new CustomDialogController({
      builder: SportTypeSelectDialog({
        selectedType: this.selectedSportType,
        onSelect: (type: number) => {
          this.onSportTypeSelected(type)
        }
      }),
      alignment: DialogAlignment.Center,
      gridCount: 4,
      autoCancel: true
    })
    this.typeFilterDialogController.open()
  }
  
  private onTimeRangeSelected(range: string) {
    this.selectedTimeRange = range
    this.applyFilters()
  }
  
  private openRecordDetail(record: SportModel) {
    // 跳转到运动记录页面，显示该类型的记录
    router.pushUrl({
      url: 'pages/SportRecordPage',
      params: { formData: { type: record.type } }
    })
  }
  
  @Builder buildStatisticsCard() {
    Row() {
      Column() {
        Text(this.formatDuration(this.totalDuration))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Text('运动时长')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      
      Column() {
        Text(this.totalCount.toString())
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Text('运动次数')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      
      Column() {
        Text(this.totalCalories.toFixed(0))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Text('消耗热量')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ top: 0, bottom: 12 })
  }
  
  @Builder buildFilterBar() {
    Row() {
      // 运动类型筛选
      Row() {
        Image(this.sportTypes.find(t => t.id === this.selectedSportType)?.icon || $r('app.media.sport_run'))
          .width(16)
          .height(16)
          .margin({ right: 6 })
        Text(this.sportTypes.find(t => t.id === this.selectedSportType)?.name || '全部')
          .fontSize(14)
          .fontColor('#333333')
        Image($r('app.media.right_point'))
          .width(12)
          .height(12)
          .margin({ left: 4 })
          .fillColor('#999999')
      }
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor('#F8F8F8')
      .borderRadius(8)
      .onClick(() => {
        this.showTypeFilterDialog()
      })
      
      // 时间范围筛选
      Row() {
        ForEach(this.timeRanges, (range: string) => {
          Text(range)
            .fontSize(14)
            .fontColor(this.selectedTimeRange === range ? '#0cc291' : '#666666')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor(this.selectedTimeRange === range ? '#E8F5E8' : '#F8F8F8')
            .borderRadius(8)
            .margin({ left: range === this.timeRanges[0] ? 0 : 8 })
            .onClick(() => {
              this.onTimeRangeSelected(range)
            })
        })
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .margin({ bottom: 12 })
  }
  
  @Builder buildRecordList() {
    if (this.filteredRecords.length === 0) {
      Column() {
        Text('暂无运动记录')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 40, bottom: 40 })
      }
      .width('100%')
    } else {
      Column() {
        ForEach(this.filteredRecords, (record: SportModel, index: number) => {
          this.buildRecordItem(record, index)
        })
      }
      .width('100%')
    }
  }
  
  @Builder buildRecordItem(record: SportModel, index: number) {
    Row() {
      Image(Utils.getSportRecordIcon(record.type))
        .width(40)
        .height(40)
        .margin({ right: 12 })
      
      Column() {
        Row() {
          Text(Utils.getSportRecordName(record.type))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
          Blank()
          Text(this.formatDuration(record.use_time))
            .fontSize(14)
            .fontColor('#0cc291')
        }
        .width('100%')
        .margin({ bottom: 6 })
        
        Row() {
          Text((() => {
            const date = new Date(record.start_time)
            const month = date.getMonth() + 1
            const day = date.getDate()
            const hour = date.getHours()
            const minute = date.getMinutes()
            return `${month}月${day}日 ${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}`
          })())
            .fontSize(12)
            .fontColor('#999999')
          Blank()
          Text(this.formatDistance(parseFloat(Utils.getDistanceByStep(record.steps))))
            .fontSize(12)
            .fontColor('#666666')
            .margin({ right: 8 })
          Text((() => {
            const cal = parseFloat(record.cal || '0')
            return cal > 0 ? cal.toFixed(0) + '千卡' : ''
          })())
            .fontSize(12)
            .fontColor('#666666')
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ top: 16, bottom: 16, left: 0, right: 0 })
    .border({ width: { bottom: index < this.filteredRecords.length - 1 ? 1 : 0 }, color: '#F0F0F0' })
    .onClick(() => {
      this.openRecordDetail(record)
    })
  }
  
  private getSafeTopPadding(): number {
    if (!EntryAbility.myWindowClass) {
      return 0
    }
    const avoidArea = EntryAbility.myWindowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
    return Math.max(0, avoidArea.topRect.height - 80)
  }
  
  @Builder buildCustomTitleBar() {
    Column() {
      if (this.getSafeTopPadding() > 0) {
        Blank()
          .height(this.getSafeTopPadding())
          .backgroundColor('#F5F5F5')
      }
      
      Row() {
        Image($r('app.media.back_btn_dark'))
          .height(28)
          .width(28)
          .onClick(() => {
            router.back()
          })
        
        Text('我的数据')
          .fontSize(18)
          .fontWeight(500)
          .fontColor('#000000')
          .margin({ left: 12 })
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
        
        // 右侧筛选按钮
        Row() {
          Text(this.getSportTypeName(this.selectedSportType))
            .fontSize(14)
            .fontColor('#333333')
          Image($r('app.media.right_point'))
            .width(12)
            .height(12)
            .margin({ left: 4 })
            .fillColor('#666666')
            .rotate({ angle: 90 })
        }
        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
        .backgroundColor('#F0F0F0')
        .borderRadius(4)
        .onClick(() => {
          this.showTypeFilterDialog()
        })
      }
      .height(56)
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .backgroundColor('#F5F5F5')
  }
  
  
  build() {
    Column() {
      // 自定义标题栏，包含右侧筛选按钮（独立组件，位置固定）
      this.buildCustomTitleBar()
      
      // 内容区域（独立组件，可以单独上移）
      Scroll() {
        Column() {
          // 统计卡片
          this.buildStatisticsCard()
          
          // 筛选栏
          this.buildFilterBar()
          
          // 运动记录列表
          this.buildRecordList()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 0 })
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
      .margin({ top: -180 }) // 只让内容上移，不影响标题
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

