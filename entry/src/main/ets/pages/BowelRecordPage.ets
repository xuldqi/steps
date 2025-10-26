import { router } from '@kit.ArkUI';
import { BowelLog } from '../appdata/Model';
import AppDataManager from '../tools/AppDataManager';
import { DateUtils } from '../tools/DateUtils';
import { CommonTitleView } from '../view/CommonTitleView';
import { Utils } from '../tools/Utils';

const BOWEL_STATUS_OPTIONS: Array<string> = ['正常', '稍硬', '便秘', '腹泻']

@Entry
@Component
struct BowelRecordPage {
  @State logs: Array<BowelLog> = []
  @State displayDate: string = DateUtils.getYMD()

  async onPageShow(): Promise<void> {
    await this.loadTodayData()
  }

  private async loadTodayData(): Promise<void> {
    const start = DateUtils.dateToTimestamp(this.displayDate)
    const end = start + 24 * 60 * 60 * 1000 - 1
    this.logs = await AppDataManager.getBowelLogsBetween(start, end)
  }

  private openAddDialog(log?: BowelLog): void {
    let status = log ? log.status : BOWEL_STATUS_OPTIONS[0]
    let note = log ? log.note : ''
    const controller: CustomDialogController = new CustomDialogController({
      builder: (): void => {
        BowelLogDialog({
          controller,
          title: log ? '编辑排便记录' : '新增排便记录',
          status,
          note,
          onConfirm: (selected: string, memo: string) => {
            if (log) {
              AppDataManager.updateBowelLog({ id: log.id, time: log.time, status: selected, note: memo })
            } else {
              AppDataManager.insertBowelLog(selected, memo)
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

  private deleteLog(log: BowelLog): void {
    AppDataManager.deleteBowelLog(log.id)
    setTimeout(() => this.loadTodayData(), 50)
  }

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '排便记录' },
        cancel: () => router.back(),
      })

    Row() {
        Text('今日排便记录')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
        Button('新增')
          .onClick(() => this.openAddDialog())
      }
      .padding({ left: 16, right: 16, top: 16, bottom: 8 })

      if (this.logs.length === 0) {
        Text('暂无记录，点击“新增”开始记录今日的排便情况。')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ left: 16, right: 16, top: 40 })
      } else {
        List() {
          ForEach(this.logs, (item: BowelLog) => {
            ListItem() {
              Row() {
                Column() {
                  Text(item.status)
                    .fontSize(18)
                    .fontWeight(FontWeight.Medium)
                  Text(DateUtils.timeToDateNoY(item.time))
                    .fontSize(12)
                    .fontColor('#888888')
                    .margin({ top: 4 })
                  if (item.note && item.note.length > 0) {
                    Text(item.note)
                      .fontSize(12)
                      .fontColor('#666666')
                      .margin({ top: 6 })
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
          }, (item: BowelLog) => item.id.toString())
        }
      }
    }
    .backgroundColor('#FFF5F5F5')
    .height('100%')
  }
}

@Component
struct BowelLogDialog {
  controller?: CustomDialogController = undefined
  title: string = ''
  status: string = BOWEL_STATUS_OPTIONS[0]
  note: string = ''
  onConfirm: (status: string, note: string) => void = () => {}

  build() {
    Column() {
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 12 })

      Text('状态').fontSize(14).fontColor('#666666').margin({ bottom: 8 })
      Flex({ justifyContent: FlexAlign.SpaceBetween, wrap: FlexWrap.Wrap }) {
        ForEach(BOWEL_STATUS_OPTIONS, (item: string) => {
          Button(item)
            .type(ButtonType.Normal)
            .backgroundColor(item === this.status ? '#0cc291' : '#F5F5F5')
            .fontColor(item === this.status ? '#ffffff' : '#333333')
            .margin({ bottom: 8 })
            .onClick(() => {
              this.status = item
            })
        })
      }
      .margin({ bottom: 12 })

      Text('备注').fontSize(14).fontColor('#666666').margin({ bottom: 6 })
      TextInput({ placeholder: '可选补充说明', text: this.note })
        .width('100%')
        .height(40)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .onChange((value: string) => this.note = value)

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
            if (!this.status) {
              Utils.showToast('请选择状态')
              return
            }
            this.onConfirm(this.status, this.note)
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
