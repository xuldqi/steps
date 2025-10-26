import { BodyRecordModel } from '../appdata/Model';
import appDataManager, { AppDataManager, DataCallback } from '../tools/AppDataManager';
import { DateUtils } from '../tools/DateUtils';
import { Utils } from '../tools/Utils';
import { BodyRecordData } from '../view/BodyRecordItemView';
import { BodyRecordItemView } from '../view/BodyRecordItemView';
import { BodyRecordList } from '../view/BodyRecordList';
import { CommonTitleView } from '../view/CommonTitleView';
import { router } from '@kit.ArkUI';
import { BodyRecordDialog } from '../view/BodyRecordDialog';

@Entry
@Component
struct BodyDataPage {
  exitApp: (() => void) | undefined;
  @State currentSubIndex: number = 0
  @State fontColor: string = '#ff3c3c3c'
  @State selectedFontColor: string = '#0cc291'
  private subController: TabsController = new TabsController();

  @State weightData: BodyRecordData = {
    data:'你还没有记录过体重',
    img: $r('app.media.body_record_weight'),
    time:'',
    hasData:false
  }
  @State heightData: BodyRecordData = {
    data:'你还没有记录过身高',
    img: $r('app.media.body_record_h'),
    time:'',
    hasData:false
  }
  @State xwData: BodyRecordData = {
    data:'你还没有记录过胸围',
    img: $r('app.media.body_record_xw'),
    time:'',
    hasData:false
  }
  @State ywData: BodyRecordData = {
    data:'你还没有记录过腰围',
    img: $r('app.media.body_record_yw'),
    time:'',
    hasData:false
  }
  @State twData: BodyRecordData = {
    data:'你还没有记录过臀围',
    img: $r('app.media.body_record_tw'),
    time:'',
    hasData:false
  }
  @State sbwData: BodyRecordData = {
    data:'你还没有记录过上臂围',
    img: $r('app.media.body_record_sbw'),
    time:'',
    hasData:false
  }
  @State dtwData: BodyRecordData = {
    data:'你还没有记录过大腿围',
    img: $r('app.media.body_record_dtw'),
    time:'',
    hasData:false
  }
  @State xtwData: BodyRecordData = {
    data:'你还没有记录过小腿围',
    img: $r('app.media.body_record_xtw'),
    time:'',
    hasData:false
  }

  @State heightDatas: Array<BodyRecordModel> = new Array<BodyRecordModel>();
  @State weightDatas: Array<BodyRecordModel> = new Array<BodyRecordModel>();
  @State xwDatas: Array<BodyRecordModel> = new Array<BodyRecordModel>();
  @State ywDatas: Array<BodyRecordModel> = new Array<BodyRecordModel>();
  @State twDatas: Array<BodyRecordModel> = new Array<BodyRecordModel>();
  @State sbwDatas: Array<BodyRecordModel> = new Array<BodyRecordModel>();
  @State dtwDatas: Array<BodyRecordModel> = new Array<BodyRecordModel>();
  @State xtwDatas: Array<BodyRecordModel> = new Array<BodyRecordModel>();



  private bodyCallback:DataCallback<BodyRecordModel> = {
    onDataResult: (type,result:Array<BodyRecordModel>,isFirstData): void => {
      if(isFirstData){
        if(type === 1){

        }
      }else{
        if(type === 1){
          this.heightDatas.length = 0
          this.heightDatas = result
          if(result.length>0){
            this.heightData.data = '身高:'+result[0].data+result[0].unit
            this.heightData.hasData = true
            this.heightData.time = DateUtils.timeToDate(result[0].time)
          }
        }else if(type === 2){
          this.weightDatas.length = 0
          this.weightDatas = result
          if(result.length>0){
            this.weightData.data = '体重:'+result[0].data+result[0].unit
            this.weightData.hasData = true
            this.weightData.time = DateUtils.timeToDate(result[0].time)
          }
        }else if(type === 3){
          this.xwDatas.length = 0
          this.xwDatas = result
          if(result.length>0){
            this.xwData.data = '胸围:'+result[0].data+result[0].unit
            this.xwData.hasData = true
            this.xwData.time = DateUtils.timeToDate(result[0].time)
          }
        }else if(type === 4){
          this.ywDatas.length = 0
          this.ywDatas = result
          if(result.length>0){
            this.ywData.data = '腰围:'+result[0].data+result[0].unit
            this.ywData.hasData = true
            this.ywData.time = DateUtils.timeToDate(result[0].time)
          }
        }else if(type === 5){
          this.twDatas.length = 0
          this.twDatas = result
          if(result.length>0){
            this.twData.data = '臀围:'+result[0].data+result[0].unit
            this.twData.hasData = true
            this.twData.time = DateUtils.timeToDate(result[0].time)
          }
        }else if(type === 6){
          this.sbwDatas.length = 0
          this.sbwDatas = result
          if(result.length>0){
            this.sbwData.data = '上臂围:'+result[0].data+result[0].unit
            this.sbwData.hasData = true
            this.sbwData.time = DateUtils.timeToDate(result[0].time)
          }
        }else if(type === 7){
          this.dtwDatas.length = 0
          this.dtwDatas = result
          if(result.length>0){
            this.dtwData.data = '大腿围:'+result[0].data+result[0].unit
            this.dtwData.hasData = true
            this.dtwData.time = DateUtils.timeToDate(result[0].time)
          }
        }else if(type === 8){
          this.xtwDatas.length = 0
          this.xtwDatas = result
          if(result.length>0){
            this.xtwData.data = '小腿围:'+result[0].data+result[0].unit
            this.xtwData.hasData = true
            this.xtwData.time = DateUtils.timeToDate(result[0].time)
          }
        }
      }

    }
  }

  // TAB view 的按钮的新建
  @Builder subTabBuilder(index: number,title:string) {
    Column() {
      Text(title).padding({top:3 })
        .fontColor(this.currentSubIndex === index ? this.selectedFontColor : this.fontColor)
        .fontSize(this.currentSubIndex === index ? 16 : 14).fontWeight(this.currentSubIndex === index ? 600 : 400).textAlign(TextAlign.Start).alignSelf(ItemAlign.Start)//TabView按钮的文本
    }.width('18%').align(Alignment.Start)
  }

  onPageShow(): void {
    appDataManager.findBodyRecordByType(1, this.bodyCallback,false)
    appDataManager.findBodyRecordByType(2, this.bodyCallback,false)
    appDataManager.findBodyRecordByType(3, this.bodyCallback,false)
    appDataManager.findBodyRecordByType(4, this.bodyCallback,false)
    appDataManager.findBodyRecordByType(5, this.bodyCallback,false)
    appDataManager.findBodyRecordByType(6, this.bodyCallback,false)
    appDataManager.findBodyRecordByType(7, this.bodyCallback,false)
    appDataManager.findBodyRecordByType(8, this.bodyCallback,false)
  }

  onPageHide(): void {
  }

  private showBodyRecordDialog(startNum:number,endNum:number,stepNum:number,curValue:number,
    title:string,content:string,selectNum:number){
    let dialog = new CustomDialogController({ builder: BodyRecordDialog({
      cancel: ()=> {
        dialog.close()
      },
      confirm: (data:number,type:number)=> {
        appDataManager.insertBodyRecord(type,data.toString())
        dialog.close()
      },
      startNum:startNum,
      endNum:endNum,
      stepNum:stepNum,
      curValue:curValue,
      bodyType:this.currentSubIndex,
      title:title,content:content,selectNum:selectNum,unit:Utils.getUnitByType(this.currentSubIndex)
    ,}),alignment: DialogAlignment.Bottom,gridCount:20,cancel: this.exitApp,autoCancel:false })
    dialog.open()
  }

  build() {
    Column() {
      CommonTitleView({data1:{str1:'身体数据'},cancel: ()=> {
        router.back()
      }})

      Stack(){
        Tabs({ barPosition: BarPosition.Start, controller: this.subController }) {
          TabContent() {// 第一个subTab1页面 start
            Column() {
              BodyRecordItemView({formData:this.weightData})
              BodyRecordItemView({formData:this.heightData})
              BodyRecordItemView({formData:this.xwData})
              BodyRecordItemView({formData:this.ywData})
              BodyRecordItemView({formData:this.twData})
              BodyRecordItemView({formData:this.sbwData})
              BodyRecordItemView({formData:this.dtwData})
              BodyRecordItemView({formData:this.xtwData})
            }.width('100%').height('100%').align(Alignment.Top)
          }.tabBar(this.subTabBuilder(0,'概况'))
          TabContent() {// 第二个subTab2页面 start
            BodyRecordList({data:this.heightDatas,type:1})
          }.tabBar(this.subTabBuilder(1,'身高'))
          TabContent() {// 第三个subTab3页面 start
            BodyRecordList({data:this.weightDatas,type:2})
          }.tabBar(this.subTabBuilder(2,'体重'))
          TabContent() {// 第四个subTab4页面 start
            BodyRecordList({data:this.xwDatas,type:3})
          }.tabBar(this.subTabBuilder(3,'胸围'))
          TabContent() {// 第五个subTab5页面 start
            BodyRecordList({data:this.ywDatas,type:4})
          }.tabBar(this.subTabBuilder(4,'腰围'))
          TabContent() {
            BodyRecordList({data:this.twDatas,type:5})
          }.tabBar(this.subTabBuilder(5,'臀围'))
          TabContent() {
            BodyRecordList({data:this.sbwDatas,type:6})
          }.tabBar(this.subTabBuilder(6,'上臂围'))
          TabContent() {
            BodyRecordList({data:this.dtwDatas,type:7})
          }.tabBar(this.subTabBuilder(7,'大腿围'))
          TabContent() {
            BodyRecordList({data:this.xtwDatas,type:8})
          }.tabBar(this.subTabBuilder(8,'小腿围'))
        }.barHeight('6%').barWidth('93%').scrollable(true).width('100%').height('100%').vertical(false)
        .onChange((index: number) => {
          this.currentSubIndex = index
        }).animationDuration(0).barMode(BarMode.Scrollable)

        Row() {
          Image($r('app.media.add_all_record')).height(50).width(50).onClick(() => {
            if(this.currentSubIndex === 1){//身高
              this.showBodyRecordDialog(20.0,260.0,0.1,165.0,Utils.getBodyRecordName(this.currentSubIndex),'165.0',165.0)
            }else if(this.currentSubIndex === 2){//体重
              this.showBodyRecordDialog(5.0,300.0,0.1,55.0,Utils.getBodyRecordName(this.currentSubIndex),'55.0',55.0)
            }else{//其他的类型
              this.showBodyRecordDialog(10.0,200.0,0.1,65.0,Utils.getBodyRecordName(this.currentSubIndex),'65.0',65.0)
            }
          }).margin(30).visibility(this.currentSubIndex === 0?Visibility.Hidden:Visibility.Visible)
          
          Image($r('app.media.setting_data_sport')).height(50).width(50).onClick(() => {
            router.pushUrl({ url: 'pages/ChartPage' })
          }).margin(30).visibility(this.currentSubIndex === 0?Visibility.Visible:Visibility.Hidden)
        }
      }.width('100%').height('92%').align(Alignment.BottomEnd)
    }
  }
}