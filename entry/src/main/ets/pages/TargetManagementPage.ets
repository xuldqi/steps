import { router, window } from '@kit.ArkUI'
import { CommonTitleView } from '../view/CommonTitleView'
import preferencesUtil from '../tools/DataPreUtils'
import { Log } from '../tools/Logger'
import { Utils } from '../tools/Utils'
import EntryAbility from '../entryability/EntryAbility'
import targetManager, { TargetValue } from '../tools/TargetManager'

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

const PRIMARY = '#0cc291'

@Entry
@Component
struct TargetManagementPage {
  private cloneTarget(item: TargetItem): TargetItem {
    return {
      key: item.key,
      name: item.name,
      unit: item.unit,
      defaultValue: item.defaultValue,
      maxValue: item.maxValue,
      step: item.step,
      currentValue: item.currentValue,
      displayFormat: item.displayFormat
    }
  }

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
  @State showTargetDialog: boolean = false
  @State tempValue: number = 0
  @State tempIndex: number = 0
  private pageScroller: Scroller = new Scroller()

  async onPageShow() {
    await this.loadCurrentTargets()
    this.resetScrollPosition()
  }

  private async loadCurrentTargets() {
    if (!preferencesUtil.preferencesMap.has('steps_ohos')) {
      return
    }

    const updatedTargets: Array<TargetItem> = []
    for (let i = 0; i < this.targets.length; i++) {
      const source = this.targets[i]
      const currentValue = await preferencesUtil.getPreferenceValue('steps_ohos', source.key, source.defaultValue) as number
      const clone = this.cloneTarget(source)
      clone.currentValue = currentValue
      updatedTargets.push(clone)
    }
    this.targets = updatedTargets

    // 加载体重单位设置
    const weightUnit = await preferencesUtil.getPreferenceValue('steps_ohos', 'weight_unit_kg', true) as boolean
    this.isWeightUnitKg = weightUnit
    this.updateWeightUnit()
  }

  private updateWeightUnit() {
    const index = this.targets.findIndex(target => target.key === 'weight_target')
    if (index > -1) {
      const updatedTargets: Array<TargetItem> = []
      for (let i = 0; i < this.targets.length; i++) {
        const clone = this.cloneTarget(this.targets[i])
        if (i === index) {
          if (this.isWeightUnitKg) {
            clone.unit = '公斤'
            clone.maxValue = 300
            clone.displayFormat = 'xxx公斤'
          } else {
            clone.unit = '斤'
            clone.maxValue = 600
            clone.displayFormat = 'xxx斤'
            clone.currentValue = Math.round(clone.currentValue * 2 * 10) / 10
          }
        }
        updatedTargets.push(clone)
      }
      this.targets = updatedTargets
    }
  }

  private resetScrollPosition() {
    setTimeout(() => {
      this.pageScroller.scrollTo({
        xOffset: 0,
        yOffset: 0,
        animation: false
      })
    }, 0)
  }

  private openTargetAdjustDialog(target: TargetItem) {
    this.selectedTarget = this.cloneTarget(target)
    this.tempValue = target.currentValue
    this.tempIndex = this.resolveIndexForValue(target.currentValue)
    this.showTargetDialog = true
  }

  private async onTargetAdjustConfirm() {
    if (!this.selectedTarget) return

    // 计算要保存的值
    const valueList = this.generateValueList()
    const candidate = (this.tempIndex >= 0 && this.tempIndex < valueList.length)
      ? valueList[this.tempIndex]
      : this.tempValue
    let saveValue = this.roundByStep(candidate, this.selectedTarget.step, this.selectedTarget.maxValue)
    
    // 体重单位转换
    if (this.selectedTarget.key === 'weight_target' && !this.isWeightUnitKg) {
      saveValue = saveValue / 2 // 斤转公斤
    }
    
    // 更新UI显示
    const targetIndex = this.targets.findIndex(t => t.key === this.selectedTarget!.key)
    if (targetIndex !== -1) {
      const updatedTargets: Array<TargetItem> = []
      for (let i = 0; i < this.targets.length; i++) {
        const clone = this.cloneTarget(this.targets[i])
        if (i === targetIndex) {
          // UI显示值：如果是斤制，需要将公斤转换为斤显示
          let displayValue = saveValue
          if (this.selectedTarget.key === 'weight_target' && !this.isWeightUnitKg) {
            displayValue = saveValue * 2
          }
          clone.currentValue = displayValue
        }
        updatedTargets.push(clone)
      }
      this.targets = updatedTargets
    }

    // 保存到偏好设置
    await preferencesUtil.putPreferenceValue('steps_ohos', this.selectedTarget.key, saveValue)
    
    // 使用TargetManager同步更新到所有页面
    await targetManager.updateTarget(this.selectedTarget.key as keyof TargetValue, saveValue)

    this.selectedTarget = null
    this.showTargetDialog = false
    Utils.showToast('目标设置已保存')
  }

  private onTargetAdjustCancel() {
    this.selectedTarget = null
    this.showTargetDialog = false
  }

  build() {
    Stack() {
      Column() {
        CommonTitleView({
          data1: { str1: '目标管理' },
          cancel: () => {
            router.back()
          }
        })

        Scroll(this.pageScroller) {
          Column() {
            ForEach(this.targets, (target: TargetItem, index: number) => {
              this.buildTargetItem(target, index)
            }, (target: TargetItem) => `${target.key}-${target.currentValue}`)
          }
          .width('100%')
          .padding({ bottom: this.getSafeBottomPadding(), left: 16, right: 16 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')

      // 目标修改弹窗
      if (this.showTargetDialog && this.selectedTarget) {
        this.buildTargetDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder buildTargetItem(target: TargetItem, index: number) {
    Column() {
      Row() {
        Column() {
          Text(target.name)
            .fontSize(16)
            .fontWeight(500)
            .fontColor('#222222')
            .alignSelf(ItemAlign.Start)
          
          Text(this.formatTargetDisplay(target))
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 4 })
            .alignSelf(ItemAlign.Start)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Image($r('app.media.right_point'))
          .width(16)
          .height(16)
      }
      .width('100%')
    }
    .padding({ left: 20, right: 20, top: 14, bottom: 14 })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .width('100%')
    .margin({ 
      top: index === 0 ? -228 : 0,
      bottom: 12 
    })
    .onClick(() => {
      this.openTargetAdjustDialog(target)
    })
  }

  @Builder buildTargetDialog() {
    Stack() {
      // 半透明背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .onClick(() => {
          this.onTargetAdjustCancel()
        })

      // 弹窗内容
      Column() {
        Text(this.selectedTarget!.name)
          .fontSize(18)
          .fontWeight(500)
          .fontColor('#333333')
          .margin({ bottom: 20 })

        // 弹窗内不再显示“当前值”
        // 保留与选择器之间的间距
        Blank().height(12)

        // 统一滑动选择器
        TextPicker({
          range: this.generateValueList().map(v => this.getDisplayValue(v) + this.selectedTarget!.unit),
          selected: this.tempIndex
        })
          .onChange((value, index) => {
            const list = this.generateValueList()
            const idxRaw = Array.isArray(index) ? index[0] as number : (index as number)
            if (typeof idxRaw === 'number' && idxRaw >= 0 && idxRaw < list.length) {
              this.tempIndex = idxRaw
              this.tempValue = list[idxRaw]
              return
            }
            const numeric = this.parsePickerValue(value)
            if (!Number.isNaN(numeric)) {
              const snapped = this.roundByStep(numeric, this.selectedTarget!.step, this.selectedTarget!.maxValue)
              this.tempValue = snapped
              this.tempIndex = this.resolveIndexForValue(snapped)
            }
          })
          .selectedTextStyle({ color: Color.Black, font: { size: 24, weight: FontWeight.Medium } })
          .textStyle({ color: '#666666', font: { size: 18, weight: FontWeight.Normal } })
          .height(200)
          .width('100%')
          .margin({ bottom: 30 })

        Row() {
          Button('取消')
            .width(100)
            .height(40)
            .fontSize(16)
            .fontColor('#666666')
            .backgroundColor('#F0F0F0')
            .onClick(() => {
              this.onTargetAdjustCancel()
            })

          Button('确定')
            .width(100)
            .height(40)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(PRIMARY)
            .margin({ left: 20 })
            .onClick(() => {
              this.onTargetAdjustConfirm()
            })
        }
        .justifyContent(FlexAlign.SpaceAround)
        .margin({ bottom: 10 })
      }
      .width('88%')
      .padding({ top: 24, bottom: 24, left: 24, right: 24 })
      .backgroundColor('#FFFFFF')
      .borderRadius(20)
      .align(Alignment.Center)
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }


  private generateValueList(): Array<number> {
    if (!this.selectedTarget) return []
    
    const values: Array<number> = []
    for (let value = this.selectedTarget.step; value <= this.selectedTarget.maxValue; value += this.selectedTarget.step) {
      values.push(this.roundByStep(value, this.selectedTarget.step, this.selectedTarget.maxValue))
    }
    return values
  }

  private getDisplayValue(value: number): string {
    if (!this.selectedTarget) return value.toString()
    
    return this.getDisplayText(value)
  }

  private getSelectedIndex(): number {
    if (!this.selectedTarget) return 0
    return this.resolveIndexForValue(this.tempValue)
  }

  private formatTargetDisplay(target: TargetItem): string {
    const rounded = this.roundByStep(target.currentValue, target.step, target.maxValue)
    const decimals = target.step < 1 ? Math.max(0, Math.round(Math.log10(1 / target.step))) : 0
    const valueStr = target.step < 1 ? rounded.toFixed(decimals) : Math.round(rounded).toString()
    if (target.displayFormat.indexOf('xxx') >= 0) {
      return target.displayFormat.replace('xxx', valueStr)
    }
    if (target.displayFormat.indexOf('xx') >= 0) {
      return target.displayFormat.replace('xx', valueStr)
    }
    return `${valueStr}${target.unit}`
  }

  private getSafeBottomPadding(): number {
    if (!EntryAbility.myWindowClass) {
      return 16
    }
    const avoidArea = EntryAbility.myWindowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
    return avoidArea.bottomRect.height + 16
  }

  // helper: 统一数值显示，避免 51.50000000000002
  private getDisplayText(value: number): string {
    if (!this.selectedTarget) return value.toString()
    const step = this.selectedTarget.step
    const rounded = this.roundByStep(value, step, this.selectedTarget.maxValue)
    // 对 weight_target(步长0.1) 保留1位；其他按整数显示
    if (step < 1) {
      const decimals = Math.max(0, Math.round(Math.log10(1 / step)))
      return rounded.toFixed(decimals)
    }
    return Math.round(rounded).toString()
  }

  // helper: 按步长与上限进行稳定四舍五入，解决浮点误差
  private roundByStep(val: number, step: number, maxVal: number): number {
    const decimals = step < 1 ? Math.max(0, Math.round(Math.log10(1 / step))) : 0
    const factor = Math.pow(10, decimals)
    const snapped = Math.min(maxVal, Math.max(step, Math.round(val * factor) / factor))
    // 再按 step 对齐（避免 0.30000000000004）
    const aligned = Math.round(snapped / step) * step
    return Math.round(aligned * factor) / factor
  }

  private parsePickerValue(value: string | Array<string>): number {
    if (!this.selectedTarget) {
      return Number.NaN
    }
    const raw = Array.isArray(value) ? (value.length > 0 ? value[0] : '') : value
    const unit = this.selectedTarget.unit ?? ''
    const normalized = unit.length > 0 ? raw.replace(unit, '') : raw
    const trimmed = normalized.trim()
    return Number.parseFloat(trimmed)
  }

  private resolveIndexForValue(value: number): number {
    const list = this.generateValueList()
    const target = this.roundByStep(value, this.selectedTarget?.step ?? 1, this.selectedTarget?.maxValue ?? value)
    let index = list.findIndex(v => v === target)
    if (index >= 0) {
      return index
    }
    index = list.findIndex(v => Math.abs(v - target) < 1e-6)
    return index >= 0 ? index : 0
  }

}
