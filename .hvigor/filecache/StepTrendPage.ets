// import { McLineChart, McBarChart, Options } from '@mcui/mccharts'  // 暂时注释
import { CommonTitleView } from '../view/CommonTitleView'
import { router } from '@kit.ArkUI'
import appDataManager, { DataCallback } from '../tools/AppDataManager'
import { PerStepModel } from '../appdata/Model'
import { DateUtils } from '../tools/DateUtils'
import { Log } from '../tools/Logger'
import { Utils } from '../tools/Utils'

@Entry
@Component
struct StepTrendPage {
  @State currentTabIndex: number = 0
  @State fontColor: string = '#ff3c3c3c'
  @State selectedFontColor: string = '#0cc291'
  private tabController: TabsController = new TabsController()

  // 步数数据
  @State stepChartData: Array<PerStepModel> = new Array<PerStepModel>()
  @State stepLineOption: Options = new Options({
    title: { show: true, text: '最近7天步数趋势', right: 20, top: 30 },
    xAxis: { data: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'] },
    yAxis: { show: true, name: '步数' },
    series: [{ 
      name: '步数', 
      type: 'line',
      data: [0, 0, 0, 0, 0, 0, 0],
      lineStyle: { color: '#0cc291', width: 3 },
      itemStyle: { color: '#0cc291' }
    }]
  })

  @State stepBarOption: Options = new Options({
    title: { show: true, text: '最近7天步数对比', right: 20, top: 30 },
    xAxis: { data: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'] },
    yAxis: { show: true, name: '步数' },
    series: [{ 
      name: '步数', 
      type: 'bar',
      data: [0, 0, 0, 0, 0, 0, 0],
      barStyle: { 
        color: '#0cc291',
        borderRadius: [4, 4]
      }
    }]
  })

  // 统计数据
  @State totalSteps: number = 0
  @State averageSteps: number = 0
  @State maxSteps: number = 0
  @State minSteps: number = 0
  @State targetDays: number = 0
  @State targetStepNum: number = 5000

  // 步数数据回调
  private stepCallback: DataCallback<PerStepModel> = {
    onDataResult: (type: number, result: PerStepModel[], isReturnFirstData: boolean): void => {
      this.stepChartData = result
      this.updateStepChart()
      this.calculateStatistics()
    }
  }

  // 更新步数图表
  private updateStepChart() {
    const dates = ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
    const steps = [0, 0, 0, 0, 0, 0, 0]
    
    // 获取最近7天的数据
    for (let i = 0; i < 7; i++) {
      const dateStr = DateUtils.getYMD_(i)
      const dayData = this.stepChartData.find(item => item.date === dateStr)
      if (dayData) {
        steps[i] = dayData.steps
      }
    }

    // 更新折线图
    // this.stepLineOption.setVal({
      xAxis: { data: dates },
      series: [{ 
        name: '步数', 
        type: 'line',
        data: steps,
        lineStyle: { color: '#0cc291', width: 3 },
        itemStyle: { color: '#0cc291' }
      }]
    })

    // 更新柱状图
    // this.stepBarOption.setVal({
      xAxis: { data: dates },
      series: [{ 
        name: '步数', 
        type: 'bar',
        data: steps,
        barStyle: { 
          color: '#0cc291',
          borderRadius: [4, 4]
        }
      }]
    })
  }

  // 计算统计数据
  private calculateStatistics() {
    if (this.stepChartData.length === 0) return

    this.totalSteps = this.stepChartData.reduce((sum, item) => sum + item.steps, 0)
    this.averageSteps = Math.round(this.totalSteps / this.stepChartData.length)
    
    const steps = this.stepChartData.map(item => item.steps)
    this.maxSteps = Math.max(...steps)
    this.minSteps = Math.min(...steps)
    
    this.targetDays = this.stepChartData.filter(item => item.steps >= this.targetStepNum).length
  }

  onPageShow(): void {
    this.loadStepData()
  }

  private loadStepData() {
    // 加载步数数据
    appDataManager.getStepPerDayWeekList(this.stepCallback)
  }

  // Tab按钮构建器
  @Builder tabBuilder(index: number, title: string) {
    Column() {
      Text(title)
        .fontColor(this.currentTabIndex === index ? this.selectedFontColor : this.fontColor)
        .fontSize(this.currentTabIndex === index ? 16 : 14)
        .fontWeight(this.currentTabIndex === index ? 600 : 400)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '步数趋势分析' },
        cancel: () => {
          router.back()
        }
      })

      Tabs({ barPosition: BarPosition.Start, controller: this.tabController }) {
        // 趋势图
        TabContent() {
          Scroll() {
            Column() {
              Text('步数趋势图')
                .fontSize(18)
                .fontWeight(600)
                .margin({ top: 20, bottom: 10 })
                .alignSelf(ItemAlign.Start)
                .padding({ left: 20 })

              McLineChart({
                options: this.stepLineOption
              })
              .height(300)
              .margin({ top: 10, bottom: 20 })

              // 统计卡片
              Row() {
                Column() {
                  Text('总步数')
                    .fontSize(14)
                    .fontColor('#666')
                  Text(this.totalSteps.toString())
                    .fontSize(24)
                    .fontWeight(600)
                    .fontColor('#0cc291')
                }
                .layoutWeight(1)
                .padding(15)
                .backgroundColor('#f8f9fa')
                .borderRadius(10)

                Column() {
                  Text('平均步数')
                    .fontSize(14)
                    .fontColor('#666')
                  Text(this.averageSteps.toString())
                    .fontSize(24)
                    .fontWeight(600)
                    .fontColor('#0cc291')
                }
                .layoutWeight(1)
                .padding(15)
                .backgroundColor('#f8f9fa')
                .borderRadius(10)
                .margin({ left: 10 })
              }
              .width('90%')
              .margin({ bottom: 20 })

              Row() {
                Column() {
                  Text('最高步数')
                    .fontSize(14)
                    .fontColor('#666')
                  Text(this.maxSteps.toString())
                    .fontSize(24)
                    .fontWeight(600)
                    .fontColor('#ff6b6b')
                }
                .layoutWeight(1)
                .padding(15)
                .backgroundColor('#f8f9fa')
                .borderRadius(10)

                Column() {
                  Text('达标天数')
                    .fontSize(14)
                    .fontColor('#666')
                  Text(`${this.targetDays}/7天`)
                    .fontSize(24)
                    .fontWeight(600)
                    .fontColor(this.targetDays >= 5 ? '#0cc291' : '#ff6b6b')
                }
                .layoutWeight(1)
                .padding(15)
                .backgroundColor('#f8f9fa')
                .borderRadius(10)
                .margin({ left: 10 })
              }
              .width('90%')
              .margin({ bottom: 20 })
            }
          }
        }
        .tabBar(this.tabBuilder(0, '趋势'))

        // 对比图
        TabContent() {
          Scroll() {
            Column() {
              Text('步数对比图')
                .fontSize(18)
                .fontWeight(600)
                .margin({ top: 20, bottom: 10 })
                .alignSelf(ItemAlign.Start)
                .padding({ left: 20 })

              McBarChart({
                options: this.stepBarOption
              })
              .height(300)
              .margin({ top: 10, bottom: 20 })

              // 详细统计
              Column() {
                Text('详细统计')
                  .fontSize(18)
                  .fontWeight(600)
                  .margin({ bottom: 15 })
                  .alignSelf(ItemAlign.Start)

                ForEach(this.stepChartData, (item, index) => {
                  const isTarget = item.steps >= this.targetStepNum
                  Row() {
                    Text(DateUtils.getWeek(item.date))
                      .fontSize(16)
                      .fontWeight(500)
                      .layoutWeight(1)
                    
                    Text(item.steps.toString())
                      .fontSize(16)
                      .fontWeight(600)
                      .fontColor(isTarget ? '#0cc291' : '#666')
                      .margin({ right: 10 })
                    
                    Text(isTarget ? '达标' : '未达标')
                      .fontSize(12)
                      .fontColor(isTarget ? '#0cc291' : '#ff6b6b')
                      .backgroundColor(isTarget ? '#e8f5e8' : '#ffe8e8')
                      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                      .borderRadius(10)
                  }
                  .width('100%')
                  .padding(15)
                  .backgroundColor('#f8f9fa')
                  .borderRadius(10)
                  .margin({ bottom: 10 })
                })
              }
              .width('90%')
              .padding(20)
              .backgroundColor('#ffffff')
              .borderRadius(15)
              .margin({ bottom: 20 })
            }
          }
        }
        .tabBar(this.tabBuilder(1, '对比'))
      }
      .barHeight('8%')
      .barWidth('100%')
      .scrollable(true)
      .onChange((index: number) => {
        this.currentTabIndex = index
      })
      .width('100%')
      .height('85%')
    }
  }
}


