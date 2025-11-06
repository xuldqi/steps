import { router } from '@kit.ArkUI'
import { CommonTitleView } from '../view/CommonTitleView'
import preferencesUtil from '../tools/PreferencesUtil'

@Entry
@Component
struct UserProfilePage {
  @State userName: string = '未登录用户'
  @State userCode: string = '华为账号登录'
  @State userImg: PixelMap | undefined = undefined
  @State nickname: string = '运动达人'
  
  @State gender: string = 'male'
  @State age: number = 0
  @State userHeight: number = 0
  @State targetWeight: number = 0

  async onPageShow() {
    await this.loadUserInfo()
  }

  private async loadUserInfo() {
    const nickname = await preferencesUtil.getPreferenceValue('steps_ohos', 'userNickname', '')
    const name = await preferencesUtil.getPreferenceValue('steps_ohos', 'userName', '')
    const genderPref = await preferencesUtil.getPreferenceValue('steps_ohos', 'gender', 'male')
    const agePref = await preferencesUtil.getPreferenceValue('steps_ohos', 'age', 0)
    const heightPref = await preferencesUtil.getPreferenceValue('steps_ohos', 'height', 0)
    const targetWeightPref = await preferencesUtil.getPreferenceValue('steps_ohos', 'targetWeight', 0)

    if (nickname && nickname.length > 0) {
      this.nickname = nickname
      this.userName = nickname
    } else if (name && name.length > 0 && name !== '未登录用户') {
      this.userName = name
      this.nickname = name
    } else {
      this.userName = '未登录用户'
      this.nickname = '运动达人'
    }

    this.gender = genderPref || 'male'
    this.age = Number(agePref) || 0
    this.userHeight = Number(heightPref) || 0
    this.targetWeight = Number(targetWeightPref) || 0
  }

  private formatGender(): string {
    return this.gender === 'male' ? '男' : '女'
  }

  private buildDivider() {
    Divider()
      .color('#F0F0F0')
      .strokeWidth(1)
      .margin({ left: 16, right: 16 })
  }

  @Builder
  buildInfoRow(label: string, value: () => string, onClick: () => void) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor('#333333')
        .layoutWeight(1)
      Text(value())
        .fontSize(15)
        .fontColor('#666666')
        .margin({ right: 8 })
      Image($r('app.media.right_point'))
        .width(16)
        .height(16)
        .fillColor('#CCCCCC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .onClick(onClick)
  }

  private openNicknameDialog() {
    // TODO: 打开昵称编辑对话框
    console.info('[UserProfilePage] 打开昵称编辑')
  }

  private openGenderDialog() {
    // TODO: 打开性别选择对话框
    console.info('[UserProfilePage] 打开性别选择')
  }

  private openAgeDialog() {
    // TODO: 打开年龄编辑对话框
    console.info('[UserProfilePage] 打开年龄编辑')
  }

  private openHeightDialog() {
    // TODO: 打开身高编辑对话框
    console.info('[UserProfilePage] 打开身高编辑')
  }

  private openWeightDialog() {
    // TODO: 打开体重编辑对话框
    console.info('[UserProfilePage] 打开体重编辑')
  }

  private openAvatarDialog() {
    // TODO: 打开头像选择对话框
    console.info('[UserProfilePage] 打开头像选择')
  }

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '个人详情' },
        cancel: () => {
          router.back()
        },
        titleBackgroundColor: '#F5F5F5',
        useSafeTop: true
      })

      Scroll() {
        Column() {
          // 个人信息卡片
          Column() {
            // 头像
            Row() {
              Text('头像')
                .fontSize(15)
                .fontColor('#333333')
                .layoutWeight(1)
              if (this.userImg) {
                Image(this.userImg)
                  .width(40)
                  .height(40)
                  .borderRadius(20)
              } else {
                Image($r('app.media.default_user_icon'))
                  .width(40)
                  .height(40)
                  .borderRadius(20)
                  .fillColor('#BDBDBD')
              }
              Image($r('app.media.right_point'))
                .width(16)
                .height(16)
                .margin({ left: 8 })
                .fillColor('#CCCCCC')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .onClick(() => this.openAvatarDialog())

            this.buildDivider()

            // 昵称
            this.buildInfoRow('昵称', () => this.nickname, () => this.openNicknameDialog())

            this.buildDivider()

            // 性别
            this.buildInfoRow('性别', () => this.formatGender(), () => this.openGenderDialog())

            this.buildDivider()

            // 年龄
            this.buildInfoRow('年龄', () => (this.age > 0 ? `${this.age}岁` : '--'), () => this.openAgeDialog())

            this.buildDivider()

            // 身高
            this.buildInfoRow('身高', () => (this.userHeight > 0 ? `${this.userHeight.toFixed(1)}厘米` : '--'), () => this.openHeightDialog())
          }
          .width('94%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .margin({ top: 16, bottom: 16 })

          // 体重信息卡片
          Column() {
            Row() {
              Text('目标体重')
                .fontSize(15)
                .fontColor('#333333')
                .layoutWeight(1)
              Text(this.targetWeight > 0 ? `${this.targetWeight.toFixed(1)}公斤` : '--')
                .fontSize(15)
                .fontColor('#666666')
                .margin({ right: 8 })
              Image($r('app.media.right_point'))
                .width(16)
                .height(16)
                .fillColor('#CCCCCC')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .onClick(() => this.openWeightDialog())
          }
          .width('94%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .margin({ bottom: 16 })
        }
        .width('100%')
        .padding({ top: 8 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

