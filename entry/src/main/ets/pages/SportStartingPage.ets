import web_webview from '@ohos.web.webview';
import EntryAbility from '../entryability/EntryAbility';
import { router } from '@kit.ArkUI';
import { SubFragmentData } from '../view/SubFragment';
import { Log } from '../tools/Logger';

@Entry
@Component
struct SportingPage {
  @State countDown:string = '3'
  @State fontS:number = 200
  private timeID:number = 0
  private params:SubFragmentData = {
    type:1,
    curTarget:'',
    subTopTitle:'',
    subTopData:'',
    subBotData: '',
  }

  onPageShow(): void {
    this.params = router.getParams() as SubFragmentData;
    Log.i('Received parameter: ' + this.params.type);


    this.fontS = 50
    this.timeID = setInterval(()=>{
      let num = parseInt(this.countDown)
      num = num-1
      if(num == 0){
        this.countDown = 'GO'
        clearInterval(this.timeID)
        router.replaceUrl({ url: 'pages/SportingPage',params: this.params, })

      }else{
        this.countDown = num.toString()

      }
    },1000)
  }

  onBackPress(): boolean | void {
    return true
  }

  build() {
    Stack() {
      Text(this.countDown).fontColor('#0cc291').fontWeight(700).fontSize(this.fontS).textAlign(TextAlign.Center)
        .animation({
          duration:1000,   //播放时长
          curve:Curve.Linear, //动画曲线
          iterations:4,   // 播放次数 -1为无限播放
          playMode:PlayMode.Normal  //动画在奇数次（1、3、5...）正向播放，在偶数次（2、4、6...）反向播放。
        })
    }.width("100%").height('100%').backgroundColor("#00000000").alignContent(Alignment.Center)
  }
}