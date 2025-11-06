import { router } from '@kit.ArkUI'
import { CommonTitleView } from '../view/CommonTitleView'
import preferencesUtil from '../tools/PreferencesUtil'

interface TargetItem {
  key: string
  name: string
  unit: string
  defaultValue: number
  maxValue: number
  step: number
  currentValue: number
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
      currentValue: 5000
    },
    {
      key: 'calorie_target',
      name: '热量消耗',
      unit: '千卡',
      defaultValue: 300,
      maxValue: 2000,
      step: 10,
      currentValue: 300
    },
    {
      key: 'exercise_time_target',
      name: '锻炼时长',
      unit: '分钟',
      defaultValue: 25,
      maxValue: 1440,
      step: 1,
      currentValue: 25
    },
    {
      key: 'activity_count_target',
      name: '活动次数',
      unit: '次',
      defaultValue: 12,
      maxValue: 24,
      step: 1,
      currentValue: 12
    }
  ]

  async onPageShow() {
    await this.loadCurrentTargets()
  }

  private async loadCurrentTargets() {
    for (let i = 0; i < this.targets.length; i++) {
      const target = this.targets[i]
      const saved = await preferencesUtil.getPreferenceValue('steps_ohos', target.key, target.defaultValue)
      this.targets[i].currentValue = Number(saved) || target.defaultValue
    }
  }

  private formatTargetDisplay(target: TargetItem): string {
    if (target.key === 'step_target') {
      return `${target.currentValue}步/天`
    } else if (target.key === 'calorie_target') {
      return `${target.currentValue}千卡/天`
    } else if (target.key === 'exercise_time_target') {
      return `${target.currentValue}分钟/天`
    } else if (target.key === 'activity_count_target') {
      return `${target.currentValue}次/天`
    }
    return `${target.currentValue}${target.unit}`
  }

  private async saveTarget(target: TargetItem) {
    await preferencesUtil.putPreferenceValue('steps_ohos', target.key, target.currentValue)
  }

  @Builder
  buildTargetItem(target: TargetItem, index: number) {
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
      top: index === 0 ? 16 : 0,
      bottom: 12 
    })
    .onClick(() => {
      // TODO: 打开目标调整对话框
      console.info(`[TargetManagementPage] 打开目标调整: ${target.name}`)
    })
  }

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '目标管理' },
        cancel: () => {
          router.back()
        },
        useSafeTop: true
      })

      Scroll() {
        Column() {
          ForEach(this.targets, (target: TargetItem, index: number) => {
            this.buildTargetItem(target, index)
          }, (target: TargetItem) => `${target.key}-${target.currentValue}`)
        }
        .width('100%')
        .padding({ bottom: 16, left: 16, right: 16 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

