import { router } from '@kit.ArkUI'
import { Log } from '../tools/Logger'

@CustomDialog
export struct YSXYDialog {

  controller?: CustomDialogController = undefined
  cancel: () => void = () => {
  }
  confirm: () => void = () => {
  }
  toYSXY: () => void = () => {
  }

  build() {
    Column() {
      Text("欢迎使用微步运动").fontSize(22).margin({ top: 35 }).fontWeight(FontWeight.Bold)
      Text(){
            Span('我们会使用您设备的部分必要权限\n1.为了能能让产品功能正常运行，我们可能会使用存储权限，用于存储您使用中生成的数据，如设置，日志等。\n' +
                '2.未经您同意，我们不会从第三方获取或对外提供您的信息。\n3.更多请查看')
            Span('《用户协议》').fontColor('#0cc291').onClick(() => {
              router.pushUrl({ url: 'pages/XYPage'},router.RouterMode.Single, (err) => {
              })
              this.toYSXY()
            })
            Span('合')
            Span('《隐私政策》').fontColor('#0cc291').onClick(() => {

              router.pushUrl({ url: 'pages/YSPage'},router.RouterMode.Single, (err) => {
              })
              this.toYSXY()
            })
      }.fontSize(15)
        .padding({ top: 25,left:35,right:35,bottom:25 })
      Blank()

      Row() {
        Text('拒绝')
          .width('50%')
          .height(50)
          .backgroundColor('#ffbebebe')
          .fontColor(Color.White)
          .fontSize(16)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.cancel() //调用回调
          })
        Text('同意')
          .width('50%')
          .height(50)
          .backgroundColor('#0cc291')
          .fontColor(Color.White)
          .fontSize(16)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.confirm() //调用回调
          })
      }
    }.width('100%').height('AUTO')
  }
}
