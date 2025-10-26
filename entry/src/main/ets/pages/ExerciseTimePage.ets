import { CommonTitleView } from '../view/CommonTitleView'
import { router } from '@kit.ArkUI'
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
struct ExerciseTimePage {
  @State curOffset: number = 0
  @State top_week: string = ''
  @State reward_str: string = ''
  @State allMinutes: number = 0
  @State argMinutes: number = 0
  @State targetMinutes: number = 25
  @State currentMinutes: number = 0
  private dates: Array<string> = new Array<string>()
  
  @State seriesRadiusOption: Options = new Options({
    title: { show: true, text: '最近七天的锻炼时长', right: 20, top: 30 },
    xAxis: { data: ['周一', '周二', '周三', '周四', '周五', '周六', '周日']},
    series: [{ name: '时长', barStyle: { 
          width: 10,
          color:'#FFB950',
          borderRadius: [4, 4] },
        data: [0, 0, 0, 0, 0, 0, 0] }]
  })

  // 锻炼时长数据
  @State exerciseData: Array<SportModel> = new Array<SportModel>()

  private exerciseCallback: DataCallback<SportModel> = {
    onDataResult: (type: number, result: SportModel[], isReturnFirstData: boolean): void => {
      this.exerciseData = result
      this.calculateExerciseStats()
    }
  }

  private calculateExerciseStats() {
    this.allMinutes = 0
    let maxMinutes = 0
    let rewardDays = 0

    for (let item of this.exerciseData) {
      const minutes = Math.floor(item.use_time / 60)
      this.allMinutes = this.allMinutes + minutes
      if (minutes >= this.targetMinutes) {
        rewardDays = rewardDays + 1
      }
      if (maxMinutes < minutes) {
        maxMinutes = minutes
      }
    }
    this.argMinutes = this.allMinutes / 7

    // 计算今日锻炼时长（假设是最后一天的数据）
    if (this.exerciseData.length > 0) {
      this.currentMinutes = Math.floor(this.exerciseData[this.exerciseData.length - 1].use_time / 60)
    }

    if (rewardDays > 0) {
      this.reward_str = "本周锻炼达标天数" + rewardDays + "天"
    } else {
      this.reward_str = "最近一周没有一天锻炼达标哦！"
    }
    
    let mm_datas = new Array<number>()
    let mm_dates = new Array<string>()
    out: for (let i = 0; i < this.dates.length; i++) {
      mm_dates.push(DateUtils.getWeek(this.dates[i]))
      Log.i('exerciseCallback mm_dates:' + mm_dates[i])
      for (let item of this.exerciseData) {
        const itemDate = new Date(item.start_time).toISOString().split('T')[0]
        if (this.dates[i] === itemDate) {
          mm_datas.push(Math.floor(item.use_time / 60))
          continue out
        }
      }
      mm_datas.push(0)
    }
    this.seriesRadiusOption.setVal({
      xAxis: { data: mm_dates },
      series: [{ name: '时长', barStyle: { 
            width: 10,
            color:'#FFB950',
            borderRadius: [4, 4] }, data: mm_datas }]
    })
  }

  onPageShow(): void {
    this.loadTargetMinutes()
    this.showWeekExerciseRecord(this.curOffset)
  }

  private async loadTargetMinutes() {
    await targetManager.loadTargets()
    this.targetMinutes = targetManager.getTarget('exercise_time_target')
  }

  async onTargetModified(newValue: number) {
    await targetManager.updateTarget('exercise_time_target', newValue)
    this.targetMinutes = newValue
    this.calculateExerciseStats()
  }

  showWeekExerciseRecord(i: number) {
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
    appDataManager.findSportByType(1, this.exerciseCallback, false) // 室内跑
    appDataManager.findSportByType(2, this.exerciseCallback, false) // 室外跑
    appDataManager.findSportByType(3, this.exerciseCallback, false) // 健走
    appDataManager.findSportByType(4, this.exerciseCallback, false) // 徒步
    appDataManager.findSportByType(5, this.exerciseCallback, false) // 登山
  }

  build() {
    Column() {
      CommonTitleView({data1:{str1:'锻炼时长统计'},cancel:()=>{
          router.back()
      }})
      Scroll(){
        Column(){
          Row(){
            Image($r('app.media.back_btn_dark')).width(20).height(20).margin(5).onClick(() => {
              this.curOffset = this.curOffset + 1
              this.showWeekExerciseRecord(this.curOffset)
            })
            Text(this.top_week).fontSize(14)
            Image($r('app.media.right_btn')).width(20).height(20).margin(5).onClick(() => {
              this.curOffset = this.curOffset - 1
              this.showWeekExerciseRecord(this.curOffset)
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
            targetName: '锻炼时长',
            currentValue: this.currentMinutes,
            targetValue: this.targetMinutes,
            unit: '分钟'
          })
          .margin({ top: 12 })
          Row(){
            Text(){
              Span('总时长\n')
              Span(this.allMinutes.toString()).fontWeight(600).fontSize(30)
              Span('分钟')
            }.margin({ top:8,bottom:10,right:5 }).layoutWeight(1).borderRadius(15).padding(15).backgroundColor($r('sys.color.white'))
            Text(){
              Span('平均每日时长\n')
              Span(this.argMinutes.toFixed(0)).fontWeight(600).fontSize(30)
              Span('分钟')
            }.margin({ left:5,top:8,bottom:10}).layoutWeight(1).borderRadius(15).padding(15).backgroundColor($r('sys.color.white'))
          }.margin({top:10}).width('92%')
        }.width('100%').height('91%')
      }
    }
  }
}
