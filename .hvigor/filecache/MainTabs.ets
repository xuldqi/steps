
import {Log} from '../tools/Logger'
import mainCardManager from '../tools/MainCardManager'
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
import { router } from '@kit.ArkUI'
import EntryAbility from '../entryability/EntryAbility'
import { DateUtils } from '../tools/DateUtils'
import { SportModel } from '../appdata/Model'

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
  @State tabColor: string = '#FFF5F5F5'
  private controller: TabsController = new TabsController()
  private subController: TabsController = new TabsController();
  private panOptionLeft: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Left });
  private panOptionRight: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Right });
  private scroller: Scroller = new Scroller()
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
  @State userCode: string = '登录功能开发中'//累计跑步距离

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

  @State targetProgress: Array<GoalProgressItem> = [
    { key: 'calorie', label: '热量消耗', unit: '千卡', color: '#FF8C47', current: 0, target: DEFAULT_CALORIE_TARGET },
    { key: 'time', label: '锻炼时长', unit: '分钟', color: '#FFB950', current: 0, target: DEFAULT_TIME_TARGET },
    { key: 'activity', label: '活动次数', unit: '次', color: '#C7C9CC', current: 0, target: DEFAULT_ACTIVITY_TARGET }
  ]

  @State dailyQuote: string = '保持自律，坚持运动，收获更好的自己。'
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

  private calorieTargetSetting: number = DEFAULT_CALORIE_TARGET
  private timeTargetSetting: number = DEFAULT_TIME_TARGET
  private activityTargetSetting: number = DEFAULT_ACTIVITY_TARGET

  private currentCalories: number = 0
  private currentSportMinutes: number = 0
  private currentActivityCount: number = 0

  aboutToAppear(): void {
    this.syncUserProfile()
    this.loadGoalTargets()
    this.requestTodaySportSummary()
    this.loadDailyQuote()
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
      this.userCode = storedCode === '立即登录' ? '登录功能开发中' : storedCode
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
    this.tarSteps = await preferencesUtil.getPreferenceValue('steps_ohos', 'step_target', 5000) as number
    StepData.targetStepNum = this.tarSteps

    //更新当前步数信息
    this.updateStepsView(StepData.getCurrentSteps())
    this.formData.tarSteps = '/'+this.tarSteps+'步'
    //步数回调注册
    StepData.addCallback(this.stepsCallback)
    //卡片信息更新
    this.updateMainCard()

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
  }

  /**
   * 更新卡片的列表
   * */
  private updateMainCard(){
    //mainCardManager.saveItemCardData("1,2,3,4,5,6,");
    if(!mainCardManager.getMainCardChanged()){
      return;
    }
    this.line1.length = 0;
    this.line2.length = 0;
    this.line3.length = 0;
    //mainCardContainer.removeAllViews();
    let mainCards:ArrayList<number> = mainCardManager.getCardSet();
    for(let i=0;i<mainCards.length;i++){
      if(this.line1.length<2){
        this.line1.push({item:mainCards[i],index:i})
        Log.i("line1:"+mainCards[i])
        continue
      }
      if(this.line2.length<2){
        this.line2.push({item:mainCards[i],index:i-2})
        Log.i("line2:"+mainCards[i])
        continue
      }
      if(this.line3.length<2){
        this.line3.push({item:mainCards[i],index:i-4})
        Log.i("line3:"+mainCards[i])
        continue
      }
    }

    mainCardManager.setMainCardChangedAlreadyUpdate();
  }

  private async loadGoalTargets() {
    if (!preferencesUtil.preferencesMap.has('steps_ohos') && EntryAbility.context) {
      await preferencesUtil.loadPreference(EntryAbility.context, 'steps_ohos')
    }
    const calorieTarget = await preferencesUtil.getPreferenceValue('steps_ohos', 'calorie_target', DEFAULT_CALORIE_TARGET) as number
    const timeTarget = await preferencesUtil.getPreferenceValue('steps_ohos', 'sport_time_target', DEFAULT_TIME_TARGET) as number
    const activityTarget = await preferencesUtil.getPreferenceValue('steps_ohos', 'sport_activity_target', DEFAULT_ACTIVITY_TARGET) as number

    this.calorieTargetSetting = typeof calorieTarget === 'number' ? calorieTarget : DEFAULT_CALORIE_TARGET
    this.timeTargetSetting = typeof timeTarget === 'number' ? timeTarget : DEFAULT_TIME_TARGET
    this.activityTargetSetting = typeof activityTarget === 'number' ? activityTarget : DEFAULT_ACTIVITY_TARGET

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
      for (const item of result) {
        const minutes = Math.floor(item.use_time / 60)
        totalMinutes += minutes
      }
      this.currentSportMinutes = totalMinutes
      this.currentActivityCount = result.length
      this.updateGoalProgressItem('time', this.currentSportMinutes, this.timeTargetSetting)
      this.updateGoalProgressItem('activity', this.currentActivityCount, this.activityTargetSetting)
    }
  } as DataCallback<SportModel>

  private updateCalorieProgress(steps: number) {
    if (steps < 0) {
      steps = 0
    }
    const calories = Number.parseFloat(Utils.getKalByStep(steps))
    this.currentCalories = calories
    this.updateGoalProgressItem('calorie', calories, this.calorieTargetSetting)
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
    if (value >= 100) {
      return Math.round(value).toString()
    }
    return value.toFixed(1)
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

  private navigateToGoalDetail(goalKey: string) {
    switch (goalKey) {
      case 'calorie':
        // 跳转到热量消耗统计页面
        router.pushUrl({ url: 'pages/ChartPage' })
        break
      case 'time':
        // 跳转到锻炼时长统计页面
        router.pushUrl({ url: 'pages/SportRecordPage' })
        break
      case 'activity':
        // 跳转到活动次数统计页面
        router.pushUrl({ url: 'pages/SportRecordPage' })
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
          .fontSize(22)
          .fontWeight(700)
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
          .backgroundColor('#EEEEEE')
          .height(6)
          .borderRadius(3)
          .width('100%')

        Row()
          .backgroundColor(goal.color)
          .height(6)
          .borderRadius(3)
          .width(this.computeProgressWidth(goal.current, goal.target))
      }.margin({ top: 10 })
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
      Text('每日警句')
        .fontSize(16)
        .fontWeight(500)
        .fontColor('#222222')
        .margin({ bottom: 8 })
        .alignSelf(ItemAlign.Start)

      Text(this.dailyQuote)
        .fontSize(13)
        .fontColor('#666666')
        .lineHeight(20)
        .textAlign(TextAlign.Start)
        .width('100%')
    }
    .width('92%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .margin({ top: 12 })
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

                this.buildHealthFeatureSection()
                Text('编辑卡片').fontSize(18).fontColor('#ff09926d').margin(15).onClick(() => {
                  router.pushUrl({ url: 'pages/EditMainCardPage' })
                })
                // 临时隐藏分享卡片
                // BannerView({str1:'和好友一起运动\n',str2:'邀请好友一起为健康加油',img:$r('app.media.new_home_share_friend')}).onClick(() => {
                //   router.pushUrl({ url: 'pages/BitMapPage' })
                // })

              }.width('100%')//第一页scroll的根节点
            }.width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Off)
          }.tabBar(this.tabBuilder(0,'健康',$r('app.media.home_icon_f'),$r('app.media.home_icon_n'))) //Tab1 按钮
          // 第一个tab页面 end
          TabContent() {
            Column(){
              Text("运动").fontColor('#000000').fontSize(20).fontWeight(500).width('95%').margin({bottom:10,top:10})
              Tabs({ barPosition: BarPosition.Start, controller: this.subController }) {
                TabContent() {// 第一个subTab1页面 start
                  SubFragment({formData:this.subFragmentDataInside})
                }.tabBar(this.subTabBuilder(0,'室内跑')).gesture(PanGesture(this.panOptionRight)
                    .onActionEnd(() => {
                      this.controller.changeIndex(0)
                    })
                )
                TabContent() {// 第二个subTab2页面 start
                  SubFragment({formData:this.subFragmentDataOut})
                }.tabBar(this.subTabBuilder(1,'室外跑'))
                TabContent() {// 第三个subTab3页面 start
                  SubFragment({formData:this.subFragmentDataWalk})
                }.tabBar(this.subTabBuilder(2,'健走'))
                TabContent() {// 第四个subTab4页面 start
                  SubFragment({formData:this.subFragmentDataFoot})
                }.tabBar(this.subTabBuilder(3,'徒步'))
                TabContent() {// 第五个subTab5页面 start
                  SubFragment({formData:this.subFragmentDataClimb})
                }.tabBar(this.subTabBuilder(4,'登山'))
                TabContent() {// 第六个subTab6页面 start - 数据统计
                  Column() {
                    Text('数据统计')
                      .fontSize(18)
                      .fontWeight(600)
                      .margin({ top: 20, bottom: 10 })
                      .alignSelf(ItemAlign.Start)
                      .padding({ left: 20 })
                    
                    Row() {
                      Column() {
                        Image($r('app.media.setting_data_sport'))
                          .width(50)
                          .height(50)
                          .margin({ bottom: 10 })
                        Text('步数趋势')
                          .fontSize(16)
                          .fontWeight(500)
                        Text('查看最近7天步数变化')
                          .fontSize(12)
                          .fontColor('#666')
                          .margin({ top: 5 })
                      }
                      .layoutWeight(1)
                      .padding(20)
                      .backgroundColor('#f8f9fa')
                      .borderRadius(15)
                      .margin({ right: 10 })
                      .onClick(() => {
                        router.pushUrl({ url: 'pages/ChartPage' })
                      })

                      Column() {
                        Image($r('app.media.setting_body_record'))
                          .width(50)
                          .height(50)
                          .margin({ bottom: 10 })
                        Text('运动分析')
                          .fontSize(16)
                          .fontWeight(500)
                        Text('查看运动类型分布')
                          .fontSize(12)
                          .fontColor('#666')
                          .margin({ top: 5 })
                      }
                      .layoutWeight(1)
                      .padding(20)
                      .backgroundColor('#f8f9fa')
                      .borderRadius(15)
                      .margin({ left: 10 })
                      .onClick(() => {
                        router.pushUrl({ url: 'pages/ChartPage' })
                      })
                    }
                    .width('90%')
                    .margin({ top: 20 })

                    Row() {
                      Column() {
                        Image($r('app.media.setting_body_record'))
                          .width(50)
                          .height(50)
                          .margin({ bottom: 10 })
                        Text('身体数据')
                          .fontSize(16)
                          .fontWeight(500)
                        Text('查看体重变化趋势')
                          .fontSize(12)
                          .fontColor('#666')
                          .margin({ top: 5 })
                      }
                      .layoutWeight(1)
                      .padding(20)
                      .backgroundColor('#f8f9fa')
                      .borderRadius(15)
                      .margin({ right: 10 })
                      .onClick(() => {
                        router.pushUrl({ url: 'pages/ChartPage' })
                      })

                      Column() {
                        Image($r('app.media.setting_data_sport'))
                          .width(50)
                          .height(50)
                          .margin({ bottom: 10 })
                        Text('周报总结')
                          .fontSize(16)
                          .fontWeight(500)
                        Text('查看详细周报数据')
                          .fontSize(12)
                          .fontColor('#666')
                          .margin({ top: 5 })
                      }
                      .layoutWeight(1)
                      .padding(20)
                      .backgroundColor('#f8f9fa')
                      .borderRadius(15)
                      .margin({ left: 10 })
                      .onClick(() => {
                        router.pushUrl({ url: 'pages/StepWeekPage' })
                      })
                    }
                    .width('90%')
                    .margin({ top: 20 })
                  }
                  .width('100%')
                  .height('100%')
                  .align(Alignment.Top)
                }.tabBar(this.subTabBuilder(5,'统计')).gesture(PanGesture(this.panOptionLeft)
                    .onActionEnd(() => {
                      this.controller.changeIndex(2)
                    })
                )
              }.barHeight('6%').barWidth('93%').scrollable(true).width('100%').height('100%').vertical(false)
              .onChange((index: number) => {
                this.currentSubIndex = index
              }).animationDuration(100)
            }.width('100%').height('100%').align(Alignment.Top)//第一页scroll的根节点
          }.tabBar(this.tabBuilder(1,'运动',$r('app.media.tab_sport_f'),$r('app.media.tab_sport_n'))) //Tab2 按钮
          TabContent() {
            Scroll(this.scroller){
              Column(){
                Image($r('app.media.setting_bg_icon')).width(25).height(25).margin({top:5}).alignSelf(ItemAlign.End).onClick(() => {
                  //跳转设置
                  router.pushUrl({ url: 'pages/SettingPage' })
                })
                Row(){
                  Image(this.userImg).alt($r('app.media.user_image')).width(60).height(60).borderRadius(15)
                  Text(){
                    Span(this.userName).fontSize(18).fontColor('#000000').fontWeight(600)
                    Span('\n')
                    Span(this.userCode).fontSize(13).fontColor('#ff727272')
                  }.textAlign(TextAlign.Start).textAlign(TextAlign.Start).margin({left:10}).layoutWeight(1)
                }.width('94%').margin({top:15})

                Row() {
                  UserDataView({formData:this.userData1}).onClick(() => {
                    router.pushUrl({ url: 'pages/StepWeekPage' })
                  })
                  UserDataView({formData:this.userData2})
                }.margin({top:15})

                Column(){
                  SettingItemView({formData:{type:1,title:'运动记录',icon:$r('app.media.setting_data_sport')}})
                  SettingItemView({formData:{type:2,title:'身体数据',icon:$r('app.media.setting_body_record')}})
                  SettingItemView({formData:{type:8,title:'数据统计',icon:$r('app.media.setting_data_sport')}}).onClick(() => {
                    router.pushUrl({ url: 'pages/ChartPage' })
                  })
                }.width('96%').backgroundColor('#FFFFFF').borderRadius(15).margin({top:20})

                Column(){
                  SettingItemView({formData:{type:3,title:'分享',icon:$r('app.media.setting_share_app')}})
                  SettingItemView({formData:{type:4,title:'个人信息手机清单',icon:$r('app.media.userinfo_sj')}})
                  SettingItemView({formData:{type:5,title:'个人信息共享清单',icon:$r('app.media.userinfo_gx')}})
                  SettingItemView({formData:{type:6,title:'给软件评分',icon:$r('app.media.setting_rate_us')}})
                  SettingItemView({formData:{type:7,title:'帮助与反馈',icon:$r('app.media.setting_advice_suggest')}})
                }.width('96%').backgroundColor('#FFFFFF').borderRadius(15).margin({top:20})

              }.width('100%').padding({left:'1%',right:'1%'})
            }.width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Off)
          }.tabBar(this.tabBuilder(2,'我的',$r('app.media.setting_icon_f'),$r('app.media.setting_icon_n'))) //Tab3 按钮
        }
        .vertical(false).onTabBarClick((index: number) => {
          this.controller.changeIndex(index)
        })
        .barHeight('7%').barWidth('100%').scrollable(true).barBackgroundColor('#FFFFFFFF')
        .onChange((index: number) => {
          this.currentIndex = index
        })
        .width('100%').height('100%')
        .backgroundColor(this.tabColor) // tab的整体控件
      }
      .width('100%')
      .height('100%')
      .alignContent(Alignment.Bottom)
  }
}
