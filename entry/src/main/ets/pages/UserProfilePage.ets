import { router, window } from '@kit.ArkUI'
import { CommonTitleView } from '../view/CommonTitleView'
import { AppStateStore } from '../services/AppStateStore'
import preferencesUtil from '../tools/DataPreUtils'
import { Log } from '../tools/Logger'
import EntryAbility from '../entryability/EntryAbility'
import type { AppState } from '../models/AppModels'
import { userDataManager, UserMetrics } from '../services/UserDataManager'
import appDataManager, { AppDataManager, DataCallback } from '../tools/AppDataManager'
import { BodyRecordModel } from '../appdata/Model'
import { BodyRecordDialog } from '../view/BodyRecordDialog'
import { Utils } from '../tools/Utils'
import picker from '@ohos.file.picker'
import { BusinessError } from '@kit.BasicServicesKit'

@Entry
@Component
struct UserProfilePage {
  private appStateStore: AppStateStore = AppStateStore.getInstance()
  private appStateUnsubscribe: (() => void) | null = null
  private metricsUnsubscribe: (() => void) | null = null

  @State userName: string = '未登录用户'
  @State userCode: string = '华为账号登录'
  @State userImg: PixelMap | undefined = undefined
  @State nickname: string = '运动达人'
  @State isLoggedIn: boolean = false

  // 身体数据
  @State gender: string = 'male' // 'male' | 'female'
  @State age: number = 0
  @State userHeight: number = 0
  @State initialWeight: number = 0
  @State targetWeight: number = 0
  @State private hasSetInitialWeight: boolean = false

  // 用于强制触发 UI 重组
  @State private uiVersion: number = 0

  private bumpUI(): void {
    this.uiVersion++
  }

  private allWeights: Array<BodyRecordModel> = []
  private weightCallback: DataCallback<BodyRecordModel> = {
    onDataResult: (type: number, result: BodyRecordModel[], isFirst: boolean): void => {
      if (type !== AppDataManager.TYPE_WEIGHT) return
      this.allWeights = result || []
      this.loadInitialWeight()
      Log.i('[UserProfilePage] weightCallback: 初始体重已更新为 ' + this.initialWeight)
    }
  }

  getSafeTopPadding(): number {
    if (!EntryAbility.myWindowClass) {
      return 0
    }
    const avoidArea = EntryAbility.myWindowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
    return Math.max(0, avoidArea.topRect.height)
  }

  private setImmersiveStatusBar(): void {
    if (!EntryAbility.myWindowClass) {
      return
    }
    try {
      EntryAbility.myWindowClass.setWindowSystemBarProperties({
        statusBarColor: '#F5F5F5',
        statusBarContentColor: '#000000',
        navigationBarColor: '#F5F5F5',
        navigationBarContentColor: '#000000'
      })
    } catch (err) {
      Log.e('[UserProfilePage] 设置状态栏失败: ' + JSON.stringify(err))
    }
  }

  private restoreStatusBar(): void {
    if (!EntryAbility.myWindowClass) {
      return
    }
    try {
      EntryAbility.myWindowClass.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        statusBarContentColor: '#000000',
        navigationBarColor: '#00000000',
        navigationBarContentColor: '#000000'
      })
    } catch (err) {
      Log.e('[UserProfilePage] 恢复状态栏失败: ' + JSON.stringify(err))
    }
  }

  private isLoadingData: boolean = false

  aboutToAppear(): void {
    // 提前建立订阅，确保任何时刻的数据更新都能立刻回调
    this.metricsUnsubscribe?.()
    this.metricsUnsubscribe = userDataManager.subscribe((metrics) => {
      Log.i('[UserProfilePage] subscribe 即时回调 metrics=' + JSON.stringify(metrics))
      this.updateBodyData(metrics)
    })
  }

  async onPageShow(): Promise<void> {
    // 设置沉浸式状态栏（灰色背景）
    this.setImmersiveStatusBar()
    await this.loadUserInfo()
    await this.loadBodyData()

    // 订阅应用状态变化
    this.appStateUnsubscribe = this.appStateStore.subscribe((state) => {
      this.applyAppState(state)
    })
    // 立即应用当前状态
    this.applyAppState(this.appStateStore.getState())
    appDataManager.findBodyRecordByType(AppDataManager.TYPE_WEIGHT, this.weightCallback, false)
  }

  aboutToDisappear(): void {
    // 恢复状态栏
    this.restoreStatusBar()
    if (this.appStateUnsubscribe) {
      this.appStateUnsubscribe()
      this.appStateUnsubscribe = null
    }
    if (this.metricsUnsubscribe) {
      this.metricsUnsubscribe()
      this.metricsUnsubscribe = null
    }
  }

  private async loadUserInfo(): Promise<void> {
    try {
      await this.syncUserProfile()
      await this.loadUserImage()
    } catch (error) {
      Log.e('[UserProfilePage] 加载用户信息失败: ' + JSON.stringify(error))
    }
  }

  private async syncUserProfile(): Promise<void> {
    // preferences 应该在 EntryAbility 中初始化
    if (!preferencesUtil.preferencesMap.has('steps_ohos') && EntryAbility.context) {
      await preferencesUtil.loadPreference(EntryAbility.context, 'steps_ohos')
    }
    // 优先加载本地昵称（如果存在）
    const storedNickname = await preferencesUtil.getPreferenceValue('steps_ohos', 'userNickname', '') as string
    if (typeof storedNickname === 'string' && storedNickname.length > 0) {
      this.nickname = storedNickname
      this.userName = storedNickname
    } else {
      // 如果没有本地昵称，检查是否有登录账号名称
      const storedName = await preferencesUtil.getPreferenceValue('steps_ohos', 'userName', '') as string
      if (typeof storedName === 'string' && storedName.length > 0 && storedName !== '未登录用户') {
      this.userName = storedName
        this.nickname = storedName
      } else {
        // 未登录用户，默认为"未登录用户"
        this.userName = '未登录用户'
        this.nickname = '未登录用户'
      }
    }
    const storedCode = await preferencesUtil.getPreferenceValue('steps_ohos', 'userCode', this.userCode) as string
    if (typeof storedCode === 'string') {
      this.userCode = storedCode === '登录功能开发中' ? '华为账号登录' : storedCode
    }
  }

  private async loadUserImage(): Promise<void> {
    // TODO: 加载用户头像
    this.userImg = undefined
  }

  private async loadBodyData(): Promise<void> {
    Log.i('[UserProfilePage] loadBodyData: 开始加载数据')
    
    // 先从 preferences 加载基础数据（避免订阅回调干扰）
    const metrics = await userDataManager.loadMetrics()
    Log.i('[UserProfilePage] loadBodyData: 从 preferences 加载的 metrics=' + JSON.stringify(metrics))

    // 先设置基础数据
    const heightFromPrefs = Number(metrics.height)
    const ageFromPrefs = Number(metrics.age)
    const targetFromPrefs = metrics.targetWeight !== undefined ? Number(metrics.targetWeight) : NaN

    this.gender = metrics.gender || this.gender
    if (!Number.isNaN(ageFromPrefs) && ageFromPrefs > 0) {
      this.age = ageFromPrefs
    }
    if (!Number.isNaN(heightFromPrefs) && heightFromPrefs > 0) {
      this.userHeight = heightFromPrefs
    }
    if (!Number.isNaN(targetFromPrefs) && targetFromPrefs > 0) {
      this.targetWeight = targetFromPrefs
    }

    Log.i('[UserProfilePage] loadBodyData: 第一阶段 gender=' + this.gender + ', age=' + this.age + ', height=' + this.userHeight + ', target=' + this.targetWeight)
    
    // 然后从数据库同步最新身高和体重数据到 preferences（这会触发订阅，但 isLoadingData 会阻止更新）
    await this.syncLatestHeight()
    await this.syncLatestWeight()
    
    // 等待一小段时间确保数据已同步
    await new Promise<void>((resolve: () => void) => setTimeout(resolve, 200))
    
    // 再次从 preferences 加载数据（确保获取到同步后的最新值）
    const updatedMetrics = await userDataManager.loadMetrics()
    Log.i('[UserProfilePage] loadBodyData: 同步后从 preferences 加载的 metrics=' + JSON.stringify(updatedMetrics))

    // 更新数据（优先使用同步后的值）
    const updatedHeight = Number(updatedMetrics.height)
    const updatedAge = Number(updatedMetrics.age)
    const updatedTarget = updatedMetrics.targetWeight !== undefined ? Number(updatedMetrics.targetWeight) : NaN

    this.gender = updatedMetrics.gender || this.gender
    if (!Number.isNaN(updatedAge) && updatedAge > 0) {
      this.age = updatedAge
    }
    if (!Number.isNaN(updatedHeight) && updatedHeight > 0) {
      this.userHeight = updatedHeight
    }

    // 加载目标体重
    const targetWeight = await preferencesUtil.getPreferenceValue('steps_ohos', 'weight_target', 0) as number
    Log.i('[UserProfilePage] loadBodyData: 目标体重=' + targetWeight)
    if (targetWeight > 0) {
      this.targetWeight = targetWeight
    } else if (!Number.isNaN(updatedTarget) && updatedTarget > 0) {
      this.targetWeight = updatedTarget
    }

    Log.i('[UserProfilePage] loadBodyData: 第二阶段 gender=' + this.gender + ', age=' + this.age + ', height=' + this.userHeight + ', target=' + this.targetWeight)
    
    // 确保初始体重也被加载（从数据库）
    appDataManager.findBodyRecordByType(AppDataManager.TYPE_WEIGHT, this.weightCallback, false)

    // 等待初始体重加载完成
    await new Promise<void>((resolve: () => void) => setTimeout(resolve, 300))

    Log.i('[UserProfilePage] loadBodyData: 加载完成，当前状态 age=' + this.age + ', height=' + this.userHeight + ', targetWeight=' + this.targetWeight + ', initialWeight=' + this.initialWeight)

    // 最后再拉一次 metrics 并统一走 updateBodyData，确保界面刷新
    const finalMetrics = await userDataManager.loadMetrics()
    this.updateBodyData(finalMetrics)
    this.bumpUI()
  }

  private async syncLatestHeight(): Promise<void> {
    return new Promise<void>((resolve) => {
      // 从数据库获取最新的身高记录，并同步到 preferences 和页面显示
      appDataManager.findBodyRecordByType(AppDataManager.TYPE_HEIGHT, {
        onDataResult: async (type: number, result: Array<BodyRecordModel>, isFirst: boolean): Promise<void> => {
          if (type !== AppDataManager.TYPE_HEIGHT) {
            Log.i('[UserProfilePage] syncLatestHeight: type 不匹配，type=' + type)
            resolve()
            return
          }
          Log.i('[UserProfilePage] syncLatestHeight: 查询结果数量=' + (result ? result.length : 0))
          if (result && result.length > 0) {
            // 获取最新的身高记录（已经按时间倒序排列）
            const latestRecord = result[0]
            Log.i('[UserProfilePage] syncLatestHeight: 最新记录 data=' + latestRecord.data)
            // 移除可能的单位字符，只保留数字和小数点
            let cleanData = latestRecord.data.replace(/[^0-9.]/g, '')
            const heightValue = parseFloat(cleanData)
            Log.i('[UserProfilePage] syncLatestHeight: 解析后的身高值=' + heightValue)
            if (!isNaN(heightValue) && heightValue > 0) {
              // 如果数据库中的身高与 preferences 中的不一致，更新 preferences
              const currentHeight = await preferencesUtil.getPreferenceValue('steps_ohos', 'height', 0) as number
              Log.i('[UserProfilePage] syncLatestHeight: preferences 中的身高=' + currentHeight)
              if (Math.abs(currentHeight - heightValue) > 0.01) {
                // 同步到 preferences 并触发更新
                Log.i('[UserProfilePage] syncLatestHeight: 更新 preferences 中的身高')
                await userDataManager.updateHeight(heightValue)
              }
              // 确保页面显示最新数据
              this.userHeight = heightValue
              Log.i('[UserProfilePage] syncLatestHeight: 设置 this.userHeight=' + this.userHeight)
            } else {
              Log.i('[UserProfilePage] syncLatestHeight: 身高值无效，heightValue=' + heightValue)
            }
          } else {
            Log.i('[UserProfilePage] syncLatestHeight: 数据库中没有身高记录')
          }
          resolve()
        }
      }, true) // isReturnFirstData = true，只获取最新一条
    })
  }

  private async syncLatestWeight(): Promise<void> {
    return new Promise<void>((resolve) => {
      // 从数据库获取最新的体重记录，并同步到 preferences 和页面显示
      appDataManager.findBodyRecordByType(AppDataManager.TYPE_WEIGHT, {
        onDataResult: async (type: number, result: Array<BodyRecordModel>, isFirst: boolean): Promise<void> => {
          if (type !== AppDataManager.TYPE_WEIGHT) {
            Log.i('[UserProfilePage] syncLatestWeight: type 不匹配，type=' + type)
            resolve()
            return
          }
          Log.i('[UserProfilePage] syncLatestWeight: 查询结果数量=' + (result ? result.length : 0))
          if (result && result.length > 0) {
            const sorted = [...result].sort((a, b) => b.time - a.time)
            const latestRecord = sorted[0]
            Log.i('[UserProfilePage] syncLatestWeight: 最新记录 data=' + latestRecord.data)
            // 移除可能的单位字符，只保留数字和小数点
            let cleanData = latestRecord.data.replace(/[^0-9.]/g, '')
            const weightValue = parseFloat(cleanData)
            Log.i('[UserProfilePage] syncLatestWeight: 解析后的体重值=' + weightValue)
            if (!isNaN(weightValue) && weightValue > 0) {
              // 如果数据库中的体重与 preferences 中的不一致，更新 preferences
              const currentWeight = await preferencesUtil.getPreferenceValue('steps_ohos', 'weight', 0) as number
              Log.i('[UserProfilePage] syncLatestWeight: preferences 中的体重=' + currentWeight)
              if (Math.abs(currentWeight - weightValue) > 0.01) {
                // 同步到 preferences 并触发更新
                Log.i('[UserProfilePage] syncLatestWeight: 更新 preferences 中的体重')
                await userDataManager.updateWeight(weightValue)
              }
            } else {
              Log.i('[UserProfilePage] syncLatestWeight: 体重值无效，weightValue=' + weightValue)
            }
          } else {
            Log.i('[UserProfilePage] syncLatestWeight: 数据库中没有体重记录')
          }
          resolve()
        }
      }, true) // isReturnFirstData = true，只获取最新一条
    })
  }

  private loadInitialWeight(): void {
    if (this.hasSetInitialWeight) {
      Log.i('[UserProfilePage] loadInitialWeight: 用户刚设置过，跳过覆盖 initialWeight=' + this.initialWeight)
      return
    }
    if (this.allWeights.length === 0) {
      Log.i('[UserProfilePage] loadInitialWeight: 没有体重数据，保留当前 initialWeight=' + this.initialWeight)
      return
    }
    const sorted = [...this.allWeights].sort((a, b) => a.time - b.time)
    // 移除可能的单位字符，只保留数字和小数点
    let cleanData = sorted[0].data.replace(/[^0-9.]/g, '')
    const weightValue = parseFloat(cleanData)
    this.initialWeight = isNaN(weightValue) || weightValue <= 0 ? 0 : weightValue
    Log.i('[UserProfilePage] loadInitialWeight: 从数据库加载，排序后第一条=' + sorted[0].data + ', 解析后=' + weightValue + ', 最终初始体重=' + this.initialWeight)
  }

  private updateBodyData(metrics: UserMetrics): void {
    Log.i('[UserProfilePage] updateBodyData: 接收到 metrics=' + JSON.stringify(metrics) + ', 当前 state gender=' + this.gender + ', age=' + this.age + ', height=' + this.userHeight + ', target=' + this.targetWeight)
    // 确保所有数据都正确显示
    const oldAge = this.age
    const oldHeight = this.userHeight
    const oldGender = this.gender
    const oldTargetWeight = this.targetWeight
    
    const nextGender = metrics.gender && metrics.gender.length > 0 ? metrics.gender : this.gender
    const nextAge = Number(metrics.age)
    const nextHeight = Number(metrics.height)
    const nextTarget = metrics.targetWeight !== undefined ? Number(metrics.targetWeight) : NaN

    this.gender = nextGender ?? 'male'
    if (!Number.isNaN(nextAge) && nextAge >= 0) {
      this.age = nextAge
    }
    if (!Number.isNaN(nextHeight) && nextHeight >= 0) {
      this.userHeight = nextHeight
    }
    if (!Number.isNaN(nextTarget) && nextTarget > 0) {
      this.targetWeight = nextTarget
    }
    // 确保数据已更新，触发 UI 刷新
    Log.i('[UserProfilePage] updateBodyData: 更新后 gender=' + this.gender + ', age=' + this.age + ', height=' + this.userHeight + ', targetWeight=' + this.targetWeight)
    Log.i('[UserProfilePage] updateBodyData: 变化 age:' + oldAge + '->' + this.age + ', height:' + oldHeight + '->' + this.userHeight + ', gender:' + oldGender + '->' + this.gender + ', targetWeight:' + oldTargetWeight + '->' + this.targetWeight)
    this.bumpUI()
  }

  private applyAppState(state: AppState): void {
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
        Log.e('[UserProfilePage] 跳转登录页失败: ' + err.message)
      })
    }
  }

  private formatGender(): string {
    return this.gender === 'male' ? '男' : '女'
  }

  private formatAge(): string {
    return this.age > 0 ? `${this.age}岁` : '--'
  }

  private formatHeight(): string {
    return this.userHeight > 0 ? `${this.userHeight.toFixed(1)}厘米` : '--'
  }

  private formatWeight(value: number): string {
    return value > 0 ? `${value.toFixed(1)}公斤` : '--'
  }

  @Builder
  private buildAvatarDialog(dialog: CustomDialogController) {
    Column() {
      Text('选择头像')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 20 })
      
      Row() {
        Button('从相册选择')
          .type(ButtonType.Capsule)
          .backgroundColor('#0cc291')
          .fontColor('#FFFFFF')
          .width(200)
          .onClick(async () => {
            try {
              const photoPickerOptions = new picker.PhotoSelectOptions()
              photoPickerOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE
              photoPickerOptions.maxSelectNumber = 1
              const photoSelect = new picker.PhotoViewPicker()
              const photoSelectResult = await photoSelect.select(photoPickerOptions)
              if (photoSelectResult && photoSelectResult.photoUris.length > 0) {
                const uri = photoSelectResult.photoUris[0]
                await preferencesUtil.putPreferenceValue('steps_ohos', 'userAvatarUri', uri)
                // 同步到全局应用状态，确保“我的”页即时刷新
                this.appStateStore.updateUser({ avatar: uri })
                Log.i('[UserProfilePage] 选择的头像URI: ' + uri)
                dialog.close()
                Utils.showToast('头像设置成功')
                this.bumpUI()
              }
            } catch (err) {
              Log.e('[UserProfilePage] 选择头像失败: ' + (err as BusinessError).message)
              Utils.showToast('选择头像失败')
            }
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 20 })
      
      Row() {
        Button('取消')
          .type(ButtonType.Capsule)
          .backgroundColor('#F5F5F5')
          .fontColor('#333333')
          .width(120)
          .onClick(() => {
            dialog.close()
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .padding(20)
    .width('90%')
    .borderRadius(16)
  }

  private avatarDialog?: CustomDialogController

  private openAvatarDialog(): void {
    this.avatarDialog = new CustomDialogController({
      builder: () => {
        this.buildAvatarDialog(this.avatarDialog!)
      },
      alignment: DialogAlignment.Center,
      autoCancel: true
    })
    this.avatarDialog.open()
  }

  @State private tempNickname: string = ''

  @Builder
  private buildNicknameDialog(dialog: CustomDialogController) {
    Column() {
      Text('编辑昵称')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 20 })
      
      TextInput({ placeholder: '请输入昵称', text: this.tempNickname })
        .width('100%')
        .height(48)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.tempNickname = value.trim()
        })
        .margin({ bottom: 20 })
      
      Row() {
        Button('取消')
          .type(ButtonType.Capsule)
          .backgroundColor('#F5F5F5')
          .fontColor('#333333')
          .width(120)
          .onClick(() => {
            dialog.close()
          })
        Button('保存')
          .type(ButtonType.Capsule)
          .backgroundColor('#0cc291')
          .fontColor('#FFFFFF')
          .width(120)
          .margin({ left: 12 })
          .onClick(async () => {
            if (this.tempNickname.length > 0 && this.tempNickname.length <= 20) {
              try {
                // 保存本地昵称（优先使用本地昵称）
                await preferencesUtil.putPreferenceValue('steps_ohos', 'userNickname', this.tempNickname)
                // 同时更新userName，确保"我的"页面也能显示
                await preferencesUtil.putPreferenceValue('steps_ohos', 'userName', this.tempNickname)
                // 标记已使用本地昵称，不再跟随账号名
                await preferencesUtil.putPreferenceValue('steps_ohos', 'useLocalNickname', true)
                // 更新页面显示
                this.nickname = this.tempNickname
                this.userName = this.tempNickname
                // 同步到全局应用状态，确保“我的”页即时刷新
                this.appStateStore.updateUser({ nickname: this.tempNickname })
                // 未登录场景也需要通知订阅者读取本地昵称
                this.appStateStore.forceEmit()
                dialog.close()
                Utils.showToast('昵称保存成功')
                this.bumpUI()
              } catch (err) {
                Log.e('[UserProfilePage] 保存昵称失败: ' + (err as Error).message)
                Utils.showToast('保存失败，请重试')
              }
            } else {
              Utils.showToast('昵称长度应在1-20个字符之间')
            }
          })
      }
      .width('100%')
    }
    .padding(20)
    .width('90%')
    .borderRadius(16)
  }

  private nicknameDialog?: CustomDialogController

  private openNicknameDialog(): void {
    this.tempNickname = this.nickname
    this.nicknameDialog = new CustomDialogController({
      builder: () => {
        this.buildNicknameDialog(this.nicknameDialog!)
      },
      alignment: DialogAlignment.Center,
      autoCancel: true
    })
    this.nicknameDialog.open()
  }

  @State private tempGender: string = 'male'

  @Builder
  private buildGenderDialog(dialog: CustomDialogController) {
    Column() {
      Text('选择性别')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 20 })
      
      Column() {
        Button('男')
          .type(ButtonType.Capsule)
          .backgroundColor(this.tempGender === 'male' ? '#0cc291' : '#F5F5F5')
          .fontColor(this.tempGender === 'male' ? '#FFFFFF' : '#333333')
          .width('100%')
          .height(48)
          .onClick(async () => {
            await this.applyGenderChange('male', dialog)
          })
        Button('女')
          .type(ButtonType.Capsule)
          .backgroundColor(this.tempGender === 'female' ? '#0cc291' : '#F5F5F5')
          .fontColor(this.tempGender === 'female' ? '#FFFFFF' : '#333333')
          .width('100%')
          .height(48)
          .margin({ top: 12 })
          .onClick(async () => {
            await this.applyGenderChange('female', dialog)
          })
      }
      .width('100%')
    }
    .padding(20)
    .width('90%')
    .borderRadius(16)
  }

  private async applyGenderChange(nextGender: string, dialog: CustomDialogController) {
    if (this.gender === nextGender) {
      dialog.close()
      return
    }
    this.tempGender = nextGender
    this.gender = nextGender
    await userDataManager.updateGender(nextGender)
    await userDataManager.refreshMetrics()
    // 直接拉一次最新 metrics，确保本页立即一致
    const metricsAfterGender = await userDataManager.loadMetrics()
    this.updateBodyData(metricsAfterGender)
    dialog.close()
    Utils.showToast('性别已更新')
    this.bumpUI()
  }

  private genderDialog?: CustomDialogController

  private openGenderDialog(): void {
    this.tempGender = this.gender
    this.genderDialog = new CustomDialogController({
      builder: () => {
        this.buildGenderDialog(this.genderDialog!)
      },
      alignment: DialogAlignment.Center,
      autoCancel: true
    })
    this.genderDialog.open()
  }

  private openAgeDialog(): void {
    const baseValue = this.age > 0 ? this.age : 25
    const normalized = Math.min(120, Math.max(1, baseValue))

    let dialog: CustomDialogController
    dialog = new CustomDialogController({
      builder: BodyRecordDialog({
        title: '设置年龄',
        unit: '岁',
        bodyType: -1, // 年龄不使用bodyType
        startNum: 1,
        endNum: 120,
        stepNum: 1,
        selectNum: normalized,
        content: normalized.toString(),
        cancel: () => {
          dialog.close()
        },
        confirm: async (value: number, _type: number) => {
          dialog.close()
          this.age = value
          await userDataManager.updateAge(value)
          Log.i('[UserProfilePage] openAgeDialog confirm 保存 age=' + value)
          await userDataManager.refreshMetrics()
          const metricsAfterAge = await userDataManager.loadMetrics()
          this.updateBodyData(metricsAfterAge)
          Utils.showToast('年龄保存成功')
          this.bumpUI()
        }
      }),
      autoCancel: true
    })
    dialog.open()
  }

  private openHeightDialog(): void {
    const baseValue = this.userHeight > 0 ? this.userHeight : 170
    const normalized = Math.min(230, Math.max(80, parseFloat(baseValue.toFixed(1))))

    let dialog: CustomDialogController
    dialog = new CustomDialogController({
      builder: BodyRecordDialog({
        title: '设置身高',
        unit: '厘米',
        bodyType: AppDataManager.TYPE_HEIGHT,
        startNum: 80,
        endNum: 230,
        stepNum: 0.1,
        selectNum: normalized,
        content: normalized.toFixed(1),
        cancel: () => {
          dialog.close()
        },
        confirm: async (value: number, _type: number) => {
          dialog.close()
          const formatted = value.toFixed(1)
          this.userHeight = parseFloat(formatted)
          appDataManager.insertBodyRecord(AppDataManager.TYPE_HEIGHT, formatted)
          await userDataManager.updateHeight(this.userHeight)
          Log.i('[UserProfilePage] openHeightDialog confirm 保存 height=' + formatted)
          await userDataManager.refreshMetrics()
          const metricsAfterHeight = await userDataManager.loadMetrics()
          this.updateBodyData(metricsAfterHeight)
          Utils.showToast('身高保存成功')
          this.bumpUI()
        }
      }),
      autoCancel: true
    })
    dialog.open()
  }

  private openInitialWeightDialog(): void {
    const baseValue = this.initialWeight > 0
      ? this.initialWeight
      : (this.targetWeight > 0 ? this.targetWeight : 60)
    const normalized = Math.min(200, Math.max(30, parseFloat(baseValue.toFixed(1))))

    let dialog: CustomDialogController
    dialog = new CustomDialogController({
      builder: BodyRecordDialog({
        title: '设置初始体重',
        unit: '公斤',
        bodyType: AppDataManager.TYPE_WEIGHT,
        startNum: 30,
        endNum: 200,
        stepNum: 0.1,
        selectNum: normalized,
        content: normalized.toFixed(1),
        cancel: () => {
          dialog.close()
        },
        confirm: async (value: number, _type: number) => {
          dialog.close()
          const formatted = value.toFixed(1)
          const weightValue = parseFloat(formatted)
          // 查找最早的体重记录
          const sorted = [...this.allWeights].sort((a, b) => a.time - b.time)
          if (sorted.length > 0) {
            const earliest = sorted[0]
            const updated: BodyRecordModel = {
              id: earliest.id,
              time: earliest.time,
              type: earliest.type,
              data: formatted,
              unit: earliest.unit
            }
            appDataManager.updateBodyRecordItem(updated)
          } else {
            appDataManager.insertBodyRecord(AppDataManager.TYPE_WEIGHT, formatted)
          }
          this.initialWeight = weightValue
          this.hasSetInitialWeight = true
          Log.i('[UserProfilePage] openInitialWeightDialog confirm 保存初始=' + formatted)
          await this.syncLatestWeight()
          await userDataManager.refreshMetrics()
          const metricsAfterInit = await userDataManager.loadMetrics()
          this.updateBodyData(metricsAfterInit)
          setTimeout(() => {
            appDataManager.findBodyRecordByType(AppDataManager.TYPE_WEIGHT, this.weightCallback, false)
          }, 200)
          Utils.showToast('初始体重保存成功')
          this.bumpUI()
        }
      }),
      autoCancel: true
    })
    dialog.open()
  }

  private openTargetWeightDialog(): void {
    const baseValue = this.targetWeight > 0 ? this.targetWeight : (this.initialWeight > 0 ? this.initialWeight : 60)
    const normalized = Math.min(200, Math.max(30, parseFloat(baseValue.toFixed(1))))

    let dialog: CustomDialogController
    dialog = new CustomDialogController({
      builder: BodyRecordDialog({
        title: '设置目标体重',
        unit: '公斤',
        bodyType: -1, // 目标体重不使用bodyType
        startNum: 30,
        endNum: 200,
        stepNum: 0.1,
        selectNum: normalized,
        content: normalized.toFixed(1),
        cancel: () => {
          dialog.close()
        },
        confirm: async (value: number, _type: number) => {
          dialog.close()
          this.targetWeight = value
          await userDataManager.updateTargetWeight(value)
          // 保存目标体重更新时间戳，用于体重趋势页面显示
          await preferencesUtil.putPreferenceValue('steps_ohos', 'weight_target_update_time', Date.now())
          Log.i('[UserProfilePage] openTargetWeightDialog confirm 保存目标=' + value)
          await userDataManager.refreshMetrics()
          const metricsAfterTarget = await userDataManager.loadMetrics()
          this.updateBodyData(metricsAfterTarget)
          Utils.showToast('目标体重保存成功')
          this.bumpUI()
        }
      }),
      autoCancel: true
    })
    dialog.open()
  }

  @Builder
  private buildInfoRow(label: string, valueBuilder: () => string, onClick: () => void) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor('#333333')
        .layoutWeight(1)
      Text(valueBuilder())
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
    .onClick(onClick)
  }

  @Builder
  private buildDivider() {
    Divider()
      .color('#F0F0F0')
      .strokeWidth(1)
      .margin({ left: 16, right: 16 })
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
          .margin({ top: -240, bottom: 16 })

          // 体重信息卡片
          Column() {
            // 初始体重
            this.buildInfoRow('初始体重', () => (this.initialWeight > 0 ? `${this.initialWeight.toFixed(1)}公斤` : '--'), () => this.openInitialWeightDialog())

            this.buildDivider()

            // 目标体重
            this.buildInfoRow('目标体重', () => (this.targetWeight > 0 ? `${this.targetWeight.toFixed(1)}公斤` : '--'), () => this.openTargetWeightDialog())
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
      .margin({ top: 0 })
      .layoutWeight(1)
    }
    // 保留 uiVersion，仅用于必要时触发重新渲染
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
