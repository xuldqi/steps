import {Log} from '../tools/Logger'
import preferencesUtil from './DataPreUtils';
import { ArrayList } from '@kit.ArkTS';

export class MainCardManager {


  public static readonly HEAD_ADD:number = 0;
  public static readonly HEAD_DELETE:number = -1;
  public static readonly STEPS_DISTANCE:number = 1;
  public static readonly STEPS_ENERGY:number = 2;
  public static readonly STEPS_SPORTS:number = 3;
  public static readonly STEPS_COUNT_TIME:number = 4;
  public static readonly STEPS_BODY_DATA:number = 5;
  public static readonly STEPS_WEIGHT:number = 6;
  public static readonly STEPS_CARD_STORE_KEY:string = "STEPS_CARD_STORE_KEY";
  private defaultShowCard:string = "1,2,3,4,5,6,";
  private set = new ArrayList<number>();
  private isMainCardChanged:boolean = true;

  public async loadMainCardManager(){
    let dataStr:string = await preferencesUtil.getPreferenceValue('steps_ohos', MainCardManager.STEPS_CARD_STORE_KEY, this.defaultShowCard) as string
    Log.i("MainCardManager init:"+dataStr);
    let items:string[] = dataStr.split(",");
    if(items.length>0){
      for (let i=0;i<items.length;i++){
        Log.i("MainCardManager items:"+items[i]);
        if(items[i].trim() != null && items[i].trim() !="") {
          this.set.add(parseInt(items[i]));
          Log.i("MainCardManager items:"+this.set[this.set.length-1]);
        }
      }
    }
  }

  public saveItemCardData( types:string){
    this.isMainCardChanged = true;
    preferencesUtil.putPreferenceValue('steps_ohos', MainCardManager.STEPS_CARD_STORE_KEY, types)

    this.set.clear();
    let items:string[] = types.split(",");
    if(items.length>0){
      for (let i=0;i<items.length;i++){
        Log.i("saveItemCardData items:"+items[i]);
        if(items[i].trim() != null && items[i].trim() !="") {
          this.set.add(parseInt(items[i]));
          Log.i("saveItemCardData items:"+this.set[this.set.length-1]);

        }
      }
    }
    this.setMainCardChangedCreate()
  }

  public getType(type:number):string {
    switch (type){
      case MainCardManager.HEAD_ADD:
        return "已展示数据";
      case MainCardManager.HEAD_DELETE:
        return "未展示数据";
      case MainCardManager.STEPS_DISTANCE:
        return  "走路距离";
      case MainCardManager.STEPS_ENERGY:
        return "热量消耗";
      case MainCardManager.STEPS_SPORTS:
        return "运动记录";
      case MainCardManager.STEPS_COUNT_TIME:
        return "时间计时";
      case MainCardManager.STEPS_BODY_DATA:
        return "体重记录";
      case MainCardManager.STEPS_WEIGHT:
        return  "身体数据";
    }
  }



  public getMainCardChanged():boolean {
    return this.isMainCardChanged;
  }

  public setMainCardChangedAlreadyUpdate() {
    this.isMainCardChanged = false;
  }

  public setMainCardChangedCreate() {
    this.isMainCardChanged = true;
  }

  public isItemCardShow(type:number):boolean{
    return this.set.has(type)
  }

  public getCardSet():ArrayList<number>{
    return this.set;
  }
}


const mainCardManager = new MainCardManager()

export default mainCardManager as MainCardManager