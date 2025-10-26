import { CommonTitleView } from '../view/CommonTitleView'
import { router } from '@kit.ArkUI'
import { McBarChart, Options } from '@mcui/mccharts'
import appDataManager, { DataCallback } from '../tools/AppDataManager'
import { PerStepModel } from '../appdata/Model'
import { DateUtils } from '../tools/DateUtils'
import { Log } from '../tools/Logger'
import { TargetProgressView } from '../view/TargetModifyDialog'
import preferencesUtil from '../tools/DataPreUtils'
import targetManager, { TargetValue } from '../tools/TargetManager'

@Entry
@Component
struct ChartPage {
  @State curOffset: number = 0
  @State top_week: string = ''
  @State reward_str: string = ''
  @State allCalories: number = 0
  @State argCalories: number = 0
  @State targetCalories: number = 300
  @State currentCalories: number = 0
  private dates: Array<string> = new Array<string>()
  
  @State seriesRadiusOption: Options = new Options({
    title: { show: true, text: '最近七天的热量消耗', right: 20, top: 30 },
    xAxis: { data: ['周一', '周二', '周三', '周四', '周五', '周六', '周日']},
    series: [{ name: '热量', barStyle: { 
          width: 10,
          color:'#FF8C47',
          borderRadius: [4, 4] },
        data: [0, 0, 0, 0, 0, 0, 0] }]
  })

  // 热量数据
  @State calorieChartData: Array<PerStepModel> = new Array<PerStepModel>()

  private calorieCallback: DataCallback<PerStepModel> = {
    onDataResult: (type: number, result: PerStepModel[], isReturnFirstData: boolean): void => {
      this.calorieChartData = result
      this.calculateCalorieStats()
    }
  }

  private calculateCalorieStats() {
    this.allCalories = 0
    let maxCalories = 0
    let rewardDays = 0

    for (let item of this.calorieChartData) {
      const calories = Math.round(item.steps / 1000 * 50)
      this.allCalories = this.allCalories + calories
      if (calories >= this.targetCalories) {
        rewardDays = rewardDays + 1
      }
      if (maxCalories < calories) {
        maxCalories = calories
      }
    }
    this.argCalories = this.allCalories / 7

    // 计算今日热量（假设是最后一天的数据）
    if (this.calorieChartData.length > 0) {
      this.currentCalories = Math.round(this.calorieChartData[this.calorieChartData.length - 1].steps / 1000 * 50)
    }

    if (rewardDays > 0) {
      this.reward_str = "本周热量达标天数" + rewardDays + "天"
    } else {
      this.reward_str = "最近一周没有一天热量达标哦！"
    }
    
    let mm_datas = new Array<number>()
    let mm_dates = new Array<string>()
    out: for (let i = 0; i < this.dates.length; i++) {
      mm_dates.push(DateUtils.getWeek(this.dates[i]))
      Log.i('calorieCallback mm_dates:' + mm_dates[i])
      for (let item of this.calorieChartData) {
        if (this.dates[i] === item.date) {
          mm_datas.push(Math.round(item.steps / 1000 * 50))
          continue out
        }
      }
      mm_datas.push(0)
    }
    this.seriesRadiusOption.setVal({
      xAxis: { data: mm_dates },
      series: [{ name: '热量', barStyle: { 
            width: 10,
            color:'#FF8C47',
            borderRadius: [4, 4] }, data: mm_datas }]
    })
  }

  onPageShow(): void {
    Log.i('ChartPage onPageShow called')
    this.loadTargetCalories()
    this.showWeekCalorieRecord(this.curOffset)
  }

  private async loadTargetCalories() {
    await targetManager.loadTargets()
    this.targetCalories = targetManager.getTarget('calorie_target')
  }

  async onTargetModified(newValue: number) {
    await targetManager.updateTarget('calorie_target', newValue)
    this.targetCalories = newValue
    this.calculateCalorieStats()
  }

  showWeekCalorieRecord(i: number) {
    this.top_week = DateUtils.getYMDCH(6 + 7 * i) + ' - ' + DateUtils.getYMDCH(7 * i)
    this.dates.length = 0
    this.dates.push(DateUtils.getYMD_(6 + 7 * i))
    this.dates.push(DateUtils.getYMD_(5 + 7 * i))
    this.dates.push(DateUtils.getYMD_(4 + 7 * i))
    this.dates.push(DateUtils.getYMD_(3 + 7 * i))
    this.dates.push(DateUtils.getYMD_(2 + 7 * i))
    this.dates.push(DateUtils.getYMD_(1 + 7 * i))
    this.dates.push(DateUtils.getYMD_(7 * i))
    
    // 获取步数数据
    appDataManager.getStepPerDayWeekList(this.calorieCallback)
  }

  build() {
    Column() {
      CommonTitleView({data1:{str1:'热量消耗统计'},cancel:()=>{
          router.back()
      }})
      Scroll(){
        Column(){
          Row(){
            Image($r('app.media.back_btn_dark')).width(20).height(20).margin(5).onClick(() => {
              this.curOffset = this.curOffset + 1
              this.showWeekCalorieRecord(this.curOffset)
            })
            Text(this.top_week).fontSize(14)
            Image($r('app.media.right_btn')).width(20).height(20).margin(5).onClick(() => {
              this.curOffset = this.curOffset - 1
              this.showWeekCalorieRecord(this.curOffset)
            })
          }.margin(7)
                 Row(){
                   Image($r('app.media.week_report_reward')).width(18).height(18)
                   Text(this.reward_str).fontSize(12).fontColor('#ff3e3e3e')
                 }
          Row() {
            McBarChart({
              options: this.seriesRadiusOption
            })
          }.height('30%').margin({top:8})
          
          // 目标进度
          TargetProgressView({
            targetName: '热量',
            currentValue: this.currentCalories,
            targetValue: this.targetCalories,
            unit: '千卡'
          })
          .margin({ top: 12 })
          Row(){
            Text(){
              Span('总消耗\n')
              Span(this.allCalories.toString()).fontWeight(600).fontSize(30)
              Span('千卡')
            }.margin({ top:8,bottom:10,right:5 }).layoutWeight(1).borderRadius(15).padding(15).backgroundColor('#FFFFFF')
            Text(){
              Span('平均每日消耗\n')
              Span(this.argCalories.toFixed(0)).fontWeight(600).fontSize(30)
              Span('千卡')
            }.margin({ left:5,top:8,bottom:10}).layoutWeight(1).borderRadius(15).padding(15).backgroundColor('#FFFFFF')
          }.margin({top:10}).width('92%')
        }.width('100%').height('91%')
      }
    }
  }
}
