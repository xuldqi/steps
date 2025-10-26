import { router } from '@kit.ArkUI';
import { MoodLog } from '../appdata/Model';
import AppDataManager from '../tools/AppDataManager';
import { DateUtils } from '../tools/DateUtils';
import { CommonTitleView } from '../view/CommonTitleView';
import { Utils } from '../tools/Utils';
import { systemDateTime } from '@kit.BasicServicesKit';

@Entry
@Component
struct MoodRecordPage {
  @State logs: Array<MoodLog> = []
  @State displayDate: string = DateUtils.getYMD()
  @State averageScore: number = 0

  async onPageShow(): Promise<void> {
    await this.loadTodayData()
  }

  private async loadTodayData(): Promise<void> {
    const start = DateUtils.dateToTimestamp(this.displayDate)
    const end = start + 24 * 60 * 60 * 1000 - 1
    this.logs = await AppDataManager.getMoodLogsBetween(start, end)
    if (this.logs.length === 0) {
      this.averageScore = 0
    } else {
      const total: number = this.logs.reduce((sum: number, item: MoodLog) => sum + item.score, 0)
      const average: number = total / this.logs.length
      this.averageScore = Number.parseFloat(average.toFixed(1))
    }
  }

  private openAddDialog(log?: MoodLog): void {
    let score = log ? log.score : 3
    let note = log ? log.note : ''
    const controller: CustomDialogController = new CustomDialogController({
      builder: (): void => {
        MoodDialog({
          controller,
          title: log ? '编辑今日心情' : '记录今日心情',
          score,
          note,
          onConfirm: (newScore: number, memo: string) => {
            if (log) {
              AppDataManager.updateMoodLog({ id: log.id, time: log.time, score: newScore, note: memo })
            } else {
              AppDataManager.insertMoodLog(newScore, memo)
            }
            controller.close()
            setTimeout(() => this.loadTodayData(), 50)
          }
        })
      },
      alignment: DialogAlignment.Bottom,
      autoCancel: false
    })
    controller.open()
  }

  private deleteLog(log: MoodLog): void {
    AppDataManager.deleteMoodLog(log.id)
    setTimeout(() => this.loadTodayData(), 50)
  }

  private formatScore(score: number): string {
    switch (score) {
      case 5: return '非常棒'
      case 4: return '不错'
      case 3: return '一般'
      case 2: return '有点糟'
      case 1: return '不开心'
      default: return ''
    }
  }

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '今日感受' },
        cancel: () => router.back(),
      })

      Column() {
        Text('今日平均心情').fontSize(14).fontColor('#666666')
        if (this.logs.length === 0) {
          Text('暂未记录').fontSize(28).fontWeight(FontWeight.Bold).margin({ top: 4 })
        } else {
          Text(`${this.averageScore} / 5`).fontSize(28).fontWeight(FontWeight.Bold).margin({ top: 4 })
        }
        Button('记录心情').margin({ top: 16 }).onClick(() => this.openAddDialog())
      }
      .padding({ left: 20, right: 20, top: 20, bottom: 20 })
      .backgroundColor('#F3E5F5')
      .borderRadius(16)
      .margin({ left: '4%', right: '4%', top: 12 })

      Text('历史记录').fontSize(16).fontWeight(FontWeight.Medium).margin({ left: 16, top: 16, bottom: 8 })

      if (this.logs.length === 0) {
        Text('暂无记录，点击“记录心情”写下今日的感受。').fontSize(14).fontColor('#999999').margin({ left: 16, right: 16, top: 40 })
      } else {
        List() {
          ForEach(this.logs, (item: MoodLog) => {
            ListItem() {
              Column() {
                Text(`${this.formatScore(item.score)} (${item.score}/5)`).fontSize(16).fontWeight(FontWeight.Medium)
                Text(DateUtils.timeToDateNoY(item.time)).fontSize(12).fontColor('#888888').margin({ top: 4 })
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
          }, (item: MoodLog) => item.id.toString())
        }
      }
    }
    .backgroundColor('#FFF5F5F5')
    .height('100%')
  }
}

@Component
struct MoodDialog {
  controller?: CustomDialogController = undefined
  title: string = ''
  score: number = 3
  note: string = ''
  onConfirm: (score: number, note: string) => void = () => {}

  build() {
    Column() {
      Text(this.title).fontSize(18).fontWeight(FontWeight.Medium).margin({ bottom: 16 })

      Text('选择心情').fontSize(14).fontColor('#666666').margin({ bottom: 8 })
      Row() {
        ForEach([1,2,3,4,5], (i: number) => {
          Button(`${i}`)
            .backgroundColor(i === this.score ? '#0cc291' : '#F5F5F5')
            .fontColor(i === this.score ? '#ffffff' : '#333333')
            .margin({ right: 8 })
            .onClick(() => this.score = i)
        })
      }
      .margin({ bottom: 12 })

      Text('备注').fontSize(14).fontColor('#666666').margin({ bottom: 6 })
      TextInput({ placeholder: '记录原因或想法', text: this.note })
        .width('100%')
        .height(40)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .onChange((value: string) => this.note = value)

      Row() {
        Button('取消').type(ButtonType.Normal).layoutWeight(1).onClick(() => this.controller?.close())
        Button('保存').type(ButtonType.Capsule).layoutWeight(1).margin({ left: 12 }).onClick(() => {
          this.onConfirm(this.score, this.note)
        })
      }
      .margin({ top: 20 })
    }
    .padding(20)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }
}
