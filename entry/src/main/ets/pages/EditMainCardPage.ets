import { router } from '@kit.ArkUI'
import { MainCardItemModel } from '../appdata/Model';
import mainCardManager from '../tools/MainCardManager'
import { MainCardManager } from '../tools/MainCardManager'
import { CommonTitleView } from '../view/CommonTitleView'
import { ArrayList } from '@kit.ArkTS';
import { Log } from '../tools/Logger';

@Entry
@Component
struct EditMainCardPage {
  @State mainCardItemModels:Array<MainCardItemModel> = new Array<MainCardItemModel>()
  @State dragIndex:number = -1

  onPageShow(): void {
    this.mainCardItemModels.length = 0
    let mainCards:ArrayList<number> = mainCardManager.getCardSet();
    let headAdd:MainCardItemModel = { isAdded:false,type:MainCardManager.HEAD_ADD,title: mainCardManager.getType(MainCardManager.HEAD_ADD),visible:true};
    this.mainCardItemModels.push(headAdd);

    let orgItems:Array<number> = new Array<number>();
    orgItems.push(MainCardManager.STEPS_DISTANCE);
    orgItems.push(MainCardManager.STEPS_ENERGY);
    orgItems.push(MainCardManager.STEPS_SPORTS);
    orgItems.push(MainCardManager.STEPS_COUNT_TIME);
    orgItems.push(MainCardManager.STEPS_BODY_DATA);
    orgItems.push(MainCardManager.STEPS_WEIGHT);

    for (let model of mainCards){
      let mainCardItemModel:MainCardItemModel = {
        isAdded:true,
        type:model,
        title:mainCardManager.getType(model),
        visible:true
      }
      this.mainCardItemModels.push(mainCardItemModel);
      for(let i=0;i<orgItems.length;i++){
        if(model == orgItems[i]){
          orgItems.splice(i,1)
        }
      }
    }

    let headDelete:MainCardItemModel = { isAdded:false,type:MainCardManager.HEAD_DELETE,title: mainCardManager.getType(MainCardManager.HEAD_DELETE),visible:true};
    this.mainCardItemModels.push(headDelete);

    for (let model of orgItems){
      let mainCardItemModel:MainCardItemModel = {
        isAdded:false,
        type:model,
        title:mainCardManager.getType(model),
        visible:true
      }
      this.mainCardItemModels.push(mainCardItemModel);
    }
  }

  build() {
    Column() {
      Column() {
        CommonTitleView({data1:{str1:'编辑卡片'},str2:'长按可拖动顺序',cancel:()=>{
          router.back()
        }})
        Column(){
          List(){
            ForEach(this.mainCardItemModels, (item: MainCardItemModel, index: number) => {
              if(item.type === MainCardManager.HEAD_ADD || item.type === MainCardManager.HEAD_DELETE){
                ListItem(){
                  Text(item.title).fontColor('#ff757575').width('100%').textAlign(TextAlign.Start)
                }.width('100%').padding(15)
              }else{
                ListItem(){
                  Row(){
                    Text(item.title).layoutWeight(1).margin({left:20})
                    Image(item.isAdded?$r('app.media.main_card_del'):$r('app.media.main_card_add'))
                      .width(13)
                      .height(13)
                      .onClick(() => {
                        this.toggleCardVisibility(item, index)
                      })
                  }
                }.visibility(item.visible?Visibility.Visible:Visibility.Hidden)
                .width('100%').padding(15).onDragStart(() => {
                  item.visible = false; // 拖拽时，设置子组件原位置图标不可见
                }).onTouch((event: TouchEvent) => { // 拖拽释放时，记录目标位置子组件index值
                  if (event.type === TouchType.Down) {
                    this.dragIndex = index;
                  }
                })

              }
            })
          }.width('100%').height('100%').onDrop((event: DragEvent, extraParams: string) => {
            this.mainCardItemModels[this.dragIndex].visible = true;
            let insertIndex: number = JSON.parse(extraParams).insertIndex
            Log.i('dragIndex:'+this.dragIndex+',insertIndex:'+insertIndex)

            this.changeIndex(this.dragIndex, insertIndex); // 互换子组件index值
          })
        }.width('100%').height('91%')
      }
    }
  }

  toggleCardVisibility(item: MainCardItemModel, index: number) {
    // 切换卡片的展示状态
    item.isAdded = !item.isAdded
    Log.i(`Toggle card ${item.title}: ${item.isAdded ? 'added' : 'removed'}`)
    
    // 保存数据
    this.saveData()
  }

  changeIndex(dragIndex: number, insertIndex: number) {
    let dragItem = this.mainCardItemModels[dragIndex]
    for(let i = 0;i<this.mainCardItemModels.length;i++){
      if(this.mainCardItemModels[i].type == MainCardManager.HEAD_DELETE){
        Log.d("MainCard changeIndex:"+i);
        if(insertIndex>=i){
          dragItem.isAdded = false
        }else{
          dragItem.isAdded = true
        }
      }
    }
    this.mainCardItemModels.splice(dragIndex,1)
    this.mainCardItemModels.splice(insertIndex, 0, dragItem);
    this.saveData()
  }

  private saveData(){
    let data = "";
    for(let item of this.mainCardItemModels){
      if(item.isAdded){
        data = data+item.type+",";
      }
    }
    Log.i("MainCard saveData:"+data);
    mainCardManager.saveItemCardData(data);
  }
}