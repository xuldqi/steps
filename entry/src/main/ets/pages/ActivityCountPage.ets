import { CommonTitleView } from '../view/CommonTitleView'
import { router, window } from '@kit.ArkUI'
import appDataManager, { DataCallback } from '../tools/AppDataManager'
import { SportModel } from '../appdata/Model'
import { Log } from '../tools/Logger'
import { DateUtils } from '../tools/DateUtils'
import { McBarChart, Options } from '@mcui/mccharts'
import { TargetProgressView } from '../view/TargetModifyDialog'
import preferencesUtil from '../tools/DataPreUtils'
import targetManager, { TargetValue } from '../tools/TargetManager'

@Entry
@Component
struct ActivityCountPage {
  @State curOffset: number = 0
  @State top_week: string = ''
  @State reward_str: string = ''
  @State allActivities: number = 0
  @State argActivities: number = 0
  @State targetActivities: number = 12
  @State currentActivities: number = 0
  private dates: Array<string> = new Array<string>()
  
  @State seriesRadiusOption: Options = new Options({
    title: { show: true, text: '次', right: 20, top: 30 },
    xAxis: { data: ['周一', '周二', '周三', '周四', '周五', '周六', '周日']},
    series: [{ name: '次数', barStyle: { 
          width: 10,
          color:'#C7C9CC',
          borderRadius: [4, 4] },
        data: [0, 0, 0, 0, 0, 0, 0] }]
  })

  // 活动次数数据
  @State activityData: Array<SportModel> = new Array<SportModel>()

  private activityCallback: DataCallback<SportModel> = {
    onDataResult: (type: number, result: SportModel[], isReturnFirstData: boolean): void => {
      this.activityData = result
      this.calculateActivityStats()
    }
  }

  private calculateActivityStats() {
    // 先按日期聚合数据
    const dailyActivities: Map<string, number> = new Map()
    for (const item of this.activityData) {
      const itemDate = DateUtils.timeToDateNoYM2(item.start_time)
      const existing = dailyActivities.get(itemDate) ?? 0
      dailyActivities.set(itemDate, existing + 1)
    }

    // 从聚合数据计算统计数据
    this.allActivities = 0
    let maxActivities = 0
    let rewardDays = 0
    for (const count of dailyActivities.values()) {
      this.allActivities = this.allActivities + count
      if (count >= this.targetActivities) {
        rewardDays = rewardDays + 1
      }
      if (maxActivities < count) {
        maxActivities = count
      }
    }
    this.argActivities = this.allActivities / 7

    // 计算今日活动次数（从聚合数据中获取）
    const todayDate = DateUtils.getYMD()
    this.currentActivities = dailyActivities.get(todayDate) ?? 0

    if (rewardDays > 0) {
      this.reward_str = "本周活动达标天数" + rewardDays + "天"
    } else {
      this.reward_str = "最近一周没有一天活动达标哦！"
    }
    
    let mm_datas = new Array<number>()
    let mm_dates = new Array<string>()
    for (let i = 0; i < this.dates.length; i++) {
      mm_dates.push(DateUtils.getWeek(this.dates[i]))
      mm_datas.push(dailyActivities.get(this.dates[i]) ?? 0)
    }
    this.seriesRadiusOption.setVal({
      xAxis: { data: mm_dates },
      series: [{ name: '次数', barStyle: { 
            width: 10,
            color:'#C7C9CC',
            borderRadius: [4, 4] }, data: mm_datas }]
    })
  }

  onPageShow(): void {
    this.loadTargetActivities()
    targetManager.addListener(this.onTargetsChanged)
    this.showWeekActivityRecord(this.curOffset)
  }

  aboutToDisappear(): void {
    targetManager.removeListener(this.onTargetsChanged)
  }

  private onTargetsChanged = (targets: TargetValue) => {
    const target = targets.activity_count_target
    if (this.targetActivities !== target) {
      this.targetActivities = target
      this.calculateActivityStats()
    }
  }

  private async loadTargetActivities() {
    await targetManager.loadTargets()
    this.targetActivities = targetManager.getTarget('activity_count_target')
  }

  async onTargetModified(newValue: number) {
    await targetManager.updateTarget('activity_count_target', newValue)
    this.targetActivities = newValue
    this.calculateActivityStats()
  }

  showWeekActivityRecord(i: number) {
    this.top_week = DateUtils.getYMDCH(6 + 7 * i) + ' - ' + DateUtils.getYMDCH(7 * i)
    this.dates.length = 0
    this.dates.push(DateUtils.getYMD_(6 + 7 * i))
    this.dates.push(DateUtils.getYMD_(5 + 7 * i))
    this.dates.push(DateUtils.getYMD_(4 + 7 * i))
    this.dates.push(DateUtils.getYMD_(3 + 7 * i))
    this.dates.push(DateUtils.getYMD_(2 + 7 * i))
    this.dates.push(DateUtils.getYMD_(1 + 7 * i))
    this.dates.push(DateUtils.getYMD_(7 * i))
    
    // 获取所有运动数据
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

  build() {
    Column() {
      CommonTitleView({data1:{str1:'活动次数统计'},cancel:()=>{
          router.back()
      }})
      Scroll(){
        Column(){
          Row(){
            Image($r('app.media.back_btn_dark')).width(20).height(20).margin(5).onClick(() => {
              this.curOffset = this.curOffset + 1
              this.showWeekActivityRecord(this.curOffset)
            })
            Text(this.top_week).fontSize(14)
            Image($r('app.media.right_btn')).width(20).height(20).margin(5).onClick(() => {
              this.curOffset = this.curOffset - 1
              this.showWeekActivityRecord(this.curOffset)
            })
          }.margin(7)
                 Row(){
                   Image($r('app.media.week_report_reward')).width(18).height(18)
                   Text(this.reward_str).fontSize(12).fontColor('#ff3e3e3e')
                 }
                
          // 先展示柱状图（白色卡片）
          Column(){
            Row() {
              McBarChart({
                options: this.seriesRadiusOption
              })
            }
            .height('30%')
          }
          .width('92%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .padding(16)
          .margin({ top: 12 })

          // 然后目标进度（白色卡片）
          Column(){
            TargetProgressView({
              targetName: '次',
              currentValue: this.currentActivities,
              targetValue: this.targetActivities,
              unit: '次'
            })
          }
          .width('92%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .padding(16)
          .margin({ top: 12 })
          Row(){
            Text(){
              Span('总次数\n')
              Span(this.allActivities.toString()).fontWeight(600).fontSize(30)
              Span('次')
            }.margin({ top:8,bottom:10,right:5 }).layoutWeight(1).borderRadius(15).padding(15).backgroundColor($r('sys.color.white'))
            Text(){
              Span('平均每日次数\n')
              Span(this.argActivities.toFixed(0)).fontWeight(600).fontSize(30)
              Span('次')
            }.margin({ left:5,top:8,bottom:10}).layoutWeight(1).borderRadius(15).padding(15).backgroundColor($r('sys.color.white'))
          }.margin({top:10}).width('92%')
        }.width('100%').height('91%')
      }
    }
    .backgroundColor('#F5F5F5')
  }
}
