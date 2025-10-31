import {Log} from '../tools/Logger'
import { SqlData } from '../appdata/SqlData';
import { Context } from '@kit.AbilityKit';
import { BusinessError, systemDateTime } from '@kit.BasicServicesKit';
import { relationalStore } from '@kit.ArkData';
import { DateUtils } from './DateUtils';
import { BodyRecordModel, Model, MoodLog, PerStepModel, SleepLog, SportModel, WaterLog, BowelLog, MenstruationLog } from '../appdata/Model';

export interface  SportDataStatus {
  isChange: boolean,
  type: number,
}

export interface DataCallback<T> {
  onDataResult:(type:number,result:Array<T>,isReturnFirstData:boolean,date?:string)=> void;
};

export interface ModelCallback<T> {
  onResult:(result:T,isEnd?:boolean,date?:string)=> void;
};

export interface AllSportCallback {
  onDataResult:(type:number,allDistance:string)=> void;
};

export class AppDataManager {


  public static readonly HEAD_ADD:number = 0;
  public static readonly HEAD_DELETE:number = -1;
  public static readonly STEPS_DISTANCE:number = 1;
  public static readonly STEPS_ENERGY:number = 2;
  public static readonly STEPS_SPORTS:number = 3;
  public static readonly STEPS_COUNT_TIME:number = 4;
  public static readonly STEPS_BODY_DATA:number = 5;
  public static readonly STEPS_WEIGHT:number = 6;

  public static readonly TYPE_BODY = 0;
  public static readonly TYPE_HEIGHT = 1;
  public static readonly TYPE_WEIGHT = 2;
  public static readonly TYPE_XW = 3;
  public static readonly TYPE_YW = 4;
  public static readonly TYPE_TW = 5;
  public static readonly TYPE_SBW = 6;
  public static readonly TYPE_DTW = 7;
  public static readonly TYPE_XTW = 8;

  private sqlData:SqlData = null;

  private sportDataStatus:SportDataStatus = {
    isChange: true,
    type: 0
  }

  //获取运动是否变化的标致
  public getSportDataStatus():SportDataStatus{
    return this.sportDataStatus
  }
  //设置运动是否变化的标致
  public setSportDataStatus(isChange:boolean,type:number){
    this.sportDataStatus.isChange = isChange
    this.sportDataStatus.type = type
  }
  //重置运动是否变化的标致
  public resetSportDataStatus(){
    this.sportDataStatus.isChange = false
    this.sportDataStatus.type = 0
  }

  /**
   * 初始化数据库
   * */
  public initSqlData(context: Context) {
    if(this.sqlData === null){
      this.sqlData = new SqlData()
    }
    this.sqlData.loadDataBase(context)
  }

  /**
   * 插入运动数据
   * */
  public insertSportRecord(startTime:number,useTime:number,steps:number,type:number,subType:number,cal:string,onSuccess?: () => void){
    let obj: relationalStore.ValuesBucket = {};
    obj.start_time = startTime;
    obj.use_time = useTime;
    obj.steps_num = steps;
    obj.type = type;
    obj.sub_type = subType;
    obj.cal = cal;
    Log.i(`insertSportRecord`);
    this.addDbData(SqlData.StepCountDbColumns_TB_NAME,obj, () => {
      this.setSportDataStatus(true, type)
      onSuccess?.()
    })
  }

  /**
   * 插入每天的步数数据
   * */
  public insertStepPerDay(steps:number){
    let obj: relationalStore.ValuesBucket = {};
    obj.time = systemDateTime.getTime();
    obj.date = DateUtils.getYMD();
    obj.step_count = steps;
    obj.backup1 = 0;
    obj.state = 0;
    Log.i(`insertStepPerDay`);
    this.addDbData(SqlData.StepPerDayDbColumns_TB_NAME,obj)
  }
  /**
   * 插入身体的信息数据
   * */
  public insertBodyRecord(type:number,data:string){
    let obj: relationalStore.ValuesBucket = {};
    obj.target_time = systemDateTime.getTime();
    obj.target_type = type;
    obj.data = data;
    obj.unit = this.getUnitByType(type);
    Log.i(`insertBodyRecord:`);
    this.addDbData(SqlData.BodayRecordColumns_TB_NAME,obj)
  }

  public insertWaterLog(amount: number, note: string = '') {
    const log: WaterLog = {
      id: 0,
      time: systemDateTime.getTime(),
      amount,
      note,
    }
    this.addDbData(SqlData.WaterLogColumns_TB_NAME, Model.getWaterLogValues(log))
  }

  public updateWaterLog(log: WaterLog) {
    if (this.sqlData == null) {
      Log.i('updateWaterLog error. sqlData null')
      return
    }
    const predicates = new relationalStore.RdbPredicates(SqlData.WaterLogColumns_TB_NAME)
    predicates.equalTo(SqlData.WaterLogColumns_COLUMN_ID, log.id)
    if (this.sqlData.getDbStore() !== undefined) {
      this.sqlData.getDbStore().update(Model.getWaterLogValues(log), predicates, (err: BusinessError, rows: number) => {
        if (err) {
          Log.e(`updateWaterLog error:${err.code}, msg:${err.message}`)
          return
        }
        Log.i(`updateWaterLog rows:${rows}`)
      })
    }
  }

  public deleteWaterLog(id: number) {
    this.deleteByTableAndId(SqlData.WaterLogColumns_TB_NAME, id)
  }

  public async getWaterLogsBetween(startTime: number, endTime: number): Promise<Array<WaterLog>> {
    return new Promise((resolve) => {
      const data: Array<WaterLog> = []
      const predicates = new relationalStore.RdbPredicates(SqlData.WaterLogColumns_TB_NAME)
      predicates.between(SqlData.WaterLogColumns_COLUMN_TIME, startTime, endTime)
      predicates.orderByDesc(SqlData.WaterLogColumns_COLUMN_TIME)
      if (this.sqlData.getDbStore() === undefined) {
        resolve(data)
        return
      }
      this.sqlData.getDbStore().query(predicates, [
        SqlData.WaterLogColumns_COLUMN_ID,
        SqlData.WaterLogColumns_COLUMN_TIME,
        SqlData.WaterLogColumns_COLUMN_AMOUNT,
        SqlData.WaterLogColumns_COLUMN_NOTE
      ], (err: BusinessError, resultSet) => {
        if (err) {
          Log.e(`getWaterLogsBetween error:${err.code}, msg:${err.message}`)
          resolve(data)
          return
        }
        while (resultSet.goToNextRow()) {
          data.push({
            id: resultSet.getLong(resultSet.getColumnIndex(SqlData.WaterLogColumns_COLUMN_ID)),
            time: resultSet.getLong(resultSet.getColumnIndex(SqlData.WaterLogColumns_COLUMN_TIME)),
            amount: resultSet.getLong(resultSet.getColumnIndex(SqlData.WaterLogColumns_COLUMN_AMOUNT)),
            note: resultSet.getString(resultSet.getColumnIndex(SqlData.WaterLogColumns_COLUMN_NOTE)) ?? ''
          })
        }
        resultSet.close()
        resolve(data)
      })
    })
  }

  public insertBowelLog(status: string, note: string = '') {
    const log: BowelLog = {
      id: 0,
      time: systemDateTime.getTime(),
      status,
      note,
    }
    this.addDbData(SqlData.BowelLogColumns_TB_NAME, Model.getBowelLogValues(log))
  }

  public updateBowelLog(log: BowelLog) {
    if (this.sqlData == null) {
      Log.i('updateBowelLog error. sqlData null')
      return
    }
    const predicates = new relationalStore.RdbPredicates(SqlData.BowelLogColumns_TB_NAME)
    predicates.equalTo(SqlData.BowelLogColumns_COLUMN_ID, log.id)
    if (this.sqlData.getDbStore() !== undefined) {
      this.sqlData.getDbStore().update(Model.getBowelLogValues(log), predicates, (err: BusinessError, rows: number) => {
        if (err) {
          Log.e(`updateBowelLog error:${err.code}, msg:${err.message}`)
          return
        }
        Log.i(`updateBowelLog rows:${rows}`)
      })
    }
  }

  public deleteBowelLog(id: number) {
    this.deleteByTableAndId(SqlData.BowelLogColumns_TB_NAME, id)
  }

  public async getBowelLogsBetween(startTime: number, endTime: number): Promise<Array<BowelLog>> {
    return new Promise((resolve) => {
      const data: Array<BowelLog> = []
      const predicates = new relationalStore.RdbPredicates(SqlData.BowelLogColumns_TB_NAME)
      predicates.between(SqlData.BowelLogColumns_COLUMN_TIME, startTime, endTime)
      predicates.orderByDesc(SqlData.BowelLogColumns_COLUMN_TIME)
      if (this.sqlData.getDbStore() === undefined) {
        resolve(data)
        return
      }
      this.sqlData.getDbStore().query(predicates, [
        SqlData.BowelLogColumns_COLUMN_ID,
        SqlData.BowelLogColumns_COLUMN_TIME,
        SqlData.BowelLogColumns_COLUMN_STATUS,
        SqlData.BowelLogColumns_COLUMN_NOTE
      ], (err: BusinessError, resultSet) => {
        if (err) {
          Log.e(`getBowelLogsBetween error:${err.code}, msg:${err.message}`)
          resolve(data)
          return
        }
        while (resultSet.goToNextRow()) {
          data.push({
            id: resultSet.getLong(resultSet.getColumnIndex(SqlData.BowelLogColumns_COLUMN_ID)),
            time: resultSet.getLong(resultSet.getColumnIndex(SqlData.BowelLogColumns_COLUMN_TIME)),
            status: resultSet.getString(resultSet.getColumnIndex(SqlData.BowelLogColumns_COLUMN_STATUS)) ?? '',
            note: resultSet.getString(resultSet.getColumnIndex(SqlData.BowelLogColumns_COLUMN_NOTE)) ?? ''
          })
        }
        resultSet.close()
        resolve(data)
      })
    })
  }

  public insertMenstruationLog(startTime: number, endTime: number, cycleLength: number, note: string = '') {
    const log: MenstruationLog = {
      id: 0,
      start_time: startTime,
      end_time: endTime,
      cycle_length: cycleLength,
      note,
    }
    this.addDbData(SqlData.MenstruationLogColumns_TB_NAME, Model.getMenstruationLogValues(log))
  }

  public updateMenstruationLog(log: MenstruationLog) {
    const predicates = new relationalStore.RdbPredicates(SqlData.MenstruationLogColumns_TB_NAME)
    predicates.equalTo(SqlData.MenstruationLogColumns_COLUMN_ID, log.id)
    if (this.sqlData.getDbStore() !== undefined) {
      this.sqlData.getDbStore().update(Model.getMenstruationLogValues(log), predicates, (err: BusinessError) => {
        if (err) {
          Log.e(`updateMenstruationLog error:${err.code}, msg:${err.message}`)
        }
      })
    }
  }

  public deleteMenstruationLog(id: number) {
    this.deleteByTableAndId(SqlData.MenstruationLogColumns_TB_NAME, id)
  }

  public async getMenstruationLogs(limit: number = 20): Promise<Array<MenstruationLog>> {
    return new Promise((resolve) => {
      const data: Array<MenstruationLog> = []
      const predicates = new relationalStore.RdbPredicates(SqlData.MenstruationLogColumns_TB_NAME)
      predicates.orderByDesc(SqlData.MenstruationLogColumns_COLUMN_START_TIME)
      if (limit > 0) {
        predicates.limitAs(limit)
      }
      if (this.sqlData.getDbStore() === undefined) {
        resolve(data)
        return
      }
      this.sqlData.getDbStore().query(predicates, [
        SqlData.MenstruationLogColumns_COLUMN_ID,
        SqlData.MenstruationLogColumns_COLUMN_START_TIME,
        SqlData.MenstruationLogColumns_COLUMN_END_TIME,
        SqlData.MenstruationLogColumns_COLUMN_CYCLE_LENGTH,
        SqlData.MenstruationLogColumns_COLUMN_NOTE
      ], (err: BusinessError, resultSet) => {
        if (err) {
          Log.e(`getMenstruationLogs error:${err.code}, msg:${err.message}`)
          resolve(data)
          return
        }
        while (resultSet.goToNextRow()) {
          data.push({
            id: resultSet.getLong(resultSet.getColumnIndex(SqlData.MenstruationLogColumns_COLUMN_ID)),
            start_time: resultSet.getLong(resultSet.getColumnIndex(SqlData.MenstruationLogColumns_COLUMN_START_TIME)),
            end_time: resultSet.getLong(resultSet.getColumnIndex(SqlData.MenstruationLogColumns_COLUMN_END_TIME)),
            cycle_length: resultSet.getLong(resultSet.getColumnIndex(SqlData.MenstruationLogColumns_COLUMN_CYCLE_LENGTH)),
            note: resultSet.getString(resultSet.getColumnIndex(SqlData.MenstruationLogColumns_COLUMN_NOTE)) ?? ''
          })
        }
        resultSet.close()
        resolve(data)
      })
    })
  }

  public insertSleepLog(startTime: number, endTime: number, quality: number, note: string = '') {
    const log: SleepLog = {
      id: 0,
      start_time: startTime,
      end_time: endTime,
      quality,
      note,
    }
    this.addDbData(SqlData.SleepLogColumns_TB_NAME, Model.getSleepLogValues(log))
  }

  public updateSleepLog(log: SleepLog) {
    const predicates = new relationalStore.RdbPredicates(SqlData.SleepLogColumns_TB_NAME)
    predicates.equalTo(SqlData.SleepLogColumns_COLUMN_ID, log.id)
    if (this.sqlData.getDbStore() !== undefined) {
      this.sqlData.getDbStore().update(Model.getSleepLogValues(log), predicates, (err: BusinessError) => {
        if (err) {
          Log.e(`updateSleepLog error:${err.code}, msg:${err.message}`)
        }
      })
    }
  }

  public deleteSleepLog(id: number) {
    this.deleteByTableAndId(SqlData.SleepLogColumns_TB_NAME, id)
  }

  public async getSleepLogsBetween(startTime: number, endTime: number): Promise<Array<SleepLog>> {
    return new Promise((resolve) => {
      const data: Array<SleepLog> = []
      const predicates = new relationalStore.RdbPredicates(SqlData.SleepLogColumns_TB_NAME)
      predicates.between(SqlData.SleepLogColumns_COLUMN_START_TIME, startTime, endTime)
      predicates.orderByDesc(SqlData.SleepLogColumns_COLUMN_START_TIME)
      if (this.sqlData.getDbStore() === undefined) {
        resolve(data)
        return
      }
      this.sqlData.getDbStore().query(predicates, [
        SqlData.SleepLogColumns_COLUMN_ID,
        SqlData.SleepLogColumns_COLUMN_START_TIME,
        SqlData.SleepLogColumns_COLUMN_END_TIME,
        SqlData.SleepLogColumns_COLUMN_QUALITY,
        SqlData.SleepLogColumns_COLUMN_NOTE
      ], (err: BusinessError, resultSet) => {
        if (err) {
          Log.e(`getSleepLogsBetween error:${err.code}, msg:${err.message}`)
          resolve(data)
          return
        }
        while (resultSet.goToNextRow()) {
          data.push({
            id: resultSet.getLong(resultSet.getColumnIndex(SqlData.SleepLogColumns_COLUMN_ID)),
            start_time: resultSet.getLong(resultSet.getColumnIndex(SqlData.SleepLogColumns_COLUMN_START_TIME)),
            end_time: resultSet.getLong(resultSet.getColumnIndex(SqlData.SleepLogColumns_COLUMN_END_TIME)),
            quality: resultSet.getLong(resultSet.getColumnIndex(SqlData.SleepLogColumns_COLUMN_QUALITY)),
            note: resultSet.getString(resultSet.getColumnIndex(SqlData.SleepLogColumns_COLUMN_NOTE)) ?? ''
          })
        }
        resultSet.close()
        resolve(data)
      })
    })
  }

  public insertMoodLog(score: number, note: string = '') {
    const log: MoodLog = {
      id: 0,
      time: systemDateTime.getTime(),
      score,
      note,
    }
    this.addDbData(SqlData.MoodLogColumns_TB_NAME, Model.getMoodLogValues(log))
  }

  public updateMoodLog(log: MoodLog) {
    const predicates = new relationalStore.RdbPredicates(SqlData.MoodLogColumns_TB_NAME)
    predicates.equalTo(SqlData.MoodLogColumns_COLUMN_ID, log.id)
    if (this.sqlData.getDbStore() !== undefined) {
      this.sqlData.getDbStore().update(Model.getMoodLogValues(log), predicates, (err: BusinessError) => {
        if (err) {
          Log.e(`updateMoodLog error:${err.code}, msg:${err.message}`)
        }
      })
    }
  }

  public deleteMoodLog(id: number) {
    this.deleteByTableAndId(SqlData.MoodLogColumns_TB_NAME, id)
  }

  public async getMoodLogsBetween(startTime: number, endTime: number): Promise<Array<MoodLog>> {
    return new Promise((resolve) => {
      const data: Array<MoodLog> = []
      const predicates = new relationalStore.RdbPredicates(SqlData.MoodLogColumns_TB_NAME)
      predicates.between(SqlData.MoodLogColumns_COLUMN_TIME, startTime, endTime)
      predicates.orderByDesc(SqlData.MoodLogColumns_COLUMN_TIME)
      if (this.sqlData.getDbStore() === undefined) {
        resolve(data)
        return
      }
      this.sqlData.getDbStore().query(predicates, [
        SqlData.MoodLogColumns_COLUMN_ID,
        SqlData.MoodLogColumns_COLUMN_TIME,
        SqlData.MoodLogColumns_COLUMN_SCORE,
        SqlData.MoodLogColumns_COLUMN_NOTE
      ], (err: BusinessError, resultSet) => {
        if (err) {
          Log.e(`getMoodLogsBetween error:${err.code}, msg:${err.message}`)
          resolve(data)
          return
        }
        while (resultSet.goToNextRow()) {
          data.push({
            id: resultSet.getLong(resultSet.getColumnIndex(SqlData.MoodLogColumns_COLUMN_ID)),
            time: resultSet.getLong(resultSet.getColumnIndex(SqlData.MoodLogColumns_COLUMN_TIME)),
            score: resultSet.getLong(resultSet.getColumnIndex(SqlData.MoodLogColumns_COLUMN_SCORE)),
            note: resultSet.getString(resultSet.getColumnIndex(SqlData.MoodLogColumns_COLUMN_NOTE)) ?? ''
          })
        }
        resultSet.close()
        resolve(data)
      })
    })
  }
  /**
   * 查询身体数据根据数据的类型
   * */
  public findBodyRecordByType(type:number,callback:DataCallback<BodyRecordModel>,isReturnFirstData:boolean){
    let predicates2 = new relationalStore.RdbPredicates(SqlData.BodayRecordColumns_TB_NAME);
    predicates2.equalTo(SqlData.BodayRecordColumns_COLUMN_TYPE, type);
    predicates2.orderByDesc(SqlData.BodayRecordColumns_COLUMN_TIME)
    this.sqlData.getDbStore().query(predicates2,
      [SqlData.BodayRecordColumns_COLUMN_ID,
        SqlData.BodayRecordColumns_COLUMN_TIME,
        SqlData.BodayRecordColumns_COLUMN_TYPE,
        SqlData.BodayRecordColumns_COLUMN_DATA,
        SqlData.BodayRecordColumns_COLUMN_UNIT], (err: BusinessError, resultSet) => {
      if (err) {
        Log.i(`Failed findBodyRecordByType. Code:${err.code}, message:${err.message}`);
        return;
      }
      Log.i(`findBodyRecordByType: ${resultSet.columnNames}, column count: ${resultSet.columnCount}`);
      let datas:Array<BodyRecordModel> = new Array<BodyRecordModel>();
      // resultSet是一个数据集合的游标，默认指向第-1个记录，有效的数据从0开始。
      while (resultSet.goToNextRow()) {
        let item:BodyRecordModel = {
          id:resultSet.getLong(resultSet.getColumnIndex(SqlData.BodayRecordColumns_COLUMN_ID)),
          time:resultSet.getLong(resultSet.getColumnIndex(SqlData.BodayRecordColumns_COLUMN_TIME)),
          type:resultSet.getLong(resultSet.getColumnIndex(SqlData.BodayRecordColumns_COLUMN_TYPE)),
          data:resultSet.getString(resultSet.getColumnIndex(SqlData.BodayRecordColumns_COLUMN_DATA)),
          unit:resultSet.getString(resultSet.getColumnIndex(SqlData.BodayRecordColumns_COLUMN_UNIT)),
        }
        datas.push(item)
        Log.i(`id=${item.id}, time=${item.time}, type=${item.type}, data=${item.data}, unit=${item.unit}`);
        if(isReturnFirstData){
          Log.i(`isReturnFirstData = true`);
          break
        }
      }
      resultSet.close();
      callback.onDataResult(type,datas,isReturnFirstData)
    })
  }

  /**
   * 查询身体数据根据数据的类型
   * */
  public findBodyRecordByTypeAndDate2(type:number,startTime:number,endTime:number,callback:DataCallback<BodyRecordModel>,isEnd:boolean){
    let predicates2 = new relationalStore.RdbPredicates(SqlData.BodayRecordColumns_TB_NAME);
    predicates2.equalTo(SqlData.BodayRecordColumns_COLUMN_TYPE, type);
    predicates2.between(SqlData.BodayRecordColumns_COLUMN_TIME,startTime,endTime)
    predicates2.orderByDesc(SqlData.BodayRecordColumns_COLUMN_TIME)
    this.sqlData.getDbStore().query(predicates2,
      [SqlData.BodayRecordColumns_COLUMN_ID,
        SqlData.BodayRecordColumns_COLUMN_TIME,
        SqlData.BodayRecordColumns_COLUMN_TYPE,
        SqlData.BodayRecordColumns_COLUMN_DATA,
        SqlData.BodayRecordColumns_COLUMN_UNIT], (err: BusinessError, resultSet) => {
        if (err) {
          Log.i(`Failed findBodyRecordByTypeAndDate. Code:${err.code}, message:${err.message}`);
          return;
        }
        Log.i(`findBodyRecordByTypeAndDate: ${resultSet.columnNames}, column count: ${resultSet.columnCount}`);
        let datas:Array<BodyRecordModel> = new Array<BodyRecordModel>();
        // resultSet是一个数据集合的游标，默认指向第-1个记录，有效的数据从0开始。
        while (resultSet.goToNextRow()) {
          let item:BodyRecordModel = {
            id:resultSet.getLong(resultSet.getColumnIndex(SqlData.BodayRecordColumns_COLUMN_ID)),
            time:resultSet.getLong(resultSet.getColumnIndex(SqlData.BodayRecordColumns_COLUMN_TIME)),
            type:resultSet.getLong(resultSet.getColumnIndex(SqlData.BodayRecordColumns_COLUMN_TYPE)),
            data:resultSet.getString(resultSet.getColumnIndex(SqlData.BodayRecordColumns_COLUMN_DATA)),
            unit:resultSet.getString(resultSet.getColumnIndex(SqlData.BodayRecordColumns_COLUMN_UNIT)),
          }
          datas.push(item)
          Log.i(`id=${item.id}, time=${item.time}, type=${item.type}, data=${item.data}, unit=${item.unit}`);
        }
        resultSet.close();
        callback.onDataResult(type,datas,isEnd,DateUtils.timeToDateNoYM2(startTime))
      })
  }

  /**
   * 查询身体数据根据数据的类型
   * */
  public findBodyRecordByTypeAndDate(type:number,startTime:number,endTime:number,callback:DataCallback<BodyRecordModel>){
    let predicates2 = new relationalStore.RdbPredicates(SqlData.BodayRecordColumns_TB_NAME);
    predicates2.equalTo(SqlData.BodayRecordColumns_COLUMN_TYPE, type);
    predicates2.between(SqlData.BodayRecordColumns_COLUMN_TIME,startTime,endTime)
    predicates2.orderByDesc(SqlData.BodayRecordColumns_COLUMN_TIME)
    this.sqlData.getDbStore().query(predicates2,
      [SqlData.BodayRecordColumns_COLUMN_ID,
        SqlData.BodayRecordColumns_COLUMN_TIME,
        SqlData.BodayRecordColumns_COLUMN_TYPE,
        SqlData.BodayRecordColumns_COLUMN_DATA,
        SqlData.BodayRecordColumns_COLUMN_UNIT], (err: BusinessError, resultSet) => {
        if (err) {
          Log.i(`Failed findBodyRecordByTypeAndDate. Code:${err.code}, message:${err.message}`);
          return;
        }
        Log.i(`findBodyRecordByTypeAndDate: ${resultSet.columnNames}, column count: ${resultSet.columnCount}`);
        let datas:Array<BodyRecordModel> = new Array<BodyRecordModel>();
        // resultSet是一个数据集合的游标，默认指向第-1个记录，有效的数据从0开始。
        while (resultSet.goToNextRow()) {
          let item:BodyRecordModel = {
            id:resultSet.getLong(resultSet.getColumnIndex(SqlData.BodayRecordColumns_COLUMN_ID)),
            time:resultSet.getLong(resultSet.getColumnIndex(SqlData.BodayRecordColumns_COLUMN_TIME)),
            type:resultSet.getLong(resultSet.getColumnIndex(SqlData.BodayRecordColumns_COLUMN_TYPE)),
            data:resultSet.getString(resultSet.getColumnIndex(SqlData.BodayRecordColumns_COLUMN_DATA)),
            unit:resultSet.getString(resultSet.getColumnIndex(SqlData.BodayRecordColumns_COLUMN_UNIT)),
          }
          datas.push(item)
          Log.i(`id=${item.id}, time=${item.time}, type=${item.type}, data=${item.data}, unit=${item.unit}`);
        }
        resultSet.close();
        callback.onDataResult(type,datas,false)
      })
  }
  /**
   * 查询运动数据根据运动的类型
   * */
  public findSportByType(type:number,callback:DataCallback<SportModel>,isReturnFirstData:boolean){
    let predicates2 = new relationalStore.RdbPredicates(SqlData.StepCountDbColumns_TB_NAME);
    if(type != 0){
      predicates2.equalTo(SqlData.StepCountDbColumns_COLUMN_TYPE, type);
    }
    predicates2.orderByAsc(SqlData.StepCountDbColumns_COLUMN_TIME)
    this.sqlData.getDbStore().query(predicates2,
      [SqlData.StepCountDbColumns_COLUMN_ID,
        SqlData.StepCountDbColumns_COLUMN_TYPE,
        SqlData.StepCountDbColumns_COLUMN_SUB_TYPE,
        SqlData.StepCountDbColumns_COLUMN_STEPS,
        SqlData.StepCountDbColumns_COLUMN_TIME,
        SqlData.StepCountDbColumns_COLUMN_USE_TIME,
        SqlData.StepCountDbColumns_COLUMN_CAL], (err: BusinessError, resultSet) => {
        if (err) {
          Log.i(`Failed findSportByType. Code:${err.code}, message:${err.message}`);
          return;
        }
        Log.i(`findSportByType: ${resultSet.columnNames}, column count: ${resultSet.columnCount}`);
        let datas:Array<SportModel> = new Array<SportModel>();
        // resultSet是一个数据集合的游标，默认指向第-1个记录，有效的数据从0开始。
        while (resultSet.goToNextRow()) {
          let item:SportModel = {
            id:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepCountDbColumns_COLUMN_ID)),
            type:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepCountDbColumns_COLUMN_TYPE)),
            sub_type:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepCountDbColumns_COLUMN_SUB_TYPE)),
            steps:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepCountDbColumns_COLUMN_STEPS)),
            start_time:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepCountDbColumns_COLUMN_TIME)),
            use_time:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepCountDbColumns_COLUMN_USE_TIME)),
            cal:resultSet.getString(resultSet.getColumnIndex(SqlData.StepCountDbColumns_COLUMN_CAL)),
          }
          datas.push(item)
          Log.i(`id=${item.id}, start_time=${item.start_time}, type=${item.type}, use_time=${item.use_time}, cal=${item.cal}`);
          if(isReturnFirstData){
            Log.i(`isReturnFirstData = true`);
            break
          }
        }
        resultSet.close();
        callback.onDataResult(type,datas,isReturnFirstData)
      })
  }
  /**
   * 查询所有的运动类型的总里程
   * */
  public findSportAllData(callback:AllSportCallback){
    let predicates2 = new relationalStore.RdbPredicates(SqlData.StepCountDbColumns_TB_NAME);
    predicates2.orderByAsc(SqlData.StepCountDbColumns_COLUMN_TIME)
    this.sqlData.getDbStore().query(predicates2,
      [SqlData.StepCountDbColumns_COLUMN_ID,
        SqlData.StepCountDbColumns_COLUMN_TYPE,
        SqlData.StepCountDbColumns_COLUMN_STEPS], (err: BusinessError, resultSet) => {
        if (err) {
          Log.i(`Failed findSportByType. Code:${err.code}, message:${err.message}`);
          return;
        }
        Log.i(`findSportByType: ${resultSet.columnNames}, column count: ${resultSet.columnCount}`);
        // resultSet是一个数据集合的游标，默认指向第-1个记录，有效的数据从0开始。
        let indoor = 0;
        let outdoor = 0;
        let walk = 0;
        let foot = 0;
        let climb = 0;
        while (resultSet.goToNextRow()) {
            let type = resultSet.getLong(resultSet.getColumnIndex(SqlData.StepCountDbColumns_COLUMN_TYPE))
            let steps = resultSet.getLong(resultSet.getColumnIndex(SqlData.StepCountDbColumns_COLUMN_STEPS))
            if(type === 1){
              indoor = indoor + steps
            }else if(type === 2){
              outdoor = outdoor + steps
            }else if(type === 3){
              walk = walk + steps
            }else if(type === 4){
              foot = foot + steps
            }else if(type === 5){
              climb = climb + steps
            }
        }
        callback.onDataResult(1,this.getDistanceByStep(indoor))
        callback.onDataResult(2,this.getDistanceByStep(outdoor))
        callback.onDataResult(3,this.getDistanceByStep(walk))
        callback.onDataResult(4,this.getDistanceByStep(foot))
        callback.onDataResult(5,this.getDistanceByStep(climb))
        resultSet.close();
      })
  }

  public getStepPerDay(date:string,callback:ModelCallback<PerStepModel>){
    let predicates2 = new relationalStore.RdbPredicates(SqlData.StepPerDayDbColumns_TB_NAME);
    predicates2.equalTo(SqlData.StepPerDayDbColumns_COLUMN_DATE, date);
    this.sqlData.getDbStore().query(predicates2,
      [SqlData.StepPerDayDbColumns_COLUMN_ID,
        SqlData.StepPerDayDbColumns_COLUMN_TIME,
        SqlData.StepPerDayDbColumns_COLUMN_DATE,
        SqlData.StepPerDayDbColumns_COLUMN_STEP_COUNT,
        SqlData.StepPerDayDbColumns_COLUMN_STATE,
        SqlData.StepPerDayDbColumns_COLUMN_BACKUP1], (err: BusinessError, resultSet) => {
        if (err) {
          Log.i(`Failed getStepPerDay. Code:${err.code}, message:${err.message}`);
          return;
        }
        Log.i(`getStepPerDay: ${resultSet.columnNames}, column count: ${resultSet.columnCount}`);
        let data:PerStepModel = null
        // resultSet是一个数据集合的游标，默认指向第-1个记录，有效的数据从0开始。
        while (resultSet.goToNextRow()) {
          data = {
            id:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_ID)),
            time:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_TIME)),
            date:resultSet.getString(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_DATE)),
            steps:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_STEP_COUNT)),
            state:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_STATE)),
            backup:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_BACKUP1)),
          }
          Log.i(`id=${data.id}, time=${data.date}, type=${data.steps}`);
        }
        resultSet.close();
        callback.onResult(data)
      })
  }

  public updateStepPerDay(model:PerStepModel){
    let predicates1 = new relationalStore.RdbPredicates(SqlData.StepPerDayDbColumns_TB_NAME); // 创建表'EMPLOYEE'的predicates
    predicates1.equalTo(SqlData.StepPerDayDbColumns_COLUMN_ID, model.id); // 匹配表'EMPLOYEE'中'NAME'为'Lisa'的字段
    if (this.sqlData.getDbStore() !== undefined) {
      this.sqlData.getDbStore().update(Model.getPerStepModel(model), predicates1, (err: BusinessError, rows: number) => {
        if (err) {
          Log.e(`updateStepPerDay. Code:${err.code}, message:${err.message}`);
          return;
        }
        Log.i(`Succeeded updateStepPerDay: ${rows}`);
      })
    }
  }

  /**
   * 步数换算距离
   * */
  private getDistanceByStep(step:number):string{
    let kmiles = (step)*0.6/1000;
    return kmiles.toFixed(2);
  }
  /**
   * 查插入数据
   * */
  private addDbData(table:string,valueBucket:relationalStore.ValuesBucket,onSuccess?: (rowId: number) => void){
    if(this.sqlData == null){
      Log.i(`addDbData error. sqlData null`);
    }
    if (this.sqlData.getDbStore() !== undefined) {
      this.sqlData.getDbStore().insert(table, valueBucket, (err: BusinessError, rowId: number) => {
        if (err) {
          Log.e(`Failed addDbData. Code:${err.code}, message:${err.message}`);
          return;
        }
        Log.i(`Succeeded addDbData. rowId:${rowId}`);
        onSuccess?.(rowId)
      })
    }
  }
  /**
   * 更新数据
   * */
  public updateBodyRecordItem(data:BodyRecordModel){
    let predicates1 = new relationalStore.RdbPredicates(SqlData.BodayRecordColumns_TB_NAME); // 创建表'EMPLOYEE'的predicates
    predicates1.equalTo(SqlData.BodayRecordColumns_COLUMN_ID, data.id); // 匹配表'EMPLOYEE'中'NAME'为'Lisa'的字段
    if (this.sqlData.getDbStore() !== undefined) {
      this.sqlData.getDbStore().update(Model.getBodyRecordModel(data), predicates1, (err: BusinessError, rows: number) => {
        if (err) {
          Log.e(`updateBodyRecordItem. Code:${err.code}, message:${err.message}`);
          return;
        }
        Log.i(`Succeeded updateBodyRecordItem: ${rows}`+`,data: ${data.data}`);
      })
    }
  }
  /**
   * 删除数据
   * */
  public deleteBodyRecordAndId(id:number){
    this.deleteByTableAndId(SqlData.BodayRecordColumns_TB_NAME,id)
  }
  /**
   * 删除数据
   * */
  private deleteByTableAndId(table:string,id:number){
    if(this.sqlData == null){
      Log.i(`deleteByTableAndId error. sqlData null`);
    }
    let predicates1 = new relationalStore.RdbPredicates(table);
    predicates1.equalTo('id', id);
    if (this.sqlData.getDbStore() !== undefined) {
      this.sqlData.getDbStore().delete(predicates1, (err: BusinessError, rows: number) => {
        if (err) {
          Log.e(`Failed deleteByTableAndId:${err.code}, message:${err.message}`);
          return;
        }
        Log.i(`deleteByTableAndId: ${rows}`);
      })
    }
  }

  public findAllByTypeWithDate(type:number,startTime:number,endTime:number,callback:DataCallback<SportModel>) {
    let predicates2 = new relationalStore.RdbPredicates(SqlData.StepCountDbColumns_TB_NAME);
    if(type != 0){
      predicates2.equalTo(SqlData.StepCountDbColumns_COLUMN_TYPE, type);
    }
    predicates2.between(SqlData.StepCountDbColumns_COLUMN_TIME,startTime,endTime)
    predicates2.orderByAsc(SqlData.StepCountDbColumns_COLUMN_TIME)
    this.sqlData.getDbStore().query(predicates2,
      [SqlData.StepCountDbColumns_COLUMN_ID,
        SqlData.StepCountDbColumns_COLUMN_TYPE,
        SqlData.StepCountDbColumns_COLUMN_SUB_TYPE,
        SqlData.StepCountDbColumns_COLUMN_STEPS,
        SqlData.StepCountDbColumns_COLUMN_TIME,
        SqlData.StepCountDbColumns_COLUMN_USE_TIME,
        SqlData.StepCountDbColumns_COLUMN_CAL], (err: BusinessError, resultSet) => {
        if (err) {
          Log.i(`Failed findAllByTypeWithDate. Code:${err.code}, message:${err.message}`);
          return;
        }
        Log.i(`findAllByTypeWithDate: ${resultSet.columnNames}, column count: ${resultSet.columnCount}`);
        let datas:Array<SportModel> = new Array<SportModel>();
        // resultSet是一个数据集合的游标，默认指向第-1个记录，有效的数据从0开始。
        while (resultSet.goToNextRow()) {
          let item:SportModel = {
            id:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepCountDbColumns_COLUMN_ID)),
            type:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepCountDbColumns_COLUMN_TYPE)),
            sub_type:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepCountDbColumns_COLUMN_SUB_TYPE)),
            steps:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepCountDbColumns_COLUMN_STEPS)),
            start_time:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepCountDbColumns_COLUMN_TIME)),
            use_time:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepCountDbColumns_COLUMN_USE_TIME)),
            cal:resultSet.getString(resultSet.getColumnIndex(SqlData.StepCountDbColumns_COLUMN_CAL)),
          }
          datas.push(item)
          Log.i(`id=${item.id}, start_time=${item.start_time}, type=${item.type}, use_time=${item.use_time}, cal=${item.cal}`);
        }
        resultSet.close();
        callback.onDataResult(type,datas,false)
      })
  }
  /**
   * 获取一周内的总步数
   * */
  public getStepPerDayWeek(callback:ModelCallback<number>){
    let predicates2 = new relationalStore.RdbPredicates(SqlData.StepPerDayDbColumns_TB_NAME);
    predicates2.in(SqlData.StepPerDayDbColumns_COLUMN_DATE, [DateUtils.getYMD_(0),DateUtils.getYMD_(1),
      DateUtils.getYMD_(2),DateUtils.getYMD_(3),DateUtils.getYMD_(4),DateUtils.getYMD_(5),DateUtils.getYMD_(6)]);
    this.sqlData.getDbStore().query(predicates2,
      [SqlData.StepPerDayDbColumns_COLUMN_DATE,
        SqlData.StepPerDayDbColumns_COLUMN_STEP_COUNT,], (err: BusinessError, resultSet) => {
        if (err) {
          Log.i(`Failed getStepPerDayWeek. Code:${err.code}, message:${err.message}`);
          return;
        }
        Log.i(`getStepPerDayWeek: ${resultSet.columnNames}, column count: ${resultSet.columnCount}`);
        let allSteps:number = 0
        while (resultSet.goToNextRow()) {
          let date = resultSet.getString(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_DATE))
          let steps = resultSet.getLong(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_STEP_COUNT))
          allSteps = allSteps+steps
        }
        callback.onResult(allSteps)
        resultSet.close();
      })
  }

  public getStepPerDayWeekList(callback:DataCallback<PerStepModel>){
    let predicates2 = new relationalStore.RdbPredicates(SqlData.StepPerDayDbColumns_TB_NAME);
    predicates2.in(SqlData.StepPerDayDbColumns_COLUMN_DATE, [DateUtils.getYMD_(0),DateUtils.getYMD_(1),
      DateUtils.getYMD_(2),DateUtils.getYMD_(3),DateUtils.getYMD_(4),DateUtils.getYMD_(5),DateUtils.getYMD_(6)]);
    this.sqlData.getDbStore().query(predicates2,
      [ SqlData.StepPerDayDbColumns_COLUMN_ID,
        SqlData.StepPerDayDbColumns_COLUMN_TIME,
        SqlData.StepPerDayDbColumns_COLUMN_DATE,
        SqlData.StepPerDayDbColumns_COLUMN_STATE,
        SqlData.StepPerDayDbColumns_COLUMN_BACKUP1,
        SqlData.StepPerDayDbColumns_COLUMN_STEP_COUNT,], (err: BusinessError, resultSet) => {
        if (err) {
          Log.i(`Failed getStepPerDayWeek. Code:${err.code}, message:${err.message}`);
          return;
        }
        Log.i(`getStepPerDayWeek: ${resultSet.columnNames}, column count: ${resultSet.columnCount}`);
        let datas:Array<PerStepModel> = new Array<PerStepModel>();
        // resultSet是一个数据集合的游标，默认指向第-1个记录，有效的数据从0开始。
        while (resultSet.goToNextRow()) {
          let data = {
            id:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_ID)),
            time:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_TIME)),
            date:resultSet.getString(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_DATE)),
            steps:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_STEP_COUNT)),
            state:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_STATE)),
            backup:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_BACKUP1)),
          }
          datas.push(data)
        }
        callback.onDataResult(0,datas,false)
        resultSet.close();
      })
  }

  /**
   * 获取一月内的总步数
   * */
  public getStepPerMonth(month:string,callback:ModelCallback<number>,isEnd:boolean){
    let predicates2 = new relationalStore.RdbPredicates(SqlData.StepPerDayDbColumns_TB_NAME);
    predicates2.like(SqlData.StepPerDayDbColumns_COLUMN_DATE, month);
    this.sqlData.getDbStore().query(predicates2,
      [SqlData.StepPerDayDbColumns_COLUMN_DATE,
        SqlData.StepPerDayDbColumns_COLUMN_STEP_COUNT,], (err: BusinessError, resultSet) => {
        if (err) {
          Log.i(`Failed getStepPerDay. Code:${err.code}, message:${err.message}`);
          return;
        }
        Log.i(`getStepPerDay: ${resultSet.columnNames}, column count: ${resultSet.columnCount}`);
        let allSteps:number = 0
        while (resultSet.goToNextRow()) {
          let date = resultSet.getString(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_DATE))
          let steps = resultSet.getLong(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_STEP_COUNT))
          allSteps = allSteps+steps
        }
        callback.onResult(allSteps,isEnd,month)
        resultSet.close();
      })
  }

  public getStepPerDayWeekList2(days:Array<string>,callback:DataCallback<PerStepModel>){
    let predicates2 = new relationalStore.RdbPredicates(SqlData.StepPerDayDbColumns_TB_NAME);
    predicates2.in(SqlData.StepPerDayDbColumns_COLUMN_DATE, [days[0],days[1],
      days[2],days[3],days[4],days[5],days[6]]);
    this.sqlData.getDbStore().query(predicates2,
      [ SqlData.StepPerDayDbColumns_COLUMN_ID,
        SqlData.StepPerDayDbColumns_COLUMN_TIME,
        SqlData.StepPerDayDbColumns_COLUMN_DATE,
        SqlData.StepPerDayDbColumns_COLUMN_STATE,
        SqlData.StepPerDayDbColumns_COLUMN_BACKUP1,
        SqlData.StepPerDayDbColumns_COLUMN_STEP_COUNT,], (err: BusinessError, resultSet) => {
        if (err) {
          Log.i(`Failed getStepPerDayWeek. Code:${err.code}, message:${err.message}`);
          return;
        }
        Log.i(`getStepPerDayWeek: ${resultSet.columnNames}, column count: ${resultSet.columnCount}`);
        let datas:Array<PerStepModel> = new Array<PerStepModel>();
        // resultSet是一个数据集合的游标，默认指向第-1个记录，有效的数据从0开始。
        while (resultSet.goToNextRow()) {
          let data = {
            id:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_ID)),
            time:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_TIME)),
            date:resultSet.getString(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_DATE)),
            steps:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_STEP_COUNT)),
            state:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_STATE)),
            backup:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_BACKUP1)),
          }
          datas.push(data)
          Log.i(`getStepPerDayWeek id: ${data.id}, steps: ${data.steps},date:${data.date}`);
        }
        callback.onDataResult(0,datas,false)
        resultSet.close();
      })
  }

  public getStepPerDayWeekList3(days:Array<string>,callback:DataCallback<PerStepModel>,isEnd:boolean){
    let predicates2 = new relationalStore.RdbPredicates(SqlData.StepPerDayDbColumns_TB_NAME);
    predicates2.in(SqlData.StepPerDayDbColumns_COLUMN_DATE, [days[0],days[1],
      days[2],days[3],days[4],days[5],days[6]]);
    this.sqlData.getDbStore().query(predicates2,
      [ SqlData.StepPerDayDbColumns_COLUMN_ID,
        SqlData.StepPerDayDbColumns_COLUMN_TIME,
        SqlData.StepPerDayDbColumns_COLUMN_DATE,
        SqlData.StepPerDayDbColumns_COLUMN_STATE,
        SqlData.StepPerDayDbColumns_COLUMN_BACKUP1,
        SqlData.StepPerDayDbColumns_COLUMN_STEP_COUNT,], (err: BusinessError, resultSet) => {
        if (err) {
          Log.i(`Failed getStepPerDayWeek. Code:${err.code}, message:${err.message}`);
          return;
        }
        Log.i(`getStepPerDayWeek: ${resultSet.columnNames}, column count: ${resultSet.columnCount}`);
        let datas:Array<PerStepModel> = new Array<PerStepModel>();
        // resultSet是一个数据集合的游标，默认指向第-1个记录，有效的数据从0开始。
        while (resultSet.goToNextRow()) {
          let data = {
            id:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_ID)),
            time:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_TIME)),
            date:resultSet.getString(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_DATE)),
            steps:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_STEP_COUNT)),
            state:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_STATE)),
            backup:resultSet.getLong(resultSet.getColumnIndex(SqlData.StepPerDayDbColumns_COLUMN_BACKUP1)),
          }
          datas.push(data)
          Log.i(`getStepPerDayWeek id: ${data.id}, steps: ${data.steps},date:${data.date}`);
        }
        callback.onDataResult(0,datas,isEnd,days[0])
        resultSet.close();
      })
  }

  /**
   * 根据类型获取数据单位
   * */
  public getUnitByType(type:number){
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

  /**
   * 根据类型获取主页卡片的次标题
   * */
  public getMainCardSubStr(type:number): string {
    switch (type){
      case 1:
        return "今日"
      case 2:
        return "今日"
      case 3:
        return "当前"
      case 4:
        return "秒表计时"
      case 5:
        return "身高"
      case 6:
        return "当前"

    }
    return "运动记录"
  }
  /**
   * 根据类型获取主页卡片的次内容
   * */
  public getMainCardSubData(type:number):string{
    switch (type){
      case 1:
        return "1.5公里"
      case 2:
        return "70千卡"
      case 3:
        return "5公里"
      case 4:
        return "倒计时"
      case 5:
        return "围度"
      case 6:
        return "70公斤"
    }
    return "";
  }

  public getMainCardSubDataSize(type:number):number{
    switch (type){
      case 1:
        return 16
      case 2:
        return 16
      case 3:
        return 16
      case 4:
        return 13
      case 5:
        return 13
      case 6:
        return 16
    }
    return 15;
  }

  public getMainCardSubDataWeight(type:number):number{
    switch (type){
      case 1:
        return 500
      case 2:
        return 500
      case 3:
        return 500
      case 4:
        return 300
      case 5:
        return 300
      case 6:
        return 500
    }
    return 15;
  }

  public hasMainCardLastData(type:number):boolean{
    switch (type){
      case 1:
      case 2:
      case 3:
      case 6:
        return true
      case 4:
      case 5:
        return false
    }
    return true;
  }

  public getMainCardLastTitle(type:number):string{
    switch (type){
      case 1:
        return "昨天"
      case 2:
        return "昨天"
      case 3:
        return "上次"
      case 4:
        return ""
      case 5:
        return ""
      case 6:
        return "上次"
    }
    return "";
  }

  public getMainCardLastData(type:number):string{
    switch (type){
      case 1:
        return "无数据"
      case 2:
        return "无数据"
      case 3:
        return "无数据"
      case 4:
        return ""
      case 5:
        return ""
      case 6:
        return "无数据"
    }
    return "";
  }
}


const appDataManager = new AppDataManager()

export default appDataManager as AppDataManager
