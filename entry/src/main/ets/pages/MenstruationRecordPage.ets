import { router } from '@kit.ArkUI';
import { MenstruationLog } from '../appdata/Model';
import AppDataManager from '../tools/AppDataManager';
import preferencesUtil from '../tools/DataPreUtils';
import { DateUtils } from '../tools/DateUtils';
import { CommonTitleView } from '../view/CommonTitleView';
import { Utils } from '../tools/Utils';
import { systemDateTime } from '@kit.BasicServicesKit';

const DEFAULT_CYCLE_LENGTH = 28


@Entry
@Component
struct MenstruationRecordPage {
  @State logs: Array<MenstruationLog> = []
  @State cycleLength: number = DEFAULT_CYCLE_LENGTH
  @State nextPrediction: string = '暂无数据'

  async onPageShow(): Promise<void> {
    await this.loadCyclePreference()
    await this.loadLogs()
  }

  private async loadCyclePreference(): Promise<void> {
    const value = await preferencesUtil.getPreferenceValue('steps_ohos', 'menstrual_cycle_length', DEFAULT_CYCLE_LENGTH) as number
    this.cycleLength = typeof value === 'number' ? value : DEFAULT_CYCLE_LENGTH
  }

  private async loadLogs(): Promise<void> {
    this.logs = await AppDataManager.getMenstruationLogs(50)
    if (this.logs.length > 0) {
      const last = this.logs[0]
      const nextStart = last.start_time + this.cycleLength * 24 * 60 * 60 * 1000
      this.nextPrediction = DateUtils.timeToDateNoYM(nextStart)
    } else {
      this.nextPrediction = '暂无数据'
    }
  }

  private openRecordDialog(log?: MenstruationLog): void {
    const now = systemDateTime.getTime()
    let start = log ? log.start_time : now
    let end = log ? log.end_time : now
    let cycle = log ? log.cycle_length : this.cycleLength
    let note = log ? log.note : ''
    const controller: CustomDialogController = new CustomDialogController({
      builder: (): void => {
        MenstruationDialog({
          controller,
          title: log ? '编辑生理期记录' : '新增生理期记录',
          startTime: start,
          endTime: end,
          cycleLength: cycle,
          note,
          onConfirm: (newStart: number, newEnd: number, newCycle: number, memo: string) => {
            if (newEnd < newStart) {
              Utils.showToast('结束日期不能早于开始日期')
              return
            }
            if (log) {
              AppDataManager.updateMenstruationLog({ id: log.id, start_time: newStart, end_time: newEnd, cycle_length: newCycle, note: memo })
            } else {
              AppDataManager.insertMenstruationLog(newStart, newEnd, newCycle, memo)
            }
            preferencesUtil.putPreferenceValue('steps_ohos', 'menstrual_cycle_length', newCycle)
            controller.close()
            setTimeout(async () => {
              await this.loadCyclePreference()
              await this.loadLogs()
            }, 100)
          }
        })
      },
      alignment: DialogAlignment.Center,
      autoCancel: false
    })
    controller.open()
  }

  private deleteLog(log: MenstruationLog): void {
    AppDataManager.deleteMenstruationLog(log.id)
    setTimeout(async () => {
      await this.loadLogs()
    }, 50)
  }

  private formatPeriodSummary(log: MenstruationLog): string {
    const duration = Math.max(1, Math.round((log.end_time - log.start_time) / (24 * 60 * 60 * 1000)) + 1)
    return `持续 ${duration} 天，周期 ${log.cycle_length} 天`
  }

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '生理期记录' },
        cancel: () => router.back(),
      })

      Column() {
        Text('周期长度').fontSize(14).fontColor('#666666')
        Text(`${this.cycleLength} 天`).fontSize(26).fontWeight(FontWeight.Bold).margin({ top: 4 })
        Text('预计下次：' + this.nextPrediction).fontSize(14).fontColor('#888888').margin({ top: 6 })
        Button('记录本次生理期').margin({ top: 16 }).onClick(() => this.openRecordDialog())
      }
      .padding({ left: 20, right: 20, top: 20, bottom: 20 })
      .backgroundColor('#FFE8F0')
      .borderRadius(16)
      .margin({ left: '4%', right: '4%', top: 12 })

      Text('历史记录').fontSize(16).fontWeight(FontWeight.Medium).margin({ left: 16, top: 16, bottom: 8 })

      if (this.logs.length === 0) {
        Text('暂无记录，点击上方按钮开始记录生理期。')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ left: 16, right: 16, top: 40 })
      } else {
        List() {
          ForEach(this.logs, (item: MenstruationLog) => {
            ListItem() {
              Column() {
                Text(`${DateUtils.timeToDateNoYM(item.start_time)} - ${DateUtils.timeToDateNoYM(item.end_time)}`)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                Text(this.formatPeriodSummary(item)).fontSize(12).fontColor('#888888').margin({ top: 4 })
                if (item.note && item.note.length > 0) {
                  Text(item.note).fontSize(12).fontColor('#666666').margin({ top: 6 })
                }
                Row() {
                  Button('编辑').type(ButtonType.Normal).margin({ right: 12 }).onClick(() => this.openRecordDialog(item))
                  Button('删除').type(ButtonType.Normal).backgroundColor('#FFD6D6').onClick(() => this.deleteLog(item))
                }
                .margin({ top: 12 })
              }
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
            }
            .margin({ left: 16, right: 16, bottom: 12 })
          }, (item: MenstruationLog) => item.id.toString())
        }
      }
    }
    .backgroundColor('#FFF5F5F5')
    .height('100%')
  }
}

@Component
struct MenstruationDialog {
  controller?: CustomDialogController = undefined
  title: string = ''
  startTime: number = systemDateTime.getTime()
  endTime: number = systemDateTime.getTime()
  cycleLength: number = DEFAULT_CYCLE_LENGTH
  note: string = ''
  onConfirm: (start: number, end: number, cycle: number, note: string) => void = () => {}

  private getStartDate(): Date {
    return new Date(this.startTime)
  }

  private getEndDate(): Date {
    return new Date(this.endTime)
  }

  build() {
    Column() {
      Text(this.title).fontSize(18).fontWeight(FontWeight.Medium).margin({ bottom: 16 })
      Text('开始日期').fontSize(14).fontColor('#666666')
      DatePicker({
        start: new Date('2010-01-01'),
        end: new Date('2100-12-31'),
        selected: this.getStartDate()
      }).onDateChange((value: Date) => {
        const selectedTime: number = value.getTime()
        this.startTime = selectedTime
        if (this.endTime < this.startTime) {
          this.endTime = this.startTime
        }
      })
      .margin({ bottom: 12 })

      Text('结束日期').fontSize(14).fontColor('#666666')
      DatePicker({
        start: new Date('2010-01-01'),
        end: new Date('2100-12-31'),
        selected: this.getEndDate()
      }).onDateChange((value: Date) => {
        this.endTime = value.getTime()
      })
      .margin({ bottom: 12 })

      Text('周期长度（天）').fontSize(14).fontColor('#666666').margin({ bottom: 6 })
      Row() {
        Button('-').onClick(() => {
          if (this.cycleLength > 20) {
            this.cycleLength -= 1
          }
        })
        Text(`${this.cycleLength}`).fontSize(20).fontWeight(FontWeight.Medium).margin({ left: 16, right: 16 })
        Button('+').onClick(() => {
          if (this.cycleLength < 40) {
            this.cycleLength += 1
          }
        })
      }
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 12 })

      Text('备注').fontSize(14).fontColor('#666666').margin({ bottom: 6 })
      TextInput({ placeholder: '可选补充说明', text: this.note })
        .width('100%')
        .height(40)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .onChange((value: string) => this.note = value)

      Row() {
        Button('取消').type(ButtonType.Normal).layoutWeight(1).onClick(() => this.controller?.close())
        Button('保存').type(ButtonType.Capsule).layoutWeight(1).margin({ left: 12 }).onClick(() => {
          this.onConfirm(this.startTime, this.endTime, this.cycleLength, this.note)
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
