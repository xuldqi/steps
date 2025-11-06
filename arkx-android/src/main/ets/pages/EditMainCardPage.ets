import { router } from '@kit.ArkUI'
import { MainCardItemModel } from '../appdata/Model'
import mainCardManager from '../tools/MainCardManager'
import { MainCardManager } from '../tools/MainCardManager'
import { CommonTitleView } from '../view/CommonTitleView'

@Entry
@Component
struct EditMainCardPage {
  @State mainCardItemModels: Array<MainCardItemModel> = []

  onPageShow() {
    this.loadCards()
  }

  private loadCards() {
    this.mainCardItemModels.length = 0
    const mainCards = mainCardManager.getCardSet()
    
    // 添加"已展示数据"标题
    const headAdd: MainCardItemModel = {
      id: 0,
      isAdded: false,
      type: MainCardManager.HEAD_ADD,
      title: mainCardManager.getType(MainCardManager.HEAD_ADD),
      visible: true
    }
    this.mainCardItemModels.push(headAdd)

    // 所有可用的卡片类型
    const allCardTypes = [
      MainCardManager.STEPS_DISTANCE,
      MainCardManager.STEPS_ENERGY,
      MainCardManager.STEPS_SPORTS,
      MainCardManager.STEPS_COUNT_TIME,
      MainCardManager.STEPS_BODY_DATA,
      MainCardManager.STEPS_WEIGHT
    ]

    // 添加已展示的卡片
    for (const cardType of mainCards) {
      const item: MainCardItemModel = {
        id: cardType,
        isAdded: true,
        type: cardType,
        title: mainCardManager.getType(cardType),
        visible: true
      }
      this.mainCardItemModels.push(item)
    }

    // 添加"未展示数据"标题
    const headDelete: MainCardItemModel = {
      id: -1,
      isAdded: false,
      type: MainCardManager.HEAD_DELETE,
      title: mainCardManager.getType(MainCardManager.HEAD_DELETE),
      visible: true
    }
    this.mainCardItemModels.push(headDelete)

    // 添加未展示的卡片
    for (const cardType of allCardTypes) {
      if (!mainCards.includes(cardType)) {
        const item: MainCardItemModel = {
          id: cardType,
          isAdded: false,
          type: cardType,
          title: mainCardManager.getType(cardType),
          visible: true
        }
        this.mainCardItemModels.push(item)
      }
    }
  }

  private toggleCardVisibility(item: MainCardItemModel, index: number) {
    const targetItem = this.mainCardItemModels[index]
    if (!targetItem || targetItem.type === MainCardManager.HEAD_ADD || targetItem.type === MainCardManager.HEAD_DELETE) {
      return
    }

    const toggled = !targetItem.isAdded
    targetItem.isAdded = toggled

    // 从原位置移除
    this.mainCardItemModels.splice(index, 1)

    // 找到分隔符位置
    const headDeleteIndex = this.getHeadIndex(MainCardManager.HEAD_DELETE)
    if (headDeleteIndex < 0) {
      return
    }

    // 重新插入到对应的分组位置
    if (toggled) {
      // 加入「已展示」列表，放在删除分隔符之前
      this.mainCardItemModels.splice(headDeleteIndex, 0, targetItem)
    } else {
      // 加入「未展示」列表，放在删除分隔符之后
      this.mainCardItemModels.splice(headDeleteIndex + 1, 0, targetItem)
    }

    this.saveData()
  }

  private saveData() {
    let data = ''
    for (const item of this.mainCardItemModels) {
      if (item.isAdded && item.type !== MainCardManager.HEAD_ADD && item.type !== MainCardManager.HEAD_DELETE) {
        data = data + item.type + ','
      }
    }
    mainCardManager.saveItemCardData(data)
  }

  private getHeadIndex(type: number): number {
    for (let i = 0; i < this.mainCardItemModels.length; i++) {
      if (this.mainCardItemModels[i].type === type) {
        return i
      }
    }
    return -1
  }

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '编辑卡片' },
        cancel: () => {
          router.back()
        },
        useSafeTop: true
      })

      List() {
        ForEach(this.mainCardItemModels, (item: MainCardItemModel, index: number) => {
          if (item.type === MainCardManager.HEAD_ADD || item.type === MainCardManager.HEAD_DELETE) {
            ListItem() {
              Text(item.title)
                .fontColor('#757575')
                .width('100%')
                .textAlign(TextAlign.Start)
                .padding(15)
            }
            .width('100%')
          } else {
            ListItem() {
              Row() {
                Text(item.title)
                  .layoutWeight(1)
                  .margin({ left: 24 })
                  .fontSize(16)
                  .fontWeight(500)

                Image(item.isAdded ? $r('app.media.main_card_del') : $r('app.media.main_card_add'))
                  .width(20)
                  .height(20)
                  .margin({ right: 24 })
                  .onClick(() => {
                    this.toggleCardVisibility(item, index)
                  })
              }
              .width('100%')
              .height(56)
              .backgroundColor('#FFFFFF')
              .borderRadius(18)
              .alignItems(VerticalAlign.Center)
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 6, bottom: 6 })
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

