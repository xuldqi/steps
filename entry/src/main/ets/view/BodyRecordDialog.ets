import { Log } from '../tools/Logger'
import { Utils } from '../tools/Utils'
import RuleView from './RuleView'

@CustomDialog
export struct BodyRecordDialog {

  @State title:string = ''
  @State unit:string = ''
  @State content:string = ''
  @State bodyType:number = 1
  @State startNum:number = 50
  @State endNum:number = 1000
  @State stepNum:number = 1
  @State selectNum:number = 100
  private curValue:number = 0

  controller?: CustomDialogController = undefined
  cancel: () => void = () => {
  }
  confirm: (data:number,bodyType:number) => void = () => {
  }

  aboutToAppear() {
    // 初始化 curValue 为 selectNum，确保即使用户没有滚动也能获取到正确的值
    this.curValue = this.selectNum
  }

  build() {
    Column() {
      Row(){
        Image(Utils.getBodyRecordIcon(this.bodyType)).width(20).height(20)
        Text(this.title).fontSize(22).fontWeight(FontWeight.Bold).margin({left:20})
      }.margin({ top: 25 })
      Text(this.content){
        Span(this.content).fontWeight(500).fontSize(28)
        Span(this.unit).fontWeight(500).fontSize(28)
      }.fontSize(15).padding({ top: 15,left:35,right:35,bottom:15 })
      RuleView({
        start:this.startNum,
        end:this.endNum,
        step:this.stepNum,
        ruleColor:'#ff7a7a7a',
        markColor:'#0cc291',
        currentValue:this.selectNum,
        onUpdate:(v) => {
          this.curValue = parseFloat(v)
          this.content = v
        }
      }).height(80).width('95%')

      Row() {
        Button('取消')
          .type(ButtonType.Capsule)
          .backgroundColor('#F5F5F5')
          .fontColor('#333333')
          .width(120)
          .onClick(() => {
            this.cancel() //调用回调
          })
        Button('确定')
          .type(ButtonType.Capsule)
          .backgroundColor('#0cc291')
          .fontColor('#FFFFFF')
          .width(120)
          .margin({ left: 12 })
          .onClick(() => {
            // 如果 curValue 为 0 或无效，使用 selectNum 作为备用值
            const finalValue = (this.curValue > 0) ? this.curValue : this.selectNum
            this.confirm(finalValue, this.bodyType) //调用回调
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 20, bottom: 20 })
    }.width('100%').height('AUTO')
  }
}
