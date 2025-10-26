import { router } from '@kit.ArkUI';
import { SportModel } from '../appdata/Model';
import AppDataManager, { DataCallback } from '../tools/AppDataManager';
import { DateUtils } from '../tools/DateUtils';
import { Log } from '../tools/Logger';
import { Utils } from '../tools/Utils';
import { Common2TitleData, Common2TitleView } from '../view/Common2TitleView';
import { SportTypeDialog } from '../view/SportTypeDialog';
import { SubFragmentData } from '../view/SubFragment';
import { McBarChart, Options } from '@mcui/mccharts';
import { SportRecordDialog } from '../view/SportRecordDialog';
import { CommonTitleView } from '../view/CommonTitleView';

interface SportTypeStat {
  name: string
  count: number
  percentage: number
}

@Entry
@Component
struct SportRecordPage {
  @State currentType: number = 0
  @State data: Array<SportModel> = new Array<SportModel>();
  
  // 统计相关状态
  @State curOffset: number = 0
  @State top_week: string = ''
  @State totalDistance: number = 0
  @State totalTime: number = 0
  @State totalActivities: number = 0
  @State totalCalories: number = 0
  @State selectedMetric: string = '运动次数' // 运动次数、运动时长
  @State timeRange: string = '周' // 周、月、年
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

  // 运动类型占比数据
  @State sportTypeStats: Array<SportTypeStat> = []


  onPageShow(): void {
    let params = router.getParams() as SubFragmentData;
    if (params && params.type !== undefined) {
      this.currentType = params.type
      Log.i('SportRecordPage Received: ' + this.currentType);
    } else {
      // 如果没有参数，使用默认值
      this.currentType = 0 // 显示所有记录
      Log.i('SportRecordPage Using default type: ' + this.currentType);
    }
    this.showWeekSportRecord(this.curOffset)
  }

  exitApp() {

  }

  private sportCallback:DataCallback<SportModel> = {
    onDataResult: (type: number, result: SportModel[], isReturnFirstData: boolean): void => {
      if(isReturnFirstData){
        if(type === 1){

        }
      }else{
        this.data.length = 0
        this.data = result
        this.calculateSportStats()
      }
    }
  }

  private calculateSportStats() {
    this.totalDistance = 0
    this.totalTime = 0
    this.totalActivities = this.data.length
    this.totalCalories = 0

    // 计算运动类型统计
    const typeCount: Map<number, number> = new Map()
    
    for (let item of this.data) {
      this.totalDistance = this.totalDistance + parseFloat(Utils.getDistanceByStep(item.steps))
      this.totalTime = this.totalTime + item.use_time
      // 计算热量消耗（根据步数估算）
      const calories = Math.round(parseFloat(Utils.getDistanceByStep(item.steps)) * 50)
      this.totalCalories = this.totalCalories + calories
      
      // 统计运动类型
      const count = typeCount.get(item.type) || 0
      typeCount.set(item.type, count + 1)
    }

    // 计算运动类型占比
    this.sportTypeStats = []
    typeCount.forEach((count: number, type: number) => {
      const percentage = this.totalActivities > 0 ? (count / this.totalActivities * 100) : 0
      this.sportTypeStats.push({
        name: Utils.getSportRecordName(type),
        count: count,
        percentage: Math.round(percentage * 10) / 10
      })
    })
    
    // 按次数排序
    this.sportTypeStats.sort((a, b) => b.count - a.count)
    
    // 计算每日数据
    let mm_datas = new Array<number>()
    let mm_dates = new Array<string>()
    out: for (let i = 0; i < this.dates.length; i++) {
      mm_dates.push(DateUtils.getWeek(this.dates[i]))
      Log.i('sportCallback mm_dates:' + mm_dates[i])
      let dayValue = 0
      for (let item of this.data) {
        const itemDate = new Date(item.start_time).toISOString().split('T')[0]
        if (this.dates[i] === itemDate) {
          if (this.selectedMetric === '运动次数') {
            dayValue = dayValue + 1
          } else if (this.selectedMetric === '运动时长') {
            dayValue = dayValue + Math.floor(item.use_time / 60) // 转换为分钟
          }
        }
      }
      mm_datas.push(dayValue)
    }
    
    this.seriesRadiusOption.setVal({
      xAxis: { data: mm_dates },
      series: [{ 
        name: this.selectedMetric, 
        barStyle: { 
          width: 10,
          color:'#0cc291',
          borderRadius: [4, 4] 
        }, 
        data: mm_datas 
      }]
    })
  }

  private showWeekSportRecord(i: number) {
    this.top_week = DateUtils.getYMDCH(6 + 7 * i) + ' - ' + DateUtils.getYMDCH(7 * i)
    this.dates.length = 0
    this.dates.push(DateUtils.getYMD_(6 + 7 * i))
    this.dates.push(DateUtils.getYMD_(5 + 7 * i))
    this.dates.push(DateUtils.getYMD_(4 + 7 * i))
    this.dates.push(DateUtils.getYMD_(3 + 7 * i))
    this.dates.push(DateUtils.getYMD_(2 + 7 * i))
    this.dates.push(DateUtils.getYMD_(1 + 7 * i))
    this.dates.push(DateUtils.getYMD_(7 * i))
    
    // 重新加载数据
    AppDataManager.findSportByType(this.currentType, this.sportCallback, false)
  }

  private openAddSportDialog() {
    // 使用简单的页面跳转方式
    router.pushUrl({
      url: 'pages/AddSportPage',
      params: {
        onConfirm: (sportType: number, duration: number, distance: number, calories: number, startTime: number) => {
          // 计算步数（根据距离估算）
          const steps = Math.round(distance * 1000 / 0.6)
          
          // 插入运动记录
          AppDataManager.insertSportRecord(
            startTime,
            duration,
            steps,
            sportType,
            0,
            calories.toString()
          )
          
          // 延迟刷新数据，确保数据库操作完成
          setTimeout(() => {
            this.showWeekSportRecord(this.curOffset)
            Utils.showToast('运动记录添加成功')
          }, 200)
        }
      }
    })
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Image($r('app.media.back_btn_dark'))
          .width(20)
          .height(20)
          .onClick(() => {
            router.back()
          })
        
        // 标题区域 - 使用绝对定位实现居中
        Stack() {
          Text(Utils.getSportRecordTitle(this.currentType))
            .fontSize(18)
            .fontWeight(500)
            .fontColor('#333333')
            .textAlign(TextAlign.Center)
          
          // 右侧按钮组
          Row() {
            Text('▼')
              .fontSize(12)
              .fontColor('#666666')
              .margin({ right: 8 })
              .onClick(() => {
                this.openSportTypeDialog()
              })
            
            Text('运动日历>')
              .fontSize(14)
              .fontColor('#0cc291')
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/SportCalendarPage'
                })
              })
          }
          .position({ x: 0, y: 0 })
          .alignSelf(ItemAlign.End)
        }
        .layoutWeight(1)
        .height(40)
      }
      .width('100%')
      .padding({ top: 16, bottom: 16, left: 20, right: 20 })
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 1 }, color: '#F0F0F0' })
      
      Scroll() {
        Column() {
          // 趋势查看区域
          this.buildTrendSection()
          
          // 信息概览
          this.buildInfoOverview()
          
          // 运动次数占比（仅全部运动时显示）
          if (this.currentType === 0) {
            this.buildSportTypeStats()
          }
          
          // 添加运动按钮
          this.buildAddSportButton()
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildTrendSection() {
    Column() {
      // 趋势查看标题和指标选择
      Row() {
        Text('趋势查看')
          .fontSize(16)
          .fontWeight(500)
          .fontColor('#333333')
          .layoutWeight(1)
        
        Row() {
          Text(this.selectedMetric)
            .fontSize(14)
            .fontColor('#666666')
          Text('▼')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ left: 4 })
        }
        .onClick(() => {
          this.toggleMetric()
        })
      }
      .width('100%')
      .margin({ bottom: 12 })
      
      // 时间范围选择
      Row() {
        ForEach(['周', '月', '年'], (item: string) => {
          Text(item)
            .fontSize(14)
            .fontColor(this.timeRange === item ? '#0cc291' : '#666666')
            .fontWeight(this.timeRange === item ? 500 : 400)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(this.timeRange === item ? '#E8F5E8' : 'transparent')
            .borderRadius(4)
            .onClick(() => {
              this.timeRange = item
            })
        })
      }
      .width('100%')
      .margin({ bottom: 12 })
      
      // 日期范围导航
      Row() {
        Image($r('app.media.back_btn_dark'))
          .width(20)
          .height(20)
          .onClick(() => {
            this.curOffset = this.curOffset + 1
            this.showWeekSportRecord(this.curOffset)
          })
        
        Text(this.top_week)
          .fontSize(14)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        Image($r('app.media.right_btn'))
          .width(20)
          .height(20)
          .onClick(() => {
            this.curOffset = this.curOffset - 1
            this.showWeekSportRecord(this.curOffset)
          })
      }
      .width('100%')
      .margin({ bottom: 12 })
      
      // 当前值显示
      Row() {
        Text(this.getCurrentValue())
          .fontSize(24)
          .fontWeight(600)
          .fontColor('#333333')
        
        Text(this.getCurrentUnit())
          .fontSize(16)
          .fontColor('#666666')
          .margin({ left: 8 })
        
        Text('11月15日')
          .fontSize(14)
          .fontColor('#666666')
          .layoutWeight(1)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .margin({ bottom: 16 })
      
      // 柱状图
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
    .margin({ bottom: 12 })
  }

  @Builder
  buildInfoOverview() {
    Column() {
      Text('信息概览')
        .fontSize(16)
        .fontWeight(500)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 12 })
      
      Row() {
        Column() {
          Text('运动时长')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ bottom: 4 })
          Text((this.totalTime / 60).toFixed(1))
            .fontSize(20)
            .fontWeight(600)
            .fontColor('#333333')
          Text('小时')
            .fontSize(12)
            .fontColor('#666666')
        }
        .layoutWeight(1)
        
        Column() {
          Text('运动次数')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ bottom: 4 })
          Text(this.totalActivities.toString())
            .fontSize(20)
            .fontWeight(600)
            .fontColor('#333333')
          Text('次')
            .fontSize(12)
            .fontColor('#666666')
        }
        .layoutWeight(1)
        
        Column() {
          Text('消耗热量')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ bottom: 4 })
          Text(this.totalCalories.toFixed(0))
            .fontSize(20)
            .fontWeight(600)
            .fontColor('#333333')
          Text('千卡')
            .fontSize(12)
            .fontColor('#666666')
        }
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 12 })
  }

  @Builder
  buildSportTypeStats() {
    Column() {
      Text('运动次数占比')
        .fontSize(16)
        .fontWeight(500)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 12 })
      
      ForEach(this.sportTypeStats, (item: SportTypeStat, index: number) => {
        Row() {
          Text((index + 1).toString())
            .fontSize(14)
            .fontColor('#666666')
            .width(20)
          
          Text(item.name)
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)
            .margin({ left: 8 })
          
          Text(item.count.toString())
            .fontSize(14)
            .fontColor('#333333')
            .margin({ right: 8 })
          
          Text(item.percentage.toFixed(1) + '%')
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
    .margin({ bottom: 12 })
  }

  @Builder
  buildAddSportButton() {
    Button('添加运动')
      .fontSize(16)
      .fontColor('#FFFFFF')
      .backgroundColor('#0cc291')
      .borderRadius(8)
      .width('100%')
      .height(48)
      .onClick(() => {
        this.openAddSportDialog()
      })
      .margin({ bottom: 20 })
  }

  private getCurrentValue(): string {
    if (this.selectedMetric === '运动次数') {
      return this.totalActivities.toString()
    } else if (this.selectedMetric === '运动时长') {
      return Math.floor(this.totalTime / 60).toString()
    }
    return '0'
  }

  private getCurrentUnit(): string {
    if (this.selectedMetric === '运动次数') {
      return '次'
    } else if (this.selectedMetric === '运动时长') {
      return '分钟'
    }
    return ''
  }

  private toggleMetric() {
    if (this.selectedMetric === '运动次数') {
      this.selectedMetric = '运动时长'
    } else {
      this.selectedMetric = '运动次数'
    }
    this.calculateSportStats()
  }

  private openSportTypeDialog() {
    let dialog = new CustomDialogController({ 
      builder: SportTypeDialog({
        onSelect: (type: number) => {
          dialog.close()
          this.currentType = type
          this.showWeekSportRecord(this.curOffset)
        },
        currentIndex: this.currentType,
      }),
      alignment: DialogAlignment.Top,
      gridCount: 4,
      cancel: this.exitApp,
      autoCancel: false,
      backgroundBlurStyle: BlurStyle.NONE,
      backgroundColor: '#ffeaeaea',
      offset: { dx: 0, dy: 50 }
    })
    dialog.open()
  }
}