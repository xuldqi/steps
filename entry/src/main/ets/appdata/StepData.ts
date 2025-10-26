import { sensor } from '@kit.SensorServiceKit';
import { BusinessError, systemDateTime } from '@kit.BasicServicesKit';
import { Log } from '../tools/Logger';
import { ArrayList } from '@kit.ArkTS';
import { DateUtils } from '../tools/DateUtils';
import preferencesUtil from '../tools/DataPreUtils';
import appDataManager, { ModelCallback } from '../tools/AppDataManager';
import { PerStepModel } from './Model';

export interface StepsCallback {
  onSteps(steps: number)
};

class StepData{

  private isRegisterStep:boolean = false
  private _targetStepNum: number = 5000;

  public get targetStepNum(): number {
    return this._targetStepNum;
  }

  public set targetStepNum(value: number) {
    this._targetStepNum = value;
  }

  private lastCallbackSteps:number = -1;
  private isTodayFirstTime:boolean = true;
  private todaySteps:number = 0;

  private callbacks: ArrayList<StepsCallback> = new ArrayList<StepsCallback>();

  public addCallback(callback:StepsCallback){
    if(!this.callbacks.has(callback)){
      this.callbacks.add(callback)
    }
  }

  public removeCallback(callback:StepsCallback){
    if(this.callbacks.has(callback)){
      this.callbacks.remove(callback)
    }
  }

  public getCurrentSteps():number{
    return this.todaySteps
  }


  public registerStepCount() {
    try {
      if(this.isRegisterStep){
        Log.i('already  registerStepCount');
        return
      }
      sensor.on(sensor.SensorId.PEDOMETER, (data: sensor.PedometerResponse) => {
        Log.i('Succeeded in invoking on. Step count: ' + data.steps);

        if (this.isTodayFirstTime) {
          this.isTodayFirstTime = false;
          let currentDate = DateUtils.getYMD();
          preferencesUtil.putPreferenceValue('steps_ohos', 'is_today_first_time', currentDate)
          preferencesUtil.putPreferenceValue('steps_ohos', 'lastCallbackSteps', data.steps)
        }

        Log.i("StepsNum b今天的步数1:" + this.todaySteps + ",当前系统步数:" + data.steps + ",上次系统步数:" + this.lastCallbackSteps);
        if(this.lastCallbackSteps == -1){
          this.lastCallbackSteps = data.steps;
        }

        if(data.steps < this.lastCallbackSteps){
          this.lastCallbackSteps = data.steps;
        }
        //当前的系统步数-打开App时的系统步数+打开App时候的步数记录=当前步数
        this.todaySteps = this.todaySteps + data.steps - this.lastCallbackSteps;
        preferencesUtil.putPreferenceValue('steps_ohos', 'TODAY_TODAY_STEP_NUM', this.todaySteps)

        this.lastCallbackSteps = data.steps;
        preferencesUtil.putPreferenceValue('steps_ohos', 'lastCallbackSteps', data.steps)

        for (const item of this.callbacks) {
          item.onSteps(this.todaySteps)
        }
      }, { interval: 100000000 });
      this.isRegisterStep = true
    } catch (error) {
      let e: BusinessError = error as BusinessError;
      Log.e(`Failed to invoke on. Code: ${e.code}, message: ${e.message}`);
    }
  }

  private checkCallBack:ModelCallback<PerStepModel> = {
    onResult: (stepPerDayModel: PerStepModel): void => {
      if(stepPerDayModel == null) {
        appDataManager.insertStepPerDay(this.todaySteps);
        Log.i("StepsNum null:" + this.todaySteps);
      }else{
        stepPerDayModel.steps = this.todaySteps;
        appDataManager.updateStepPerDay(stepPerDayModel);
        Log.i("StepsNum has:"+ stepPerDayModel.toString());
      }

      for (const item of this.callbacks) {
        item.onSteps(this.todaySteps)
      }

    }
  }


  //判断是不是今天第一次打开，同步检查步数
  public async checkIsFirstOpenToday(){
      let currentDate = DateUtils.getYMD();//当前的日期
      let m = await preferencesUtil.getPreferenceValue('steps_ohos', 'is_today_first_time', '') as string;
      this.lastCallbackSteps = await preferencesUtil.getPreferenceValue('steps_ohos', 'lastCallbackSteps', -1) as number;
      Log.i("checkIsFirstOpenToday m:"+m+",currentDate:"+currentDate+",lastCallbackSteps:"+this.lastCallbackSteps);
      if(m !== currentDate){
        //今天第一次打开
        this.isTodayFirstTime = true;
        this.todaySteps = Math.floor(Math.random() * (400 - 50) + 50)
        preferencesUtil.putPreferenceValue('steps_ohos','TODAY_TODAY_STEP_NUM',this.todaySteps);
        preferencesUtil.putPreferenceValue('steps_ohos','STEP_NUM_LIMIT',1500);
      }else{
        //不是第一次打开
        this.todaySteps = await preferencesUtil.getPreferenceValue('steps_ohos', 'TODAY_TODAY_STEP_NUM', 0) as number;
        this.isTodayFirstTime = false;
      }
      appDataManager.getStepPerDay(currentDate,this.checkCallBack);
      Log.i("StepsNum registerStepListener");
  }

  public unRegisterStepCount() {
    try {
      sensor.off(sensor.SensorId.PEDOMETER);
      this.isRegisterStep = false
    } catch (error) {
      let e: BusinessError = error as BusinessError;
      Log.e(`Failed to invoke on. Code: ${e.code}, message: ${e.message}`);
    }
  }
}

const stepData = new StepData()

export default stepData as StepData