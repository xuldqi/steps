import { router } from '@kit.ArkUI'
import { CommonTitleView } from '../view/CommonTitleView'
import { AppDataManager, DataCallback } from '../tools/AppDataManager'
import { BodyRecordModel } from '../appdata/Model'
import { DateUtils } from '../tools/DateUtils'
import { Utils } from '../tools/Utils'

interface BodyRecordItem {
  type: number
  name: string
  icon: Resource
  data: string
  time: string
  hasData: boolean
}

@Entry
@Component
struct BodyDataPage {
  @State currentSubIndex: number = 0
  private subController: TabsController = new TabsController()

  @State heightData: BodyRecordItem = {
    type: AppDataManager.TYPE_HEIGHT,
    name: '身高',
    icon: $r('app.media.body_record_h'),
    data: '你还没有记录过身高',
    time: '',
    hasData: false
  }
  @State xwData: BodyRecordItem = {
    type: AppDataManager.TYPE_XW,
    name: '胸围',
    icon: $r('app.media.body_record_xw'),
    data: '你还没有记录过胸围',
    time: '',
    hasData: false
  }
  @State ywData: BodyRecordItem = {
    type: AppDataManager.TYPE_YW,
    name: '腰围',
    icon: $r('app.media.body_record_yw'),
    data: '你还没有记录过腰围',
    time: '',
    hasData: false
  }
  @State twData: BodyRecordItem = {
    type: AppDataManager.TYPE_TW,
    name: '臀围',
    icon: $r('app.media.body_record_tw'),
    data: '你还没有记录过臀围',
    time: '',
    hasData: false
  }
  @State sbwData: BodyRecordItem = {
    type: AppDataManager.TYPE_SBW,
    name: '上臂围',
    icon: $r('app.media.body_record_sbw'),
    data: '你还没有记录过上臂围',
    time: '',
    hasData: false
  }
  @State dtwData: BodyRecordItem = {
    type: AppDataManager.TYPE_DTW,
    name: '大腿围',
    icon: $r('app.media.body_record_dtw'),
    data: '你还没有记录过大腿围',
    time: '',
    hasData: false
  }
  @State xtwData: BodyRecordItem = {
    type: AppDataManager.TYPE_XTW,
    name: '小腿围',
    icon: $r('app.media.body_record_xtw'),
    data: '你还没有记录过小腿围',
    time: '',
    hasData: false
  }

  @State heightDatas: Array<BodyRecordModel> = []
  @State xwDatas: Array<BodyRecordModel> = []
  @State ywDatas: Array<BodyRecordModel> = []
  @State twDatas: Array<BodyRecordModel> = []
  @State sbwDatas: Array<BodyRecordModel> = []
  @State dtwDatas: Array<BodyRecordModel> = []
  @State xtwDatas: Array<BodyRecordModel> = []

  private bodyCallback: DataCallback<BodyRecordModel> = {
    onDataResult: (type: number, result: Array<BodyRecordModel>, isFirstData: boolean): void => {
      const sorted = result ? result.slice().sort((a, b) => b.time - a.time) : []
      
      if (type === AppDataManager.TYPE_HEIGHT) {
        this.heightDatas = sorted
        if (sorted.length > 0) {
          this.heightData.data = `身高: ${sorted[0].data}${sorted[0].unit}`
          this.heightData.hasData = true
          this.heightData.time = DateUtils.timeToDate(sorted[0].time)
        } else {
          this.heightData.data = '你还没有记录过身高'
          this.heightData.hasData = false
          this.heightData.time = ''
        }
      } else if (type === AppDataManager.TYPE_XW) {
        this.xwDatas = sorted
        if (sorted.length > 0) {
          this.xwData.data = `胸围: ${sorted[0].data}${sorted[0].unit}`
          this.xwData.hasData = true
          this.xwData.time = DateUtils.timeToDate(sorted[0].time)
        } else {
          this.xwData.data = '你还没有记录过胸围'
          this.xwData.hasData = false
          this.xwData.time = ''
        }
      } else if (type === AppDataManager.TYPE_YW) {
        this.ywDatas = sorted
        if (sorted.length > 0) {
          this.ywData.data = `腰围: ${sorted[0].data}${sorted[0].unit}`
          this.ywData.hasData = true
          this.ywData.time = DateUtils.timeToDate(sorted[0].time)
        } else {
          this.ywData.data = '你还没有记录过腰围'
          this.ywData.hasData = false
          this.ywData.time = ''
        }
      } else if (type === AppDataManager.TYPE_TW) {
        this.twDatas = sorted
        if (sorted.length > 0) {
          this.twData.data = `臀围: ${sorted[0].data}${sorted[0].unit}`
          this.twData.hasData = true
          this.twData.time = DateUtils.timeToDate(sorted[0].time)
        } else {
          this.twData.data = '你还没有记录过臀围'
          this.twData.hasData = false
          this.twData.time = ''
        }
      } else if (type === AppDataManager.TYPE_SBW) {
        this.sbwDatas = sorted
        if (sorted.length > 0) {
          this.sbwData.data = `上臂围: ${sorted[0].data}${sorted[0].unit}`
          this.sbwData.hasData = true
          this.sbwData.time = DateUtils.timeToDate(sorted[0].time)
        } else {
          this.sbwData.data = '你还没有记录过上臂围'
          this.sbwData.hasData = false
          this.sbwData.time = ''
        }
      } else if (type === AppDataManager.TYPE_DTW) {
        this.dtwDatas = sorted
        if (sorted.length > 0) {
          this.dtwData.data = `大腿围: ${sorted[0].data}${sorted[0].unit}`
          this.dtwData.hasData = true
          this.dtwData.time = DateUtils.timeToDate(sorted[0].time)
        } else {
          this.dtwData.data = '你还没有记录过大腿围'
          this.dtwData.hasData = false
          this.dtwData.time = ''
        }
      } else if (type === AppDataManager.TYPE_XTW) {
        this.xtwDatas = sorted
        if (sorted.length > 0) {
          this.xtwData.data = `小腿围: ${sorted[0].data}${sorted[0].unit}`
          this.xtwData.hasData = true
          this.xtwData.time = DateUtils.timeToDate(sorted[0].time)
        } else {
          this.xtwData.data = '你还没有记录过小腿围'
          this.xtwData.hasData = false
          this.xtwData.time = ''
        }
      }
    }
  }

  onPageShow() {
    AppDataManager.getInstance().findBodyRecordByType(AppDataManager.TYPE_HEIGHT, this.bodyCallback, false)
    AppDataManager.getInstance().findBodyRecordByType(AppDataManager.TYPE_XW, this.bodyCallback, false)
    AppDataManager.getInstance().findBodyRecordByType(AppDataManager.TYPE_YW, this.bodyCallback, false)
    AppDataManager.getInstance().findBodyRecordByType(AppDataManager.TYPE_TW, this.bodyCallback, false)
    AppDataManager.getInstance().findBodyRecordByType(AppDataManager.TYPE_SBW, this.bodyCallback, false)
    AppDataManager.getInstance().findBodyRecordByType(AppDataManager.TYPE_DTW, this.bodyCallback, false)
    AppDataManager.getInstance().findBodyRecordByType(AppDataManager.TYPE_XTW, this.bodyCallback, false)
  }

  @Builder
  buildBodyRecordItem(item: BodyRecordItem) {
    Column() {
      Row() {
        Image(item.icon)
          .width(40)
          .height(40)
          .margin({ right: 12 })

        Column() {
          Text(item.name)
            .fontSize(16)
            .fontWeight(500)
            .fontColor('#333333')
            .alignSelf(ItemAlign.Start)
          
          Text(item.data)
            .fontSize(14)
            .fontColor(item.hasData ? '#333333' : '#999999')
            .alignSelf(ItemAlign.Start)
            .margin({ top: 4 })
          
          if (item.hasData && item.time) {
            Text(item.time)
              .fontSize(12)
              .fontColor('#666666')
              .alignSelf(ItemAlign.Start)
              .margin({ top: 4 })
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Image($r('app.media.right_point'))
          .width(16)
          .height(16)
          .fillColor('#CCCCCC')
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ bottom: 12 })
    .onClick(() => {
      // TODO: 打开记录对话框
      console.info(`[BodyDataPage] 打开记录: ${item.name}`)
    })
  }

  @Builder
  buildRecordList(records: Array<BodyRecordModel>, name: string) {
    Column() {
      if (records.length === 0) {
        Text(`暂无${name}记录`)
          .fontSize(14)
          .fontColor('#999999')
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding(40)
      } else {
        ForEach(records, (record: BodyRecordModel) => {
          Row() {
            Column() {
              Text(`${name}: ${record.data}${record.unit}`)
                .fontSize(16)
                .fontWeight(500)
                .fontColor('#333333')
                .alignSelf(ItemAlign.Start)
              
              Text(DateUtils.timeToDate(record.time))
                .fontSize(12)
                .fontColor('#666666')
                .alignSelf(ItemAlign.Start)
                .margin({ top: 4 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding(16)
          .border({ width: { bottom: 1 }, color: '#F0F0F0' })
        })
      }
    }
    .width('100%')
    .padding(16)
  }

  @Builder
  subTabBuilder(index: number, text: string) {
    Text(text)
      .fontSize(14)
      .fontColor(this.currentSubIndex === index ? '#0cc291' : '#333333')
      .fontWeight(this.currentSubIndex === index ? FontWeight.Medium : FontWeight.Normal)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '身体数据' },
        cancel: () => {
          router.back()
        },
        useSafeTop: true
      })

      Tabs({ barPosition: BarPosition.Start, controller: this.subController }) {
        TabContent() {
          Scroll() {
            Column() {
              this.buildBodyRecordItem(this.heightData)
              this.buildBodyRecordItem(this.xwData)
              this.buildBodyRecordItem(this.ywData)
              this.buildBodyRecordItem(this.twData)
              this.buildBodyRecordItem(this.sbwData)
              this.buildBodyRecordItem(this.dtwData)
              this.buildBodyRecordItem(this.xtwData)
            }
            .width('100%')
            .padding(16)
          }
          .width('100%')
          .layoutWeight(1)
        }
        .tabBar(this.subTabBuilder(0, '概况'))

        TabContent() {
          Scroll() {
            this.buildRecordList(this.heightDatas, '身高')
          }
          .width('100%')
          .layoutWeight(1)
        }
        .tabBar(this.subTabBuilder(1, '身高'))

        TabContent() {
          Scroll() {
            this.buildRecordList(this.xwDatas, '胸围')
          }
          .width('100%')
          .layoutWeight(1)
        }
        .tabBar(this.subTabBuilder(2, '胸围'))

        TabContent() {
          Scroll() {
            this.buildRecordList(this.ywDatas, '腰围')
          }
          .width('100%')
          .layoutWeight(1)
        }
        .tabBar(this.subTabBuilder(3, '腰围'))

        TabContent() {
          Scroll() {
            this.buildRecordList(this.twDatas, '臀围')
          }
          .width('100%')
          .layoutWeight(1)
        }
        .tabBar(this.subTabBuilder(4, '臀围'))

        TabContent() {
          Scroll() {
            this.buildRecordList(this.sbwDatas, '上臂围')
          }
          .width('100%')
          .layoutWeight(1)
        }
        .tabBar(this.subTabBuilder(5, '上臂围'))

        TabContent() {
          Scroll() {
            this.buildRecordList(this.dtwDatas, '大腿围')
          }
          .width('100%')
          .layoutWeight(1)
        }
        .tabBar(this.subTabBuilder(6, '大腿围'))

        TabContent() {
          Scroll() {
            this.buildRecordList(this.xtwDatas, '小腿围')
          }
          .width('100%')
          .layoutWeight(1)
        }
        .tabBar(this.subTabBuilder(7, '小腿围'))
      }
      .barHeight('6%')
      .barWidth('100%')
      .barMode(BarMode.Scrollable)
      .scrollable(true)
      .width('100%')
      .layoutWeight(1)
      .vertical(false)
      .onChange((index: number) => {
        this.currentSubIndex = index
      })
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

