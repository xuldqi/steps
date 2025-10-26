import { BodyRecordModel } from '../appdata/Model'
import { Log } from '../tools/Logger'
import { Utils } from '../tools/Utils'
import RuleView from './RuleView'

@CustomDialog
export struct ModifyBodyRecordDialog {

  @State title:string = ''
  @State unit:string = ''
  @State content:string = ''
  @State bodyData:BodyRecordModel = {
    id: -1,
    time: 0,
    type: 0,
    data: '',
    unit: '',
  }
  @State startNum:number = 50
  @State endNum:number = 1000
  @State stepNum:number = 1
  @State selectNum:number = 100
  @State index:number = -1
  private curValue:number = 0

  controller?: CustomDialogController = undefined
  cancel: () => void = () => {
  }
  confirm: (bodyData:BodyRecordModel,index:number) => void = () => {
  }

  build() {
    Column() {
      Row(){
        Image(Utils.getBodyRecordIcon(this.bodyData.type)).width(20).height(20)
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
          Log.i("onUpdate 1:"+v)
          this.curValue = parseFloat(v)
          this.content = v
        }
      }).height(80).width('95%')

      Row() {
        Text('取消')
          .width('50%')
          .height(50)
          .backgroundColor('#ffbebebe')
          .fontColor(Color.White)
          .fontSize(16)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.cancel() //调用回调
          })
        Text('确定')
          .width('50%')
          .height(50)
          .backgroundColor('#0cc291')
          .fontColor(Color.White)
          .fontSize(16)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.bodyData.data = this.curValue.toString()
            this.confirm(this.bodyData,this.index) //调用回调
          })
      }.margin({top:15})
    }.width('100%').height('AUTO')
  }
}
