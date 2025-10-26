import { router } from '@kit.ArkUI';
import { WaterLog } from '../appdata/Model';
import AppDataManager from '../tools/AppDataManager';
import preferencesUtil from '../tools/DataPreUtils';
import { DateUtils } from '../tools/DateUtils';
import { CommonTitleView } from '../view/CommonTitleView';
import { Utils } from '../tools/Utils';

const DEFAULT_WATER_TARGET = 2000

@Entry
@Component
struct WaterRecordPage {
  @State logs: Array<WaterLog> = []
  @State totalToday: number = 0
  @State targetAmount: number = DEFAULT_WATER_TARGET
  @State displayDate: string = DateUtils.getYMD()

  async onPageShow(): Promise<void> {
    await this.loadTarget()
    await this.loadTodayData()
  }

  private async loadTarget(): Promise<void> {
    const target = await preferencesUtil.getPreferenceValue('steps_ohos', 'water_target', DEFAULT_WATER_TARGET) as number
    if (typeof target === 'number') {
      this.targetAmount = target
    } else {
      this.targetAmount = DEFAULT_WATER_TARGET
    }
  }

  private async loadTodayData(): Promise<void> {
    const start = DateUtils.dateToTimestamp(this.displayDate)
    const end = start + 24 * 60 * 60 * 1000 - 1
    this.logs = await AppDataManager.getWaterLogsBetween(start, end)
    this.totalToday = this.logs.reduce((sum: number, item: WaterLog) => sum + item.amount, 0)
  }

  private openAddDialog(log?: WaterLog): void {
    let amount = log ? log.amount : 250
    let note = log ? log.note : ''
    const controller: CustomDialogController = new CustomDialogController({
      builder: (): void => {
        WaterLogDialog({
          controller,
          title: log ? '编辑喝水记录' : '新增喝水记录',
          amount,
          note,
          onConfirm: (value: number, text: string) => {
            if (log) {
              AppDataManager.updateWaterLog({ id: log.id, time: log.time, amount: value, note: text })
            } else {
              AppDataManager.insertWaterLog(value, text)
            }
            controller.close()
            setTimeout(() => this.loadTodayData(), 100)
          }
        })
      },
      alignment: DialogAlignment.Bottom,
      autoCancel: false
    })
    controller.open()
  }

  private openTargetDialog(): void {
    let tempValue = this.targetAmount
    const controller: CustomDialogController = new CustomDialogController({
      builder: (): void => {
        TargetDialog({
          controller,
          value: tempValue,
          onChange: (v: number) => {
            tempValue = v
          },
          onConfirm: () => {
            preferencesUtil.putPreferenceValue('steps_ohos', 'water_target', tempValue)
            this.targetAmount = tempValue
            controller.close()
          }
        })
      },
      alignment: DialogAlignment.Center,
      autoCancel: false
    })
    controller.open()
  }

  private deleteLog(log: WaterLog): void {
    AppDataManager.deleteWaterLog(log.id)
    setTimeout(() => this.loadTodayData(), 50)
  }

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '喝水记录' },
        cancel: () => router.back(),
      })

      Column() {
        Row() {
          Column() {
            Text('今日饮水').fontSize(14).fontColor('#666666')
            Text(`${this.totalToday} ml`).fontSize(28).fontWeight(FontWeight.Bold).fontColor('#121212').margin({ top: 4 })
          }
          .layoutWeight(1)

          Column() {
            Text('目标').fontSize(12).fontColor('#888888')
            Text(`${this.targetAmount} ml`).fontSize(18).fontColor('#0cc291').margin({ top: 2 })
          }
          Button('调整目标')
            .margin({ left: 12 })
            .onClick(() => this.openTargetDialog())
        }
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 12 })

        Progress({
          value: this.targetAmount > 0 ? Math.min(100, Math.round(this.totalToday * 100 / this.targetAmount)) : 0
        })
          .width('100%')
      }
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      .backgroundColor('#F2FBF6')
      .borderRadius(16)
      .margin({ left: '4%', right: '4%', top: 12 })

      Row() {
        Text('今日记录')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
        Button('新增')
          .onClick(() => this.openAddDialog())
      }
      .padding({ left: 16, right: 16, top: 12, bottom: 6 })

      if (this.logs.length === 0) {
        Text('暂无记录，点击上方“新增”添加今日的第一杯水。')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ left: 16, right: 16, top: 40 })
      } else {
        List() {
          ForEach(this.logs, (item: WaterLog) => {
            ListItem() {
              Row() {
                Column() {
                  Text(`${item.amount} ml`).fontSize(18).fontWeight(FontWeight.Medium)
                  Text(DateUtils.timeToDateNoY(item.time)).fontSize(12).fontColor('#888888').margin({ top: 4 })
                  if (item.note && item.note.length > 0) {
                    Text(item.note).fontSize(12).fontColor('#666666').margin({ top: 6 })
                  }
                }
                .layoutWeight(1)

                Button('编辑')
                  .type(ButtonType.Normal)
                  .margin({ right: 8 })
                  .onClick(() => this.openAddDialog(item))
                Button('删除')
                  .type(ButtonType.Normal)
                  .backgroundColor('#FFD6D6')
                  .onClick(() => this.deleteLog(item))
              }
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
            }
            .margin({ left: 16, right: 16, bottom: 12 })
          }, (item: WaterLog) => item.id.toString())
        }
      }
    }
    .backgroundColor('#FFF5F5F5')
    .height('100%')
  }
}

@Component
struct WaterLogDialog {
  controller?: CustomDialogController = undefined
  title: string = ''
  amount: number = 0
  note: string = ''
  onConfirm: (amount: number, note: string) => void = () => {}

  build() {
    Column() {
      Text(this.title).fontSize(18).fontWeight(FontWeight.Medium).margin({ bottom: 12 })
      Row() {
        Button('-')
          .onClick(() => {
            if (this.amount > 50) {
              this.amount -= 50
            }
          })
        Text(`${this.amount} ml`).fontSize(20).fontWeight(FontWeight.Medium).margin({ left: 16, right: 16 })
        Button('+')
          .onClick(() => {
            this.amount += 50
          })
      }
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 12 })

      Text('备注').fontSize(14).fontColor('#666666').margin({ bottom: 6 })
      TextInput({ placeholder: '可选，记录感受或时间', text: this.note })
        .width('100%')
        .height(40)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .onChange((value: string) => this.note = value)

      Row() {
        Button('取消')
          .type(ButtonType.Normal)
          .backgroundColor('#F1F1F1')
          .layoutWeight(1)
          .onClick(() => this.controller?.close())
        Button('保存')
          .type(ButtonType.Capsule)
          .layoutWeight(1)
          .margin({ left: 12 })
          .onClick(() => {
            if (this.amount <= 0) {
              Utils.showToast('饮水量必须大于0')
              return
            }
            this.onConfirm(this.amount, this.note)
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

@Component
struct TargetDialog {
  controller?: CustomDialogController = undefined
  value: number = DEFAULT_WATER_TARGET
  onChange: (value: number) => void = () => {}
  onConfirm: () => void = () => {}

  build() {
    Column() {
      Text('设置每日饮水目标').fontSize(18).fontWeight(FontWeight.Medium).margin({ bottom: 16 })
      Row() {
        Button('-')
          .onClick(() => {
            if (this.value > 500) {
              this.value -= 100
              this.onChange(this.value)
            }
          })
        Text(`${this.value} ml`).fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 16, right: 16 })
        Button('+')
          .onClick(() => {
            if (this.value < 5000) {
              this.value += 100
              this.onChange(this.value)
            }
          })
      }
      .alignItems(VerticalAlign.Center)

      Row() {
        Button('取消')
          .type(ButtonType.Normal)
          .layoutWeight(1)
          .onClick(() => this.controller?.close())
        Button('保存')
          .type(ButtonType.Capsule)
          .layoutWeight(1)
          .margin({ left: 12 })
          .onClick(() => {
            if (this.value <= 0) {
              Utils.showToast('目标必须大于0')
              return
            }
            this.onConfirm()
          })
      }
      .margin({ top: 24 })
    }
    .padding(20)
    .width('80%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }
}
