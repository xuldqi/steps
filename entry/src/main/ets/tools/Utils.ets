import { promptAction, router } from '@kit.ArkUI'
import { AppDataManager } from './AppDataManager'
import { abilityAccessCtrl, bundleManager, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Log } from './Logger';
import EntryAbility from '../entryability/EntryAbility';
import preferencesUtil from './DataPreUtils';

export interface SportTarget {
  name: string;
  value: number;
  type:number;
}

export class Utils{
  static permissions: Array<Permissions> = ['ohos.permission.ACTIVITY_MOTION'];

  static getMainCardIcon(type:number): Resource {
    switch (type){
      case 1:
        return $r('app.media.main_card_sport')
      case 2:
        return $r('app.media.main_card_cal')
      case 3:
        return $r('app.media.main_card_run')
      case 4:
        return $r('app.media.main_card_count_time')
      case 5:
        return $r('app.media.main_card_body_record')
      case 6:
        return $r('app.media.main_card_weight')
    }
    return $r('app.media.main_card_run')
  }

  static getMainCardStr(type:number): string {
    switch (type){
      case 1:
        return "走路距离"
      case 2:
        return "热量消耗"
      case 3:
        return "运动记录"
      case 4:
        return "时间计时"
      case 5:
        return "身体数据"
      case 6:
        return "体重记录"
    }
    return "运动记录"
  }

  /**
   * 根据类型获取数据单位
   * */
  public static getUnitByType(type:number){
    switch (type) {
      case AppDataManager.TYPE_HEIGHT:
        return "厘米";
      case AppDataManager.TYPE_WEIGHT:
        return "千克";
      case AppDataManager.TYPE_DTW:
        return "厘米";
      case AppDataManager.TYPE_SBW:
        return "厘米";
      case AppDataManager.TYPE_XW:
        return "厘米";
      case AppDataManager.TYPE_YW:
        return "厘米";
      case AppDataManager.TYPE_TW:
        return "厘米";
      case AppDataManager.TYPE_XTW:
        return "厘米";
    }
    return "";
  }

  static toMainCardPage(type:number) {
    Log.i('toMainCardPage called with type: ' + type)
    switch (type){
      case 1:
        Log.i('Navigating to DistanceTrendPage for walking distance')
        router.pushUrl({ url: 'pages/DistanceTrendPage' })
        return
      case 2:
        router.pushUrl({ url: 'pages/ChartPage' })
        return
      case 3:
        router.pushUrl({ url: 'pages/ExerciseRecordPage' })
        return
      case 4:
        router.pushUrl({ url: 'pages/CountTimePage' })
        return
      case 5:
        router.pushUrl({ url: 'pages/BodyDataPage' })
        return
      case 6:
        // 体重趋势
        router.pushUrl({ url: 'pages/WeightTrendPage' })
        return
    }
    return
  }

  static showToast(text:string){
    promptAction.showToast({
      message:text,
      duration:1600,
      bottom:150
    })
  }

  static getSubSportStartIcon(type:number): Resource {
    switch (type){
      case 1:
        return $r('app.media.sport_inside_run')
      case 2:
        return $r('app.media.sport_outside_run')
      case 3:
      case 4:
      case 5:
        return $r('app.media.start')
    }
    return $r('app.media.start')
  }

  static getSportTypeName(type:number): string {
    switch (type){
      case 1:
        return '室内跑'
      case 2:
        return '室外跑'
      case 3:
        return '健走'
      case 4:
        return '徒步'
      case 5:
        return '登山'
      case 6:
        return '骑行'
      case 7:
        return '瑜伽'
      case 8:
        return '跳绳'
    }
    return '室外跑'
  }

  static getSportRecordTitle(type:number): string {
    switch (type){
      case 0:
        return '所有记录'
      case 1:
        return '室内跑记录'
      case 2:
        return '室外跑记录'
      case 3:
        return '健走记录'
      case 4:
        return '徒步记录'
      case 5:
        return '登山记录'
      case 6:
        return '骑行记录'
      case 7:
        return '瑜伽记录'
      case 8:
        return '跳绳记录'
    }
    return '所有记录'
  }

  static getSportTypeList(): Array<SportTarget> {
    let list: Array<SportTarget> =
      [
        { name: '所有记录', value: 0,type:0 },
        { name: '室内跑记录', value: 0,type:1 },
        { name: '室外跑记录', value: 0,type:2 },
        { name: '健走记录', value: 0,type:3 },
        { name: '徒步记录', value: 0,type:4 },
        { name: '登山记录', value: 0,type:5 },
        { name: '骑行记录', value: 0,type:6 }
      ]
    return list;
  }

  static getSportTargetList(): Array<SportTarget> {
    let list: Array<SportTarget> =
      [
        { name: '自由', value: -1,type:0 },
        { name: '0.4公里', value: 400,type:1 },
        { name: '0.8公里', value: 800,type:2 },
        { name: '1.0公里', value: 1000,type:3 },
        { name: '2.0公里', value: 2000,type:4 },
        { name: '3.0公里', value: 3000,type:5 },
        { name: '4.0公里', value: 4000,type:6 },
        { name: '5.0公里', value: 5000,type:7 },
        { name: '6.0公里', value: 6000,type:8 },
        { name: '7.0公里', value: 7000,type:9 },
        { name: '8.0公里', value: 8000,type:10 },
        { name: '9.0公里', value: 9000,type:11 },
        { name: '10.0公里', value: 10000,type:12 },
        { name: '15.0公里', value: 15000,type:13 },
        { name: '21.5公里', value: 21500,type:14 },
        { name: '42.5公里', value: 42500,type:15 },
      ]
    return list;
  }

  static getKalByStep(step:number):string{
    let kmiles = (step)*0.6/1000;
    let times = kmiles*14;

    return ((times/60)*240).toFixed(2);
  }

  static getDistanceByStep(step:number):string{
    let kmiles = (step)*0.6/1000;
    return kmiles.toFixed(2);
  }

  static getBodyRecordIcon(type:number): Resource {
    switch (type){
      case AppDataManager.TYPE_HEIGHT:
        return $r('app.media.body_record_h')
      case AppDataManager.TYPE_WEIGHT:
        return $r('app.media.body_record_weight')
      case AppDataManager.TYPE_XW:
        return $r('app.media.body_record_xw')
      case AppDataManager.TYPE_YW:
        return $r('app.media.body_record_yw')
      case AppDataManager.TYPE_TW:
        return $r('app.media.body_record_tw')
      case AppDataManager.TYPE_SBW:
        return $r('app.media.body_record_sbw')
      case AppDataManager.TYPE_DTW:
        return $r('app.media.body_record_dtw')
      case AppDataManager.TYPE_XTW:
        return $r('app.media.body_record_xtw')
    }
    return $r('app.media.body_record_h')
  }

  static getBodyRecordName(type:number): string {
    switch (type){
      case AppDataManager.TYPE_HEIGHT:
        return '身高'
      case AppDataManager.TYPE_WEIGHT:
        return '体重'
      case AppDataManager.TYPE_XW:
        return '胸围'
      case AppDataManager.TYPE_YW:
        return '腰围'
      case AppDataManager.TYPE_TW:
        return '臀围'
      case AppDataManager.TYPE_SBW:
        return '上臂围'
      case AppDataManager.TYPE_DTW:
        return '大腿围'
      case AppDataManager.TYPE_XTW:
        return '小腿围'
    }
    return '小身高'
  }

  static getSportRecordIcon(type:number): Resource {
    switch (type){
      case 1:
        return $r('app.media.sport_indoor_run')
      case 2:
        return $r('app.media.sport_run')
      case 3:
        return $r('app.media.sport_go_walk')
      case 4:
        return $r('app.media.sport_walk_alone')
      case 5:
        return $r('app.media.sport_climb')
      case 6:
        return $r('app.media.sport_ride')
    }
    return $r('app.media.sport_indoor_run')
  }

  static getSportRecordName(type:number): string {
    switch (type){
      case 1:
        return '室内跑'
      case 2:
        return '室外跑'
      case 3:
        return '健走'
      case 4:
        return '徒步'
      case 5:
        return '登山'
      case 6:
        return '骑行'
    }
    return '室内跑'
  }

  //检查权限
  static async checkPermissionGrant(permission: Permissions): Promise<abilityAccessCtrl.GrantStatus> {
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;

    // 获取应用程序的accessTokenID
    let tokenId: number = 0;
    try {
      let bundleInfo: bundleManager.BundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
      tokenId = appInfo.accessTokenId;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      Log.e(`Failed to get bundle info for self. Code is ${err.code}, message is ${err.message}`);
    }

    // 校验应用是否被授予权限
    try {
      grantStatus = await atManager.checkAccessToken(tokenId, permission);
      Log.i('checkPermissionGrant grantStatus:'+grantStatus)
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      Log.e(`Failed to check access token. Code is ${err.code}, message is ${err.message}`);
    }

    return grantStatus;
  }

  //检查权限
  static async checkPermissions(): Promise<boolean> {
    let grantStatus: abilityAccessCtrl.GrantStatus = await Utils.checkPermissionGrant(Utils.permissions[0]);
    if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      Log.i('已有授权')
      return true
    } else {
      Log.i('未授权')
      return false
    }
  }
  //申请权限
  static async requestPermissions(): Promise<boolean> {
    try {
      let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
      let data = await atManager.requestPermissionsFromUser(EntryAbility.context, Utils.permissions)
      let grantStatus: Array<number> = data.authResults;
      let length: number = grantStatus.length;
      for (let i = 0; i < length; i++) {
        if (grantStatus[i] === 0) {
          return true
        } else {
          return false;
        }
      }
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      Log.e(`Failed to check access token. Code is ${err.code}, message is ${err.message}`);
    }
    return false
  }

  static async getStepTarget(): Promise<string>{
    let data = await preferencesUtil.getPreferenceValue('steps_ohos', 'step_target', '5000') as string
    return data
  }

  static keepScreenON(isOn:boolean){
    try {
      let promise = EntryAbility.myWindowClass.setWindowKeepScreenOn(isOn);
      promise.then(() => {
        Log.i('Succeeded in setting the screen to be always on.');
      }).catch((err: BusinessError) => {
        Log.e(`Failed to set the screen to be always on. Cause code: ${err.code}, message: ${err.message}`);
      });
    } catch (exception) {
      Log.e(`Failed to set the screen to be always on. Cause code: ${exception.code}, message: ${exception.message}`);
    }
  }
}
