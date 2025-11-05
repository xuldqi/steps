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
    hasData:false,
    recordType: AppDataManager.TYPE_HEIGHT
  }
  @State xwData: BodyRecordData = {
    data:'你还没有记录过胸围',
    img: $r('app.media.body_record_xw'),
    time:'',
    hasData:false,
    recordType: AppDataManager.TYPE_XW
  }
  @State ywData: BodyRecordData = {
    data:'你还没有记录过腰围',
    img: $r('app.media.body_record_yw'),
    time:'',
    hasData:false,
    recordType: AppDataManager.TYPE_YW
  }
  @State twData: BodyRecordData = {
    data:'你还没有记录过臀围',
    img: $r('app.media.body_record_tw'),
    time:'',
    hasData:false,
    recordType: AppDataManager.TYPE_TW
  }
  @State sbwData: BodyRecordData = {
    data:'你还没有记录过上臂围',
    img: $r('app.media.body_record_sbw'),
    time:'',
    hasData:false,
    recordType: AppDataManager.TYPE_SBW
  }
  @State dtwData: BodyRecordData = {
    data:'你还没有记录过大腿围',
    img: $r('app.media.body_record_dtw'),
    time:'',
    hasData:false,
    recordType: AppDataManager.TYPE_DTW
  }
  @State xtwData: BodyRecordData = {
    data:'你还没有记录过小腿围',
    img: $r('app.media.body_record_xtw'),
    time:'',
    hasData:false,
    recordType: AppDataManager.TYPE_XTW
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
      // 处理所有数据结果（包括首次和后续）
      const sorted = result ? result.slice().sort((a, b) => b.time - a.time) : []
      
      if(type === AppDataManager.TYPE_HEIGHT){
        this.heightDatas = sorted
        if(sorted.length>0){
          this.heightData.data = '身高:'+sorted[0].data+sorted[0].unit
          this.heightData.hasData = true
          this.heightData.time = DateUtils.timeToDate(sorted[0].time)
        } else {
          this.heightData.data = '你还没有记录过身高'
          this.heightData.hasData = false
          this.heightData.time = ''
        }
        // 确保回调函数始终存在
        this.heightData.recordType = AppDataManager.TYPE_HEIGHT
        this.heightData.onAddClick = () => {
          this.showBodyRecordDialog(20.0,260.0,0.1,165.0,Utils.getBodyRecordName(AppDataManager.TYPE_HEIGHT),'165.0',165.0, AppDataManager.TYPE_HEIGHT)
        }
      }else if(type === AppDataManager.TYPE_WEIGHT){
        this.weightDatas = sorted
        if(sorted.length>0){
          this.weightData.data = '体重:'+sorted[0].data+sorted[0].unit
          this.weightData.hasData = true
          this.weightData.time = DateUtils.timeToDate(sorted[0].time)
        } else {
          this.weightData.data = '你还没有记录过体重'
          this.weightData.hasData = false
          this.weightData.time = ''
        }
      }else if(type === AppDataManager.TYPE_XW){
        this.xwDatas = sorted
        if(sorted.length>0){
          this.xwData.data = '胸围:'+sorted[0].data+sorted[0].unit
          this.xwData.hasData = true
          this.xwData.time = DateUtils.timeToDate(sorted[0].time)
        } else {
          this.xwData.data = '你还没有记录过胸围'
          this.xwData.hasData = false
          this.xwData.time = ''
        }
        this.xwData.recordType = AppDataManager.TYPE_XW
        this.xwData.onAddClick = () => {
          this.showBodyRecordDialog(10.0,200.0,0.1,65.0,Utils.getBodyRecordName(AppDataManager.TYPE_XW),'65.0',65.0, AppDataManager.TYPE_XW)
        }
      }else if(type === AppDataManager.TYPE_YW){
        this.ywDatas = sorted
        if(sorted.length>0){
          this.ywData.data = '腰围:'+sorted[0].data+sorted[0].unit
          this.ywData.hasData = true
          this.ywData.time = DateUtils.timeToDate(sorted[0].time)
        } else {
          this.ywData.data = '你还没有记录过腰围'
          this.ywData.hasData = false
          this.ywData.time = ''
        }
        this.ywData.recordType = AppDataManager.TYPE_YW
        this.ywData.onAddClick = () => {
          this.showBodyRecordDialog(10.0,200.0,0.1,65.0,Utils.getBodyRecordName(AppDataManager.TYPE_YW),'65.0',65.0, AppDataManager.TYPE_YW)
        }
      }else if(type === AppDataManager.TYPE_TW){
        this.twDatas = sorted
        if(sorted.length>0){
          this.twData.data = '臀围:'+sorted[0].data+sorted[0].unit
          this.twData.hasData = true
          this.twData.time = DateUtils.timeToDate(sorted[0].time)
        } else {
          this.twData.data = '你还没有记录过臀围'
          this.twData.hasData = false
          this.twData.time = ''
        }
        this.twData.recordType = AppDataManager.TYPE_TW
        this.twData.onAddClick = () => {
          this.showBodyRecordDialog(10.0,200.0,0.1,65.0,Utils.getBodyRecordName(AppDataManager.TYPE_TW),'65.0',65.0, AppDataManager.TYPE_TW)
        }
      }else if(type === AppDataManager.TYPE_SBW){
        this.sbwDatas = sorted
        if(sorted.length>0){
          this.sbwData.data = '上臂围:'+sorted[0].data+sorted[0].unit
          this.sbwData.hasData = true
          this.sbwData.time = DateUtils.timeToDate(sorted[0].time)
        } else {
          this.sbwData.data = '你还没有记录过上臂围'
          this.sbwData.hasData = false
          this.sbwData.time = ''
        }
        this.sbwData.recordType = AppDataManager.TYPE_SBW
        this.sbwData.onAddClick = () => {
          this.showBodyRecordDialog(10.0,200.0,0.1,65.0,Utils.getBodyRecordName(AppDataManager.TYPE_SBW),'65.0',65.0, AppDataManager.TYPE_SBW)
        }
      }else if(type === AppDataManager.TYPE_DTW){
        this.dtwDatas = sorted
        if(sorted.length>0){
          this.dtwData.data = '大腿围:'+sorted[0].data+sorted[0].unit
          this.dtwData.hasData = true
          this.dtwData.time = DateUtils.timeToDate(sorted[0].time)
        } else {
          this.dtwData.data = '你还没有记录过大腿围'
          this.dtwData.hasData = false
          this.dtwData.time = ''
        }
        this.dtwData.recordType = AppDataManager.TYPE_DTW
        this.dtwData.onAddClick = () => {
          this.showBodyRecordDialog(10.0,200.0,0.1,65.0,Utils.getBodyRecordName(AppDataManager.TYPE_DTW),'65.0',65.0, AppDataManager.TYPE_DTW)
        }
      }else if(type === AppDataManager.TYPE_XTW){
        this.xtwDatas = sorted
        if(sorted.length>0){
          this.xtwData.data = '小腿围:'+sorted[0].data+sorted[0].unit
          this.xtwData.hasData = true
          this.xtwData.time = DateUtils.timeToDate(sorted[0].time)
        } else {
          this.xtwData.data = '你还没有记录过小腿围'
          this.xtwData.hasData = false
          this.xtwData.time = ''
        }
        this.xtwData.recordType = AppDataManager.TYPE_XTW
        this.xtwData.onAddClick = () => {
          this.showBodyRecordDialog(10.0,200.0,0.1,65.0,Utils.getBodyRecordName(AppDataManager.TYPE_XTW),'65.0',65.0, AppDataManager.TYPE_XTW)
        }
      }
    }
  }

  // 获取标签对应的记录类型
  private getRecordTypeByIndex(index: number): number {
    switch(index) {
      case 1: return AppDataManager.TYPE_HEIGHT
      case 2: return AppDataManager.TYPE_XW
      case 3: return AppDataManager.TYPE_YW
      case 4: return AppDataManager.TYPE_TW
      case 5: return AppDataManager.TYPE_SBW
      case 6: return AppDataManager.TYPE_DTW
      case 7: return AppDataManager.TYPE_XTW
      default: return 0
    }
  }

  // TAB view 的按钮的新建
  @Builder subTabBuilder(index: number,title:string) {
    Column() {
      Text(title).padding({top:3, left: 4, right: 4 })
        .fontColor(this.currentSubIndex === index ? this.selectedFontColor : this.fontColor)
        .fontSize(this.currentSubIndex === index ? 16 : 14).fontWeight(this.currentSubIndex === index ? 600 : 400).textAlign(TextAlign.Center).alignSelf(ItemAlign.Center)
    }.width('auto').align(Alignment.Center).padding({ left: 2, right: 2 })
  }

  onPageShow(): void {
    interface RouteParams {
      showHeightRecord?: boolean
    }
    const params = typeof router.getParams === 'function' ? router.getParams() as RouteParams | undefined : undefined
    const needShowHeightRecord = params?.showHeightRecord === true
    
    // 初始化每个数据条目的加号点击回调
    this.heightData.onAddClick = () => {
      this.showBodyRecordDialog(20.0,260.0,0.1,165.0,Utils.getBodyRecordName(AppDataManager.TYPE_HEIGHT),'165.0',165.0, AppDataManager.TYPE_HEIGHT)
    }
    this.xwData.onAddClick = () => {
      this.showBodyRecordDialog(10.0,200.0,0.1,65.0,Utils.getBodyRecordName(AppDataManager.TYPE_XW),'65.0',65.0, AppDataManager.TYPE_XW)
    }
    this.ywData.onAddClick = () => {
      this.showBodyRecordDialog(10.0,200.0,0.1,65.0,Utils.getBodyRecordName(AppDataManager.TYPE_YW),'65.0',65.0, AppDataManager.TYPE_YW)
    }
    this.twData.onAddClick = () => {
      this.showBodyRecordDialog(10.0,200.0,0.1,65.0,Utils.getBodyRecordName(AppDataManager.TYPE_TW),'65.0',65.0, AppDataManager.TYPE_TW)
    }
    this.sbwData.onAddClick = () => {
      this.showBodyRecordDialog(10.0,200.0,0.1,65.0,Utils.getBodyRecordName(AppDataManager.TYPE_SBW),'65.0',65.0, AppDataManager.TYPE_SBW)
    }
    this.dtwData.onAddClick = () => {
      this.showBodyRecordDialog(10.0,200.0,0.1,65.0,Utils.getBodyRecordName(AppDataManager.TYPE_DTW),'65.0',65.0, AppDataManager.TYPE_DTW)
    }
    this.xtwData.onAddClick = () => {
      this.showBodyRecordDialog(10.0,200.0,0.1,65.0,Utils.getBodyRecordName(AppDataManager.TYPE_XTW),'65.0',65.0, AppDataManager.TYPE_XTW)
    }
    
    // 加载所有类型的身体记录数据（不包括体重，因为体重有专门的趋势页面）
    appDataManager.findBodyRecordByType(AppDataManager.TYPE_HEIGHT, this.bodyCallback, false)
    appDataManager.findBodyRecordByType(AppDataManager.TYPE_XW, this.bodyCallback, false)
    appDataManager.findBodyRecordByType(AppDataManager.TYPE_YW, this.bodyCallback, false)
    appDataManager.findBodyRecordByType(AppDataManager.TYPE_TW, this.bodyCallback, false)
    appDataManager.findBodyRecordByType(AppDataManager.TYPE_SBW, this.bodyCallback, false)
    appDataManager.findBodyRecordByType(AppDataManager.TYPE_DTW, this.bodyCallback, false)
    appDataManager.findBodyRecordByType(AppDataManager.TYPE_XTW, this.bodyCallback, false)
    
    // 如果需要显示身高记录，切换到身高标签页
    if (needShowHeightRecord) {
      setTimeout(() => {
        this.subController.changeIndex(1) // 切换到身高标签页（索引1，因为移除了体重，身高现在是索引1）
        // 清理参数，避免下次进入时重复打开
        if (typeof router.replaceUrl === 'function') {
          try {
            router.replaceUrl({ url: 'pages/BodyDataPage' }).catch(() => {})
          } catch (_e) {}
        }
      }, 300)
    }
  }

  onPageHide(): void {
  }

  private getCurrentRecordType(): number {
    switch(this.currentSubIndex) {
      case 1: return AppDataManager.TYPE_HEIGHT
      case 2: return AppDataManager.TYPE_XW
      case 3: return AppDataManager.TYPE_YW
      case 4: return AppDataManager.TYPE_TW
      case 5: return AppDataManager.TYPE_SBW
      case 6: return AppDataManager.TYPE_DTW
      case 7: return AppDataManager.TYPE_XTW
      default: return AppDataManager.TYPE_HEIGHT
    }
  }

  private showBodyRecordDialog(startNum:number,endNum:number,stepNum:number,curValue:number,
    title:string,content:string,selectNum:number, recordType: number){
    let dialog = new CustomDialogController({ builder: BodyRecordDialog({
      cancel: ()=> {
        dialog.close()
      },
      confirm: async (data:number,type:number)=> {
        dialog.close()
        appDataManager.insertBodyRecord(recordType, data.toString())
        // 刷新对应类型的数据，延迟确保数据库操作完成
        setTimeout(() => {
          appDataManager.findBodyRecordByType(recordType, this.bodyCallback, false)
        }, 300)
      },
      startNum:startNum,
      endNum:endNum,
      stepNum:stepNum,
      curValue:curValue,
      bodyType:recordType,
      title:title,content:content,selectNum:selectNum,unit:Utils.getUnitByType(recordType)
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
          TabContent() {
            Column() {
              BodyRecordItemView({formData:this.heightData})
              BodyRecordItemView({formData:this.xwData})
                .margin({ top: 8 })
              BodyRecordItemView({formData:this.ywData})
                .margin({ top: 8 })
              BodyRecordItemView({formData:this.twData})
                .margin({ top: 8 })
              BodyRecordItemView({formData:this.sbwData})
                .margin({ top: 8 })
              BodyRecordItemView({formData:this.dtwData})
                .margin({ top: 8 })
              BodyRecordItemView({formData:this.xtwData})
                .margin({ top: 8 })
            }
            .width('100%')
            .height('100%')
            .align(Alignment.Top)
          }.tabBar(this.subTabBuilder(0,'概况'))
          
          TabContent() {
            BodyRecordList({data:this.heightDatas,type:AppDataManager.TYPE_HEIGHT})
          }.tabBar(this.subTabBuilder(1,'身高'))
          
          TabContent() {
            BodyRecordList({data:this.xwDatas,type:AppDataManager.TYPE_XW})
          }.tabBar(this.subTabBuilder(2,'胸围'))
          
          TabContent() {
            BodyRecordList({data:this.ywDatas,type:AppDataManager.TYPE_YW})
          }.tabBar(this.subTabBuilder(3,'腰围'))
          
          TabContent() {
            BodyRecordList({data:this.twDatas,type:AppDataManager.TYPE_TW})
          }.tabBar(this.subTabBuilder(4,'臀围'))
          
          TabContent() {
            BodyRecordList({data:this.sbwDatas,type:AppDataManager.TYPE_SBW})
          }.tabBar(this.subTabBuilder(5,'上臂围'))
          
          TabContent() {
            BodyRecordList({data:this.dtwDatas,type:AppDataManager.TYPE_DTW})
          }.tabBar(this.subTabBuilder(6,'大腿围'))
          
          TabContent() {
            BodyRecordList({data:this.xtwDatas,type:AppDataManager.TYPE_XTW})
          }.tabBar(this.subTabBuilder(7,'小腿围'))
        }
        .barHeight(48)
        .barWidth('93%')
        .scrollable(true)
        .width('100%')
        .height('100%')
        .vertical(false)
        .onChange((index: number) => {
          this.currentSubIndex = index
        })
        .barMode(BarMode.Scrollable)

        Image($r('app.media.add_all_record'))
          .height(50)
          .width(50)
          .margin({ right: 30, bottom: 120 })
          .onClick(() => {
            const recordType = this.getCurrentRecordType()
            if(recordType === AppDataManager.TYPE_HEIGHT){
              this.showBodyRecordDialog(20.0,260.0,0.1,165.0,Utils.getBodyRecordName(recordType),'165.0',165.0, recordType)
            }else{//其他的类型
              this.showBodyRecordDialog(10.0,200.0,0.1,65.0,Utils.getBodyRecordName(recordType),'65.0',65.0, recordType)
            }
          })
          .visibility(this.currentSubIndex === 0 ? Visibility.Hidden : Visibility.Visible)
          .align(Alignment.BottomEnd)
      }
      .width('100%')
      .height('92%')
      .margin({ top: -16 })
      .alignContent(Alignment.BottomEnd)
    }
  }
}
