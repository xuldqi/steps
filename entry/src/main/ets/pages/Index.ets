import router from '@ohos.router'
import { Log } from '../tools/Logger'
import { YSXYDialog } from '../view/YSXYDialog'
import preferencesUtil from '../tools/DataPreUtils'
import { common } from '@kit.AbilityKit'
import { Utils } from '../tools/Utils'
import EntryAbility from '../entryability/EntryAbility'
import { window } from '@kit.ArkUI'
import { AppStateStore } from '../services/AppStateStore'

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
      void this.jumpToMain();
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
        void this.jumpToMain();
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

  private async jumpToMain(){
    // 尝试静默登录，失败时继续跳转首页由用户主动登录
    if (!AppStateStore.getInstance().isUserLoggedIn()) {
      try {
        await AppStateStore.getInstance().autoLogin();
      } catch (error) {
        Log.e('[Index] 自动登录失败:' + JSON.stringify(error));
      }
    }
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
      .width('100%')
      .layoutWeight(1)
      .alignContent(Alignment.Center)
      Row() {
        Image($r('app.media.icon'))
          .height(64)
          .width(64)
          .borderRadius(10)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ bottom: this.getSafeBottomPadding() })
    }
    .width('100%')
    .height('100%')
  }

  private getSafeBottomPadding(): number {
    if (!EntryAbility.myWindowClass) {
      return 48
    }
    const avoidArea = EntryAbility.myWindowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
    return Math.max(48, avoidArea.bottomRect.height + 24)
  }
}
