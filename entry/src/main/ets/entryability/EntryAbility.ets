import { AbilityConstant, common, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import preferencesUtil from '../tools/DataPreUtils'
import AppDataManager from '../tools/AppDataManager';
import StepData from '../appdata/StepData';
import { Log } from '../tools/Logger';
import { HuaweiAuthService } from '../services/HuaweiAuthService';
import { CloudDBService } from '../services/CloudDBService';


export default class EntryAbility extends UIAbility {

  static myWindowClass:window.Window
  static context: common.UIAbilityContext

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
    
    // 保存context
    EntryAbility.context = this.context
    
    // 初始化本地存储
    preferencesUtil.loadPreference(this.context, 'steps_ohos')
    AppDataManager.initSqlData(this.context)
    
    // 初始化云服务
    try {
      await HuaweiAuthService.getInstance().init(this.context);
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

        //windowClass.setWindowLayoutFullScreen(true)
        // 隐藏状态栏显示
        EntryAbility.myWindowClass.setWindowSystemBarEnable(['status'])
        EntryAbility.myWindowClass.setWindowBackgroundColor('#F5F5F5')
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
