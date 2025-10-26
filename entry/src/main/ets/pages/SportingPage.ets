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
  @State iconSize: number = 90 //按键图标大小
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

  private stopSport(){
    Utils.showToast('运动已结束')
    Utils.keepScreenON(false)
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
  }

  onPageShow(): void {
    let params = router.getParams() as SubFragmentData;
    this.sportType = params.type
    this.data1.str1 = Utils.getSportTypeName(this.sportType)
    Log.i('SportingPage Received parameter: ' + params.type + ','+this.data1.str1 );
    StepData.addCallback(this.stepsCallback)
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
        router.back()
        dialog.close()
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
        Text(this.sportDistance).fontWeight(600).fontSize(60)
        Text('距离/公里').fontWeight(350).fontSize(20)
        Row(){
          Column(){
            Image($r('app.media.count_speed')).width(30).height(30)
            Text(this.sportSteps).fontWeight(400).fontSize(32)
            Text('步数').fontWeight(400).fontSize(13).fontColor('#ff6d6d6d')
          }.width('33.3%')
          Column(){
            Image($r('app.media.count_time')).width(30).height(30)
            Text(this.sportTime).fontWeight(400).fontSize(32)
            Text('时间').fontWeight(400).fontSize(13).fontColor('#ff6d6d6d')
          }.width('33.3%')
          Column(){
            Image($r('app.media.count_kal')).width(30).height(30)
            Text(this.sportCals).fontWeight(400).fontSize(32)
            Text('卡路里/千卡').fontWeight(400).fontSize(13).fontColor('#ff6d6d6d')
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