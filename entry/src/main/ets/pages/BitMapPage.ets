import { CommonTitleView } from '../view/CommonTitleView'
import { router } from '@kit.ArkUI'

@Entry
@Component
struct BitMapPage {


  build() {
    Column() {
      Column() {
        CommonTitleView({data1:{str1:'分享'},cancel:()=>{
          router.back()
        }})
        Column(){

        }.width('100%').height('91%')
      }

    }
  }
}
