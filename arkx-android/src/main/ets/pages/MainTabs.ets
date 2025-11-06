import { router } from '@kit.ArkUI'
import { MainTopView, TopData } from '../view/MainTopView'
import { MainCardView, MainCardData } from '../view/MainCardView'
import { SubFragment, SubFragmentData } from '../view/SubFragment'
import { TITLE_SAFE_TOP_OFFSET } from '../tools/UiConstants'
import mainCardManager from '../tools/MainCardManager'
import appDataManager from '../tools/AppDataManager'
import preferencesUtil from '../tools/PreferencesUtil'

@Entry
@Component
struct MainTabs {
  @State fontColor: string = '#182431'
  @State selectedFontColor: string = '#0cc291'
  @State mainCardH: string = '27%'
  @State currentIndex: number = 0
  @State currentSubIndex: number = 0
  @State tabColor: string = '#F5F5F5'
  @State version: string = '1.2.0'
  
  private controller: TabsController = new TabsController()
  private subController: TabsController = new TabsController()
  private scroller: Scroller = new Scroller()
  private sportSubScrollers: Array<Scroller> = [
    new Scroller(), new Scroller(), new Scroller(),
    new Scroller(), new Scroller(), new Scroller()
  ]
  
  private tarSteps: number = 5000
  @State formData: TopData = {
    curSteps: '0',
    tarSteps: '/5000步',
    tarStepsPer: 0,
    tarStepsPerStr: '0%',
    tarStepsHintStr: '还差3000步达到目标'
  }

  @State subFragmentDataInside: SubFragmentData = {
    type: 1,
    curTarget: '自由',
    subTopTitle: '累计室内跑步距离',
    subTopData: '5',
    subBotData: '室内跑记录'
  }
  @State subFragmentDataOut: SubFragmentData = {
    type: 2,
    curTarget: '自由',
    subTopTitle: '累计室外跑步距离',
    subTopData: '8',
    subBotData: '室外跑记录'
  }
  @State subFragmentDataWalk: SubFragmentData = {
    type: 3,
    curTarget: '自由',
    subTopTitle: '累计健走距离',
    subTopData: '3',
    subBotData: '健走记录'
  }
  @State subFragmentDataFoot: SubFragmentData = {
    type: 4,
    curTarget: '自由',
    subTopTitle: '累计徒步距离',
    subTopData: '2',
    subBotData: '徒步记录'
  }
  @State subFragmentDataClimb: SubFragmentData = {
    type: 5,
    curTarget: '自由',
    subTopTitle: '累计登山距离',
    subTopData: '1',
    subBotData: '登山记录'
  }
  @State subFragmentDataRide: SubFragmentData = {
    type: 6,
    curTarget: '自由',
    subTopTitle: '累计骑行距离',
    subTopData: '10',
    subBotData: '骑行记录'
  }

  @State line1: Array<MainCardData> = []
  @State line2: Array<MainCardData> = []
  @State line3: Array<MainCardData> = []
  
  @State userName: string = '未登录用户'
  @State userCode: string = '华为账号登录'
  @State userImg: PixelMap | undefined = undefined

  async aboutToAppear() {
    await this.loadData()
  }

  private async loadData() {
    await mainCardManager.loadMainCardManager()
    await this.loadStepTarget()
    await this.syncUserProfile()
    this.updateMainCard()
    this.updateStepsView(0) // TODO: 从步数传感器获取
  }

  private async loadStepTarget() {
    const target = await preferencesUtil.getPreferenceValue('steps_ohos', 'step_target', '5000')
    this.tarSteps = parseInt(target) || 5000
    this.formData.tarSteps = '/' + this.tarSteps + '步'
  }

  private async syncUserProfile() {
    const nickname = await preferencesUtil.getPreferenceValue('steps_ohos', 'userNickname', '')
    const name = await preferencesUtil.getPreferenceValue('steps_ohos', 'userName', '')
    if (nickname && nickname.length > 0) {
      this.userName = nickname
    } else if (name && name.length > 0 && name !== '未登录用户') {
      this.userName = name
    } else {
      this.userName = '未登录用户'
    }
  }

  private updateMainCard() {
    this.line1.length = 0
    this.line2.length = 0
    this.line3.length = 0
    const mainCards = mainCardManager.getCardSet()
    for (let i = 0; i < mainCards.length; i++) {
      if (this.line1.length < 2) {
        this.line1.push(this.createMainCardData(mainCards[i], i))
        continue
      }
      if (this.line2.length < 2) {
        this.line2.push(this.createMainCardData(mainCards[i], i - 2))
        continue
      }
      if (this.line3.length < 2) {
        this.line3.push(this.createMainCardData(mainCards[i], i - 4))
        continue
      }
    }
  }

  private createMainCardData(item: number, index: number): MainCardData {
    return {
      item,
      index,
      subtitle: appDataManager.getMainCardSubStr(item),
      value: appDataManager.getMainCardSubData(item),
      prevTitle: appDataManager.getMainCardLastTitle(item),
      prevValue: appDataManager.getMainCardLastData(item)
    }
  }

  private updateStepsView(steps: number) {
    this.formData.curSteps = steps.toString()
    this.formData.tarStepsPer = (steps * 100) / this.tarSteps
    let percent = Math.floor((steps * 100) / this.tarSteps)
    if (percent > 100) {
      percent = 100
    }
    this.formData.tarStepsPerStr = percent + '%'
    if (steps > this.tarSteps) {
      this.formData.tarStepsHintStr = '已完成目标'
    } else {
      const remaining = this.tarSteps - steps
      this.formData.tarStepsHintStr = '还差' + remaining + '步达到目标'
    }
  }

  private handleLoginTap() {
    router.pushUrl({ url: 'pages/LoginPage' })
  }

  private getSafeTopPadding(): number {
    // 简化版：固定安全区
    return Math.max(0, 0 - TITLE_SAFE_TOP_OFFSET)
  }

  @Builder
  tabBuilder(index: number, text: string, selectedIcon: Resource, normalIcon: Resource) {
    Column() {
      Image(this.currentIndex === index ? selectedIcon : normalIcon)
        .width(24)
        .height(24)
      Text(text)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? this.selectedFontColor : this.fontColor)
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  subTabBuilder(index: number, text: string) {
    Text(text)
      .fontSize(14)
      .fontColor(this.currentSubIndex === index ? this.selectedFontColor : this.fontColor)
      .fontWeight(this.currentSubIndex === index ? FontWeight.Medium : FontWeight.Normal)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }

  build() {
    Stack() {
      Tabs({ barPosition: BarPosition.End, controller: this.controller }) {
        // Tab 1: 健康
        TabContent() {
          Scroll(this.scroller) {
            Column() {
              Text('健康')
                .fontColor('#000000')
                .fontSize(20)
                .fontWeight(500)
                .width('95%')
                .margin({ bottom: 10, top: 10 })
                .padding({ top: this.getSafeTopPadding() })

              MainTopView({ formData: this.formData })

              if (this.line1.length > 0) {
                Row() {
                  ForEach(this.line1, (item: MainCardData, index: number) => {
                    MainCardView({ formData: item })
                  })
                }
                .width('92%')
                .height(this.mainCardH)
                .margin({ top: 10 })
              }

              if (this.line2.length > 0) {
                Row() {
                  ForEach(this.line2, (item: MainCardData, index: number) => {
                    MainCardView({ formData: item })
                  })
                }
                .width('92%')
                .height(this.mainCardH)
                .margin({ top: 10 })
              }

              if (this.line3.length > 0) {
                Row() {
                  ForEach(this.line3, (item: MainCardData, index: number) => {
                    MainCardView({ formData: item })
                  })
                }
                .width('92%')
                .height(this.mainCardH)
                .margin({ top: 10 })
              }

              Text('编辑卡片')
                .fontSize(18)
                .fontColor('#09926d')
                .margin(15)
                .onClick(() => {
                  router.pushUrl({ url: 'pages/EditMainCardPage' })
                })
            }
            .width('100%')
            .backgroundColor(this.tabColor)
          }
          .width('100%')
          .height('100%')
          .align(Alignment.Top)
          .scrollBar(BarState.Off)
          .backgroundColor(this.tabColor)
        }
        .tabBar(this.tabBuilder(0, '健康', $r('app.media.home_icon_f'), $r('app.media.home_icon_n')))

        // Tab 2: 运动
        TabContent() {
          Column() {
            Text('运动')
              .fontColor('#000000')
              .fontSize(20)
              .fontWeight(500)
              .width('95%')
              .margin({ bottom: 10, top: 10 })
              .padding({ top: this.getSafeTopPadding() })

            Tabs({ barPosition: BarPosition.Start, controller: this.subController }) {
              TabContent() {
                Scroll(this.sportSubScrollers[0]) {
                  Column() {
                    SubFragment({ formData: this.subFragmentDataInside })
                  }
                  .width('100%')
                  .backgroundColor('#FFFFFF')
                }
                .width('100%')
                .align(Alignment.Top)
                .scrollBar(BarState.Off)
                .backgroundColor('#FFFFFF')
              }
              .tabBar(this.subTabBuilder(0, '室内跑'))

              TabContent() {
                Scroll(this.sportSubScrollers[1]) {
                  Column() {
                    SubFragment({ formData: this.subFragmentDataOut })
                  }
                  .width('100%')
                  .backgroundColor('#FFFFFF')
                }
                .width('100%')
                .align(Alignment.Top)
                .scrollBar(BarState.Off)
                .backgroundColor('#FFFFFF')
              }
              .tabBar(this.subTabBuilder(1, '室外跑'))

              TabContent() {
                Scroll(this.sportSubScrollers[2]) {
                  Column() {
                    SubFragment({ formData: this.subFragmentDataWalk })
                  }
                  .width('100%')
                  .backgroundColor('#FFFFFF')
                }
                .width('100%')
                .align(Alignment.Top)
                .scrollBar(BarState.Off)
                .backgroundColor('#FFFFFF')
              }
              .tabBar(this.subTabBuilder(2, '健走'))

              TabContent() {
                Scroll(this.sportSubScrollers[3]) {
                  Column() {
                    SubFragment({ formData: this.subFragmentDataFoot })
                  }
                  .width('100%')
                  .backgroundColor('#FFFFFF')
                }
                .width('100%')
                .align(Alignment.Top)
                .scrollBar(BarState.Off)
                .backgroundColor('#FFFFFF')
              }
              .tabBar(this.subTabBuilder(3, '徒步'))

              TabContent() {
                Scroll(this.sportSubScrollers[4]) {
                  Column() {
                    SubFragment({ formData: this.subFragmentDataClimb })
                  }
                  .width('100%')
                  .backgroundColor('#FFFFFF')
                }
                .width('100%')
                .align(Alignment.Top)
                .scrollBar(BarState.Off)
                .backgroundColor('#FFFFFF')
              }
              .tabBar(this.subTabBuilder(4, '登山'))

              TabContent() {
                Scroll(this.sportSubScrollers[5]) {
                  Column() {
                    SubFragment({ formData: this.subFragmentDataRide })
                  }
                  .width('100%')
                  .backgroundColor('#FFFFFF')
                }
                .width('100%')
                .align(Alignment.Top)
                .scrollBar(BarState.Off)
                .backgroundColor('#FFFFFF')
              }
              .tabBar(this.subTabBuilder(5, '骑行'))
            }
            .barHeight('6%')
            .barWidth('100%')
            .barMode(BarMode.Scrollable)
            .scrollable(true)
            .width('100%')
            .layoutWeight(1)
            .vertical(false)
            .onChange((index: number) => {
              this.currentSubIndex = index
            })
            .backgroundColor('#FFFFFF')
          }
          .width('100%')
          .height('100%')
          .backgroundColor('#FFFFFF')
        }
        .tabBar(this.tabBuilder(1, '运动', $r('app.media.tab_sport_f'), $r('app.media.tab_sport_n')))

        // Tab 3: 我的
        TabContent() {
          Scroll(this.scroller) {
            Column() {
              Row() {
                Row() {
                  if (this.userImg) {
                    Image(this.userImg)
                      .width(60)
                      .height(60)
                      .borderRadius(15)
                  } else {
                    Image($r('app.media.default_user_icon'))
                      .width(60)
                      .height(60)
                      .borderRadius(15)
                      .fillColor('#BDBDBD')
                  }
                  Text() {
                    Span(this.userName)
                      .fontSize(18)
                      .fontColor('#000000')
                      .fontWeight(600)
                    Span('\n')
                    Span(this.userCode)
                      .fontSize(13)
                      .fontColor('#727272')
                  }
                  .textAlign(TextAlign.Start)
                  .margin({ left: 10 })
                }
                .layoutWeight(1)
                .onClick(() => {
                  this.handleLoginTap()
                })

                Row() {
                  Text('个人信息')
                    .fontSize(14)
                    .fontColor('#333333')
                  Image($r('app.media.right_point'))
                    .width(16)
                    .height(16)
                    .margin({ left: 4 })
                    .fillColor('#999999')
                }
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .onClick(() => {
                  router.pushUrl({ url: 'pages/UserProfilePage' })
                })
              }
              .width('94%')
              .height(80)
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .margin({ top: 10 })
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
              .justifyContent(FlexAlign.SpaceBetween)
              .alignItems(VerticalAlign.Center)

              Column() {
                Row() {
                  Text('用户协议')
                    .layoutWeight(1)
                    .fontSize(15)
                    .fontColor('#333333')
                  Image($r('app.media.right_point'))
                    .width(15)
                    .height(15)
                    .fillColor('#999999')
                }
                .width('100%')
                .padding(12)
                .onClick(() => {
                  router.pushUrl({ url: 'pages/XYPage' })
                })

                Row() {
                  Text('隐私协议')
                    .layoutWeight(1)
                    .fontSize(15)
                    .fontColor('#333333')
                  Image($r('app.media.right_point'))
                    .width(15)
                    .height(15)
                    .fillColor('#999999')
                }
                .width('100%')
                .padding(12)
                .onClick(() => {
                  router.pushUrl({ url: 'pages/YSPage' })
                })

                Row() {
                  Text('设置')
                    .layoutWeight(1)
                    .fontSize(15)
                    .fontColor('#333333')
                  Image($r('app.media.right_point'))
                    .width(15)
                    .height(15)
                    .fillColor('#999999')
                }
                .width('100%')
                .padding(12)
                .onClick(() => {
                  router.pushUrl({ url: 'pages/SettingPage' })
                })

                Row() {
                  Text('版本号')
                    .layoutWeight(1)
                    .fontSize(15)
                    .fontColor('#333333')
                  Text(this.version)
                    .fontSize(15)
                    .fontColor('#676767')
                }
                .width('100%')
                .padding(12)
              }
              .width('96%')
              .backgroundColor('#FFFFFF')
              .borderRadius(15)
              .margin({ top: 20 })
            }
            .width('100%')
            .padding({
              left: '1%',
              right: '1%',
              top: this.getSafeTopPadding()
            })
            .backgroundColor(this.tabColor)
          }
          .width('100%')
          .height('100%')
          .align(Alignment.Top)
          .scrollBar(BarState.Off)
          .backgroundColor(this.tabColor)
        }
        .tabBar(this.tabBuilder(2, '我的', $r('app.media.setting_icon_f'), $r('app.media.setting_icon_n')))
      }
      .vertical(false)
      .onTabBarClick((index: number) => {
        this.controller.changeIndex(index)
      })
      .barHeight('7%')
      .barWidth('100%')
      .scrollable(true)
      .barBackgroundColor('#e4e4e4')
      .onChange((index: number) => {
        this.currentIndex = index
      })
      .width('100%')
      .height('100%')
      .backgroundColor(this.tabColor)
    }
    .width('100%')
    .height('100%')
  }
}

