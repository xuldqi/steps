import { router, window } from '@kit.ArkUI'
import { CommonTitleView } from '../view/CommonTitleView'
import { AppStateStore } from '../services/AppStateStore'
import preferencesUtil from '../tools/DataPreUtils'
import { Log } from '../tools/Logger'

@Entry
@Component
struct UserProfilePage {
  private appStateStore: AppStateStore = AppStateStore.getInstance()
  private appStateUnsubscribe: (() => void) | null = null

  @State userName: string = '未登录用户'
  @State userCode: string = '华为账号登录'
  @State userImg: PixelMap | undefined = undefined
  @State nickname: string = '运动达人'
  @State isLoggedIn: boolean = false

  getSafeTopPadding(): number {
    if (!EntryAbility.myWindowClass) {
      return 0
    }
    const avoidArea = EntryAbility.myWindowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
    return Math.max(0, avoidArea.topRect.height)
  }

  onPageShow(): void {
    this.loadUserInfo()
    // 订阅应用状态变化
    this.appStateUnsubscribe = this.appStateStore.subscribe((state) => {
      this.applyAppState(state)
    })
    // 立即应用当前状态
    this.applyAppState(this.appStateStore.getState())
  }

  aboutToDisappear(): void {
    if (this.appStateUnsubscribe) {
      this.appStateUnsubscribe()
      this.appStateUnsubscribe = null
    }
  }

  private async loadUserInfo(): Promise<void> {
    try {
      await this.syncUserProfile()
      await this.loadUserImage()
    } catch (error) {
      Log.e('[UserProfilePage] 加载用户信息失败:', JSON.stringify(error))
    }
  }

  private async syncUserProfile(): Promise<void> {
    if (!preferencesUtil.preferencesMap.has('steps_ohos') && EntryAbility.context) {
      await preferencesUtil.loadPreference(EntryAbility.context, 'steps_ohos')
    }
    const storedName = await preferencesUtil.getPreferenceValue('steps_ohos', 'userName', this.userName)
    if (typeof storedName === 'string') {
      this.userName = storedName
    }
    const storedCode = await preferencesUtil.getPreferenceValue('steps_ohos', 'userCode', this.userCode)
    if (typeof storedCode === 'string') {
      this.userCode = storedCode === '登录功能开发中' ? '华为账号登录' : storedCode
    }
  }

  private async loadUserImage(): Promise<void> {
    // TODO: 加载用户头像
    this.userImg = undefined
  }

  private applyAppState(state: any): void {
    if (state && state.user) {
      this.nickname = state.user.nickname ?? '运动达人'
      this.userName = state.user.nickname ?? '运动达人'
      this.userCode = state.user.inviteCode ? `邀请码：${state.user.inviteCode}` : '已登录'
      this.isLoggedIn = true
    } else {
      this.userName = '未登录用户'
      this.userCode = '华为账号登录'
      this.isLoggedIn = false
    }
  }

  private handleLoginTap(): void {
    if (!this.isLoggedIn) {
      router.pushUrl({ url: 'pages/LoginPage' }).catch((err: Error) => {
        Log.e('[UserProfilePage] 跳转登录页失败:', err.message)
      })
    }
  }

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '个人信息' },
        cancel: () => {
          router.back()
        }
      })

      Scroll() {
        Column() {
          // 用户信息卡片
          Column() {
            Row() {
              Image(this.userImg)
                .alt($r('app.media.user_image'))
                .width(80)
                .height(80)
                .borderRadius(40)
                .backgroundColor('#F0F0F0')

              Column() {
                Text(this.userName)
                  .fontSize(20)
                  .fontWeight(600)
                  .fontColor('#222222')
                Text(this.userCode)
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ top: 4 })
              }
              .layoutWeight(1)
              .margin({ left: 16 })
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding(20)
          }
          .width('94%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .margin({ top: 16, bottom: 8 })

          // 登录/退出按钮
          Column() {
            if (!this.isLoggedIn) {
              Row() {
                Text('登录账号')
                  .fontSize(16)
                  .fontColor('#FFFFFF')
              }
              .width('100%')
              .height(44)
              .backgroundColor('#0cc291')
              .borderRadius(12)
              .justifyContent(FlexAlign.Center)
              .onClick(() => {
                this.handleLoginTap()
              })
            } else {
              Row() {
                Text('退出登录')
                  .fontSize(16)
                  .fontColor('#FF4444')
              }
              .width('100%')
              .height(44)
              .backgroundColor('#FFF5F5')
              .borderRadius(12)
              .justifyContent(FlexAlign.Center)
              .onClick(() => {
                // TODO: 实现退出登录
                Log.i('[UserProfilePage] 退出登录')
              })
            }
          }
          .width('94%')
          .margin({ top: 8, bottom: 16 })

          // 个人信息列表
          Column() {
            // 昵称
            Row() {
              Text('昵称')
                .fontSize(15)
                .fontColor('#333333')
                .layoutWeight(1)
              Text(this.nickname)
                .fontSize(15)
                .fontColor('#666666')
              Image($r('app.media.right_point'))
                .width(16)
                .height(16)
                .margin({ left: 8 })
                .fillColor('#CCCCCC')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .onClick(() => {
              // TODO: 编辑昵称
              Log.i('[UserProfilePage] 编辑昵称')
            })

            Divider()
              .color('#F0F0F0')
              .strokeWidth(1)
              .margin({ left: 16, right: 16 })

            // 账号信息
            Row() {
              Text('账号信息')
                .fontSize(15)
                .fontColor('#333333')
                .layoutWeight(1)
              Text(this.isLoggedIn ? '已登录' : '未登录')
                .fontSize(15)
                .fontColor('#666666')
              Image($r('app.media.right_point'))
                .width(16)
                .height(16)
                .margin({ left: 8 })
                .fillColor('#CCCCCC')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          }
          .width('94%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .margin({ bottom: 16 })
        }
        .width('100%')
        .padding({ bottom: this.getSafeTopPadding() + 20 })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

