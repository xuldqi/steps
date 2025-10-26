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
struct StepTrendPage {
  @State curOffset: number = 0
  @State top_week: string = ''
  @State reward_str: string = ''
  @State allSteps: number = 0
  @State argSteps: number = 0
  @State targetSteps: number = 5000
  @State currentSteps: number = 0
  private dates: Array<string> = new Array<string>()
  
  @State seriesRadiusOption: Options = new Options({
    title: { show: true, text: '最近七天的步数统计', right: 20, top: 30 },
    xAxis: { data: ['周一', '周二', '周三', '周四', '周五', '周六', '周日']},
    series: [{ name: '步数', barStyle: { 
          width: 10,
          color:'#0cc291',
          borderRadius: [4, 4] },
        data: [0, 0, 0, 0, 0, 0, 0] }]
  })

  // 步数数据
  @State stepChartData: Array<PerStepModel> = new Array<PerStepModel>()

  private stepCallback: DataCallback<PerStepModel> = {
    onDataResult: (type: number, result: PerStepModel[], isReturnFirstData: boolean): void => {
      this.stepChartData = result
      this.calculateStepStats()
    }
  }

  private calculateStepStats() {
    this.allSteps = 0
    let maxSteps = 0
    let rewardDays = 0

    for (let item of this.stepChartData) {
      this.allSteps = this.allSteps + item.steps
      if (item.steps >= this.targetSteps) {
        rewardDays = rewardDays + 1
      }
      if (maxSteps < item.steps) {
        maxSteps = item.steps
      }
    }
    this.argSteps = this.allSteps / 7

    // 计算今日步数（假设是最后一天的数据）
    if (this.stepChartData.length > 0) {
      this.currentSteps = this.stepChartData[this.stepChartData.length - 1].steps
    }

    if (rewardDays > 0) {
      this.reward_str = "本周步数达标天数" + rewardDays + "天"
    } else {
      this.reward_str = "最近一周没有一天步数达标哦！"
    }
    
    let mm_datas = new Array<number>()
    let mm_dates = new Array<string>()
    out: for (let i = 0; i < this.dates.length; i++) {
      mm_dates.push(DateUtils.getWeek(this.dates[i]))
      Log.i('stepCallback mm_dates:' + mm_dates[i])
      for (let item of this.stepChartData) {
        if (this.dates[i] === item.date) {
          mm_datas.push(item.steps)
          continue out
        }
      }
      mm_datas.push(0)
    }
    this.seriesRadiusOption.setVal({
      xAxis: { data: mm_dates },
      series: [{ name: '步数', barStyle: { 
            width: 10,
            color:'#0cc291',
            borderRadius: [4, 4] }, data: mm_datas }]
    })
  }

  onPageShow(): void {
    Log.i('StepTrendPage onPageShow called')
    this.loadTargetSteps()
    this.showWeekStepRecord(this.curOffset)
  }

  private async loadTargetSteps() {
    await targetManager.loadTargets()
    this.targetSteps = targetManager.getTarget('step_target')
  }

  async onTargetModified(newValue: number) {
    await targetManager.updateTarget('step_target', newValue)
    this.targetSteps = newValue
    this.calculateStepStats()
  }

  showWeekStepRecord(i: number) {
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
    appDataManager.getStepPerDayWeekList(this.stepCallback)
  }

  build() {
    Column() {
      CommonTitleView({data1:{str1:'步数趋势统计'},cancel:()=>{
          router.back()
      }})
      Scroll(){
        Column(){
          Row(){
            Image($r('app.media.back_btn_dark')).width(20).height(20).margin(5).onClick(() => {
              this.curOffset = this.curOffset + 1
              this.showWeekStepRecord(this.curOffset)
            })
            Text(this.top_week).fontSize(14)
            Image($r('app.media.right_btn')).width(20).height(20).margin(5).onClick(() => {
              this.curOffset = this.curOffset - 1
              this.showWeekStepRecord(this.curOffset)
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
            targetName: '步数',
            currentValue: this.currentSteps,
            targetValue: this.targetSteps,
            unit: '步'
          })
          .margin({ top: 12 })
          Row(){
            Text(){
              Span('总步数\n')
              Span(this.allSteps.toString()).fontWeight(600).fontSize(30)
              Span('步')
            }.margin({ top:8,bottom:10,right:5 }).layoutWeight(1).borderRadius(15).padding(15).backgroundColor('#FFFFFF')
            Text(){
              Span('平均每日步数\n')
              Span(this.argSteps.toFixed(0)).fontWeight(600).fontSize(30)
              Span('步')
            }.margin({ left:5,top:8,bottom:10}).layoutWeight(1).borderRadius(15).padding(15).backgroundColor('#FFFFFF')
          }.margin({top:10}).width('92%')
        }.width('100%').height('91%')
      }
    }
  }
}