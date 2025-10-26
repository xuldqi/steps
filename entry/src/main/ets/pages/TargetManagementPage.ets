import { router } from '@kit.ArkUI'
import { CommonTitleView } from '../view/CommonTitleView'
import preferencesUtil from '../tools/DataPreUtils'
import { Utils } from '../tools/Utils'

interface TargetItem {
  key: string
  name: string
  unit: string
  defaultValue: number
  maxValue: number
  step: number
  currentValue: number
  displayFormat: string
}

interface PickerResult {
  index: number
}

@Entry
@Component
struct TargetManagementPage {
  @State targets: Array<TargetItem> = [
    {
      key: 'step_target',
      name: '走路步数',
      unit: '步',
      defaultValue: 5000,
      maxValue: 50000,
      step: 1000,
      currentValue: 5000,
      displayFormat: 'xxx步/天'
    },
    {
      key: 'weight_target',
      name: '目标体重',
      unit: '公斤',
      defaultValue: 50,
      maxValue: 300,
      step: 0.1,
      currentValue: 50,
      displayFormat: 'xxx公斤'
    },
    {
      key: 'distance_target',
      name: '走路距离',
      unit: '米',
      defaultValue: 3000,
      maxValue: 50000,
      step: 500,
      currentValue: 3000,
      displayFormat: 'xxx米/天'
    },
    {
      key: 'calorie_target',
      name: '热量消耗',
      unit: '千卡',
      defaultValue: 300,
      maxValue: 2000,
      step: 10,
      currentValue: 300,
      displayFormat: 'xxx千卡/天'
    },
    {
      key: 'exercise_time_target',
      name: '锻炼时长',
      unit: '分钟',
      defaultValue: 25,
      maxValue: 1440,
      step: 1,
      currentValue: 25,
      displayFormat: 'xxx分钟/天'
    },
    {
      key: 'activity_count_target',
      name: '活动次数',
      unit: '次',
      defaultValue: 12,
      maxValue: 24,
      step: 1,
      currentValue: 12,
      displayFormat: 'xx次/天'
    }
  ]

  @State selectedTarget: TargetItem | null = null
  @State isWeightUnitKg: boolean = true

  async onPageShow() {
    await this.loadCurrentTargets()
  }

  private async loadCurrentTargets() {
    if (!preferencesUtil.preferencesMap.has('steps_ohos')) {
      return
    }

    for (let i = 0; i < this.targets.length; i++) {
      const target = this.targets[i]
      const currentValue = await preferencesUtil.getPreferenceValue('steps_ohos', target.key, target.defaultValue) as number
      this.targets[i].currentValue = currentValue
    }

    // 加载体重单位设置
    const weightUnit = await preferencesUtil.getPreferenceValue('steps_ohos', 'weight_unit_kg', true) as boolean
    this.isWeightUnitKg = weightUnit
    this.updateWeightUnit()
  }

  private updateWeightUnit() {
    const weightTarget = this.targets.find(t => t.key === 'weight_target')
    if (weightTarget) {
      if (this.isWeightUnitKg) {
        weightTarget.unit = '公斤'
        weightTarget.maxValue = 300
        weightTarget.displayFormat = 'xxx公斤'
      } else {
        weightTarget.unit = '斤'
        weightTarget.maxValue = 600
        weightTarget.displayFormat = 'xxx斤'
        // 转换当前值
        weightTarget.currentValue = Math.round(weightTarget.currentValue * 2 * 10) / 10
      }
    }
  }

  private openTargetAdjustDialog(target: TargetItem) {
    this.selectedTarget = {
      key: target.key,
      name: target.name,
      unit: target.unit,
      defaultValue: target.defaultValue,
      maxValue: target.maxValue,
      step: target.step,
      currentValue: target.currentValue,
      displayFormat: target.displayFormat
    }
    
    // 简单的数值调整：增加一个步长
    const currentValue = this.selectedTarget.currentValue
    const newValue = currentValue + this.selectedTarget.step
    
    if (newValue <= this.selectedTarget.maxValue) {
      this.selectedTarget.currentValue = newValue
      this.onTargetAdjustConfirm(newValue)
    } else {
      // 如果超过最大值，重置为最小值
      this.selectedTarget.currentValue = this.selectedTarget.step
      this.onTargetAdjustConfirm(this.selectedTarget.step)
    }
  }

  private async onTargetAdjustConfirm(newValue: number) {
    if (!this.selectedTarget) return

    // 更新目标值
    const targetIndex = this.targets.findIndex(t => t.key === this.selectedTarget!.key)
    if (targetIndex !== -1) {
      this.targets[targetIndex].currentValue = newValue
    }

    // 保存到偏好设置
    let saveValue = newValue
    if (this.selectedTarget.key === 'weight_target' && !this.isWeightUnitKg) {
      saveValue = newValue / 2 // 斤转公斤
    }
    
    await preferencesUtil.putPreferenceValue('steps_ohos', this.selectedTarget.key, saveValue)
    
    // 使用TargetManager同步更新到所有页面
    await this.syncTargetToAllPages(this.selectedTarget.key, saveValue)
    
    this.selectedTarget = null
    Utils.showToast('目标设置已保存')
  }

  private async syncTargetToAllPages(key: string, value: number) {
    // 导入TargetManager并更新目标值
    const targetManagerModule = await import('../tools/TargetManager')
    const targetManager = targetManagerModule.default
    await targetManager.updateTarget(key as keyof import('../tools/TargetManager').TargetValue, value)
  }

  private onTargetAdjustCancel() {
    this.selectedTarget = null
  }

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '目标管理' },
        cancel: () => {
          router.back()
        }
      })

      // 目标列表 - 直接从标题栏下方开始
      Column() {
        ForEach(this.targets, (target: TargetItem) => {
          this.buildTargetItem(target)
        })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16 })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder buildTargetItem(target: TargetItem) {
    Row() {
      Column() {
        Text(target.name)
          .fontSize(16)
          .fontColor('#333333')
          .alignSelf(ItemAlign.Start)
        
        Text(target.displayFormat.replace('xxx', target.currentValue.toString()).replace('xx', target.currentValue.toString()))
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 4 })
          .alignSelf(ItemAlign.Start)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Image($r('app.media.right_point'))
        .width(15)
        .height(15)
        .margin({ right: 16 })
    }
    .width('100%')
    .height(60)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ bottom: 8 })
    .onClick(() => {
      this.openTargetAdjustDialog(target)
    })
  }


  private generateValueList(): Array<number> {
    if (!this.selectedTarget) return []
    
    const values: Array<number> = []
    for (let value = this.selectedTarget.step; value <= this.selectedTarget.maxValue; value += this.selectedTarget.step) {
      values.push(value)
    }
    return values
  }

  private getDisplayValue(value: number): string {
    if (!this.selectedTarget) return value.toString()
    
    if (this.selectedTarget.key === 'weight_target' && this.selectedTarget.step === 0.1) {
      return value.toFixed(1)
    }
    return value.toString()
  }

  private getSelectedIndex(): number {
    if (!this.selectedTarget) return 0
    const valueList = this.generateValueList()
    const index = valueList.findIndex(value => value === this.selectedTarget!.currentValue)
    return index >= 0 ? index : 0
  }

}
