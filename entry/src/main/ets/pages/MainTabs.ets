
import {Log} from '../tools/Logger'
import mainCardManager, { MainCardManager } from '../tools/MainCardManager'
import { ArrayList } from '@kit.ArkTS'
import { Utils } from '../tools/Utils'
import { BannerView } from '../view/BannerView'
import { MainTopView, TopData } from '../view/MainTopView'
import { SubFragment, SubFragmentData } from '../view/SubFragment'
import { UserData, UserDataView } from '../view/UserDataView'
import { SettingItemView } from '../view/SettingItemView'
import StepData, { StepsCallback } from '../appdata/StepData'
import preferencesUtil from '../tools/DataPreUtils'
import { MainCardData, MainCardView } from '../view/MainCardView'
import AppDataManager, { AllSportCallback, DataCallback, ModelCallback } from '../tools/AppDataManager'
import { router, window } from '@kit.ArkUI'
import EntryAbility from '../entryability/EntryAbility'
import { DateUtils } from '../tools/DateUtils'
import { SportModel, PerStepModel } from '../appdata/Model'
import { AppStateStore } from '../services/AppStateStore'
import type { AppState } from '../models/AppModels'
import targetManager, { TargetValue } from '../tools/TargetManager'

interface GoalProgressItem {
  key: string,
  label: string,
  unit: string,
  color: string,
  current: number,
  target: number,
}

const DEFAULT_CALORIE_TARGET = 300
const DEFAULT_TIME_TARGET = 25
const DEFAULT_ACTIVITY_TARGET = 12

interface HealthFeatureItem {
  label: string,
  subtitle: string,
  color: string,
  route: string,
}

interface BodyOverviewCard {
  title: string
  value: string
  unit?: string
  icon: Resource
  badgeBackground: string
  noteColor?: string
  onTap?: () => void
}

interface MainCardMetrics {
  subtitle: string
  value: string
  prevTitle?: string
  prevValue?: string
}

@Entry
@Component
struct MainTabs {
  @State fontColor: string = '#182431'
  @State selectedFontColor: string = '#0cc291'
  @State mainCardH: string = '27%'//卡片高度
  //当前tab 界面的index标号
  @State currentIndex: number = 0
  @State currentSubIndex: number = 0
  //Tab的底色
  @State tabColor: string = '#F5F5F5'
  private controller: TabsController = new TabsController()
  private subController: TabsController = new TabsController();
  private panOptionRight: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Right });
  private scroller: Scroller = new Scroller()
  private sportSubScrollers: Array<Scroller> = [
    new Scroller(),
    new Scroller(),
    new Scroller(),
    new Scroller(),
    new Scroller()
  ]
  private tarSteps:number = 5000

  @State formData: TopData = {
    curSteps:'0', // 当前步数
    tarSteps: '/5000步', //目标步数
    tarStepsPer: 0, //当前步数进度，满格100%
    tarStepsPerStr: '0%',//当前步数进度百分比字符
    tarStepsHintStr: '还差3000步达到目标',//当前步数目标提醒
  }
  @State subFragmentDataInside: SubFragmentData = {
    type:1, // 运动类型 室内跑
    curTarget:'自由',
    subTopTitle:'累计室内跑步距离',
    subTopData: '5', //总的运动里程
    subBotData: '室内跑记录', //运动底部提示
  }
  @State subFragmentDataOut: SubFragmentData = {
    type:2, // 运动类型 室外跑
    curTarget:'自由',
    subTopTitle:'累计室外跑步距离',
    subTopData: '8', //总的运动里程
    subBotData: '室外跑记录', //运动底部提示
  }
  @State subFragmentDataWalk: SubFragmentData = {
    type:3, // 运动类型 健走
    curTarget:'自由',
    subTopTitle:'累计健走距离',
    subTopData: '3', //总的运动里程
    subBotData: '健走记录', //运动底部提示
  }
  @State subFragmentDataFoot: SubFragmentData = {
    type:4, // 运动类型 徒步
    curTarget:'自由',
    subTopTitle:'累计徒步距离',
    subTopData: '6', //总的运动里程
    subBotData: '徒步记录', //运动底部提示
  }
  @State subFragmentDataClimb: SubFragmentData = {
    type:5, // 运动类型 登山
    curTarget:'自由',
    subTopTitle:'累计登山距离',
    subTopData: '9', //总的运动里程
    subBotData: '登山记录', //运动底部提示
  }

  @State stepsHintStr: string = '经常运动的人睡眠质量比一般人好50%'//中部运动提示语
  @State allRunKm: string = '5'//累计跑步距离

  @State userImg: PixelMap | undefined = undefined;
  @State userName: string = '未登录用户'//累计跑步距离
  @State userCode: string = '华为账号登录'//登录提示

  @State userData1: UserData = {
    title:'周报总结',
    subTitle: '总步数',
    data: '0步',
    subData: '总运动时长0分钟'
  }

  @State userData2: UserData = {
    title:'我的钱包',
    subTitle: '现有金额',
    data: '0金币',
    subData: '历史获得0金币'
  }

  // 身体数据状态
  @State currentHeight: number = 0
  @State currentWeight: number = 0
  @State basalMetabolism: number = 0
  @State bmi: number = 0
  @State bmiStatus: string = ''
  @State userAge: number = 25
  @State userGender: string = 'male'

  @State targetProgress: Array<GoalProgressItem> = [
    { key: 'calorie', label: '热量消耗', unit: '千卡', color: '#FF8C47', current: 0, target: DEFAULT_CALORIE_TARGET },
    { key: 'time', label: '锻炼时长', unit: '分钟', color: '#FFB950', current: 0, target: DEFAULT_TIME_TARGET },
    { key: 'activity', label: '活动次数', unit: '次', color: '#C7C9CC', current: 0, target: DEFAULT_ACTIVITY_TARGET }
  ]

  @State dailyQuote: string = '保持自律，坚持运动，收获更好的自己。'
  @State dailyQuotes: Array<string> = [
    '保持自律，坚持运动，收获更好的自己。',
    '运动是生命的源泉，坚持是成功的秘诀。',
    '每天一小步，健康一大步。',
    '运动让生活更精彩，坚持让梦想更接近。',
    '健康是最大的财富，运动是最好的投资。',
    '每一次运动，都是对未来的投资。',
    '坚持运动，让身体和心灵都更强大。',
    '运动不仅改变身体，更改变心态。'
  ]
  private readonly allQuotes: Array<string> = [
    '保持自律，坚持运动，收获更好的自己。',
    '今天多迈一步，离目标就近一步。',
    '再小的步伐也是向前，别停下脚步。',
    '让汗水见证努力，为健康加油。',
    '坚持就是胜利，加油！',
    '运动是最好的保健品，健康是最宝贵的财富。',
    '每天进步一点点，健康生活每一天。',
    '生命在于运动，健康源于坚持。',
    '身体是革命的本钱，运动是健康的源泉。',
    '走路是世界上最好的运动。',
    '运动不是为了别人，而是为了更好的自己。',
    '健康不是一切，但失去健康就失去一切。',
    '每一次流汗都是对未来的投资。',
    '不怕慢，就怕站。今天的努力是明天的健康。',
    '运动的意义不在于超越别人，而在于超越昨天的自己。',
  ]

  @State healthFeatures: Array<HealthFeatureItem> = [
    { label: '喝水记录', subtitle: '养成好习惯', color: '#E1F5FE', route: 'pages/WaterRecordPage' },
    { label: '排便记录', subtitle: '关注肠胃', color: '#FFF3E0', route: 'pages/BowelRecordPage' },
    { label: '生理期', subtitle: '贴心提醒', color: '#FCE4EC', route: 'pages/MenstruationRecordPage' },
    { label: '睡眠', subtitle: '记录作息', color: '#E8F5E9', route: 'pages/SleepRecordPage' },
    { label: '今日感受', subtitle: '写下心情', color: '#F3E5F5', route: 'pages/MoodRecordPage' }
  ]


  @State  line1:Array<MainCardData> = new Array<MainCardData>();//第一行卡片数组
  @State  line2:Array<MainCardData> = new Array<MainCardData>();//第二行卡片数组
  @State  line3:Array<MainCardData> = new Array<MainCardData>();//第三行卡片数组
  @State cardMetrics: Record<number, MainCardMetrics> = {}
  @State currentDateStr: string = DateUtils.getYMD()
  private dateWatcherId: number = 0

  private calorieTargetSetting: number = DEFAULT_CALORIE_TARGET
  private timeTargetSetting: number = DEFAULT_TIME_TARGET
  private activityTargetSetting: number = DEFAULT_ACTIVITY_TARGET

  private currentCalories: number = 0
  private currentSportMinutes: number = 0
  private currentActivityCount: number = 0
  private appStore = AppStateStore.getInstance()
  private unsubscribe: (() => void) | null = null

  aboutToAppear(): void {
    this.unsubscribe?.()
    this.unsubscribe = this.appStore.subscribe((state: AppState) => {
      this.applyAppState(state)
    })
    this.syncUserProfile()
    this.loadGoalTargets()
    this.requestTodaySportSummary()
    this.loadDailyQuote()
    this.currentDateStr = DateUtils.getYMD()
    this.startDailyWatcher()
    targetManager.addListener(this.onTargetsChanged)
  }

  aboutToDisappear(): void {
    targetManager.removeListener(this.onTargetsChanged)
  }

  private onTargetsChanged = (targets: TargetValue) => {
    const newCalorieTarget = targets.calorie_target
    const newTimeTarget = targets.exercise_time_target
    const newActivityTarget = targets.activity_count_target
    const newStepTarget = targets.step_target
    
    if (this.calorieTargetSetting !== newCalorieTarget) {
      this.calorieTargetSetting = newCalorieTarget
      this.updateGoalProgressItem('calorie', this.currentCalories, this.calorieTargetSetting)
    }
    if (this.timeTargetSetting !== newTimeTarget) {
      this.timeTargetSetting = newTimeTarget
      this.updateGoalProgressItem('time', this.currentSportMinutes, this.timeTargetSetting)
    }
    if (this.activityTargetSetting !== newActivityTarget) {
      this.activityTargetSetting = newActivityTarget
      this.updateGoalProgressItem('activity', this.currentActivityCount, this.activityTargetSetting)
    }
    if (this.tarSteps !== newStepTarget) {
      this.tarSteps = newStepTarget
      StepData.targetStepNum = this.tarSteps
      this.formData.tarSteps = '/' + this.tarSteps + '步'
      this.updateStepsView(StepData.getCurrentSteps())
    }
  }

  private async syncUserProfile() {
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

  private handleLoginTap(): void {
    if (this.userName === '未登录用户') {
      try {
        router.pushUrl({ url: 'pages/LoginPage' }).catch((err: Error) => {
          console.error('[MainTabs] 跳转登录页失败:', err.message);
        });
      } catch (err) {
        console.error('[MainTabs] 跳转登录页异常:', err);
      }
    }
  }

  private applyAppState(state: AppState): void {
    if (state && state.user) {
      this.userName = state.user.nickname ?? '运动达人'
      this.userCode = state.user.inviteCode ? `邀请码：${state.user.inviteCode}` : '已登录'
    } else {
      this.userName = '未登录用户'
      this.userCode = '华为账号登录'
    }
  }

  private stepsCallback:StepsCallback = {
    onSteps: (steps: number): void => {
      this.updateStepsView(steps)

    }
  }

  private modelCallBack:ModelCallback<number> = {
    onResult: (result: number): void => {
      let miles = Utils.getDistanceByStep(result)
      let times = parseInt(miles)*14

      this.userData1.data = result + '步'
      this.userData1.subData = '总运动时长'+times+'分钟'
    }
  }

  private yesterdayStepCallback:ModelCallback<PerStepModel> = {
    onResult: (model: PerStepModel): void => {
      const steps = model ? model.steps : 0
      this.updateCardMetrics(MainCardManager.STEPS_DISTANCE, {
        prevTitle: '昨天',
        prevValue: this.formatDistance(steps)
      })
      this.updateCardMetrics(MainCardManager.STEPS_ENERGY, {
        prevTitle: '昨天',
        prevValue: this.formatCalories(steps)
      })
    }
  }

  private sportCallback:AllSportCallback = {
    onDataResult: (type: number, allDistance: string): void => {
      if(type === 1){
        this.subFragmentDataInside.subTopData = allDistance
      }else if(type === 2){
        this.subFragmentDataOut.subTopData = allDistance
      }else if(type === 3){
        this.subFragmentDataWalk.subTopData = allDistance
      }else if(type === 4){
        this.subFragmentDataFoot.subTopData = allDistance
      }else if(type === 5){
        this.subFragmentDataClimb.subTopData = allDistance
      }
    }
  }


  private updateStepsView(steps: number){
    this.formData.curSteps = steps.toString()
    this.formData.tarStepsPer = (steps*100)/this.tarSteps
    let percent = Math.floor((steps*100)/this.tarSteps)
    if(percent>100){
      percent = 100
    }
    this.formData.tarStepsPerStr = percent+'%'
    if(steps>this.tarSteps){
      this.formData.tarStepsHintStr = '你今日的步数已经达标啦'
    }else{
      this.formData.tarStepsHintStr = '还差'+(this.tarSteps -steps) +'步达到目标'
    }
    this.updateCalorieProgress(steps)
    this.updateCardMetrics(MainCardManager.STEPS_DISTANCE, {
      subtitle: '今日',
      value: this.formatDistance(steps)
    })
  }


  // TAB view 的按钮的新建
  @Builder tabBuilder(index: number,title:string,pIcon:Resource,nIcon:Resource) {
    Column() {
      Image(this.currentIndex === index ? pIcon : nIcon)
        .width(22)
        .height(22)//TabView按钮的图片
      Text(title).padding({top:3 })
        .fontColor(this.currentIndex === index ? this.selectedFontColor : this.fontColor)
        .fontSize(13)//TabView按钮的文本
    }.width('100%')
  }

  // TAB view 的按钮的新建
  @Builder subTabBuilder(index: number,title:string) {
    Column() {
      Text(title).padding({top:3 })
        .fontColor(this.currentSubIndex === index ? this.selectedFontColor : this.fontColor)
        .fontSize(16).fontWeight(500).textAlign(TextAlign.Start).alignSelf(ItemAlign.Start)//TabView按钮的文本
    }.width('100%').align(Alignment.Start)
  }

  async onPageShow(){
    //目标步数初始化
    await targetManager.loadTargets()
    this.tarSteps = targetManager.getTarget('step_target')
    StepData.targetStepNum = this.tarSteps

    //更新当前步数信息
    this.updateStepsView(StepData.getCurrentSteps())
    this.formData.tarSteps = '/'+this.tarSteps+'步'
    //步数回调注册
    StepData.addCallback(this.stepsCallback)
    this.loadYesterdayMetrics()
    //卡片信息更新
    this.updateMainCard()
    
    // 加载身体数据
    this.loadBodyData()

    StepData.checkIsFirstOpenToday()//每次初始化一次步数信息
    //检查权限,注册步数监听
    const result: boolean = await Utils.checkPermissions();
    if(result){
      StepData.registerStepCount()
    }else{
      const result2: boolean = await Utils.requestPermissions();
      if(result2){
        StepData.registerStepCount()
      }else{
        Utils.showToast("你已经拒绝授权，无法读取步数正常使用")
      }
    }

    //更新运动的目标数据
    this.onUpdateSportTarget()

    //检查运动记录是否变化，更新第二个页面的总运动信息
    if(AppDataManager.getSportDataStatus().isChange){
      AppDataManager.findSportAllData(this.sportCallback)
      AppDataManager.resetSportDataStatus()
    }
    this.requestTodaySportSummary()
    //更新周步数信息
    AppDataManager.getStepPerDayWeek(this.modelCallBack)
    this.loadDailyQuote()
  }

  async onUpdateSportTarget(){
    let sportTar1 = await preferencesUtil.getPreferenceValue('steps_ohos', 'SportTarget'+this.subFragmentDataInside.type, 0) as number
    this.subFragmentDataInside.curTarget = Utils.getSportTargetList()[sportTar1].name
    let sportTar2 = await preferencesUtil.getPreferenceValue('steps_ohos', 'SportTarget'+this.subFragmentDataOut.type, 0) as number
    this.subFragmentDataOut.curTarget = Utils.getSportTargetList()[sportTar2].name
    let sportTar3 = await preferencesUtil.getPreferenceValue('steps_ohos', 'SportTarget'+this.subFragmentDataWalk.type, 0) as number
    this.subFragmentDataWalk.curTarget = Utils.getSportTargetList()[sportTar3].name
    let sportTar4 = await preferencesUtil.getPreferenceValue('steps_ohos', 'SportTarget'+this.subFragmentDataFoot.type, 0) as number
    this.subFragmentDataFoot.curTarget = Utils.getSportTargetList()[sportTar4].name
    let sportTar5 = await preferencesUtil.getPreferenceValue('steps_ohos', 'SportTarget'+this.subFragmentDataClimb.type, 0) as number
    this.subFragmentDataClimb.curTarget = Utils.getSportTargetList()[sportTar5].name
  }

  onPageHide(): void {
    StepData.removeCallback(this.stepsCallback)
    this.stopDailyWatcher()
    this.unsubscribe?.()
    this.unsubscribe = null
  }

  /**
   * 更新卡片的列表
   * */
  private updateMainCard(){
    this.line1.length = 0;
    this.line2.length = 0;
    this.line3.length = 0;
    //mainCardContainer.removeAllViews();
    let mainCards:ArrayList<number> = mainCardManager.getCardSet();
    for(let i=0;i<mainCards.length;i++){
      if(this.line1.length<2){
        this.line1.push(this.createMainCardData(mainCards[i], i))
        Log.i("line1:"+mainCards[i])
        continue
      }
      if(this.line2.length<2){
        this.line2.push(this.createMainCardData(mainCards[i], i-2))
        Log.i("line2:"+mainCards[i])
        continue
      }
      if(this.line3.length<2){
        this.line3.push(this.createMainCardData(mainCards[i], i-4))
        Log.i("line3:"+mainCards[i])
        continue
      }
    }

    if (mainCardManager.getMainCardChanged()) {
      mainCardManager.setMainCardChangedAlreadyUpdate();
    }
  }

  private createMainCardData(item:number, index:number): MainCardData {
    const metrics = this.cardMetrics[item]
    const subtitle = metrics?.subtitle ?? AppDataManager.getMainCardSubStr(item)
    const value = metrics?.value ?? AppDataManager.getMainCardSubData(item)
    const prevTitle = metrics?.prevTitle ?? AppDataManager.getMainCardLastTitle(item)
    const prevValue = metrics?.prevValue ?? AppDataManager.getMainCardLastData(item)
    const data: MainCardData = {
      item,
      index,
      subtitle,
      value
    }
    if (prevTitle !== '' && prevValue !== '') {
      data.prevTitle = prevTitle
      data.prevValue = prevValue
    }
    return data
  }

  private updateCardMetrics(type: number, metrics: Partial<MainCardMetrics>) {
    const previous: MainCardMetrics = this.cardMetrics[type] ?? {
      subtitle: AppDataManager.getMainCardSubStr(type),
      value: AppDataManager.getMainCardSubData(type)
    }
    const merged: MainCardMetrics = {
      subtitle: metrics.subtitle ?? previous.subtitle,
      value: metrics.value ?? previous.value,
      prevTitle: metrics.prevTitle ?? previous.prevTitle,
      prevValue: metrics.prevValue ?? previous.prevValue
    }
    this.cardMetrics[type] = merged
    this.updateMainCard()
  }

  private startDailyWatcher() {
    this.stopDailyWatcher()
    const handler = setInterval(() => {
      const today = DateUtils.getYMD()
      if (today !== this.currentDateStr) {
        this.currentDateStr = today
        this.onNewDayArrived()
      }
    }, 60 * 1000)
    this.dateWatcherId = handler as number
  }

  private stopDailyWatcher() {
    if (this.dateWatcherId !== 0) {
      clearInterval(this.dateWatcherId)
      this.dateWatcherId = 0
    }
  }

  private async onNewDayArrived() {
    this.updateCardMetrics(MainCardManager.STEPS_DISTANCE, {
      subtitle: '今日',
      value: '0.0公里'
    })
    this.updateCardMetrics(MainCardManager.STEPS_ENERGY, {
      subtitle: '今日',
      value: '0千卡'
    })
    this.updateCardMetrics(MainCardManager.STEPS_SPORTS, {
      subtitle: '当前',
      value: '无数据',
      prevTitle: '上次',
      prevValue: '无数据'
    })

    await StepData.checkIsFirstOpenToday()
    this.updateStepsView(StepData.getCurrentSteps())
    this.requestTodaySportSummary()
    await this.loadGoalTargets()
    this.loadYesterdayMetrics()
    this.loadDailyQuote()
  }

  private formatDistance(steps: number): string {
    const distance = steps * 0.6 / 1000
    return `${distance.toFixed(1)}公里`
  }

  private formatCalories(steps: number): string {
    return `${Math.round(parseFloat(Utils.getKalByStep(steps)))}千卡`
  }

  private loadYesterdayMetrics() {
    AppDataManager.getStepPerDay(DateUtils.getYMD_(1), this.yesterdayStepCallback)
  }

  private async loadGoalTargets() {
    await targetManager.loadTargets()
    this.calorieTargetSetting = targetManager.getTarget('calorie_target')
    this.timeTargetSetting = targetManager.getTarget('exercise_time_target')
    this.activityTargetSetting = targetManager.getTarget('activity_count_target')

    this.updateGoalProgressItem('calorie', this.currentCalories, this.calorieTargetSetting)
    this.updateGoalProgressItem('time', this.currentSportMinutes, this.timeTargetSetting)
    this.updateGoalProgressItem('activity', this.currentActivityCount, this.activityTargetSetting)
  }

  private requestTodaySportSummary() {
    const startOfDay: number = DateUtils.dateToTimestamp(DateUtils.getYMD())
    const endOfDay: number = startOfDay + 24 * 60 * 60 * 1000 - 1
    AppDataManager.findAllByTypeWithDate(0, startOfDay, endOfDay, this.goalSportCallback)
  }

  private goalSportCallback = {
    onDataResult: (type: number, result: Array<SportModel>, isReturnFirstData: boolean): void => {
      let totalMinutes = 0
      let qualifiedCount = 0
      let totalCalories = 0
      let totalDistance = 0
      for (const item of result) {
        const minutes = Math.max(0, Math.floor(item.use_time / 60000))
        if (minutes >= 2) {
          qualifiedCount += 1
          totalMinutes += minutes
          totalDistance += item.steps * 0.6 / 1000
          totalCalories += Number.parseFloat(item.cal ?? '0')
        }
      }
      this.currentSportMinutes = totalMinutes
      this.currentActivityCount = qualifiedCount
      this.updateGoalProgressItem('time', this.currentSportMinutes, this.timeTargetSetting)
      this.updateGoalProgressItem('activity', this.currentActivityCount, this.activityTargetSetting)
      const summaryParts: Array<string> = []
      if (qualifiedCount > 0) {
        summaryParts.push(`${qualifiedCount}次`)
      }
      if (totalMinutes > 0) {
        summaryParts.push(`${totalMinutes}分钟`)
      }
      if (totalCalories > 0) {
        summaryParts.push(`${Math.round(totalCalories)}千卡`)
      }
      if (totalDistance > 0) {
        summaryParts.push(`${totalDistance.toFixed(1)}公里`)
      }
      const currentSummary = summaryParts.length > 0 ? summaryParts.join(' · ') : '暂无记录'
      const lastRecord = result.length > 0 ? result[result.length - 1] : undefined
      let lastSummary = '暂无记录'
      if (lastRecord) {
        const lastMinutes = Math.max(0, Math.floor(lastRecord.use_time / 60000))
        const lastCalories = Math.round(Number.parseFloat(lastRecord.cal ?? '0'))
        const lastDistance = (lastRecord.steps * 0.6 / 1000).toFixed(1)
        const lastParts: Array<string> = []
        if (lastMinutes > 0) {
          lastParts.push(`${lastMinutes}分钟`)
        }
        if (lastCalories > 0) {
          lastParts.push(`${lastCalories}千卡`)
        }
        if (lastDistance !== '0.0') {
          lastParts.push(`${lastDistance}公里`)
        }
        if (lastParts.length > 0) {
          lastSummary = lastParts.join(' · ')
        }
      }
      this.updateCardMetrics(MainCardManager.STEPS_SPORTS, {
        subtitle: '今日',
        value: currentSummary,
        prevTitle: '上次',
        prevValue: lastSummary
      })
    }
  } as DataCallback<SportModel>

  private updateCalorieProgress(steps: number) {
    if (steps < 0) {
      steps = 0
    }
    const calories = Number.parseFloat(Utils.getKalByStep(steps))
    this.currentCalories = calories
    this.updateGoalProgressItem('calorie', calories, this.calorieTargetSetting)
    this.updateCardMetrics(MainCardManager.STEPS_ENERGY, {
      subtitle: '今日',
      value: `${Math.round(calories)}千卡`
    })
  }

  private updateGoalProgressItem(key: string, current: number, target?: number) {
    const updated: Array<GoalProgressItem> = []
    for (let i = 0; i < this.targetProgress.length; i++) {
      const item = this.targetProgress[i]
      if (item.key === key) {
        updated.push({
          key: item.key,
          label: item.label,
          unit: item.unit,
          color: item.color,
          current: current,
          target: target !== undefined ? target : item.target,
        })
      } else {
        updated.push(item)
      }
    }
    this.targetProgress = updated
  }

  private formatGoalValue(value: number): string {
    if (value <= 0) {
      return '0'
    }
    return Math.round(value).toString()
  }

  private computeProgressWidth(current: number, target: number): string {
    if (target <= 0) {
      return '0%'
    }
    const percent = Math.min(100, Math.round((current / target) * 100))
    return percent + '%'
  }

  private loadDailyQuote() {
    // 基于当前日期选择每日警句
    const index = Math.abs(DateUtils.dateToTimestamp(DateUtils.getYMD())) % this.allQuotes.length
    this.dailyQuote = this.allQuotes[index]
  }

  private async loadBodyData() {
    // 加载身体数据
    this.currentHeight = await preferencesUtil.getPreferenceValue('steps_ohos', 'height', 170) as number
    this.currentWeight = await preferencesUtil.getPreferenceValue('steps_ohos', 'weight', 60) as number
    this.userAge = await preferencesUtil.getPreferenceValue('steps_ohos', 'age', 25) as number
    this.userGender = await preferencesUtil.getPreferenceValue('steps_ohos', 'gender', 'male') as string
    
    // 计算BMI
    if (this.currentHeight > 0 && this.currentWeight > 0) {
      const heightInMeters = this.currentHeight / 100
      this.bmi = this.currentWeight / (heightInMeters * heightInMeters)
      
      // 判断BMI状态
      if (this.bmi < 18.5) {
        this.bmiStatus = '过轻'
      } else if (this.bmi < 24) {
        this.bmiStatus = '正常'
      } else if (this.bmi < 28) {
        this.bmiStatus = '偏胖'
      } else {
        this.bmiStatus = '肥胖'
      }
    }
    
    // 计算基础代谢率
    if (this.currentHeight > 0 && this.currentWeight > 0 && this.userAge > 0) {
      if (this.userGender === 'male') {
        this.basalMetabolism = 10 * this.currentWeight + 6.25 * this.currentHeight - 5 * this.userAge + 5
      } else {
        this.basalMetabolism = 10 * this.currentWeight + 6.25 * this.currentHeight - 5 * this.userAge - 161
      }
    }
  }

  private navigateToGoalDetail(goalKey: string) {
    Log.i('navigateToGoalDetail called with key: ' + goalKey)
    switch (goalKey) {
      case 'calorie':
        // 跳转到热量消耗统计页面
        Log.i('Navigating to ChartPage')
        router.pushUrl({ url: 'pages/ChartPage' })
        break
      case 'time':
        // 跳转到锻炼时长统计页面
        Log.i('Navigating to ExerciseTimePage')
        router.pushUrl({ url: 'pages/ExerciseTimePage' })
        break
      case 'activity':
        // 跳转到活动次数统计页面
        Log.i('Navigating to ActivityCountPage')
        router.pushUrl({ url: 'pages/ActivityCountPage' })
        break
      default:
        Log.i('Unknown goal key: ' + goalKey)
    }
  }

  @Builder buildGoalOverviewCard() {
    Column() {
      Text('目标完成情况')
        .fontSize(16)
        .fontWeight(500)
        .fontColor('#222222')
        .margin({ bottom: 12 })
        .alignSelf(ItemAlign.Start)

      Row() {
        ForEach(this.targetProgress, (item: GoalProgressItem, index?: number) => {
          this.buildGoalOverviewItem(item, index !== undefined && index === this.targetProgress.length - 1)
        })
      }
    }
    .width('92%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .padding({ left: 16, right: 16, top: 16, bottom: 20 })
    .margin({ top: 16 })
  }

  @Builder buildGoalOverviewItem(goal: GoalProgressItem, isLast: boolean = false) {
    Column() {
      Text(goal.label)
        .fontSize(13)
        .fontColor('#999999')

      Row() {
        Text(this.formatGoalValue(goal.current))
          .fontSize(18)
          .fontWeight(600)
          .fontColor('#121212')
        Text('/')
          .fontSize(16)
          .fontColor('#999999')
          .margin({ left: 2, right: 2 })
        Text(goal.target.toString())
          .fontSize(16)
          .fontWeight(500)
          .fontColor('#666666')
        Text(goal.unit)
          .fontSize(11)
          .fontColor('#999999')
          .margin({ left: 2 })
      }
      .margin({ top: 6 })
      .alignItems(VerticalAlign.Bottom)

      Stack() {
        Row()
          .backgroundColor('#F0F0F0')
          .height(8)
          .borderRadius(4)
          .width('100%')

        Row()
          .backgroundColor(goal.current >= goal.target ? '#0cc291' : goal.color)
          .height(8)
          .borderRadius(4)
          .width(this.computeProgressWidth(goal.current, goal.target))
          .align(Alignment.TopStart)
      }
      .width('100%')
      .align(Alignment.TopStart)
      .margin({ top: 10 })
    }
    .layoutWeight(1)
    .margin({ right: isLast ? 0 : 12 })
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      this.navigateToGoalDetail(goal.key)
    })
  }

  @Builder buildDailyQuoteCard() {
    Column() {
      Row() {
        Text('每日警句')
          .fontSize(16)
          .fontWeight(500)
          .fontColor('#222222')
          .margin({ right: 8 })
        
        Swiper() {
          ForEach(this.dailyQuotes, (quote: string, index: number) => {
            Text(quote)
              .fontSize(13)
              .fontColor('#666666')
              .fontWeight(400)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .maxLines(1)
          })
        }
        .layoutWeight(1)
        .height(20)
        .indicator(false)
        .autoPlay(true)
        .interval(3000)
        .loop(true)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('92%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .margin({ top: 12 })
  }

  @Builder buildBodyDataCards() {
    Column() {
      Row() {
        Column() {
        this.bodyDataCard(this.getHeightOverviewCard())
        }
        .layoutWeight(1)
        .margin({ right: 8 })

        Column() {
          this.bodyDataCard(this.getWeightOverviewCard())
        }
        .layoutWeight(1)
        .margin({ left: 8 })
      }
      .width('100%')
      .margin({ bottom: 12 })

      Row() {
        Column() {
          this.bodyDataCard(this.getBmrOverviewCard())
        }
        .layoutWeight(1)
        .margin({ right: 8 })

        Column() {
          this.bodyDataCard(this.getBmiOverviewCard())
        }
        .layoutWeight(1)
        .margin({ left: 8 })
      }
      .width('100%')
    }
    .width('92%')
    .margin({ top: 12, bottom: 8 })
  }

  private resolveBmiColor(): string {
    if (this.bmiStatus === '正常') {
      return '#0cc291'
    }
    if (this.bmiStatus === '过轻') {
      return '#5BA7FF'
    }
    if (this.bmiStatus === '偏胖') {
      return '#FF9C57'
    }
    if (this.bmiStatus === '肥胖') {
      return '#FF6B6B'
    }
    return '#666666'
  }

  private getHeightOverviewCard(): BodyOverviewCard {
    return {
      title: '我的身高',
      value: this.currentHeight > 0 ? this.currentHeight.toFixed(1) : '--',
      unit: this.currentHeight > 0 ? '厘米' : '',
      icon: $r('app.media.icon_my_height'),
      badgeBackground: 'rgba(98,214,176,0.18)',
      onTap: () => {
        console.info('[MainTabs] 点击身高卡片，跳转到身体数据页面并打开身高记录')
        try {
          router.pushUrl({ 
            url: 'pages/BodyDataPage', 
            params: { showHeightRecord: true } 
          }).catch((err: Error) => {
            console.error('[MainTabs] 跳转失败:', err.message)
          })
        } catch (err) {
          console.error('[MainTabs] 跳转异常:', err)
        }
      }
    }
  }

  private getWeightOverviewCard(): BodyOverviewCard {
    return {
      title: '我的体重',
      value: this.currentWeight > 0 ? this.currentWeight.toFixed(1) : '--',
      unit: this.currentWeight > 0 ? '公斤' : '',
      icon: $r('app.media.icon_my_weight'),
      badgeBackground: 'rgba(231,163,255,0.18)',
      onTap: () => {
        router.pushUrl({ url: 'pages/WeightTrendPage' })
      }
    }
  }

  private getBmrOverviewCard(): BodyOverviewCard {
    return {
      title: '基础代谢',
      value: this.basalMetabolism > 0 ? Math.round(this.basalMetabolism).toString() : '--',
      unit: this.basalMetabolism > 0 ? '千卡' : '',
      icon: $r('app.media.icon_my_bmr'),
      badgeBackground: 'rgba(255,140,71,0.18)',
      onTap: () => {
        router.pushUrl({ url: 'pages/BasalMetabolismPage' })
      }
    }
  }

  private getBmiOverviewCard(): BodyOverviewCard {
    return {
      title: 'BMI 指数',
      value: this.bmi > 0 ? this.bmi.toFixed(1) : '--',
      unit: this.bmi > 0 ? (this.bmiStatus || '') : '',
      noteColor: this.resolveBmiColor(),
      icon: $r('app.media.icon_my_bmi'),
      badgeBackground: 'rgba(119,198,147,0.18)',
      onTap: () => {
        router.pushUrl({ url: 'pages/BodyMassIndexPage' })
      }
    }
  }

  @Builder private bodyDataCard(config: BodyOverviewCard) {
    Row() {
      Column() {
        Text(config.title)
          .fontSize(14)
          .fontWeight(500)
          .fontColor('#333333')

        Text(config.value)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .margin({ top: 10 })

        if (config.unit && config.unit.length > 0) {
          Text(config.unit)
            .fontSize(12)
            .fontColor(config.noteColor ?? '#666666')
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column() {
        Image(config.icon)
          .width(26)
          .height(26)
          .objectFit(ImageFit.Contain)
      }
      .width(44)
      .height(44)
      .backgroundColor(config.badgeBackground)
      .borderRadius(22)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .margin({ left: 10 })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12, left: 18, right: 18 })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ color: 'rgba(12,194,145,0.05)', radius: 6, offsetX: 0, offsetY: 4 })
    .onClick(() => {
      if (config.onTap) {
        config.onTap()
      }
    })
  }

  @Builder buildHealthFeatureSection() {
    Column() {
      Text('健康记录')
        .fontSize(16)
        .fontWeight(500)
        .fontColor('#222222')
        .margin({ bottom: 12 })

      ForEach(this.getHealthFeatureRowIndexes(), (rowIndex: number) => {
        Row() {
          ForEach(this.getHealthFeatureColumnIndexes(), (columnIndex: number) => {
            this.buildHealthFeatureCard(this.getHealthFeatureItem(rowIndex, columnIndex), columnIndex === 0 ? 0 : 12)
          }, (_columnIndex: number, columnIndex: number) => `${rowIndex}-${columnIndex}`)
        }
        .margin({ bottom: rowIndex < this.getHealthFeatureRowCount() - 1 ? 12 : 0 })
      }, (_rowIndex: number, rowIndex: number) => `row-${rowIndex}`)
    }
    .width('92%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .margin({ top: 12 })
  }

  @Builder private buildHealthFeatureCard(item: HealthFeatureItem | undefined, marginLeft: number = 0) {
    if (item === undefined) {
      Blank()
        .width('30%')
        .height(72)
        .margin({ left: marginLeft })
    } else {
      Column() {
        Text(item.label)
          .fontSize(15)
          .fontWeight(500)
          .fontColor('#121212')
        Text(item.subtitle)
          .fontSize(13)
          .fontColor('#666666')
          .margin({ top: 4 })
      }
      .padding({ left: 12, right: 12, top: 12, bottom: 12 })
      .backgroundColor(item.color)
      .borderRadius(12)
      .width('30%')
      .height(72)
      .margin({ left: marginLeft })
      .onClick(() => {
        router.pushUrl({ url: item.route })
      })
    }
  }
  private getHealthFeatureRowCount(): number {
    const total: number = this.healthFeatures.length
    if (total === 0) {
      return 0
    }
    return Math.ceil(total / 3)
  }

  private getHealthFeatureRowIndexes(): Array<number> {
    const count: number = this.getHealthFeatureRowCount()
    const indexes: Array<number> = []
    for (let index = 0; index < count; index++) {
      indexes.push(index)
    }
    return indexes
  }

  private getHealthFeatureColumnIndexes(): Array<number> {
    return [0, 1, 2]
  }

  private getHealthFeatureItem(rowIndex: number, columnIndex: number): HealthFeatureItem | undefined {
    const index: number = rowIndex * 3 + columnIndex
    if (index >= this.healthFeatures.length) {
      return undefined
    }
    return this.healthFeatures[index]
  }

  build() {
      Stack(){
        Tabs({ barPosition: BarPosition.End, controller: this.controller }) {
          TabContent() {// 第一个tab页面 start
            Scroll(this.scroller){
              Column(){
                Text("健康").fontColor('#000000').fontSize(20).fontWeight(500).width('95%').margin({bottom:10,top:10})
                  .padding({top: EntryAbility.myWindowClass ? Math.max(0, EntryAbility.myWindowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height - 80) : 0})
                MainTopView({formData:this.formData})
                //头部的绿色区域 end
                
                // 目标完成情况 - 紧接着步数大卡片
                this.buildGoalOverviewCard()
                
                // 每日警句
                this.buildDailyQuoteCard()
                
                // MainCard 卡片区域
                if(this.line1.length>0){ //第一行MainCard
                  Row(){
                    ForEach(this.line1, (item: MainCardData, index: number) => {
                      MainCardView({formData:item})
                    })
                  }.width('92%').height(this.mainCardH).margin({top:10})
                }//第一行MainCard
                if(this.line2.length>0){//第二行MainCard
                  Row(){
                    ForEach(this.line2, (item: MainCardData, index: number) => {
                      MainCardView({formData:item})
                    })
                  }.width('92%').height(this.mainCardH).margin({top:10})
                }//第二行MainCard
                if(this.line3.length>0){//第三行MainCard
                  Row(){
                    ForEach(this.line3, (item: MainCardData, index: number) => {
                      MainCardView({formData:item})
                    })
                  }.width('92%').height(this.mainCardH).margin({top:10})
                }//第三行MainCard

                // this.buildHealthFeatureSection() // 隐藏健康记录卡片
                Text('编辑卡片').fontSize(18).fontColor('#ff09926d').margin(15).onClick(() => {
                  router.pushUrl({ url: 'pages/EditMainCardPage' })
                })
                // 临时隐藏分享卡片
                // BannerView({str1:'和好友一起运动\n',str2:'邀请好友一起为健康加油',img:$r('app.media.new_home_share_friend')}).onClick(() => {
                //   router.pushUrl({ url: 'pages/BitMapPage' })
                // })

              }.width('100%')//第一页scroll的根节点
              .backgroundColor(this.tabColor)
            }.width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Off).backgroundColor(this.tabColor)
          }.tabBar(this.tabBuilder(0,'健康',$r('app.media.home_icon_f'),$r('app.media.home_icon_n'))) //Tab1 按钮
          // 第一个tab页面 end
          TabContent() {
            Column(){
              Text("运动").fontColor('#000000').fontSize(20).fontWeight(500).width('95%').margin({ bottom: 10, top: 10 })
                .padding({ top: EntryAbility.myWindowClass ? Math.max(0, EntryAbility.myWindowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height - 80) : 0 })
              Tabs({ barPosition: BarPosition.Start, controller: this.subController }) {
                TabContent() {// 第一个subTab1页面 start
                  Scroll(this.sportSubScrollers[0]) {
                    Column() {
                      SubFragment({formData:this.subFragmentDataInside})
                    }
                    .width('100%')
                    .backgroundColor('#FFFFFF')
                  }
                  .width('100%')
                  .align(Alignment.Top)
                  .scrollBar(BarState.Off)
                  .backgroundColor('#FFFFFF')
                }.tabBar(this.subTabBuilder(0,'室内跑')).gesture(PanGesture(this.panOptionRight)
                    .onActionEnd(() => {
                      this.controller.changeIndex(0)
                    })
                )
                TabContent() {// 第二个subTab2页面 start
                  Scroll(this.sportSubScrollers[1]) {
                    Column() {
                      SubFragment({formData:this.subFragmentDataOut})
                    }
                    .width('100%')
                    .backgroundColor('#FFFFFF')
                  }
                  .width('100%')
                  .align(Alignment.Top)
                  .scrollBar(BarState.Off)
                  .backgroundColor('#FFFFFF')
                }.tabBar(this.subTabBuilder(1,'室外跑'))
                TabContent() {// 第三个subTab3页面 start
                  Scroll(this.sportSubScrollers[2]) {
                    Column() {
                      SubFragment({formData:this.subFragmentDataWalk})
                    }
                    .width('100%')
                    .backgroundColor('#FFFFFF')
                  }
                  .width('100%')
                  .align(Alignment.Top)
                  .scrollBar(BarState.Off)
                  .backgroundColor('#FFFFFF')
                }.tabBar(this.subTabBuilder(2,'健走'))
                TabContent() {// 第四个subTab4页面 start
                  Scroll(this.sportSubScrollers[3]) {
                    Column() {
                      SubFragment({formData:this.subFragmentDataFoot})
                    }
                    .width('100%')
                    .backgroundColor('#FFFFFF')
                  }
                  .width('100%')
                  .align(Alignment.Top)
                  .scrollBar(BarState.Off)
                  .backgroundColor('#FFFFFF')
                }.tabBar(this.subTabBuilder(3,'徒步'))
                TabContent() {// 第五个subTab5页面 start
                  Scroll(this.sportSubScrollers[4]) {
                    Column() {
                      SubFragment({formData:this.subFragmentDataClimb})
                    }
                    .width('100%')
                    .backgroundColor('#FFFFFF')
                  }
                  .width('100%')
                  .align(Alignment.Top)
                  .scrollBar(BarState.Off)
                  .backgroundColor('#FFFFFF')
                }.tabBar(this.subTabBuilder(4,'登山'))
              }
              .barHeight('6%')
              .barWidth('93%')
              .scrollable(true)
              .width('100%')
              .layoutWeight(1)
              .vertical(false)
              .onChange((index: number) => {
                this.currentSubIndex = index
              }).animationDuration(100)
              .backgroundColor('#FFFFFF')
            }.width('100%').height('100%').backgroundColor('#FFFFFF')//第一页scroll的根节点
          }.tabBar(this.tabBuilder(1,'运动',$r('app.media.tab_sport_f'),$r('app.media.tab_sport_n'))) //Tab2 按钮
          TabContent() {
            Scroll(this.scroller){
              Column(){
                Row(){
                  Row(){
                    Image(this.userImg).alt($r('app.media.user_image')).width(60).height(60).borderRadius(15)
                    Text(){
                      Span(this.userName).fontSize(18).fontColor('#000000').fontWeight(600)
                      Span('\n')
                      Span(this.userCode).fontSize(13).fontColor('#ff727272')
                    }.textAlign(TextAlign.Start).textAlign(TextAlign.Start).margin({left:10})
                  }
                  .layoutWeight(1)
                  .onClick(() => {
                    console.info('[MainTabs] 点击登录区域, userName:', this.userName);
                    this.handleLoginTap();
                  })
                  
                  Row(){
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
                    router.pushUrl({ url: 'pages/UserProfilePage' }).catch((err: Error) => {
                      console.error('[MainTabs] 跳转个人信息页面失败:', err.message)
                    })
                  })
                }
                .width('94%')
                .height(80)
                .padding({ left: 12, right: 12, top: 10, bottom: 10 })
                .margin({top:10})
                .backgroundColor(this.userName === '未登录用户' ? '#F8F8F8' : 'transparent')
                .borderRadius(12)
                .justifyContent(FlexAlign.SpaceBetween)
                .alignItems(VerticalAlign.Center)

                // 身体数据卡片区域
                this.buildBodyDataCards()

                Column(){
                  SettingItemView({formData:{type:8,title:'数据统计',icon:$r('app.media.setting_data_sport')}}).onClick(() => {
                    router.pushUrl({ url: 'pages/ChartPage' })
                  })
                }.width('96%').backgroundColor('#FFFFFF').borderRadius(15).margin({top:20})

                Column(){
                  SettingItemView({formData:{type:9,title:'设置',icon:$r('app.media.setting_icon_n')}})
                  SettingItemView({formData:{type:4,title:'个人信息手机清单',icon:$r('app.media.userinfo_sj')}})
                  SettingItemView({formData:{type:5,title:'个人信息共享清单',icon:$r('app.media.userinfo_gx')}})
                }.width('96%').backgroundColor('#FFFFFF').borderRadius(15).margin({top:20})

              }.width('100%').padding({
                left:'1%',
                right:'1%',
                top: EntryAbility.myWindowClass ? Math.max(0, EntryAbility.myWindowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height - 80) : 0
              })
              .backgroundColor(this.tabColor)
            }.width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Off).backgroundColor(this.tabColor)
          }.tabBar(this.tabBuilder(2,'我的',$r('app.media.setting_icon_f'),$r('app.media.setting_icon_n'))) //Tab3 按钮
        }
        .vertical(false).onTabBarClick((index: number) => {
          this.controller.changeIndex(index)
        })
        .barHeight('7%').barWidth('100%').scrollable(true).barBackgroundColor('#FFFFFFFF').backgroundColor('#FFFFFFFF')
        .onChange((index: number) => {
          this.currentIndex = index
        })
        .width('100%').height('100%')
        .backgroundColor('#FFFFFFFF') // tab 的整体背景（含底部安全区）设为白色
        .padding({ bottom: EntryAbility.myWindowClass ? (EntryAbility.myWindowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).bottomRect.height + 20) : 20 })
      }
      .width('100%')
      .height('100%')
      .alignContent(Alignment.Bottom)
      .backgroundColor(this.tabColor)
  }
}
