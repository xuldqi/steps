import { CommonTitleView } from '../view/CommonTitleView';
import { router, window } from '@kit.ArkUI';
import { SportTarget, Utils } from '../tools/Utils';
import { SubFragmentData } from '../view/SubFragment';
import { Log } from '../tools/Logger';
import preferencesUtil from '../tools/DataPreUtils';
import EntryAbility from '../entryability/EntryAbility';

@Entry
@Component
struct SportTargetSetPage {

  @State currentIndex:number = 0
  @State currentType:number = 0
  private pageScroller: Scroller = new Scroller()

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
      Scroll(this.pageScroller) {
        Column() {
          ForEach(Utils.getSportTargetList(), (item: SportTarget, index: number) => {
            Text(item.name)
              .backgroundColor(this.currentIndex === index ? '#0cc291' : '#F5F5F5')
              .fontColor(this.currentIndex === index ? '#FFFFFF' : '#222222')
              .fontSize(16)
              .fontWeight(500)
              .onClick(()=>{
                this.currentIndex = index
                preferencesUtil.putPreferenceValue('steps_ohos', 'SportTarget'+this.currentType, item.type)
            })
              .padding({ left: 20, right: 20, top: 14, bottom: 14 })
              .width('92%')
              .borderRadius(12)
              .margin({ bottom: 12 })
          })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 16, bottom: this.getSafeBottomPadding() })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  private getSafeBottomPadding(): number {
    if (!EntryAbility.myWindowClass) {
      return 24
    }
    const avoidArea = EntryAbility.myWindowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
    return avoidArea.bottomRect.height + 24
  }
}
