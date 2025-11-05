import { AbilityConstant, common, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import preferencesUtil from '../tools/DataPreUtils'
import AppDataManager from '../tools/AppDataManager';
import StepData from '../appdata/StepData';
import { Log } from '../tools/Logger';
import { CloudDBService } from '../services/CloudDBService';


export default class EntryAbility extends UIAbility {

  static myWindowClass:window.Window
  static context: common.UIAbilityContext

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
    
    // 保存context
    EntryAbility.context = this.context
    
    // 初始化本地存储
    await preferencesUtil.loadPreference(this.context, 'steps_ohos')
    AppDataManager.initSqlData(this.context)
    
    // 初始化云服务
    try {
      // 忽略缺失的登录模块初始化，仅初始化云服务
      await CloudDBService.getInstance().init(this.context);
      Log.i('[EntryAbility] 云服务初始化成功');
    } catch (error) {
      Log.e('[EntryAbility] 云服务初始化失败:' + JSON.stringify(error));
    }
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    try {
      if(windowStage !== null && windowStage !== undefined){
        EntryAbility.myWindowClass = windowStage.getMainWindowSync();
        windowStage.loadContent('pages/Index', (err) => {
          if (err.code) {
            hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
            return;
          }
          hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
        });

        // 设置沉浸式状态栏
        EntryAbility.myWindowClass.setWindowLayoutFullScreen(true);
        
        // 设置状态栏可见
        EntryAbility.myWindowClass.setWindowSystemBarEnable(['status']);
        
        // 设置状态栏为透明，让页面背景色延伸
        const sysBarProps: window.SystemBarProperties = {
          statusBarColor: '#00000000', // 透明状态栏
          statusBarContentColor: '#000000' // 状态栏内容颜色为黑色
        };
        
        EntryAbility.myWindowClass.setWindowSystemBarProperties(sysBarProps);
        EntryAbility.myWindowClass.setWindowBackgroundColor('#F5F5F5');
        
        // 获取状态栏高度并设置页面顶部内边距
        const avoidArea = EntryAbility.myWindowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        const statusBarHeight = avoidArea.topRect.height;
        
        // 设置页面顶部内边距，避免内容被状态栏遮挡
        EntryAbility.myWindowClass.setWindowSystemBarProperties({
          statusBarColor: '#00000000',
          statusBarContentColor: '#000000'
        });
      }
    } catch (exception) {
      Log.e(`Failed to windowStage`);
    }
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    Log.i('Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    Log.i('Ability onBackground');
    StepData.checkIsFirstOpenToday()
  }
}
