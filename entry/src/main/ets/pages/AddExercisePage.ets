import { router } from '@kit.ArkUI'
import { CommonTitleView } from '../view/CommonTitleView'
import { Utils } from '../tools/Utils'
import AppDataManager from '../tools/AppDataManager'
import { DateUtils } from '../tools/DateUtils'
import { systemDateTime } from '@kit.BasicServicesKit'

interface ExerciseType {
  id: number
  name: string
  icon: Resource
}

@Entry
@Component
struct AddExercisePage {
  @State selectedType: number = 1
  @State duration: number = 30 // 分钟
  @State distance: number = 1.0 // 公里
  @State selectedDate: string = DateUtils.getYMD()
  @State selectedTime: string = '10:00'
  @State showTypeDialog: boolean = false
  @State showDurationDialog: boolean = false
  @State showDistanceDialog: boolean = false
  @State showDateDialog: boolean = false
  @State showTimeDialog: boolean = false

  private exerciseTypes: Array<ExerciseType> = [
    { id: 1, name: '室内跑步', icon: $r('app.media.sport_indoor_run') },
    { id: 2, name: '室外跑步', icon: $r('app.media.sport_run') },
    { id: 3, name: '骑行', icon: $r('app.media.sport_run') }, // 使用现有图标
    { id: 4, name: '健走', icon: $r('app.media.sport_go_walk') },
    { id: 5, name: '爬山', icon: $r('app.media.sport_climb') }
    // 隐藏瑜伽和跳绳
  ]

  aboutToAppear() {
    // 设置默认时间为当前时间
    const now = new Date()
    this.selectedTime = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`
  }

  private calculateCalories(): number {
    // 根据运动类型和时长计算热量
    let baseCalorie = 10
    switch (this.selectedType) {
      case 1: baseCalorie = 10; break // 室内跑
      case 2: baseCalorie = 12; break // 室外跑
      case 3: baseCalorie = 6; break  // 骑行
      case 4: baseCalorie = 6; break  // 健走
      case 5: baseCalorie = 15; break // 爬山
    }
    return Math.round(baseCalorie * this.duration)
  }

  private calculateDistance(): number {
    // 根据运动类型和时长估算距离
    let baseSpeed = 0.15
    switch (this.selectedType) {
      case 1: baseSpeed = 0.15; break // 室内跑 9km/h
      case 2: baseSpeed = 0.2; break  // 室外跑 12km/h
      case 3: baseSpeed = 0.3; break  // 骑行 18km/h
      case 4: baseSpeed = 0.08; break // 健走 5km/h
      case 5: baseSpeed = 0.05; break // 爬山 3km/h
    }
    return Math.round(baseSpeed * this.duration * 100) / 100
  }

  private getStartTime(): number {
    const dateTime = `${this.selectedDate} ${this.selectedTime}:00`
    return new Date(dateTime).getTime()
  }

  private saveExercise() {
    const startTime = this.getStartTime()
    const steps = Math.round(this.distance * 1000 / 0.6) // 根据距离估算步数
    const calories = this.calculateCalories()
    
    // 插入运动记录
    AppDataManager.insertSportRecord(
      startTime,
      this.duration * 60, // 转换为秒
      steps,
      this.selectedType,
      0,
      calories.toString()
    )
    
    Utils.showToast('运动记录添加成功')
    router.back()
  }

  private getSelectedTypeName(): string {
    const type = this.exerciseTypes.find(t => t.id === this.selectedType)
    return type ? type.name : '室内跑步'
  }

  private isDistanceRequired(): boolean {
    // 所有运动类型都需要距离
    return true
  }

  build() {
    Stack() {
      Column() {
        CommonTitleView({
          data1: { str1: '添加运动' },
          cancel: () => {
            router.back()
          }
        })

        Column() {
          // 运动类型
          this.buildInputItem('运动类型', this.getSelectedTypeName(), () => {
            this.showTypeDialog = true
          })

          // 运动时长
          this.buildInputItem('运动时长', `${this.duration}分钟`, () => {
            this.showDurationDialog = true
          })

          // 距离（仅部分运动类型需要）
          if (this.isDistanceRequired()) {
            this.buildInputItem('距离', `${this.distance}公里`, () => {
              this.showDistanceDialog = true
            })
          }

          // 运动日期
          this.buildInputItem('运动日期', this.selectedDate, () => {
            this.showDateDialog = true
          })

          // 开始时间
          this.buildInputItem('开始时间', this.selectedTime, () => {
            this.showTimeDialog = true
          })
        }
        .width('100%')
        .padding(16)
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
              router.back()
            })
          
          Button('添加')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#0cc291')
            .borderRadius(8)
            .layoutWeight(1)
            .height(48)
            .margin({ left: 12 })
            .onClick(() => {
              this.saveExercise()
            })
        }
        .width('100%')
        .padding(16)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')

      // 运动类型选择弹窗
      if (this.showTypeDialog) {
        this.buildTypeDialog()
      }

      // 时长选择弹窗
      if (this.showDurationDialog) {
        this.buildDurationDialog()
      }

      // 距离选择弹窗
      if (this.showDistanceDialog) {
        this.buildDistanceDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder buildInputItem(label: string, value: string, onClick: () => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#333333')
        .layoutWeight(1)
      
      Text(value)
        .fontSize(16)
        .fontColor('#666666')
        .margin({ right: 8 })
      
      Text('>')
        .fontSize(16)
        .fontColor('#999999')
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ bottom: 12 })
    .alignItems(VerticalAlign.Center)
    .onClick(onClick)
  }

  @Builder buildTypeDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .onClick(() => {
          this.showTypeDialog = false
        })

      Column() {
        Text('选择运动类型')
          .fontSize(16)
          .fontWeight(500)
          .fontColor('#333333')
          .margin({ bottom: 16 })

        Grid() {
          ForEach(this.exerciseTypes, (type: ExerciseType) => {
            GridItem() {
              Column() {
                Image(type.icon)
                  .width(32)
                  .height(32)
                  .margin({ bottom: 6 })
                Text(type.name)
                  .fontSize(11)
                  .fontColor(this.selectedType === type.id ? '#0cc291' : '#666666')
              }
              .width('100%')
              .padding(8)
              .backgroundColor(this.selectedType === type.id ? '#E8F5E8' : '#F8F8F8')
              .borderRadius(6)
              .onClick(() => {
                this.selectedType = type.id
                this.showTypeDialog = false
                // 重新计算距离
                this.distance = this.calculateDistance()
              })
            }
          })
        }
        .columnsTemplate('1fr 1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
      }
      .width('90%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .align(Alignment.Bottom)
    }
    .width('100%')
    .height('100%')
  }

  @Builder buildDurationDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .onClick(() => {
          this.showDurationDialog = false
        })

      Column() {
        Text('选择运动时长')
          .fontSize(18)
          .fontWeight(600)
          .fontColor('#333333')
          .margin({ bottom: 20 })

        Row() {
          Button('−')
            .fontSize(24)
            .fontColor('#666666')
            .width(50)
            .height(50)
            .borderRadius(25)
            .backgroundColor('#F8F8F8')
            .onClick(() => {
              if (this.duration > 1) {
                this.duration = this.duration - 1
                this.distance = this.calculateDistance()
              }
            })

          Column() {
            Text(this.duration.toString())
              .fontSize(32)
              .fontWeight(600)
              .fontColor('#0cc291')
            
            Text('分钟')
              .fontSize(16)
              .fontColor('#666666')
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          Button('+')
            .fontSize(24)
            .fontColor('#666666')
            .width(50)
            .height(50)
            .borderRadius(25)
            .backgroundColor('#F8F8F8')
            .onClick(() => {
              this.duration = this.duration + 1
              this.distance = this.calculateDistance()
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
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
              this.showDurationDialog = false
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
              this.showDurationDialog = false
            })
        }
        .width('100%')
      }
      .width('80%')
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
  }

  @Builder buildDistanceDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .onClick(() => {
          this.showDistanceDialog = false
        })

      Column() {
        Text('输入距离')
          .fontSize(18)
          .fontWeight(600)
          .fontColor('#333333')
          .margin({ bottom: 20 })

        Row() {
          Button('−')
            .fontSize(24)
            .fontColor('#666666')
            .width(50)
            .height(50)
            .borderRadius(25)
            .backgroundColor('#F8F8F8')
            .onClick(() => {
              if (this.distance > 0.1) {
                this.distance = Math.round((this.distance - 0.1) * 10) / 10
              }
            })

          Column() {
            Text(this.distance.toFixed(1))
              .fontSize(32)
              .fontWeight(600)
              .fontColor('#0cc291')
            
            Text('公里')
              .fontSize(16)
              .fontColor('#666666')
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          Button('+')
            .fontSize(24)
            .fontColor('#666666')
            .width(50)
            .height(50)
            .borderRadius(25)
            .backgroundColor('#F8F8F8')
            .onClick(() => {
              this.distance = Math.round((this.distance + 0.1) * 10) / 10
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
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
              this.showDistanceDialog = false
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
              this.showDistanceDialog = false
            })
        }
        .width('100%')
      }
      .width('80%')
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
  }
}
