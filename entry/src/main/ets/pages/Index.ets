import router from '@ohos.router'
import {Log} from '../tools/Logger'
import { YSXYDialog } from '../view/YSXYDialog'
import preferencesUtil from '../tools/DataPreUtils'
import { common } from '@kit.AbilityKit'
import { Utils } from '../tools/Utils'

@Entry
@Component
struct Index {
  @State timerId:number = 0

  private dialog = new CustomDialogController({ builder: YSXYDialog({
    cancel: ()=> { this.onCancel() },
    confirm: ()=> { this.onAccept() },
    toYSXY: ()=> { this.onYSXY() }
  ,}),alignment: DialogAlignment.Center,gridCount:4,cancel: this.exitApp,autoCancel:false })

  onCancel() {
    this.dialog.close()
    let context = getContext() as common.UIAbilityContext;
    context.terminateSelf()
  }

  onAccept() {
    preferencesUtil.putPreferenceValue('steps_ohos', 'isFirstOpenApp', false)
    preferencesUtil.putPreferenceValue('steps_ohos', 'step_target', 5000)
    this.dialog.close()
    this.timerId = setTimeout(() => {
      Log.i('jump main delay 3s');
      this.jumpToMain();
    }, 1000);
  }

  onYSXY() {
    this.dialog.close()
  }

  exitApp() {

  }

  async onPageShow(){
    let isFirst = await preferencesUtil.getPreferenceValue('steps_ohos', 'isFirstOpenApp', true) as boolean
    if(isFirst){
      if(this.dialog != null){
        this.dialog.open()
      }
    }else{
      this.timerId = setTimeout(() => {
        Log.i('jump main delay 3s');
        this.jumpToMain();
      }, 1000);
    }

  }

  onPageHide(){
    Log.i('onPageHide');
    clearInterval(this.timerId)
  }

  onBackPress(){
    Log.i('onBackPress');
  }

  jumpToMain(){
    router.replaceUrl({ url: 'pages/MainTabs'},router.RouterMode.Single, (err) => {
      if (err) {
        Log.e(`Click Invoke pushUrl failed, code is ${err.code}, message is ${err.message}`);
        return;
      }
      Log.i('Click Invoke pushUrl succeeded.');
    })
  }

  build() {
    Column(){
      Stack() {
        Text(){
          Span('在\n')
          Span('于\n')
          Span('运\n')
          Span('动\n')
          Span('。')
        }.fontSize(15).width(20).height(130).margin({right:20}).align(Alignment.TopStart)
        Text('生\n命\n,')
          .fontSize(15).width(20).height(130).margin({left:20}).align(Alignment.TopStart)
      }
      .height('92%').width('100%').alignContent(Alignment.Center)
      Stack() {
        Image($r('app.media.icon')).height('70%').width('AUTO').borderRadius(10)
      }.height('8%').width('100%').alignContent(Alignment.Center)
    }
  }
}