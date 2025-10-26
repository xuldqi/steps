import { BodyRecordModel } from '../appdata/Model';
import appDataManager, { AppDataManager } from '../tools/AppDataManager';
import { DateUtils } from '../tools/DateUtils';
import { Utils } from '../tools/Utils';
import { ModifyBodyRecordDialog } from './ModifyBodyRecordDialog';

@Component
export struct BodyRecordList {
  exitApp: (() => void) | undefined;
  @State data: Array<BodyRecordModel> = new Array<BodyRecordModel>();
  @State type:number = 0

  private showBodyRecordDialog(data:BodyRecordModel,startNum:number,endNum:number,stepNum:number,curValue:number,
    title:string,content:string,selectNum:number,index:number){
    let dialog = new CustomDialogController({ builder: ModifyBodyRecordDialog({
      cancel: ()=> {
        dialog.close()
      },
      confirm: (data:BodyRecordModel,index:number)=> {
        appDataManager.updateBodyRecordItem(data)
        this.data.splice(index,1)
        this.data.splice(index, 0, data);
        dialog.close()
      },
      startNum:startNum,
      endNum:endNum,
      stepNum:stepNum,
      curValue:curValue,
      bodyData:data,
      index:index,
      title:title,content:content,selectNum:selectNum,unit:Utils.getUnitByType(this.type)
    ,}),alignment: DialogAlignment.Bottom,gridCount:20,cancel: this.exitApp,autoCancel:false })
    dialog.open()
  }

  build() {
    Stack(){
      List() {
        ForEach(this.data, (item: BodyRecordModel, index: number) => {
          ListItem() {
            Row() {
              Image(Utils.getBodyRecordIcon(item.type))
                .width(30)
                .height(30)
                .margin(10)
              Text(){
                Span(item.data+item.unit).fontWeight(500).fontColor('#000000')
                Span('\n'+DateUtils.timeToDate(item.time)).fontSize(12).fontColor('#ff797979')
              }.fontSize(16).layoutWeight(1)
              Image($r('app.media.edit_body_record_item'))
                .width(20)
                .height(20)
                .margin(10)
                .onClick(() => {
                  if(item.type === 1){//身高
                    this.showBodyRecordDialog(item,20.0,260.0,0.1,165.0,Utils.getBodyRecordName(item.type),item.data,parseFloat(item.data),index)
                  }else if(item.type === 2){//体重
                    this.showBodyRecordDialog(item,5.0,300.0,0.1,55.0,Utils.getBodyRecordName(item.type),item.data,parseFloat(item.data),index)
                  }else{//其他的类型
                    this.showBodyRecordDialog(item,10.0,200.0,0.1,65.0,Utils.getBodyRecordName(item.type),item.data,parseFloat(item.data),index)
                  }
                })
              Image($r('app.media.delete_body_record_item'))
                .width(20)
                .height(20)
                .margin(10)
                .onClick(() => {
                  appDataManager.deleteBodyRecordAndId(item.id)
                  this.data.splice(index,1)
                })
            }.borderRadius(15).backgroundColor('#FFFFFF')
            .width('100%')
            .justifyContent(FlexAlign.Start)
          }.padding({left:10,right:10,top:10})
        })
      }.listDirection(Axis.Vertical).alignListItem(ListItemAlign.Start)
      .height('100%').width('100%').visibility(this.data.length > 0? Visibility.Visible:Visibility.Hidden)

      Image($r('app.media.no_data'))
        .width(70)
        .height(70)
        .margin(10)
        .visibility(this.data.length > 0? Visibility.Hidden:Visibility.Visible)
    }
  }
}