import { router } from '@kit.ArkUI'
import { Utils } from '../tools/Utils'
import { DateUtils } from '../tools/DateUtils'
import { CommonTitleView } from '../view/CommonTitleView'

interface SportType {
  type: number
  name: string
  icon: Resource
}

interface AddSportPageParams {
  onConfirm?: (sportType: number, duration: number, distance: number, calories: number, startTime: number) => void
}

@Entry
@Component
struct AddSportPage {
  @State onConfirm: (sportType: number, duration: number, distance: number, calories: number, startTime: number) => void = () => {}
  
  @State selectedSportType: number = 1
  @State duration: number = 30 // 分钟
  @State distance: number = 1.0 // 公里
  @State calories: number = 100 // 千卡
  @State selectedDate: string = DateUtils.getYMD()
  @State selectedTime: string = '10:00'
  
  private sportTypes: Array<SportType> = [
    { type: 1, name: '室内跑', icon: $r('app.media.sport_indoor_run') },
    { type: 2, name: '室外跑', icon: $r('app.media.sport_run') },
    { type: 3, name: '健走', icon: $r('app.media.sport_go_walk') },
    { type: 4, name: '徒步', icon: $r('app.media.sport_walk_alone') },
    { type: 5, name: '登山', icon: $r('app.media.sport_climb') }
  ]

  onPageShow() {
    // 获取传递的参数
    const params = router.getParams() as AddSportPageParams
    if (params && params.onConfirm) {
      this.onConfirm = params.onConfirm
    }
    
    // 设置默认时间为当前时间
    const now = new Date()
    this.selectedTime = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`
  }

  private calculateCalories(): number {
    // 根据运动类型和时长计算热量
    const baseCalories: Record<number, number> = {
      1: 10, // 室内跑
      2: 12, // 室外跑
      3: 6,  // 健走
      4: 8,  // 徒步
      5: 15  // 登山
    }
    return Math.round(baseCalories[this.selectedSportType] * this.duration)
  }

  private calculateDistance(): number {
    // 根据运动类型和时长估算距离
    const baseSpeed: Record<number, number> = {
      1: 0.15, // 室内跑 9km/h
      2: 0.2,  // 室外跑 12km/h
      3: 0.08, // 健走 5km/h
      4: 0.06, // 徒步 4km/h
      5: 0.05  // 登山 3km/h
    }
    return Math.round(baseSpeed[this.selectedSportType] * this.duration * 100) / 100
  }

  private onDurationChange(value: number) {
    this.duration = value
    this.distance = this.calculateDistance()
    this.calories = this.calculateCalories()
  }

  private onDistanceChange(value: number) {
    this.distance = value
    // 根据距离重新计算时长
    const baseSpeed: Record<number, number> = {
      1: 0.15, // 室内跑
      2: 0.2,  // 室外跑
      3: 0.08, // 健走
      4: 0.06, // 徒步
      5: 0.05  // 登山
    }
    this.duration = Math.round(value / baseSpeed[this.selectedSportType])
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
    this.onConfirm(this.selectedSportType, this.duration * 60, this.distance, this.calories, startTime)
    // 延迟返回，确保数据保存完成
    setTimeout(() => {
      router.back()
    }, 100)
  }

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '添加运动' },
        cancel: () => {
          router.back()
        }
      })

      Scroll() {
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
                    this.distance = this.calculateDistance()
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
        .padding({ left: 20, right: 20 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
