import { router, window } from '@kit.ArkUI'
import { DateUtils } from '../tools/DateUtils'
import AppDataManager from '../tools/AppDataManager'
import { Utils } from '../tools/Utils'
import { CommonTitleView } from '../view/CommonTitleView'
import preferencesUtil from '../tools/DataPreUtils'
import EntryAbility from '../entryability/EntryAbility'

interface AddSportPageParams {
  sportType?: number
}

interface SportType {
  type: number
  name: string
  icon: Resource
}

@Entry
@Component
struct AddSportPage {
  @State selectedSportType: number = 1
  @State duration: number = 30 // 分钟
  @State distance: number = 1.0 // 公里
  @State calories: number = 100 // 千卡
  @State userWeight: number = 60 // 千克
  @State selectedDate: string = DateUtils.getYMD()
  @State selectedTime: string = '10:00'
  private pageScroller: Scroller = new Scroller()
  
  private sportTypes: Array<SportType> = [
    { type: 1, name: '室内跑', icon: $r('app.media.sport_indoor_run') },
    { type: 2, name: '室外跑', icon: $r('app.media.sport_run') },
    { type: 3, name: '健走', icon: $r('app.media.sport_go_walk') },
    { type: 4, name: '徒步', icon: $r('app.media.sport_walk_alone') },
    { type: 5, name: '登山', icon: $r('app.media.sport_climb') },
    { type: 6, name: '骑行', icon: $r('app.media.sport_ride') },
    { type: 7, name: '瑜伽', icon: $r('app.media.sport_indoor_run') },
    { type: 8, name: '跳绳', icon: $r('app.media.sport_run') }
  ]

  async onPageShow() {
    // 获取传递的参数
    const params = router.getParams() as AddSportPageParams
    if (params && typeof params.sportType === 'number') {
      this.selectedSportType = params.sportType
    }
    
    // 设置默认时间为当前时间
    const now = new Date()
    this.selectedTime = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`

    const storedWeight = await preferencesUtil.getPreferenceValue('steps_ohos', 'weight', 60) as number
    if (typeof storedWeight === 'number' && !Number.isNaN(storedWeight) && storedWeight > 0) {
      this.userWeight = storedWeight
    } else {
      this.userWeight = 60
    }

    this.distance = this.requiresDistance(this.selectedSportType) ? this.calculateDistance() : 0
    this.calories = this.calculateCalories()
  }

  private calculateCalories(): number {
    const weight = this.userWeight > 0 ? this.userWeight : 60
    const distance = this.requiresDistance(this.selectedSportType) ? this.distance : 0
    let calories = 0
    switch (this.selectedSportType) {
      case 1: // 室内跑
      case 2: // 室外跑
        calories = weight * distance * 1.036 * 0.8
        break
      case 3: // 健走
        calories = weight * distance * 1.036
        break
      case 4: // 徒步
        calories = weight * distance * 1.036
        break
      case 5: // 登山
        calories = weight * distance * 1.036 * 1.2
        break
      case 6: // 骑行
        calories = weight * distance * 1.036 * 0.5
        break
      case 7: // 瑜伽
        calories = (this.duration / 60) * 150
        break
      case 8: // 跳绳
        const perMinute = (10.9 * weight * 3.5) / 200
        calories = this.duration * perMinute
        break
      default:
        calories = weight * distance * 1.036
    }
    if (!Number.isFinite(calories)) {
      calories = 0
    }
    return Math.max(0, Math.round(calories))
  }

  private calculateDistance(): number {
    const speed = this.getSpeedByType(this.selectedSportType)
    if (speed <= 0) {
      return 0
    }
    return Math.round(speed * this.duration * 100) / 100
  }

  private getSpeedByType(type: number): number {
    const baseSpeed: Record<number, number> = {
      1: 0.15, // 室内跑 9km/h
      2: 0.2,  // 室外跑 12km/h
      3: 0.08, // 健走 5km/h
      4: 0.06, // 徒步 4km/h
      5: 0.05, // 登山 3km/h
      6: 0.25  // 骑行 15km/h
    }
    return baseSpeed[type] ?? 0
  }

  private requiresDistance(type: number): boolean {
    return type !== 7 && type !== 8
  }

  private onDurationChange(value: number) {
    this.duration = value
    if (this.requiresDistance(this.selectedSportType)) {
      this.distance = this.calculateDistance()
    } else {
      this.distance = 0
    }
    this.calories = this.calculateCalories()
  }

  private onDistanceChange(value: number) {
    if (!this.requiresDistance(this.selectedSportType)) {
      return
    }
    this.distance = value
    const speed = this.getSpeedByType(this.selectedSportType)
    if (speed > 0) {
      this.duration = Math.max(1, Math.round(value / speed))
    }
    this.calories = this.calculateCalories()
  }

  private onCaloriesChange(value: number) {
    this.calories = value
  }

  private getStartTime(): number {
    const dateTime = `${this.selectedDate} ${this.selectedTime}:00`
    return new Date(dateTime).getTime()
  }

  private onSave() {
    const startTime = this.getStartTime()
    const durationMs = this.duration * 60 * 1000
    const steps = this.requiresDistance(this.selectedSportType)
      ? Math.max(0, Math.round(this.distance * 1000 / 0.6))
      : 0
    AppDataManager.insertSportRecord(
      startTime,
      durationMs,
      steps,
      this.selectedSportType,
      0,
      this.calories.toString(),
      () => {
        Utils.showToast('运动记录添加成功')
        setTimeout(() => router.back(), 150)
      }
    )
  }

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '添加运动' },
        cancel: () => {
          router.back()
        }
      })

      Scroll(this.pageScroller) {
        Column() {
          // 运动类型选择
          Column() {
            Text('运动类型')
              .fontSize(16)
              .fontWeight(500)
              .fontColor('#333333')
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 12 })

            Grid() {
              ForEach(this.sportTypes, (sport: SportType) => {
                GridItem() {
                  Column() {
                    Image(sport.icon)
                      .width(40)
                      .height(40)
                      .margin({ bottom: 8 })
                    Text(sport.name)
                      .fontSize(12)
                      .fontColor(this.selectedSportType === sport.type ? '#0cc291' : '#666666')
                  }
                  .width('100%')
                  .padding(12)
                  .backgroundColor(this.selectedSportType === sport.type ? '#E8F5E8' : '#F8F8F8')
                  .borderRadius(8)
                  .onClick(() => {
                    this.selectedSportType = sport.type
                    if (this.requiresDistance(sport.type)) {
                      this.distance = this.calculateDistance()
                    } else {
                      this.distance = 0
                    }
                    this.calories = this.calculateCalories()
                  })
                }
              })
            }
            .columnsTemplate('1fr 1fr 1fr')
            .rowsGap(12)
            .columnsGap(12)
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ bottom: 16 })

          // 运动数据输入
          Column() {
            Text('运动数据')
              .fontSize(16)
              .fontWeight(500)
              .fontColor('#333333')
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 16 })

            // 运动时长
            Row() {
              Text('运动时长')
                .fontSize(14)
                .fontColor('#666666')
                .width(80)
              
              Row() {
                Text('−')
                  .fontSize(20)
                  .fontColor('#666666')
                  .onClick(() => {
                    if (this.duration > 1) {
                      this.onDurationChange(this.duration - 1)
                    }
                  })
                
                Text(this.duration.toString())
                  .fontSize(16)
                  .fontWeight(500)
                  .fontColor('#333333')
                  .width(40)
                  .textAlign(TextAlign.Center)
                
                Text('+')
                  .fontSize(20)
                  .fontColor('#666666')
                  .onClick(() => {
                    this.onDurationChange(this.duration + 1)
                  })
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
              
              Text('分钟')
                .fontSize(14)
                .fontColor('#666666')
                .width(40)
            }
            .width('100%')
            .padding({ top: 12, bottom: 12 })
            .border({ width: { bottom: 1 }, color: '#F0F0F0' })

            // 运动距离
            if (this.requiresDistance(this.selectedSportType)) {
              Row() {
                Text('运动距离')
                  .fontSize(14)
                  .fontColor('#666666')
                  .width(80)
                
                Row() {
                  Text('−')
                    .fontSize(20)
                    .fontColor('#666666')
                    .onClick(() => {
                      if (this.distance > 0.1) {
                        this.onDistanceChange(Math.round((this.distance - 0.1) * 10) / 10)
                      }
                    })
                  
                  Text(this.distance.toFixed(1))
                    .fontSize(16)
                    .fontWeight(500)
                    .fontColor('#333333')
                    .width(40)
                    .textAlign(TextAlign.Center)
                  
                  Text('+')
                    .fontSize(20)
                    .fontColor('#666666')
                    .onClick(() => {
                      this.onDistanceChange(Math.round((this.distance + 0.1) * 10) / 10)
                    })
                }
                .layoutWeight(1)
                .justifyContent(FlexAlign.Center)
                
                Text('公里')
                  .fontSize(14)
                  .fontColor('#666666')
                  .width(40)
              }
              .width('100%')
              .padding({ top: 12, bottom: 12 })
              .border({ width: { bottom: 1 }, color: '#F0F0F0' })
            }

            // 消耗热量
            Row() {
              Text('消耗热量')
                .fontSize(14)
                .fontColor('#666666')
                .width(80)
              
              Row() {
                Text('−')
                  .fontSize(20)
                  .fontColor('#666666')
                  .onClick(() => {
                    if (this.calories > 10) {
                      this.onCaloriesChange(this.calories - 10)
                    }
                  })
                
                Text(this.calories.toString())
                  .fontSize(16)
                  .fontWeight(500)
                  .fontColor('#333333')
                  .width(40)
                  .textAlign(TextAlign.Center)
                
                Text('+')
                  .fontSize(20)
                  .fontColor('#666666')
                  .onClick(() => {
                    this.onCaloriesChange(this.calories + 10)
                  })
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
              
              Text('千卡')
                .fontSize(14)
                .fontColor('#666666')
                .width(40)
            }
            .width('100%')
            .padding({ top: 12, bottom: 12 })
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ bottom: 16 })

          // 时间选择
          Column() {
            Text('运动时间')
              .fontSize(16)
              .fontWeight(500)
              .fontColor('#333333')
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 16 })

            Row() {
              Text('日期')
                .fontSize(14)
                .fontColor('#666666')
                .width(60)
              
              Text(this.selectedDate)
                .fontSize(16)
                .fontColor('#333333')
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .padding(12)
                .backgroundColor('#F8F8F8')
                .borderRadius(8)
            }
            .width('100%')
            .margin({ bottom: 12 })

            Row() {
              Text('时间')
                .fontSize(14)
                .fontColor('#666666')
                .width(60)
              
              Text(this.selectedTime)
                .fontSize(16)
                .fontColor('#333333')
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .padding(12)
                .backgroundColor('#F8F8F8')
                .borderRadius(8)
            }
            .width('100%')
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ bottom: 20 })

          // 保存按钮
          Button('保存运动记录')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#0cc291')
            .borderRadius(8)
            .width('100%')
            .height(48)
            .onClick(() => {
              this.onSave()
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: this.getSafeBottomPadding() })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  private getSafeBottomPadding(): number {
    if (!EntryAbility.myWindowClass) {
      return 24
    }
    const avoidArea = EntryAbility.myWindowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
    return avoidArea.bottomRect.height + 24
  }
}
