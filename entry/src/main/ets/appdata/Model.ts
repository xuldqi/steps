import { relationalStore } from '@kit.ArkData';

export interface BodyRecordModel {
  id: number,
  time: number,
  type: number,
  data: string,
  unit: string,

}

export interface SportModel {
  id: number,
  type: number,
  sub_type: number,
  start_time: number,
  use_time: number,
  steps: number,
  cal: string,
}

export interface WaterLog {
  id: number,
  time: number,
  amount: number,
  note: string,
}

export interface BowelLog {
  id: number,
  time: number,
  status: string,
  note: string,
}

export interface MenstruationLog {
  id: number,
  start_time: number,
  end_time: number,
  cycle_length: number,
  note: string,
}

export interface SleepLog {
  id: number,
  start_time: number,
  end_time: number,
  quality: number,
  note: string,
}

export interface MoodLog {
  id: number,
  time: number,
  score: number,
  note: string,
}

export interface PerStepModel {
  id: number,
  state: number,
  date:string,
  steps: number,
  backup: number,
  time: number,
}

export interface MainCardItemModel {
  type: number,
  isAdded: boolean,
  title:string,
  visible:boolean,
}

export class Model{

  public static getBodyRecordModel(data:BodyRecordModel):relationalStore.ValuesBucket{
    let obj: relationalStore.ValuesBucket = {};
    obj.id = data.id;
    obj.target_time = data.time;
    obj.target_type = data.type;
    obj.data = data.data;
    obj.unit = data.unit;
    return obj
  }

  public static getSportModel(data:SportModel):relationalStore.ValuesBucket{
    let obj: relationalStore.ValuesBucket = {};
    obj.id = data.id;
    obj.type = data.type;
    obj.sub_type = data.sub_type;
    obj.start_time = data.start_time;
    obj.use_time = data.use_time;
    obj.steps_num = data.steps;
    obj.cal = data.cal;
    return obj
  }

  public static getPerStepModel(data:PerStepModel):relationalStore.ValuesBucket{
    let obj: relationalStore.ValuesBucket = {};
    obj.ID = data.id;
    obj.state = data.state;
    obj.date = data.date;
    obj.step_count = data.steps;
    obj.backup1 = data.backup;
    obj.time = data.time;
    return obj
  }

  public static getWaterLogValues(data: WaterLog): relationalStore.ValuesBucket {
    let obj: relationalStore.ValuesBucket = {}
    obj.time = data.time
    obj.amount = data.amount
    obj.note = data.note
    return obj
  }

  public static getBowelLogValues(data: BowelLog): relationalStore.ValuesBucket {
    let obj: relationalStore.ValuesBucket = {}
    obj.time = data.time
    obj.status = data.status
    obj.note = data.note
    return obj
  }

  public static getMenstruationLogValues(data: MenstruationLog): relationalStore.ValuesBucket {
    let obj: relationalStore.ValuesBucket = {}
    obj.start_time = data.start_time
    obj.end_time = data.end_time
    obj.cycle_length = data.cycle_length
    obj.note = data.note
    return obj
  }

  public static getSleepLogValues(data: SleepLog): relationalStore.ValuesBucket {
    let obj: relationalStore.ValuesBucket = {}
    obj.start_time = data.start_time
    obj.end_time = data.end_time
    obj.quality = data.quality
    obj.note = data.note
    return obj
  }

  public static getMoodLogValues(data: MoodLog): relationalStore.ValuesBucket {
    let obj: relationalStore.ValuesBucket = {}
    obj.time = data.time
    obj.score = data.score
    obj.note = data.note
    return obj
  }

}
