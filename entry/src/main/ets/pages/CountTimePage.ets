import { router } from '@kit.ArkUI';
import { Log } from '../tools/Logger';
import { systemDateTime } from '@kit.BasicServicesKit';
import { CommonDialog } from '../view/CommonDialog';
import { Utils } from '../tools/Utils';
import { DateUtils } from '../tools/DateUtils';
import { CommonTitleView } from '../view/CommonTitleView';


@Entry
@Component
struct CountTimePage {
  @State tabColor: string = '#ffeaeaea'
  @State currentIndex: number = 0
  private controller: TabsController = new TabsController()
  @State fontColor: string = '#ff484848'
  @State selectedFontColor: string = '#ff000000'
  @State iconSize: number = 110 //按键图标大小
  private isInBackground:boolean = false//是否切换到后台

  @State countTime: string = '00:00:00' //计时器显示文本
  @State isStartCount: boolean = false //计时器开始状态
  @State isCountPause: boolean = false //计时器暂停状态
  @State daBiaos:Array<string> = new Array<string>();
  private startCountTimeStamp:number = 0; //计时器开始的时间戳
  private allCountTimeStamp:number = 0; //计时器开始的时间戳
  private lastCountTimePauseStamp:number = 0; //上次暂停的时间
  private startCountTimeAllPauseStamp:number = 0; //计时器总暂停的时间戳
  private lastDaBiaoMILLISECONDS:number = 0 // 上次打标时间戳

  private hours: string[] = [] //倒计时小时选择列表
  private minus: string[] = [] //倒计时分钟选择列表
  private seconds: string[] = [] //倒计时秒数选择列表

  @State isCountDownStart: boolean = false //倒计时开始状态
  @State isCountDownPause: boolean = false //倒计时暂停状态
  @State countDownText: string = '05:00' //倒计时显示文本
  @State countDownHint: string = '共5分0秒' //倒计时提示文本

  @State countDownHourIndex: number = 0 //倒计时小时列表选择的下标
  @State countDownMinIndex: number = 5 //倒计时分钟列表选择的下标
  @State countDownSecIndex: number = 0 //倒计时秒数列表选择的下标
  private countDownTimeout:number = 0 //倒计时timeout对象，方便取消任务
  private allCountDownSecond:number = 0; //倒计时开始总秒数，毫秒单位
  private switchBackgroundTime:number = 0; //倒计时切换到后台的时间



  // TAB view 的按钮的新建
  @Builder tabBuilder(index: number,title:string) {
    Column() {
      Text(title).padding({top:3 })
        .fontColor(this.currentIndex === index ? this.selectedFontColor : this.fontColor)
        .fontSize(this.currentIndex === index ? 18 : 16).fontWeight(this.currentIndex === index ? 700 : 400)
    }.align(Alignment.Start)
  }

  onPageShow(): void {
    this.isInBackground = false
    if(this.hours.length === 0){
      for (let index = 0; index < 25; index++) {
        this.hours.push(index.toString())
      }
    }
    if(this.minus.length === 0){
      for (let index = 0; index < 61; index++) {
        this.minus.push(index.toString())
      }
    }
    if(this.seconds.length === 0){
      for (let index = 0; index < 61; index++) {
        this.seconds.push(index.toString())
      }
    }
    if(this.isCountDownStart && !this.isCountDownPause){
      //倒计时切换到后台记录时间戳
      if(this.switchBackgroundTime !== 0){
        let backgroundRunningTime = systemDateTime.getTime()-this.switchBackgroundTime;
        Log.i("background running time:"+backgroundRunningTime)
        this.allCountDownSecond = this.allCountDownSecond - backgroundRunningTime
        Log.i("remove background running time allCountDownSecond:"+this.allCountDownSecond)
        if(this.allCountDownSecond<0){
          this.stopCountDown()
          Log.i("background running too long.over countdown")
        }
        this.switchBackgroundTime = 0
      }
    }
  }

  onPageHide(): void {
    this.isInBackground = true
    if(this.isCountDownStart && !this.isCountDownPause){
      //倒计时切换到后台记录时间戳
      this.switchBackgroundTime = systemDateTime.getTime();
      Log.i("start background running time:"+this.switchBackgroundTime)
    }
  }

  /**
   * 开始计时器
   * */
  private startCountTime(){
    this.startCountTimeStamp = systemDateTime.getTime()
    clearTimeout(this.countDownTimeout)
    Utils.keepScreenON(true)
    this.countDownTimeout = setTimeout(() => {
      this.countTiming()
    },10)
  }

  /**
   * 计时器运行中
   * */
  private countTiming(){
    if(!this.isCountPause){
      //总的时间 = 当前时间戳减去开始时间戳减去暂停的时间戳
      this.allCountTimeStamp = systemDateTime.getTime() - this.startCountTimeStamp - this.startCountTimeAllPauseStamp
      this.countTime = DateUtils.convertCountTime(this.allCountTimeStamp)
    }

    this.countDownTimeout = setTimeout(() => {
      this.countTiming()
    },10)
  }

  /**
   * 计时器打标动作
   * */
  private daBiaoAction(){
    let addTime = systemDateTime.getTime() - this.startCountTimeStamp;
    let mm = addTime - this.lastDaBiaoMILLISECONDS;
    this.lastDaBiaoMILLISECONDS = addTime;

    let index = this.daBiaos.length+1
    let daDiaoItem = index+'      '+"+"+DateUtils.convertCountTime(mm)+'      '+DateUtils.convertCountTime(addTime)
    this.daBiaos.push(daDiaoItem)
  }

  onBackPress(): boolean | void {
    if(this.isStartCount){
      this.showSportingDialog1()
      return true
    }
    if(this.isCountDownStart){
      this.showSportingDialog2()
      return true
    }
    return false
  }

  private showSportingDialog1(){
    let dialog = new CustomDialogController({ builder: CommonDialog({
      cancel: ()=> {
        dialog.close()
      },
      confirm: ()=> {
        this.stopCountTime()
        router.back()
        dialog.close()
      },
      title:'退出提示',content:'运动计时中，是否退出？'
    ,}),alignment: DialogAlignment.Center,gridCount:4,cancel: this.exitApp,autoCancel:false })
    dialog.open()
  }

  private showSportingDialog2(){
    let dialog = new CustomDialogController({ builder: CommonDialog({
      cancel: ()=> {
        dialog.close()
      },
      confirm: ()=> {
        this.stopCountDown()
        router.back()
        dialog.close()
      },
      title:'退出提示',content:'运动计时中，是否退出？'
    ,}),alignment: DialogAlignment.Center,gridCount:4,cancel: this.exitApp,autoCancel:false })
    dialog.open()
  }

  exitApp() {

  }

  /**
   * 计时器停止
   * */
  private stopCountTime(){
    Utils.showToast('计时器已经结束')
    Utils.keepScreenON(false)
    this.isStartCount = false
    this.isCountPause = false //计时器暂停状态
    this.daBiaos.length = 0
    this.startCountTimeStamp = 0; //计时器开始的时间戳
    this.allCountTimeStamp = 0; //计时器开始的时间戳
    this.startCountTimeAllPauseStamp = 0; //计时器总暂停的时间戳
    this.lastDaBiaoMILLISECONDS = 0; // 重置上次打标时间戳
    this.countTime = '00:00:00'; // 重置显示时间为初始状态
    clearTimeout(this.countDownTimeout)
  }

  /**
   * 倒计时开始
   * */
  private startCountDown(){
    let hour = parseInt(this.hours[this.countDownHourIndex])
    let minute = parseInt(this.minus[this.countDownMinIndex])
    let second = parseInt(this.seconds[this.countDownSecIndex])

    this.allCountDownSecond = (hour*60*60 + minute*60 + second)*1000
    this.convertCountDownToStr(this.allCountDownSecond)
    clearTimeout(this.countDownTimeout)
    Utils.keepScreenON(true)
    this.countDownTimeout = setTimeout(() => {
      this.countDownTiming()
    },998)
  }

  /**
   * 倒计时运行中
   * */
  private countDownTiming(){
    if(!this.isInBackground){
      if(this.isCountDownPause){
        Log.i('countdown in pause')
      }else{
        if(this.allCountDownSecond === 0){
          Log.i('countdown over')
          this.stopCountDown()
          return
        }else{
          this.allCountDownSecond = this.allCountDownSecond - 1000
          //Log.i('countdown in process')
        }
      }
      this.convertCountDownToStr(this.allCountDownSecond)
    }
    this.countDownTimeout = setTimeout(() => {
      this.countDownTiming()
    },998)
  }

  /**
   * 倒计时结束
   * */
  private stopCountDown(){
    Utils.showToast('倒计时已经结束')
    this.countDownText = '00:00';
    Utils.keepScreenON(false)
    this.isCountDownStart = false
    this.isCountDownPause = false
    this.allCountDownSecond = 0
    clearTimeout(this.countDownTimeout)
  }

  /**
   * 倒计时更新UI
   * */
  private convertCountDownToStr(timeNum:number){
    let text = "";
    let hour = Math.floor(timeNum/(60*60*1000));
    if(hour > 1) {
      text = hour + ":";
    }
    timeNum = timeNum - 60*60*hour*1000;
    let min = Math.floor(timeNum/(60*1000));
    if(min > 9) {
      text = text + min + ":";
    }else{
      text = text + "0" + min + ":";
    }
    timeNum = timeNum - 60*min*1000;
    let second = Math.floor(timeNum/1000);
    if(second > 9) {
      text = text + second;
    }else{
      text = text + "0" + second;
    }
    this.countDownText = text;
  }

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '计时器' },
        cancel: () => {
          router.back()
        }
      })

      Tabs({ barPosition: BarPosition.Start, controller: this.controller }) {
        TabContent() { // 第一个tab页面 start
          Scroll() {
            Column() {
              Text(this.countTime)
                .fontWeight(700)
                .fontSize(64)
                .fontColor('#000000')
                .margin({ bottom: 30, top: 30 })

              if (!this.isStartCount) {
                Column() {
                  Image($r('app.media.start'))
                    .height(this.iconSize)
                    .width(this.iconSize)
                    .onClick(() => {
                      if (this.isCountDownStart) {
                        Utils.showToast('倒计时已经开始')
                        return
                      }
                      this.isStartCount = true
                      this.isCountPause = false
                      Utils.showToast('计时器开始')
                      this.startCountTime()
                    })
                  Text('开始').fontSize(14).fontColor('#666').margin({ top: 8 })
                }
              }

              if (this.isStartCount && !this.isCountPause) {
                Row() {
                  Column() {
                    Image($r('app.media.da_biao'))
                      .height(this.iconSize)
                      .width(this.iconSize)
                      .onClick(() => {
                        this.daBiaoAction()
                      })
                    Text('标记').fontSize(14).fontColor('#666').margin({ top: 8 })
                  }
                  .margin({ left: 30, right: 30 })

                  Column() {
                    Image($r('app.media.pause'))
                      .height(this.iconSize)
                      .width(this.iconSize)
                      .onClick(() => {
                        this.isCountPause = true
                        this.lastCountTimePauseStamp = systemDateTime.getTime()
                      })
                    Text('暂停').fontSize(14).fontColor('#666').margin({ top: 8 })
                  }
                  .margin({ left: 30, right: 30 })
                }
              }

              if (this.isStartCount && this.isCountPause) {
                Row() {
                  Column() {
                    Image($r('app.media.contiue'))
                      .height(this.iconSize)
                      .width(this.iconSize)
                      .onClick(() => {
                        this.isCountPause = false
                        this.startCountTimeAllPauseStamp = this.startCountTimeAllPauseStamp + systemDateTime.getTime() - this.lastCountTimePauseStamp
                      })
                    Text('继续').fontSize(14).fontColor('#666').margin({ top: 8 })
                  }
                  .margin({ left: 30, right: 30 })

                  Column() {
                    Image($r('app.media.stop'))
                      .height(this.iconSize)
                      .width(this.iconSize)
                      .onClick(() => {
                        this.stopCountTime()
                      })
                    Text('停止').fontSize(14).fontColor('#666').margin({ top: 8 })
                  }
                  .margin({ left: 30, right: 30 })
                }
              }

              if (this.daBiaos.length > 0) {
                List() {
                  ForEach(this.daBiaos, (item: string, index: number) => {
                    ListItem() {
                      Text(item)
                        .fontSize(14)
                        .fontColor('#ff4c4c4c')
                        .width('100%')
                        .textAlign(TextAlign.Center)
                    }
                    .padding({ left: 10, right: 10, top: 10, bottom: 6 })
                  })
                }
                .listDirection(Axis.Vertical)
                .alignListItem(ListItemAlign.Start)
                .margin({ top: 30, bottom: 10 })
                .width('88%')
              }
            }
            .alignItems(HorizontalAlign.Center)
            .width('100%')
            .padding({ bottom: 32 })
          }
          .width('100%')
          .height('100%')
          .backgroundColor('#FFFFFF')
        }.tabBar(this.tabBuilder(0, '秒表计时')) //Tab1 按钮

        TabContent() {
          Scroll() {
            Column() {
              Row() {
                TextPicker({ range: this.hours, selected: this.countDownHourIndex })
                  .onChange((value: string | string[], index: number | number[]) => {
                    Log.i('TextPicker 1 ' + JSON.stringify(value) + ', ' + 'index: ' + JSON.stringify(index))
                    this.countDownHourIndex = Number(index)
                  })
                  .divider(null)
                  .width('20%')
                  .disappearTextStyle({ color: Color.Gray, font: { size: 13, weight: FontWeight.Lighter } })
                  .textStyle({ color: Color.Gray, font: { size: 15, weight: FontWeight.Normal } })
                  .selectedTextStyle({ color: Color.Black, font: { size: 25, weight: FontWeight.Bolder } })
                Text('时').fontSize(18).fontWeight(600)
                TextPicker({ range: this.minus, selected: this.countDownMinIndex })
                  .onChange((value: string | string[], index: number | number[]) => {
                    Log.i('TextPicker 2:onChange ' + JSON.stringify(value) + ', ' + 'index: ' + JSON.stringify(index))
                    this.countDownMinIndex = Number(index)
                  })
                  .divider(null)
                  .width('20%')
                  .disappearTextStyle({ color: Color.Gray, font: { size: 13, weight: FontWeight.Lighter } })
                  .textStyle({ color: Color.Gray, font: { size: 15, weight: FontWeight.Normal } })
                  .selectedTextStyle({ color: Color.Black, font: { size: 25, weight: FontWeight.Bolder } })
                Text('分').fontSize(18).fontWeight(600)
                TextPicker({ range: this.seconds, selected: this.countDownSecIndex })
                  .onChange((value: string | string[], index: number | number[]) => {
                    Log.i('TextPicker 3 ' + JSON.stringify(value) + ', ' + 'index: ' + JSON.stringify(index))
                    this.countDownSecIndex = Number(index)
                  })
                  .divider(null)
                  .width('20%')
                  .disappearTextStyle({ color: Color.Grey, font: { size: 13, weight: FontWeight.Lighter } })
                  .textStyle({ color: Color.Grey, font: { size: 15, weight: FontWeight.Normal } })
                  .selectedTextStyle({ color: Color.Black, font: { size: 30, weight: FontWeight.Medium } })
                Text('秒').fontSize(18).fontWeight(600)
              }
              .visibility(!this.isCountDownStart ? Visibility.Visible : Visibility.None)

              Column() {
                Text(this.countDownText).fontSize(64).fontWeight(700).fontColor('#000000')
                Text(this.countDownHint).fontSize(16).fontWeight(400).fontColor('#ff666666').margin({ top: 10 })
              }
              .visibility(this.isCountDownStart ? Visibility.Visible : Visibility.None)
              .margin({ bottom: 30, top: 40 })

              Row() {
                Image($r('app.media.start'))
                  .height(this.iconSize)
                  .width(this.iconSize)
                  .onClick(() => {
                    if (this.isStartCount) {
                      Utils.showToast('计时器已经开始')
                      return
                    }
                    this.isCountDownStart = true
                    this.isCountDownPause = false
                    Utils.showToast('倒计时开始')
                    this.startCountDown()
                  })
                  .margin(30)
                  .visibility(!this.isCountDownStart ? Visibility.Visible : Visibility.None)
                Image($r('app.media.pause'))
                  .height(this.iconSize)
                  .width(this.iconSize)
                  .onClick(() => {
                    this.isCountDownPause = true
                  })
                  .margin(30)
                  .visibility((this.isCountDownStart && !this.isCountDownPause) ? Visibility.Visible : Visibility.None)
                Image($r('app.media.contiue'))
                  .height(this.iconSize)
                  .width(this.iconSize)
                  .onClick(() => {
                    this.isCountDownPause = false
                  })
                  .margin(30)
                  .visibility((this.isCountDownStart && this.isCountDownPause) ? Visibility.Visible : Visibility.None)
                Image($r('app.media.stop'))
                  .height(this.iconSize)
                  .width(this.iconSize)
                  .onClick(() => {
                    this.isCountDownStart = false
                    this.isCountDownPause = false
                    this.stopCountDown()
                  })
                  .margin(30)
                  .visibility(this.isCountDownStart ? Visibility.Visible : Visibility.None)
              }
            }
            .alignItems(HorizontalAlign.Center)
            .width('100%')
            .padding({ top: 24, bottom: 32 })
          }
          .width('100%')
          .height('100%')
          .backgroundColor('#FFFFFF')
        }.tabBar(this.tabBuilder(1, '倒计时')) //Tab2 按钮
      }
      .vertical(false)
      .onTabBarClick((index: number) => {
        this.controller.changeIndex(index)
      })
      .barHeight('7%')
      .barWidth('50%')
      .scrollable(true)
      .onChange((index: number) => {
        this.currentIndex = index
      })
      .backgroundColor('#FFFFFF')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }




}
