import { router, window } from '@kit.ArkUI'
import { CommonTitleView } from '../view/CommonTitleView'
import { Utils } from '../tools/Utils'
import AppDataManager from '../tools/AppDataManager'
import { DateUtils } from '../tools/DateUtils'
import { systemDateTime } from '@kit.BasicServicesKit'
import preferencesUtil from '../tools/DataPreUtils'

const PRIMARY = '#0cc291'

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
  @State tempDuration: number = 30
  @State tempDistance: number = 1.0
  @State selectedDate: string = DateUtils.getYMD()
  @State selectedTime: string = '10:00'
  @State showTypeDialog: boolean = false
  @State showDurationDialog: boolean = false
  @State showDistanceDialog: boolean = false
  @State showDateDialog: boolean = false
  @State showTimeDialog: boolean = false
  @State userModifiedDistance: boolean = false // 用户是否手动修改过距离
  @State calories: number = 0 // 消耗的热量
  @State distancePickerIndex: number = 0 // 距离选择器的当前索引
  @State userWeight: number = 60 // 用户体重（公斤）

  private exerciseTypes: Array<ExerciseType> = [
    { id: 1, name: '室内跑步', icon: $r('app.media.sport_indoor_run') },
    { id: 2, name: '室外跑步', icon: $r('app.media.sport_run') },
    { id: 3, name: '骑行', icon: $r('app.media.sport_run') }, // 使用现有图标
    { id: 4, name: '健走', icon: $r('app.media.sport_go_walk') },
    { id: 5, name: '爬山', icon: $r('app.media.sport_climb') }
    // 隐藏瑜伽和跳绳
  ]

  async aboutToAppear() {
    // 设置默认时间为当前时间
    const now = new Date()
    this.selectedTime = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`
    this.tempDuration = this.duration
    this.tempDistance = this.distance
    // 初始化距离选择器索引
    const list = this.generateDistanceList()
    const rounded = Math.round(this.distance * 10) / 10
    const idx = list.findIndex(v => Math.abs(v - rounded) < 0.01)
    this.distancePickerIndex = idx >= 0 ? idx : 0
    
    // 获取用户体重
    const storedWeight = await preferencesUtil.getPreferenceValue('steps_ohos', 'weight', 60) as number
    if (typeof storedWeight === 'number' && !Number.isNaN(storedWeight) && storedWeight > 0) {
      this.userWeight = storedWeight
    } else {
      this.userWeight = 60
    }
    
    // 计算初始卡路里
    this.calories = this.calculateCalories()
  }

  private generateDurationList(): Array<number> {
    const list: Array<number> = []
    for (let i = 1; i <= 300; i++) { // 1~300 分钟
      list.push(i)
    }
    return list
  }

  private getDurationSelectedIndex(): number {
    const list = this.generateDurationList()
    const idx = list.findIndex(v => v === this.tempDuration)
    return idx >= 0 ? idx : Math.max(0, Math.min(list.length - 1, this.tempDuration - 1))
  }

  private generateDistanceList(): Array<number> {
    const list: Array<number> = []
    // 0.1 ~ 100.0 公里，步进 0.1
    for (let i = 1; i <= 1000; i++) {
      list.push(Math.round(i) / 10)
    }
    return list
  }

  private getDistanceSelectedIndex(): number {
    const list = this.generateDistanceList()
    const rounded = Math.round(this.tempDistance * 10) / 10
    const idx = list.findIndex(v => Math.abs(v - rounded) < 0.01) // 使用容差比较浮点数
    return idx >= 0 ? idx : this.distancePickerIndex
  }

  private calculateCalories(): number {
    // 使用基于体重和距离的METs公式计算热量（与AddSportPage保持一致）
    const weight = this.userWeight > 0 ? this.userWeight : 60
    const distance = this.distance > 0 ? this.distance : 0
    let calories = 0
    
    switch (this.selectedType) {
      case 1: // 室内跑
      case 2: // 室外跑
        calories = weight * distance * 1.036 * 0.8
        break
      case 3: // 骑行
        calories = weight * distance * 1.036 * 0.5
        break
      case 4: // 健走
        calories = weight * distance * 1.036
        break
      case 5: // 爬山
        calories = weight * distance * 1.036 * 1.2
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
      this.duration * 60 * 1000,
      steps,
      this.selectedType,
      0,
      calories.toString(),
      () => {
        Utils.showToast('运动记录添加成功')
        router.back()
      }
    )
  }

  private getSelectedTypeName(): string {
    const type = this.exerciseTypes.find(t => t.id === this.selectedType)
    return type ? type.name : '室内跑步'
  }

  private isDistanceRequired(): boolean {
    // 所有运动类型都需要距离
    return true
  }

  private onDistanceChange(newDistance: number) {
    this.distance = newDistance
    this.userModifiedDistance = true
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
          // 运动类型（使用响应式绑定）
          this.buildTypeInputItem()

          // 运动时长（使用响应式绑定）
          this.buildDurationInputItem()

          // 距离（仅部分运动类型需要，使用响应式绑定）
          if (this.isDistanceRequired()) {
            this.buildDistanceInputItem()
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
            .backgroundColor(PRIMARY)
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

      // 日期选择弹窗
      if (this.showDateDialog) {
        this.buildDateDialog()
      }

      // 时间选择弹窗
      if (this.showTimeDialog) {
        this.buildTimeDialog()
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
    .height(60)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ bottom: 12 })
    .alignItems(VerticalAlign.Center)
    .onClick(onClick)
  }

  // 专门用于距离的输入项，直接绑定状态变量
  @Builder buildDistanceInputItem() {
    Row() {
      Text('距离')
        .fontSize(16)
        .fontColor('#333333')
        .layoutWeight(1)
      
      Text(`${this.distance.toFixed(1)}公里`)
        .fontSize(16)
        .fontColor('#666666')
        .margin({ right: 8 })
      
      Text('>')
        .fontSize(16)
        .fontColor('#999999')
    }
    .width('100%')
    .height(60)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ bottom: 12 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.tempDistance = this.distance
      // 更新距离选择器的索引
      const list = this.generateDistanceList()
      const rounded = Math.round(this.distance * 10) / 10
      const idx = list.findIndex(v => Math.abs(v - rounded) < 0.01)
      this.distancePickerIndex = idx >= 0 ? idx : 0
      this.showDistanceDialog = true
    })
  }

  // 专门用于运动时长的输入项，直接绑定状态变量
  @Builder buildDurationInputItem() {
    Row() {
      Text('运动时长')
        .fontSize(16)
        .fontColor('#333333')
        .layoutWeight(1)
      
      Text(`${this.duration}分钟`)
        .fontSize(16)
        .fontColor('#666666')
        .margin({ right: 8 })
      
      Text('>')
        .fontSize(16)
        .fontColor('#999999')
    }
    .width('100%')
    .height(60)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ bottom: 12 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.tempDuration = this.duration
      this.showDurationDialog = true
    })
  }

  // 专门用于运动类型的输入项，直接绑定状态变量
  @Builder buildTypeInputItem() {
    Row() {
      Text('运动类型')
        .fontSize(16)
        .fontColor('#333333')
        .layoutWeight(1)
      
      Text(this.getSelectedTypeName())
        .fontSize(16)
        .fontColor('#666666')
        .margin({ right: 8 })
      
      Text('>')
        .fontSize(16)
        .fontColor('#999999')
    }
    .width('100%')
    .height(60)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ bottom: 12 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.showTypeDialog = true
    })
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
          .fontSize(18)
          .fontWeight(600)
          .fontColor('#333333')
          .margin({ bottom: 12 })

        Grid() {
          ForEach(this.exerciseTypes, (type: ExerciseType) => {
            GridItem() {
              Column() {
                Image(type.icon)
                  .width(32)
                  .height(32)
                  .margin({ bottom: 6 })
                Text(type.name)
                  .fontSize(12)
                  .fontColor(this.selectedType === type.id ? '#0cc291' : '#666666')
              }
              .width('100%')
              .height(70)
              .padding(8)
              .backgroundColor(this.selectedType === type.id ? '#E8F5E8' : '#F8F8F8')
              .borderRadius(6)
              .justifyContent(FlexAlign.Center)
              .onClick(() => {
                this.selectedType = type.id
                this.showTypeDialog = false
                this.userModifiedDistance = false
                this.distance = this.calculateDistance()
                this.tempDistance = this.distance
              })
            }
          })
        }
        .columnsTemplate('1fr 1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
      }
      .width('80%')
      .height(260) // 固定弹窗高度为260px
      .padding({ top: 16, bottom: 16, left: 20, right: 20 })
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .align(Alignment.Center)
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Center)
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

        // 统一滑动选择器
        TextPicker({
          range: this.generateDurationList().map(v => `${v}分钟`),
          selected: this.getDurationSelectedIndex()
        })
          .onChange((value, index) => {
            const idx = Array.isArray(index) ? index[0] as number : (index as number)
            this.tempDuration = this.generateDurationList()[idx]
          })
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
              this.showDurationDialog = false
            })
          
          Button('确定')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(PRIMARY)
            .borderRadius(8)
            .layoutWeight(1)
            .height(48)
            .margin({ left: 12 })
            .onClick(() => {
              this.duration = this.tempDuration
              if (!this.userModifiedDistance) {
                this.distance = this.calculateDistance()
                this.tempDistance = this.distance
              }
              this.calories = this.calculateCalories()
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

        // 统一滑动选择器
        TextPicker({
          range: this.generateDistanceList().map(v => `${v.toFixed(1)}公里`),
          selected: this.getDistanceSelectedIndex()
        })
          .onChange((value, index) => {
            const idx = Array.isArray(index) ? index[0] as number : (index as number)
            this.distancePickerIndex = idx
            this.tempDistance = this.generateDistanceList()[idx]
          })
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
              this.showDistanceDialog = false
            })
          
          Button('确定')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(PRIMARY)
            .borderRadius(8)
            .layoutWeight(1)
            .height(48)
            .margin({ left: 12 })
            .onClick(() => {
              // 从当前索引获取距离值，确保使用最新的选择
              const list = this.generateDistanceList()
              const selectedDistance = list[this.distancePickerIndex]
              this.distance = selectedDistance // 直接更新距离值
              this.tempDistance = selectedDistance // 同步更新tempDistance
              this.userModifiedDistance = true // 确认用户已手动修改距离
              this.calories = this.calculateCalories() // 更新热量计算
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

  @Builder buildDateDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .onClick(() => {
          this.showDateDialog = false
        })

      Column() {
        Text('选择运动日期')
          .fontSize(18)
          .fontWeight(600)
          .fontColor('#333333')
          .margin({ bottom: 20 })

        DatePicker({
          start: new Date('2020-01-01'),
          end: new Date('2030-12-31'),
          selected: new Date(this.selectedDate)
        })
          .onChange((value: DatePickerResult) => {
            if (value.month !== undefined && value.day !== undefined) {
              this.selectedDate = `${value.year}/${(value.month + 1).toString().padStart(2, '0')}/${value.day.toString().padStart(2, '0')}`
            }
          })

        Row() {
          Button('取消')
            .fontSize(16)
            .fontColor('#666666')
            .backgroundColor('#F8F8F8')
            .borderRadius(8)
            .layoutWeight(1)
            .height(48)
            .onClick(() => {
              this.showDateDialog = false
            })
          
          Button('确定')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(PRIMARY)
            .borderRadius(8)
            .layoutWeight(1)
            .height(48)
            .margin({ left: 12 })
            .onClick(() => {
              this.showDateDialog = false
            })
        }
        .width('100%')
        .margin({ top: 20 })
      }
      .width('90%')
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
  }

  @Builder buildTimeDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .onClick(() => {
          this.showTimeDialog = false
        })

      Column() {
        Text('选择开始时间')
          .fontSize(18)
          .fontWeight(600)
          .fontColor('#333333')
          .margin({ bottom: 20 })

        TimePicker({
          selected: new Date(`2000-01-01 ${this.selectedTime}:00`)
        })
          .onChange((value: TimePickerResult) => {
            this.selectedTime = `${value.hour.toString().padStart(2, '0')}:${value.minute.toString().padStart(2, '0')}`
          })

        Row() {
          Button('取消')
            .fontSize(16)
            .fontColor('#666666')
            .backgroundColor('#F8F8F8')
            .borderRadius(8)
            .layoutWeight(1)
            .height(48)
            .onClick(() => {
              this.showTimeDialog = false
            })
          
          Button('确定')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(PRIMARY)
            .borderRadius(8)
            .layoutWeight(1)
            .height(48)
            .margin({ left: 12 })
            .onClick(() => {
              this.showTimeDialog = false
            })
        }
        .width('100%')
        .margin({ top: 20 })
      }
      .width('90%')
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
  }
}
