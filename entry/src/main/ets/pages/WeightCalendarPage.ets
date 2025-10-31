import { router } from '@kit.ArkUI'
import { CommonTitleView } from '../view/CommonTitleView'
import { BodyRecordModel } from '../appdata/Model'
import appDataManager, { AppDataManager, DataCallback } from '../tools/AppDataManager'
import { DateUtils } from '../tools/DateUtils'
import { Utils } from '../tools/Utils'

interface DayWeight {
  date: string
  items: BodyRecordModel[]
}

@Entry
@Component
struct WeightCalendarPage {
  @State days: Array<DayWeight> = []
  @State selectedIndex: number = 0

  private cb: DataCallback<BodyRecordModel> = {
    onDataResult: (type:number, result: BodyRecordModel[], isFirst:boolean): void => {
      if (type !== AppDataManager.TYPE_WEIGHT) return
      const group = new Map<string, BodyRecordModel[]>()
      for (const r of result) {
        const d = new Date(r.time)
        const ymd = `${d.getFullYear()}-${(d.getMonth()+1).toString().padStart(2,'0')}-${d.getDate().toString().padStart(2,'0')}`
        if (!group.has(ymd)) group.set(ymd, [])
        group.get(ymd)!.push(r)
      }
      const list: Array<DayWeight> = []
      const sortedEntries: Array<[string, BodyRecordModel[]]> = Array.from(group.entries()).sort((a,b)=>b[0].localeCompare(a[0]))
      for (let i = 0; i < sortedEntries.length; i++) {
        const k: string = sortedEntries[i][0]
        const arr: Array<BodyRecordModel> = sortedEntries[i][1]
        arr.sort((a,b)=>b.time - a.time)
        list.push({ date: k, items: arr })
      }
      this.days = list
      this.selectedIndex = 0
    }
  }

  onPageShow() {
    appDataManager.findBodyRecordByType(AppDataManager.TYPE_WEIGHT, this.cb, false)
  }

  private buildDelta(curr: BodyRecordModel, prev?: BodyRecordModel): string {
    if (!prev) return '与上次持平'
    const d = parseFloat(curr.data) - parseFloat(prev.data)
    if (Math.abs(d) < 0.001) return '与上次持平'
    const pct = ((d / parseFloat(prev.data)) * 100).toFixed(1)
    return d > 0 ? `+${pct}%` : `${pct}%`
  }

  build() {
    Column() {
      CommonTitleView({ data1:{ str1:'体重日历' }, cancel: ()=>{ router.back() } })

      if (this.days.length === 0) {
        Column(){
          Image($r('app.media.no_data')).width(70).height(70).margin(10)
          Text('还没有数据').fontColor('#999999')
        }.layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      } else {
        Row(){
          // 左侧日期列表（简化为纵向列表）
          List(){
            ForEach(this.days, (d: DayWeight, i: number) => {
              ListItem(){
                Text(DateUtils.getYMDCH(new Date(d.date).getTime())).fontSize(14).fontColor(this.selectedIndex===i?'#0cc291':'#333333')
                  .padding(12)
                  .onClick(()=>{ this.selectedIndex = i })
              }
            })
          }.width('38%').height('100%')

          // 右侧记录
          Column(){
            Text(this.days[this.selectedIndex].date).fontSize(16).fontWeight(500).margin({ bottom: 12 })
            ForEach(this.days[this.selectedIndex].items, (item: BodyRecordModel, idx: number) => {
              Row(){
                Text(DateUtils.getHM(item.time)).fontSize(14).fontColor('#666666').width(70)
                Text(`${item.data}${item.unit}`).fontSize(16).fontWeight(600).layoutWeight(1)
                Text(this.buildDelta(item, idx>0 ? this.days[this.selectedIndex].items[idx-1] : undefined))
                  .fontSize(12)
                  .fontColor((idx>0 && parseFloat(item.data) - parseFloat(this.days[this.selectedIndex].items[idx-1].data) > 0) ? '#E53935' : ((idx>0 && parseFloat(item.data) - parseFloat(this.days[this.selectedIndex].items[idx-1].data) < 0) ? '#43A047' : '#999999'))
              }.padding(12).backgroundColor('#FFFFFF').borderRadius(12).margin({ bottom: 8 })
            })
          }.width('62%').padding(12)
        }.layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}



