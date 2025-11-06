import { Log } from '../tools/Logger';
import { router } from '@kit.ArkUI';
import { SubFragmentData } from '../view/SubFragment';
import { CommonTitleData, CommonTitleView } from '../view/CommonTitleView';
import { Utils } from '../tools/Utils';
import StepData, { StepsCallback } from '../appdata/StepData';
import { CommonDialog } from '../view/CommonDialog';
import systemDateTime from '@ohos.systemDateTime';
import { DateUtils } from '../tools/DateUtils';
import AppDataManager from '../tools/AppDataManager';
import { SqlData } from '../appdata/SqlData';

@Entry
@Component
struct SportingPage {
  @State sportType:number = 0
  @State sportTime:string = '00:00'
  @State sportSteps:string = '0 步'
  @State sportCals:string = '0 Kal'
  @State sportDistance:string = '0.00'
  @State iconSize: number = 70 //按键图标大小
  private startSportStepsNum:number = 0
  private sportStepsNum:number = 0
  private startSportTimeStamp:number = 0
  private allSportTimeStamp:number = 0
  private lastPauseSportTimeStamp:number = 0
  private allPauseSportTimeStamp:number = 0
  private lastPauseSportStep:number = 0
  private allPauseSportStep:number = 0
  @State isSportStart:boolean = false
  @State isSportPause:boolean = false
  private sportTimeout:number = 0 //倒计时timeout对象，方便取消任务

  @State data1: CommonTitleData = {
    str1:''
  };

  private stepsCallback:StepsCallback = {
    onSteps: (steps: number): void => {
      if(!this.isSportStart){
        return
      }
      if(this.isSportPause){
        return
      }
      this.updateStepsView(steps)
    }
  }

  private updateStepsView(steps:number){
    this.sportStepsNum = steps - this.startSportStepsNum - this.allPauseSportStep
    this.sportSteps = this.sportStepsNum + ' 步'
    this.sportCals = Utils.getKalByStep(this.sportStepsNum) + ' Kal'
    this.sportDistance = Utils.getDistanceByStep(this.sportStepsNum)
  }

  private startSport(){
    this.startSportStepsNum = StepData.getCurrentSteps()
    this.startSportTimeStamp = systemDateTime.getTime()
    this.lastPauseSportTimeStamp = 0
    this.allPauseSportTimeStamp = 0
    this.lastPauseSportStep = 0
    this.allPauseSportStep = 0
    clearTimeout(this.sportTimeout)
    Utils.keepScreenON(true)
    this.sportTimeout = setTimeout(() => {
      this.sportingProgress()
    },10)
  }

  private sportingProgress(){
    if(this.isSportPause){

    }else{
      this.allSportTimeStamp = systemDateTime.getTime() - this.startSportTimeStamp - this.allPauseSportTimeStamp
      this.sportTime = DateUtils.convertCountTime(this.allSportTimeStamp)
    }
    this.sportTimeout = setTimeout(() => {
      this.sportingProgress()
    },50)
  }

  /**
   * 停止运动
   * @returns 是否成功保存记录（true=已保存，false=时长不足未保存）
   */
  private stopSport(): boolean {
    Utils.keepScreenON(false)
    
    // 检查运动时长是否少于 1 分钟（60000 毫秒）
    const MIN_DURATION_MS = 60000 // 1 分钟
    if (this.allSportTimeStamp < MIN_DURATION_MS) {
      // 少于 1 分钟，显示提示对话框，不保存记录
      this.showShortDurationDialog()
      // 重置状态但不保存记录
      this.isSportStart = false
      this.isSportPause = false
      this.startSportStepsNum = 0;
      this.startSportTimeStamp = 0;
      this.lastPauseSportTimeStamp = 0;
      this.allPauseSportTimeStamp = 0;
      this.lastPauseSportStep = 0
      this.allPauseSportStep = 0
      clearTimeout(this.sportTimeout)
      return false // 未保存
    }
    
    // 大于等于 1 分钟，正常保存记录
    Utils.showToast('运动已结束')
    AppDataManager.insertSportRecord(this.startSportTimeStamp,this.allSportTimeStamp
        ,this.sportStepsNum,this.sportType,0,this.sportCals)

    this.isSportStart = false
    this.isSportPause = false
    this.startSportStepsNum = 0;
    this.startSportTimeStamp = 0;
    this.lastPauseSportTimeStamp = 0;
    this.allPauseSportTimeStamp = 0;
    this.lastPauseSportStep = 0
    this.allPauseSportStep = 0
    clearTimeout(this.sportTimeout)

    AppDataManager.setSportDataStatus(true,this.sportType)
    return true // 已保存
  }

  private showShortDurationDialog(){
    let dialog = new CustomDialogController({ builder: CommonDialog({
      cancel: ()=> {
        dialog.close()
      },
      confirm: ()=> {
        dialog.close()
      },
      title:'提示',content:'运动时长少于 1 分钟，未记录'
    ,}),alignment: DialogAlignment.Center,gridCount:4,cancel: this.exitApp,autoCancel:false })
    dialog.open()
  }

  onPageShow(): void {
    let params = router.getParams() as SubFragmentData;
    this.sportType = params.type
    this.data1.str1 = Utils.getSportTypeName(this.sportType)
    Log.i('SportingPage Received parameter: ' + params.type + ','+this.data1.str1 );
    StepData.addCallback(this.stepsCallback)
    if (!this.isSportStart) {
      this.isSportStart = true
      this.isSportPause = false
      Utils.showToast('运动已开始')
      this.startSport()
    }
  }

  onPageHide(): void {
    StepData.removeCallback(this.stepsCallback)
  }

  onBackPress(): boolean | void {
    if(this.isSportStart){
      this.showSportingDialog()
      return true
    }
    return false
  }

  private showSportingDialog(){
    let dialog = new CustomDialogController({ builder: CommonDialog({
      cancel: ()=> {
        dialog.close()
      },
      confirm: ()=> {
        dialog.close()
        // 退出时先停止运动（会检查时长并提示）
        const saved = this.stopSport()
        // 只有成功保存记录时才关闭页面
        if (saved) {
          router.back()
        }
        // 如果时长不足，不关闭页面，让用户看到提示对话框
      },
      title:'退出提示',content:this.data1.str1+'中，是否退出？'
    ,}),alignment: DialogAlignment.Center,gridCount:4,cancel: this.exitApp,autoCancel:false })
    dialog.open()
  }

  exitApp() {

  }

  build() {
    Column() {
      CommonTitleView({data1:this.data1,cancel: ()=> {
        if(this.isSportStart){
          this.showSportingDialog()
        }else{
          router.back()
        }
      }})
      Column(){
        Text(this.sportDistance).fontWeight(600).fontSize(52)
        Text('距离/公里').fontWeight(350).fontSize(18)
        Row(){
          Column(){
            Image($r('app.media.count_speed')).width(24).height(24)
            Text(this.sportSteps).fontWeight(400).fontSize(24)
            Text('步数').fontWeight(400).fontSize(12).fontColor('#ff6d6d6d')
          }.width('33.3%')
          Column(){
            Image($r('app.media.count_time')).width(24).height(24)
            Text(this.sportTime).fontWeight(400).fontSize(24)
            Text('时间').fontWeight(400).fontSize(12).fontColor('#ff6d6d6d')
          }.width('33.3%')
          Column(){
            Image($r('app.media.count_kal')).width(24).height(24)
            Text(this.sportCals).fontWeight(400).fontSize(24)
            Text('卡路里/千卡').fontWeight(400).fontSize(12).fontColor('#ff6d6d6d')
          }.width('33.3%')
        }.width('100%').margin(30)

        Row(){
          Image($r('app.media.start')).height(this.iconSize).width(this.iconSize).onClick(() => {
            if(this.isSportStart){
              Utils.showToast('运动已经开始')
              return
            }
            this.isSportStart = true
            this.isSportPause = false
            Utils.showToast('运动已开始')
            this.startSport()
          }).margin(30).visibility(!this.isSportStart?Visibility.Visible:Visibility.None)
          Image($r('app.media.pause')).height(this.iconSize).width(this.iconSize).onClick(() => {
            this.isSportPause = true
            this.lastPauseSportTimeStamp = systemDateTime.getTime()
            this.lastPauseSportStep = StepData.getCurrentSteps()
          }).margin(30).visibility((this.isSportStart&&!this.isSportPause)?Visibility.Visible:Visibility.None)
          Image($r('app.media.contiue')).height(this.iconSize).width(this.iconSize).onClick(() => {
            this.isSportPause = false
            this.allPauseSportTimeStamp = this.allPauseSportTimeStamp+systemDateTime.getTime() - this.lastPauseSportTimeStamp
            this.allPauseSportStep = this.allPauseSportStep+StepData.getCurrentSteps() - this.lastPauseSportStep
          }).margin(30).visibility((this.isSportStart&&this.isSportPause)?Visibility.Visible:Visibility.None)
          Image($r('app.media.stop')).height(this.iconSize).width(this.iconSize).onClick(() => {
            this.isSportStart = false
            this.isSportPause = false
            this.stopSport()
          }).margin(30).visibility(this.isSportStart?Visibility.Visible:Visibility.None)
        }.width('100%').margin(20).justifyContent(FlexAlign.Center)
      }.width('100%').height('92%').justifyContent(FlexAlign.Center)
    }
  }
}
