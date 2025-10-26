import { Utils } from '../tools/Utils'
import preferencesUtil from '../tools/DataPreUtils'
import { router, Picker } from '@kit.ArkUI'
import targetManager, { TargetValue } from '../tools/TargetManager'

export interface TargetItem {
  key: string
  name: string
  unit: string
  defaultValue: number
  maxValue: number
  step: number
  currentValue: number
  displayFormat: string
}

export interface TargetManagementDialogData {
  onConfirm: (targets: Map<string, number>) => void
}

@Component
export struct TargetManagementDialog {
  @State onConfirm: (targets: Map<string, number>) => void = () => {}
  
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

  async aboutToAppear() {
    await this.loadCurrentTargets()
  }

  private async loadCurrentTargets() {
    // 使用TargetManager加载所有目标值
    await targetManager.loadTargets()
    const allTargets = targetManager.getAllTargets()

    for (let i = 0; i < this.targets.length; i++) {
      const target = this.targets[i]
      this.targets[i].currentValue = allTargets[target.key as keyof TargetValue] || target.defaultValue
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
    this.selectedTarget = target
  }

  private adjustTargetValue(delta: number) {
    if (!this.selectedTarget) return

    const newValue = this.selectedTarget.currentValue + delta
    if (newValue >= this.selectedTarget.step && newValue <= this.selectedTarget.maxValue) {
      this.selectedTarget.currentValue = Math.round(newValue / this.selectedTarget.step) * this.selectedTarget.step
    }
  }

  private async saveTargets() {
    const targetMap = new Map<string, number>()
    const targetUpdates: Partial<TargetValue> = {}
    
    for (const target of this.targets) {
      let value = target.currentValue
      
      // 处理体重单位转换
      if (target.key === 'weight_target' && !this.isWeightUnitKg) {
        value = value / 2 // 斤转公斤
      }
      
      targetMap.set(target.key, value)
      targetUpdates[target.key as keyof TargetValue] = value
    }
    
    // 使用TargetManager批量更新目标值，确保所有页面同步
    await targetManager.updateTargets(targetUpdates)
    
    // 保存体重单位设置
    await preferencesUtil.putPreferenceValue('steps_ohos', 'weight_unit_kg', this.isWeightUnitKg)
    
    this.onConfirm(targetMap)
  }

  private toggleWeightUnit() {
    this.isWeightUnitKg = !this.isWeightUnitKg
    this.updateWeightUnit()
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('目标管理')
          .fontSize(18)
          .fontWeight(600)
          .fontColor('#333333')
          .layoutWeight(1)
        
        Text('✕')
          .fontSize(20)
          .fontColor('#666666')
          .onClick(() => {
            // 关闭对话框的逻辑由父组件处理
          })
      }
      .width('100%')
      .padding({ top: 16, bottom: 16, left: 20, right: 20 })
      .border({ width: { bottom: 1 }, color: '#F0F0F0' })

      // 目标列表 - 从上到下排列
      Column() {
        ForEach(this.targets, (target: TargetItem) => {
          this.buildTargetItem(target)
        })
      }
      .width('100%')
      .layoutWeight(1)

      // 底部按钮
      Row() {
        Button('取消')
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor('#F8F8F8')
          .borderRadius(8)
          .layoutWeight(1)
          .height(48)
          .onClick(() => {
            // 关闭对话框的逻辑由父组件处理
          })
        
        Button('保存')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#0cc291')
          .borderRadius(8)
          .layoutWeight(1)
          .height(48)
          .margin({ left: 12 })
          .onClick(() => {
            this.saveTargets()
          })
      }
      .width('100%')
      .padding(20)
    }
    .width('100%')
    .height('85%')
    .backgroundColor('#F5F5F5')
    .borderRadius({ topLeft: 16, topRight: 16 })
  }

  @Builder buildTargetItem(target: TargetItem) {
    Column() {
      Row() {
        Column() {
          Text(target.name)
            .fontSize(16)
            .fontWeight(500)
            .fontColor('#333333')
            .alignSelf(ItemAlign.Start)
          
          Text(target.displayFormat.replace('xxx', target.currentValue.toString()))
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 4 })
            .alignSelf(ItemAlign.Start)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 体重单位切换按钮
        if (target.key === 'weight_target') {
          Button(this.isWeightUnitKg ? '公斤' : '斤')
            .fontSize(12)
            .fontColor('#0cc291')
            .backgroundColor('#E8F5E8')
            .borderRadius(4)
            .height(28)
            .padding({ left: 8, right: 8 })
            .margin({ right: 8 })
            .onClick(() => {
              this.toggleWeightUnit()
            })
        }

        Text('调整')
          .fontSize(14)
          .fontColor('#0cc291')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('#E8F5E8')
          .borderRadius(4)
          .onClick(() => {
            this.openTargetAdjustDialog(target)
          })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
      .margin({ bottom: 8 })
    }
    .width('100%')
    .padding({ left: 20, right: 20 })
  }
}

// 目标调整弹窗
@Component
export struct TargetAdjustDialog {
  @State target: TargetItem | null = null
  @State onConfirm: (value: number) => void = () => {}
  @State onCancel: () => void = () => {}
  @State selectedValue: number = 0

  aboutToAppear() {
    if (this.target) {
      this.selectedValue = this.target.currentValue
    }
  }

  private async onConfirmValue(newValue: number) {
    if (this.target) {
      this.target.currentValue = newValue
      // 使用TargetManager更新目标值，确保所有页面同步
      await targetManager.updateTarget(this.target.key as keyof TargetValue, newValue)
    }
    this.onConfirm(newValue)
  }

  private generateValueList(): Array<number> {
    if (!this.target) return []
    
    const values: Array<number> = []
    for (let value = this.target.step; value <= this.target.maxValue; value += this.target.step) {
      values.push(value)
    }
    return values
  }

  private getDisplayValue(value: number): string {
    if (!this.target) return value.toString()
    
    if (this.target.key === 'weight_target' && this.target.step === 0.1) {
      return value.toFixed(1)
    }
    return value.toString()
  }

  private getSelectedIndex(): number {
    if (!this.target) return 0
    const valueList = this.generateValueList()
    const index = valueList.findIndex(value => value === this.selectedValue)
    return index >= 0 ? index : 0
  }

  build() {
    Column() {
      Text(`设置${this.target?.name || '目标'}`)
        .fontSize(18)
        .fontWeight(600)
        .fontColor('#333333')
        .margin({ bottom: 20 })

      // 滑动选择器
      Picker({
        range: this.generateValueList().map(value => this.getDisplayValue(value) + (this.target?.unit || '')),
        selected: this.getSelectedIndex()
      })
      .onChange((value: string, index: number) => {
        this.selectedValue = this.generateValueList()[index]
      })
      .height(200)
      .width('100%')
      .margin({ bottom: 20 })

      Row() {
        Button('取消')
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor('#F8F8F8')
          .borderRadius(8)
          .layoutWeight(1)
          .height(48)
          .onClick(() => {
            this.onCancel()
          })
        
        Button('确定')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#0cc291')
          .borderRadius(8)
          .layoutWeight(1)
          .height(48)
          .margin({ left: 12 })
          .onClick(() => {
            this.onConfirmValue(this.selectedValue)
          })
      }
      .width('100%')
    }
    .width('80%')
    .height('60%')
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }
}
