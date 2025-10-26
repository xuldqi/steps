import { relationalStore } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { Log } from '../tools/Logger';


export class SqlData{

  public static readonly DB_NAME:string = "steps.db";
  public static readonly DB_VERSION:number = 2;
  public static readonly TABLE_NAME_STEP:string = "steps_count";
  public static readonly TABLE_NAME_TARGET:string = "target";
  public static readonly TABLE_NAME_BODAY_RECORD:string = "boday_record";
  public static readonly TABLE_STEP_PER_DAY:string = "step_per_day";
  public static readonly TABLE_WATER_LOG:string = "water_log";
  public static readonly TABLE_BOWEL_LOG:string = "bowel_log";
  public static readonly TABLE_MENSTRUATION_LOG:string = "menstruation_log";
  public static readonly TABLE_SLEEP_LOG:string = "sleep_log";
  public static readonly TABLE_MOOD_LOG:string = "mood_log";
  private rdbStore:relationalStore.RdbStore = null;

  private readonly STORE_CONFIG :relationalStore.StoreConfig= {
    name: SqlData.DB_NAME, // 数据库文件名
    securityLevel: relationalStore.SecurityLevel.S3, // 数据库安全级别
    encrypt: false, // 可选参数，指定数据库是否加密，默认不加密
    isReadOnly: false // 该参数默认为false，表示数据库可读可写。
  };


  // table name
  public static readonly StepCountDbColumns_TB_NAME = SqlData.TABLE_NAME_STEP;
  public static readonly StepCountDbColumns_COLUMN_ID = "ID";
  public static readonly StepCountDbColumns_COLUMN_TIME = "start_time";
  public static readonly StepCountDbColumns_COLUMN_USE_TIME = "use_time";
  public static readonly StepCountDbColumns_COLUMN_STEPS = "steps_num";
  public static readonly StepCountDbColumns_COLUMN_TYPE = "type";
  public static readonly StepCountDbColumns_COLUMN_SUB_TYPE = "sub_type";
  public static readonly StepCountDbColumns_COLUMN_SPEED = "speed";
  public static readonly StepCountDbColumns_COLUMN_CAL = "cal";
  public static readonly StepCountDbColumns_COLUMN_STATUS = "Cstatus";
  public static readonly StepCountDbColumns_COLUMN_SYNC1 = "sync1";
  public static readonly StepCountDbColumns_COLUMN_SYNC2 = "sync2";
  public static readonly StepCountDbColumns_COLUMN_DISTANCE = "distance";

  // table name
  public static readonly StepPerDayDbColumns_TB_NAME = SqlData.TABLE_STEP_PER_DAY;
  public static readonly StepPerDayDbColumns_COLUMN_ID = "ID";
  public static readonly StepPerDayDbColumns_COLUMN_DATE = "date";
  public static readonly StepPerDayDbColumns_COLUMN_STEP_COUNT = "step_count";
  public static readonly StepPerDayDbColumns_COLUMN_TIME = "time";
  public static readonly StepPerDayDbColumns_COLUMN_STATE = "state";
  public static readonly StepPerDayDbColumns_COLUMN_BACKUP1 = "backup1";

  // table name
  public static readonly TargetColumns_TB_NAME = SqlData.TABLE_NAME_TARGET;
  public static readonly TargetColumns_COLUMN_ID = "ID";
  public static readonly TargetColumns_COLUMN_NAME = "target_name";
  public static readonly TargetColumns_COLUMN_HINT = "target_hint";
  public static readonly TargetColumns_COLUMN_ALL_TIMES = "target_all_times";
  public static readonly TargetColumns_COLUMN_FINISH_TIMES = "target_finish_times";
  public static readonly TargetColumns_COLUMN_IS_LOOP = "is_loop";
  public static readonly TargetColumns_COLUMN_ACHIEVE_DATA_LIST = "achieve_data_list";
  public static readonly TargetColumns_COLUMN_CREATE_DATE = "start_time";
  public static readonly TargetColumns_COLUMN_LAST_DATE = "last_time";
  public static readonly TargetColumns_COLUMN_TARGET_DATE = "target_time";
  public static readonly TargetColumns_COLUMN_TARGET_TYPE = "target_type";
  public static readonly TargetColumns_COLUMN_TARGET_SYNC1 = "target_sync1";
  public static readonly TargetColumns_COLUMN_TARGET_SYNC2 = "target_sync2";
  public static readonly TargetColumns_COLUMN_TARGET_SYNC3 = "target_sync3";
  public static readonly TargetColumns_COLUMN_TARGET_SYNC4 = "target_sync4";

  // table name
  public static readonly BodayRecordColumns_TB_NAME = SqlData.TABLE_NAME_BODAY_RECORD;
  public static readonly BodayRecordColumns_COLUMN_ID = "ID";
  public static readonly BodayRecordColumns_COLUMN_TIME = "target_time";
  public static readonly BodayRecordColumns_COLUMN_TYPE = "target_type";
  public static readonly BodayRecordColumns_COLUMN_DATA = "data";
  public static readonly BodayRecordColumns_COLUMN_UNIT = "unit";

  public static readonly WaterLogColumns_TB_NAME = SqlData.TABLE_WATER_LOG;
  public static readonly WaterLogColumns_COLUMN_ID = "ID";
  public static readonly WaterLogColumns_COLUMN_TIME = "time";
  public static readonly WaterLogColumns_COLUMN_AMOUNT = "amount";
  public static readonly WaterLogColumns_COLUMN_NOTE = "note";

  public static readonly BowelLogColumns_TB_NAME = SqlData.TABLE_BOWEL_LOG;
  public static readonly BowelLogColumns_COLUMN_ID = "ID";
  public static readonly BowelLogColumns_COLUMN_TIME = "time";
  public static readonly BowelLogColumns_COLUMN_STATUS = "status";
  public static readonly BowelLogColumns_COLUMN_NOTE = "note";

  public static readonly MenstruationLogColumns_TB_NAME = SqlData.TABLE_MENSTRUATION_LOG;
  public static readonly MenstruationLogColumns_COLUMN_ID = "ID";
  public static readonly MenstruationLogColumns_COLUMN_START_TIME = "start_time";
  public static readonly MenstruationLogColumns_COLUMN_END_TIME = "end_time";
  public static readonly MenstruationLogColumns_COLUMN_CYCLE_LENGTH = "cycle_length";
  public static readonly MenstruationLogColumns_COLUMN_NOTE = "note";

  public static readonly SleepLogColumns_TB_NAME = SqlData.TABLE_SLEEP_LOG;
  public static readonly SleepLogColumns_COLUMN_ID = "ID";
  public static readonly SleepLogColumns_COLUMN_START_TIME = "start_time";
  public static readonly SleepLogColumns_COLUMN_END_TIME = "end_time";
  public static readonly SleepLogColumns_COLUMN_QUALITY = "quality";
  public static readonly SleepLogColumns_COLUMN_NOTE = "note";

  public static readonly MoodLogColumns_TB_NAME = SqlData.TABLE_MOOD_LOG;
  public static readonly MoodLogColumns_COLUMN_ID = "ID";
  public static readonly MoodLogColumns_COLUMN_TIME = "time";
  public static readonly MoodLogColumns_COLUMN_SCORE = "score";
  public static readonly MoodLogColumns_COLUMN_NOTE = "note";

  loadDataBase(context: Context) {
    Log.i('---------loadDataBase---------');
    relationalStore.getRdbStore(context, this.STORE_CONFIG, (err, store) => {
      if (err) {
        Log.i(`Failed to get RdbStore. Code:${err.code}, message:${err.message}`);
        return;
      }

      this.rdbStore = (store as relationalStore.RdbStore)
      Log.i('Succeeded in getting RdbStore.');

      if (store.version === 0) {
        store.executeSql(this.createStepCountDatabase());
        store.executeSql(this.createStepPerDayDatabase());
        store.executeSql(this.createTargetDatabase());
        store.executeSql(this.createBodayRecordDatabase());
        store.executeSql(this.createWaterLogTable());
        store.executeSql(this.createBowelLogTable());
        store.executeSql(this.createMenstruationLogTable());
        store.executeSql(this.createSleepLogTable());
        store.executeSql(this.createMoodLogTable());
        store.version = SqlData.DB_VERSION;
      } else if (store.version < SqlData.DB_VERSION) {
        if (store.version < 2) {
          store.executeSql(this.createWaterLogTable());
          store.executeSql(this.createBowelLogTable());
          store.executeSql(this.createMenstruationLogTable());
          store.executeSql(this.createSleepLogTable());
          store.executeSql(this.createMoodLogTable());
        }
        store.version = SqlData.DB_VERSION;
      }
    });

    // 请确保获取到RdbStore实例后，再进行数据库的增、删、改、查等操作
  }

  private createStepCountDatabase(){
    let textSb:string = '';
    textSb = "CREATE TABLE IF NOT EXISTS ";
    textSb = textSb.concat(SqlData.StepCountDbColumns_TB_NAME);
    textSb = textSb.concat("(");
    textSb = textSb.concat(SqlData.StepCountDbColumns_COLUMN_ID + " INTEGER PRIMARY KEY AUTOINCREMENT, ");
    textSb = textSb.concat(SqlData.StepCountDbColumns_COLUMN_TIME + " INTEGER DEFAULT 0,");
    textSb = textSb.concat(SqlData.StepCountDbColumns_COLUMN_USE_TIME + " INTEGER DEFAULT 0,");
    textSb = textSb.concat(SqlData.StepCountDbColumns_COLUMN_STEPS + " INTEGER DEFAULT 0,");
    textSb = textSb.concat(SqlData.StepCountDbColumns_COLUMN_TYPE + " INTEGER DEFAULT 0,");
    textSb = textSb.concat(SqlData.StepCountDbColumns_COLUMN_SUB_TYPE + " INTEGER DEFAULT 0,");
    textSb = textSb.concat(SqlData.StepCountDbColumns_COLUMN_SPEED + " TEXT,");//备选4
    textSb = textSb.concat(SqlData.StepCountDbColumns_COLUMN_STATUS + " TEXT,");
    textSb = textSb.concat(SqlData.StepCountDbColumns_COLUMN_CAL + " TEXT,");
    textSb = textSb.concat(SqlData.StepCountDbColumns_COLUMN_SYNC1 + " TEXT,");
    textSb = textSb.concat(SqlData.StepCountDbColumns_COLUMN_SYNC2 + " TEXT,");
    textSb = textSb.concat(SqlData.StepCountDbColumns_COLUMN_DISTANCE + " TEXT");
    textSb = textSb.concat(")");
    return textSb;
  }

  private createStepPerDayDatabase(){
    let textSb:string = '';
    textSb = "CREATE TABLE IF NOT EXISTS ";
    textSb = textSb.concat(SqlData.StepPerDayDbColumns_TB_NAME);
    textSb = textSb.concat("(");
    textSb = textSb.concat(SqlData.StepPerDayDbColumns_COLUMN_ID + " INTEGER PRIMARY KEY AUTOINCREMENT, ");
    textSb = textSb.concat(SqlData.StepPerDayDbColumns_COLUMN_DATE + " TEXT,");
    textSb = textSb.concat(SqlData.StepPerDayDbColumns_COLUMN_TIME + " INTEGER DEFAULT 0,");
    textSb = textSb.concat(SqlData.StepPerDayDbColumns_COLUMN_STEP_COUNT + " INTEGER DEFAULT 0,");
    textSb = textSb.concat(SqlData.StepPerDayDbColumns_COLUMN_STATE + " INTEGER DEFAULT 0,");
    textSb = textSb.concat(SqlData.StepPerDayDbColumns_COLUMN_BACKUP1 + " INTEGER DEFAULT 0");
    textSb = textSb.concat(")");
    return textSb;
  }

  private createTargetDatabase(){
    let textSb:string = '';
    textSb = "CREATE TABLE IF NOT EXISTS ";
    textSb = textSb.concat(SqlData.TargetColumns_TB_NAME);
    textSb = textSb.concat("(");
    textSb = textSb.concat(SqlData.TargetColumns_COLUMN_ID + " INTEGER PRIMARY KEY AUTOINCREMENT, ");
    textSb = textSb.concat(SqlData.TargetColumns_COLUMN_NAME + " TEXT,");//标题
    textSb = textSb.concat(SqlData.TargetColumns_COLUMN_HINT + " TEXT,");//副标题
    textSb = textSb.concat(SqlData.TargetColumns_COLUMN_ALL_TIMES + " INTEGER DEFAULT 1,");//限制的完成次数，默认1
    textSb = textSb.concat(SqlData.TargetColumns_COLUMN_FINISH_TIMES + " INTEGER DEFAULT 0,");//已完成次数，默认0
    textSb = textSb.concat(SqlData.TargetColumns_COLUMN_IS_LOOP + " INTEGER DEFAULT 0,");//是否是无线循环任务
    textSb = textSb.concat(SqlData.TargetColumns_COLUMN_ACHIEVE_DATA_LIST + " TEXT,");//完成的循环任务或者多次任务的时间列表
    textSb = textSb.concat(SqlData.TargetColumns_COLUMN_CREATE_DATE + " INTEGER DEFAULT 0,");//创建的时间
    textSb = textSb.concat(SqlData.TargetColumns_COLUMN_LAST_DATE + " INTEGER DEFAULT 0,");//最后一次完成的时间
    textSb = textSb.concat(SqlData.TargetColumns_COLUMN_TARGET_DATE + " INTEGER DEFAULT 0,");//目标日期
    textSb = textSb.concat(SqlData.TargetColumns_COLUMN_TARGET_TYPE + " INTEGER DEFAULT 0,");//目标类型，默认0
    textSb = textSb.concat(SqlData.TargetColumns_COLUMN_TARGET_SYNC1 + " TEXT,");//备选1
    textSb = textSb.concat(SqlData.TargetColumns_COLUMN_TARGET_SYNC2 + " TEXT,");//备选2
    textSb = textSb.concat(SqlData.TargetColumns_COLUMN_TARGET_SYNC3 + " TEXT,");//备选3
    textSb = textSb.concat(SqlData.TargetColumns_COLUMN_TARGET_SYNC4 + " TEXT");//备选4
    textSb = textSb.concat(")");
    return textSb;
  }

  private createBodayRecordDatabase(){
    let textSb:string = '';
    textSb = "CREATE TABLE IF NOT EXISTS ";
    textSb = textSb.concat(SqlData.BodayRecordColumns_TB_NAME);
    textSb = textSb.concat("(");
    textSb = textSb.concat(SqlData.BodayRecordColumns_COLUMN_ID + " INTEGER PRIMARY KEY AUTOINCREMENT, ");
    textSb = textSb.concat(SqlData.BodayRecordColumns_COLUMN_TIME + " INTEGER DEFAULT 0,");
    textSb = textSb.concat(SqlData.BodayRecordColumns_COLUMN_TYPE + " INTEGER DEFAULT 0,");
    textSb = textSb.concat(SqlData.BodayRecordColumns_COLUMN_DATA + " TEXT,");
    textSb = textSb.concat(SqlData.BodayRecordColumns_COLUMN_UNIT + " TEXT");
    textSb = textSb.concat(")");
    Log.i('body textSb:'+textSb)
    return textSb;
  }

  private createWaterLogTable() {
    let sql = "CREATE TABLE IF NOT EXISTS " + SqlData.WaterLogColumns_TB_NAME + "(" +
      SqlData.WaterLogColumns_COLUMN_ID + " INTEGER PRIMARY KEY AUTOINCREMENT, " +
      SqlData.WaterLogColumns_COLUMN_TIME + " INTEGER DEFAULT 0," +
      SqlData.WaterLogColumns_COLUMN_AMOUNT + " INTEGER DEFAULT 0," +
      SqlData.WaterLogColumns_COLUMN_NOTE + " TEXT" +
      ")"
    return sql
  }

  private createBowelLogTable() {
    let sql = "CREATE TABLE IF NOT EXISTS " + SqlData.BowelLogColumns_TB_NAME + "(" +
      SqlData.BowelLogColumns_COLUMN_ID + " INTEGER PRIMARY KEY AUTOINCREMENT, " +
      SqlData.BowelLogColumns_COLUMN_TIME + " INTEGER DEFAULT 0," +
      SqlData.BowelLogColumns_COLUMN_STATUS + " TEXT," +
      SqlData.BowelLogColumns_COLUMN_NOTE + " TEXT" +
      ")"
    return sql
  }

  private createMenstruationLogTable() {
    let sql = "CREATE TABLE IF NOT EXISTS " + SqlData.MenstruationLogColumns_TB_NAME + "(" +
      SqlData.MenstruationLogColumns_COLUMN_ID + " INTEGER PRIMARY KEY AUTOINCREMENT, " +
      SqlData.MenstruationLogColumns_COLUMN_START_TIME + " INTEGER DEFAULT 0," +
      SqlData.MenstruationLogColumns_COLUMN_END_TIME + " INTEGER DEFAULT 0," +
      SqlData.MenstruationLogColumns_COLUMN_CYCLE_LENGTH + " INTEGER DEFAULT 28," +
      SqlData.MenstruationLogColumns_COLUMN_NOTE + " TEXT" +
      ")"
    return sql
  }

  private createSleepLogTable() {
    let sql = "CREATE TABLE IF NOT EXISTS " + SqlData.SleepLogColumns_TB_NAME + "(" +
      SqlData.SleepLogColumns_COLUMN_ID + " INTEGER PRIMARY KEY AUTOINCREMENT, " +
      SqlData.SleepLogColumns_COLUMN_START_TIME + " INTEGER DEFAULT 0," +
      SqlData.SleepLogColumns_COLUMN_END_TIME + " INTEGER DEFAULT 0," +
      SqlData.SleepLogColumns_COLUMN_QUALITY + " INTEGER DEFAULT 3," +
      SqlData.SleepLogColumns_COLUMN_NOTE + " TEXT" +
      ")"
    return sql
  }

  private createMoodLogTable() {
    let sql = "CREATE TABLE IF NOT EXISTS " + SqlData.MoodLogColumns_TB_NAME + "(" +
      SqlData.MoodLogColumns_COLUMN_ID + " INTEGER PRIMARY KEY AUTOINCREMENT, " +
      SqlData.MoodLogColumns_COLUMN_TIME + " INTEGER DEFAULT 0," +
      SqlData.MoodLogColumns_COLUMN_SCORE + " INTEGER DEFAULT 3," +
      SqlData.MoodLogColumns_COLUMN_NOTE + " TEXT" +
      ")"
    return sql
  }

  public getDbStore(){
    if(this.rdbStore === null){
      Log.i('getDbStore error,db store is null')
    }
    return this.rdbStore
  }
}
