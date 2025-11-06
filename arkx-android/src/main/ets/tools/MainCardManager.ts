import preferencesUtil from './PreferencesUtil'

export class MainCardManager {
  public static readonly HEAD_ADD: number = 0
  public static readonly HEAD_DELETE: number = -1
  public static readonly STEPS_DISTANCE: number = 1
  public static readonly STEPS_ENERGY: number = 2
  public static readonly STEPS_SPORTS: number = 3
  public static readonly STEPS_COUNT_TIME: number = 4
  public static readonly STEPS_BODY_DATA: number = 5
  public static readonly STEPS_WEIGHT: number = 6
  public static readonly STEPS_CARD_STORE_KEY: string = 'STEPS_CARD_STORE_KEY'
  
  private defaultShowCard: string = '1,2,3,4,5,6,'
  private set: Array<number> = []
  private isMainCardChanged: boolean = true

  public async loadMainCardManager() {
    const dataStr: string = await preferencesUtil.getPreferenceValue('steps_ohos', MainCardManager.STEPS_CARD_STORE_KEY, this.defaultShowCard)
    const items: string[] = dataStr.split(',')
    this.set.length = 0
    for (let i = 0; i < items.length; i++) {
      if (items[i].trim() !== null && items[i].trim() !== '') {
        this.set.push(parseInt(items[i]))
      }
    }
  }

  public saveItemCardData(types: string) {
    this.isMainCardChanged = true
    preferencesUtil.putPreferenceValue('steps_ohos', MainCardManager.STEPS_CARD_STORE_KEY, types)
    this.set.length = 0
    const items: string[] = types.split(',')
    for (let i = 0; i < items.length; i++) {
      if (items[i].trim() !== null && items[i].trim() !== '') {
        this.set.push(parseInt(items[i]))
      }
    }
    this.setMainCardChangedCreate()
  }

  public getType(type: number): string {
    switch (type) {
      case MainCardManager.HEAD_ADD:
        return '已展示数据'
      case MainCardManager.HEAD_DELETE:
        return '未展示数据'
      case MainCardManager.STEPS_DISTANCE:
        return '走路距离'
      case MainCardManager.STEPS_ENERGY:
        return '热量消耗'
      case MainCardManager.STEPS_SPORTS:
        return '运动记录'
      case MainCardManager.STEPS_COUNT_TIME:
        return '时间计时'
      case MainCardManager.STEPS_BODY_DATA:
        return '身体数据'
      case MainCardManager.STEPS_WEIGHT:
        return '体重记录'
    }
    return ''
  }

  public getMainCardChanged(): boolean {
    return this.isMainCardChanged
  }

  public setMainCardChangedAlreadyUpdate() {
    this.isMainCardChanged = false
  }

  public setMainCardChangedCreate() {
    this.isMainCardChanged = true
  }

  public isItemCardShow(type: number): boolean {
    return this.set.includes(type)
  }

  public getCardSet(): Array<number> {
    return [...this.set]
  }
}

const mainCardManager = new MainCardManager()
export default mainCardManager

