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
        // 加载首页内容
        windowStage.loadContent('pages/Index', (err) => {
          if (err.code) {
            hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
            return;
          }
          hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
        });

        // 统一沉浸式：开启全屏，仅保留状态栏，由页面通过 SafeArea 顶部避让
        try {
          const mainWindow = windowStage.getMainWindowSync();
          EntryAbility.myWindowClass = mainWindow;
          // 全屏布局
          mainWindow.setWindowLayoutFullScreen(true);
          // 仅启用状态栏（不启用导航栏，依据业务需要可调整）
          mainWindow.setWindowSystemBarEnable(['status']);
          // 状态栏透明，内容延伸至顶部；具体前景色由各页面按背景调整
          mainWindow.setWindowSystemBarProperties({
            statusBarColor: '#00000000',
            statusBarContentColor: '#000000'
          });
        } catch (e) {
          Log.e('[EntryAbility] 设置沉浸式失败: ' + JSON.stringify(e));
        }
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
