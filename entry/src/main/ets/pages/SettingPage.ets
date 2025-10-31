// import web_webview from '@ohos.web.webview';
import { CommonTitleView } from '../view/CommonTitleView';
import { router } from '@kit.ArkUI';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { Utils } from '../tools/Utils';
import { bundleManager } from '@kit.AbilityKit';
import { Log } from '../tools/Logger';
import { SettingItemView } from '../view/SettingItemView';

@Entry
@Component
struct SettingPage {
  @State version:string = '1.0.1'

  onPageShow(): void {
    bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION).then((bundleInfo)=>{
      this.version = bundleInfo.versionName;//应用版本名
    }).catch((error: BusinessError )=>{
      Log.i("get bundleInfo failed,error is "+error)
    })
  }

  build() {
    Column() {
      CommonTitleView({data1:{str1:'设置'},cancel:()=>{
        router.back()
      }})
      Column(){
        Column(){
          Row(){
            Text('用户协议').layoutWeight(1)
            Image($r('app.media.right_point')).width(15).height(15)
          }.width('100%').padding(12).onClick(() => {
            router.pushUrl({ url: 'pages/XYPage' })
          })
          Row(){
            Text('隐私协议').layoutWeight(1)
            Image($r('app.media.right_point')).width(15).height(15)
          }.width('100%').padding(12).onClick(() => {
            router.pushUrl({ url: 'pages/YSPage' })
          })
        }.width('91%').margin(15).borderRadius(15).backgroundColor('#ffffff')

        Column(){
          Row(){
            Text('公众号').layoutWeight(1)
            Text('微小目标(micro-target)').fontColor('#ff676767')
          }.width('100%').padding(12).onClick(() => {
            const shardedUrl = "micro-target"
            const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, shardedUrl)
            const systemPasteboard = pasteboard.getSystemPasteboard()
            systemPasteboard.setData(pasteboardData)
            Utils.showToast('已复制micro-target到剪贴板')
          })
          Row(){
            Text('版本号').layoutWeight(1)
            Text(this.version).fontColor('#ff676767')
          }.width('100%').padding(12)
        }.width('91%').margin(15).borderRadius(15).backgroundColor('#ffffff')
      }.width('100%').height('91%')
    }
  }
}