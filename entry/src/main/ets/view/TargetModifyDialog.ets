import { router } from '@kit.ArkUI'
import preferencesUtil from '../tools/DataPreUtils'

export interface TargetModifyDialogProps {
  targetType: string
  targetName: string
  currentValue: number
  unit: string
  minValue: number
  maxValue: number
  step: number
  onConfirm: (newValue: number) => void
  onCancel: () => void
}

@Component
export struct TargetModifyDialog {
  @State targetType: string = ''
  @State targetName: string = ''
  @State currentValue: number = 0
  @State unit: string = ''
  @State minValue: number = 0
  @State maxValue: number = 100
  @State step: number = 1
  @State selectedValue: number = 0
  onConfirm: (newValue: number) => void = () => {}
  onCancel: () => void = () => {}

  aboutToAppear() {
    this.selectedValue = this.currentValue
  }

  private generateValueList(): Array<number> {
    const values: Array<number> = []
    for (let value = this.minValue; value <= this.maxValue; value += this.step) {
      if (this.step < 1) {
        values.push(parseFloat(value.toFixed(1)))
      } else {
        values.push(value)
      }
    }
    return values
  }

  private getDisplayValue(value: number): string {
    if (this.step < 1) {
      return value.toFixed(1)
    }
    return value.toString()
  }

  build() {
    Column() {
      Text(`修改${this.targetName}`)
        .fontSize(18)
        .fontWeight(600)
        .fontColor('#333333')
        .margin({ bottom: 20 })

      // 滚动选择器
      Column() {
        ForEach(this.generateValueList(), (value: number, index: number) => {
          Row() {
            Text(this.getDisplayValue(value))
              .fontSize(this.selectedValue === value ? 24 : 16)
              .fontWeight(this.selectedValue === value ? 600 : 400)
              .fontColor(this.selectedValue === value ? '#0cc291' : '#666666')
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
            
            if (this.selectedValue === value) {
              Text(this.unit)
                .fontSize(16)
                .fontColor('#0cc291')
                .margin({ left: 8 })
            }
          }
          .width('100%')
          .height(40)
          .onClick(() => {
            this.selectedValue = value
          })
        })
      }
      .height(200)
      .width('100%')
      .margin({ bottom: 30 })

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
            this.onConfirm(this.selectedValue)
          })
      }
      .width('100%')
    }
    .width('80%')
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }
}

// 目标进度组件
@Component
export struct TargetProgressView {
  @State targetName: string = ''
  @State currentValue: number = 0
  @State targetValue: number = 0
  @State unit: string = ''

  private getProgressPercentage(): number {
    if (this.targetValue <= 0) return 0
    return Math.min((this.currentValue / this.targetValue) * 100, 100)
  }

  private getProgressColor(): string {
    const percentage = this.getProgressPercentage()
    if (percentage >= 100) return '#0cc291'
    if (percentage >= 80) return '#FFB950'
    return '#FF6B6B'
  }

  private openModifyDialog() {
    // 跳转到目标管理页面
    router.pushUrl({ url: 'pages/TargetManagementPage' })
  }

  build() {
    Column() {
      Row() {
        Text('目标进度')
          .fontSize(16)
          .fontWeight(500)
          .fontColor('#333333')
          .layoutWeight(1)
        
        Row() {
          Text('修改目标')
            .fontSize(14)
            .fontColor('#0cc291')
          Text('✏️')
            .fontSize(12)
            .margin({ left: 4 })
        }
        .onClick(() => {
          this.openModifyDialog()
        })
      }
      .width('100%')
      .margin({ bottom: 12 })

      Text(`${this.currentValue}/${this.targetValue}${this.unit}`)
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 8 })

      Stack() {
        Row()
          .backgroundColor('#F0F0F0')
          .height(8)
          .borderRadius(4)
          .width('100%')

        Row()
          .backgroundColor(this.getProgressColor())
          .height(8)
          .borderRadius(4)
          .width(`${this.getProgressPercentage()}%`)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
  }
}
