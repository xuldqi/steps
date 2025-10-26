import { router } from '@kit.ArkUI';
import { SleepLog } from '../appdata/Model';
import AppDataManager from '../tools/AppDataManager';
import preferencesUtil from '../tools/DataPreUtils';
import { DateUtils } from '../tools/DateUtils';
import { CommonTitleView } from '../view/CommonTitleView';
import { Utils } from '../tools/Utils';
import { systemDateTime } from '@kit.BasicServicesKit';

const DEFAULT_SLEEP_TARGET = 8

@Entry
@Component
struct SleepRecordPage {
  @State logs: Array<SleepLog> = []
  @State targetHours: number = DEFAULT_SLEEP_TARGET
  @State todayDuration: number = 0
  @State displayDate: string = DateUtils.getYMD()

  async onPageShow(): Promise<void> {
    await this.loadTarget()
    await this.loadTodayData()
  }

  private async loadTarget(): Promise<void> {
    const value = await preferencesUtil.getPreferenceValue('steps_ohos', 'sleep_target_hours', DEFAULT_SLEEP_TARGET) as number
    this.targetHours = typeof value === 'number' ? value : DEFAULT_SLEEP_TARGET
  }

  private async loadTodayData(): Promise<void> {
    const start = DateUtils.dateToTimestamp(this.displayDate)
    const end = start + 24 * 60 * 60 * 1000 - 1
    this.logs = await AppDataManager.getSleepLogsBetween(start, end)
    this.todayDuration = this.logs.reduce((sum: number, item: SleepLog) => sum + Math.max(0, item.end_time - item.start_time), 0)
  }

  private openAddDialog(log?: SleepLog): void {
    const now = systemDateTime.getTime()
    let start = log ? log.start_time : now - 8 * 60 * 60 * 1000
    let end = log ? log.end_time : now
    let quality = log ? log.quality : 3
    let note = log ? log.note : ''
    const controller: CustomDialogController = new CustomDialogController({
      builder: (): void => {
        SleepLogDialog({
          controller,
          title: log ? '编辑睡眠记录' : '新增睡眠记录',
          startTime: start,
          endTime: end,
          quality,
          note,
          onConfirm: (newStart: number, newEnd: number, newQuality: number, memo: string) => {
            if (newEnd <= newStart) {
              Utils.showToast('结束时间需晚于开始时间')
              return
            }
            if (log) {
              AppDataManager.updateSleepLog({ id: log.id, start_time: newStart, end_time: newEnd, quality: newQuality, note: memo })
            } else {
              AppDataManager.insertSleepLog(newStart, newEnd, newQuality, memo)
            }
            controller.close()
            setTimeout(() => this.loadTodayData(), 100)
          }
        })
      },
      alignment: DialogAlignment.Center,
      autoCancel: false
    })
    controller.open()
  }

  private openTargetDialog(): void {
    let value = this.targetHours
    const controller: CustomDialogController = new CustomDialogController({
      builder: (): void => {
        TargetDialog({
          controller,
          value,
          onChange: (v: number) => value = v,
          onConfirm: () => {
            preferencesUtil.putPreferenceValue('steps_ohos', 'sleep_target_hours', value)
            this.targetHours = value
            controller.close()
          }
        })
      },
      alignment: DialogAlignment.Center,
      autoCancel: false
    })
    controller.open()
  }

  private deleteLog(log: SleepLog): void {
    AppDataManager.deleteSleepLog(log.id)
    setTimeout(() => this.loadTodayData(), 50)
  }

  private formatDuration(ms: number): string {
    const totalMinutes = Math.max(0, Math.round(ms / (60 * 1000)))
    const hours = Math.floor(totalMinutes / 60)
    const minutes = totalMinutes % 60
    return `${hours}小时${minutes}分钟`
  }

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '睡眠记录' },
        cancel: () => router.back(),
      })

      Column() {
        Row() {
          Column() {
            Text('今日睡眠时长').fontSize(14).fontColor('#666666')
            Text(this.formatDuration(this.todayDuration)).fontSize(26).fontWeight(FontWeight.Bold).margin({ top: 4 })
          }
          .layoutWeight(1)
          Column() {
            Text('目标').fontSize(12).fontColor('#888888')
            Text(`${this.targetHours} 小时`).fontSize(18).fontColor('#0cc291').margin({ top: 2 })
          }
          Button('调整目标').margin({ left: 12 }).onClick(() => this.openTargetDialog())
        }
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 12 })

        Progress({
          value: this.targetHours > 0 ? Math.min(100, Math.round(this.todayDuration * 100 / (this.targetHours * 60 * 60 * 1000))) : 0
        })
          .width('100%')
      }
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      .backgroundColor('#E8F5E9')
      .borderRadius(16)
      .margin({ left: '4%', right: '4%', top: 12 })

      Row() {
        Text('今日记录').fontSize(16).fontWeight(FontWeight.Medium).layoutWeight(1)
        Button('新增').onClick(() => this.openAddDialog())
      }
      .padding({ left: 16, right: 16, top: 16, bottom: 8 })

      if (this.logs.length === 0) {
        Text('暂无记录，点击“新增”记录睡眠时间。').fontSize(14).fontColor('#999999').margin({ left: 16, right: 16, top: 40 })
      } else {
        List() {
          ForEach(this.logs, (item: SleepLog) => {
            ListItem() {
              Column() {
                Text(`${DateUtils.timeToDateNoYM(item.start_time)} - ${DateUtils.timeToDateNoYM(item.end_time)}`)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                Text(`时长 ${this.formatDuration(item.end_time - item.start_time)} · 质量 ${item.quality}/5`)
                  .fontSize(12)
                  .fontColor('#888888')
                  .margin({ top: 4 })
                if (item.note && item.note.length > 0) {
                  Text(item.note).fontSize(12).fontColor('#666666').margin({ top: 6 })
                }
                Row() {
                  Button('编辑').type(ButtonType.Normal).margin({ right: 12 }).onClick(() => this.openAddDialog(item))
                  Button('删除').type(ButtonType.Normal).backgroundColor('#FFD6D6').onClick(() => this.deleteLog(item))
                }
                .margin({ top: 12 })
              }
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
            }
            .margin({ left: 16, right: 16, bottom: 12 })
          }, (item: SleepLog) => item.id.toString())
        }
      }
    }
    .backgroundColor('#FFF5F5F5')
    .height('100%')
  }
}

@Component
struct SleepLogDialog {
  controller?: CustomDialogController = undefined
  title: string = ''
  startTime: number = systemDateTime.getTime()
  endTime: number = systemDateTime.getTime()
  quality: number = 3
  note: string = ''
  onConfirm: (start: number, end: number, quality: number, note: string) => void = () => {}

  private formatTime(value: number): string {
    const date = new Date(value)
    const hour = date.getHours().toString().padStart(2, '0')
    const minute = date.getMinutes().toString().padStart(2, '0')
    return `${hour}:${minute}`
  }

  private adjustStart(minutes: number): void {
    this.startTime += minutes * 60 * 1000
  }

  private adjustEnd(minutes: number): void {
    this.endTime += minutes * 60 * 1000
  }

  build() {
    Column() {
      Text(this.title).fontSize(18).fontWeight(FontWeight.Medium).margin({ bottom: 16 })

      Text('入睡时间').fontSize(14).fontColor('#666666')
      Row() {
        Button('-15').onClick(() => this.adjustStart(-15))
        Button('-5').margin({ left: 8 }).onClick(() => this.adjustStart(-5))
        Text(this.formatTime(this.startTime)).fontSize(20).fontWeight(FontWeight.Medium).margin({ left: 16, right: 16 })
        Button('+5').onClick(() => this.adjustStart(5))
        Button('+15').margin({ left: 8 }).onClick(() => this.adjustStart(15))
      }
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 12 })

      Text('醒来时间').fontSize(14).fontColor('#666666')
      Row() {
        Button('-15').onClick(() => this.adjustEnd(-15))
        Button('-5').margin({ left: 8 }).onClick(() => this.adjustEnd(-5))
        Text(this.formatTime(this.endTime)).fontSize(20).fontWeight(FontWeight.Medium).margin({ left: 16, right: 16 })
        Button('+5').onClick(() => this.adjustEnd(5))
        Button('+15').margin({ left: 8 }).onClick(() => this.adjustEnd(15))
      }
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 12 })

      Text('睡眠质量').fontSize(14).fontColor('#666666').margin({ bottom: 6 })
      Row() {
        ForEach([1, 2, 3, 4, 5], (score: number) => {
          Button(`${score}`)
            .backgroundColor(score === this.quality ? '#0cc291' : '#F5F5F5')
            .fontColor(score === this.quality ? '#ffffff' : '#333333')
            .margin({ right: 8 })
            .onClick(() => this.quality = score)
        })
      }
      .margin({ bottom: 12 })

      Text('备注').fontSize(14).fontColor('#666666').margin({ bottom: 6 })
      TextInput({ placeholder: '可选补充信息', text: this.note })
        .width('100%')
        .height(40)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .onChange((value: string) => this.note = value)

      Row() {
        Button('取消').type(ButtonType.Normal).layoutWeight(1).onClick(() => this.controller?.close())
        Button('保存').type(ButtonType.Capsule).layoutWeight(1).margin({ left: 12 }).onClick(() => {
          this.onConfirm(this.startTime, this.endTime, this.quality, this.note)
        })
      }
      .margin({ top: 20 })
    }
    .padding(20)
    .width('90%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }
}

@Component
struct TargetDialog {
  controller?: CustomDialogController = undefined
  value: number = DEFAULT_SLEEP_TARGET
  onChange: (value: number) => void = () => {}
  onConfirm: () => void = () => {}

  build() {
    Column() {
      Text('设置睡眠目标').fontSize(18).fontWeight(FontWeight.Medium).margin({ bottom: 16 })
      Row() {
        Button('-').onClick(() => {
          if (this.value > 4) {
            this.value -= 1
            this.onChange(this.value)
          }
        })
        Text(`${this.value} 小时`).fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 16, right: 16 })
        Button('+').onClick(() => {
          if (this.value < 12) {
            this.value += 1
            this.onChange(this.value)
          }
        })
      }
      .alignItems(VerticalAlign.Center)

      Row() {
        Button('取消').type(ButtonType.Normal).layoutWeight(1).onClick(() => this.controller?.close())
        Button('保存').type(ButtonType.Capsule).layoutWeight(1).margin({ left: 12 }).onClick(() => this.onConfirm())
      }
      .margin({ top: 20 })
    }
    .padding(20)
    .width('80%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }
}
