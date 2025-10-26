import { CommonTitleView } from '../view/CommonTitleView';
import { router } from '@kit.ArkUI';
import { SportTarget, Utils } from '../tools/Utils';
import { SubFragmentData } from '../view/SubFragment';
import { Log } from '../tools/Logger';
import preferencesUtil from '../tools/DataPreUtils';

@Entry
@Component
struct SportTargetSetPage {

  @State currentIndex:number = 0
  @State currentType:number = 0

  async onPageShow() {
    let params = router.getParams() as SubFragmentData;
    this.currentType = params.type
    Log.i('SportTargetSetPage Received: ' + this.currentType);
    this.currentIndex = await preferencesUtil.getPreferenceValue('steps_ohos', 'SportTarget'+this.currentType, 0) as number
  }

  build() {
    Column() {
      CommonTitleView({data1:{str1:"运动目标设置"},cancel: ()=> {
        router.back()
      }})
      Column(){
          ForEach(Utils.getSportTargetList(), (item: SportTarget, index: number) => {
            Text(item.name).backgroundColor(this.currentIndex === index?'#0cc291':'#ffeaeaea')
              .onClick(()=>{
                this.currentIndex = index
                preferencesUtil.putPreferenceValue('steps_ohos', 'SportTarget'+this.currentType, item.type)
            }).padding(8).width('100%')
          })
      }.width('100%').height('92%')
    }
  }
}