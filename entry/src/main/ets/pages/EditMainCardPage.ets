import { router, window } from '@kit.ArkUI'
import { MainCardItemModel } from '../appdata/Model';
import mainCardManager from '../tools/MainCardManager'
import { MainCardManager } from '../tools/MainCardManager'
import { CommonTitleView } from '../view/CommonTitleView'
import { ArrayList } from '@kit.ArkTS';
import { Log } from '../tools/Logger';

interface DragPreviewOptions { builder: () => void; offsetX?: number; offsetY?: number }
interface DragEventEx { setDragPreviewOptions?: (options: DragPreviewOptions) => void }

@Entry
@Component
struct EditMainCardPage {
  @State mainCardItemModels:Array<MainCardItemModel> = new Array<MainCardItemModel>()
  @State dragIndex:number = -1
  @State isDragging: boolean = false

  // 自定义拖动预览构建器，使用灰色背景，尺寸为正常卡片的2倍（700x100）
  @Builder
  dragPreviewBuilder(item: MainCardItemModel, previewIndex: number) {
    Row(){
      Column() {
        Text(item.title)
          .layoutWeight(1)
          .fontSize(40)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
          .margin({ left: 48, right: 48 })

        Text(this.isPreviewInUpper(previewIndex) ? '拖动到已展示区域' : '拖动到未展示区域')
          .fontSize(20)
          .fontColor('rgba(255,255,255,0.8)')
          .margin({ left: 48, right: 48, top: 8 })
      }
      .layoutWeight(1)

      Image(item.isAdded?$r('app.media.main_card_del'):$r('app.media.main_card_add'))
        .width(64)
        .height(64)
        .margin({ right: 48 })
    }
    .width(640)
    .height(220)
    .backgroundColor(this.isPreviewInUpper(previewIndex) ? 'rgba(12,194,145,0.9)' : 'rgba(255,140,71,0.9)')
    .borderRadius(32)
    .border({ width: 3, color: this.isPreviewInUpper(previewIndex) ? '#0cc291' : '#FF8C47' })
    .shadow({ color: 'rgba(0,0,0,0.1)', radius: 24, offsetX: 0, offsetY: 12 })
    .alignItems(VerticalAlign.Center)
  }

  private isPreviewInUpper(previewIndex: number): boolean {
    const headDeleteIndex = this.getHeadIndex(MainCardManager.HEAD_DELETE)
    return headDeleteIndex < 0 ? true : previewIndex < headDeleteIndex
  }

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
                    Text(item.title)
                      .layoutWeight(1)
                      .margin({ left: 24 })
                      .fontSize(16)
                      .fontWeight(500)

                    Image(item.isAdded ? $r('app.media.main_card_del') : $r('app.media.main_card_add'))
                      .width(20)
                      .height(20)
                      .margin({ right: 24 })
                      .onClick(() => {
                        this.toggleCardVisibility(item, index)
                      })
                  }
                  .width('100%')
                  .height(56)
                  .backgroundColor('#FFFFFF')
                  .borderRadius(18)
                  .alignItems(VerticalAlign.Center)
                }.visibility(item.visible?Visibility.Visible:Visibility.Hidden)
                .width('100%')
                .padding({left:20,right:20,top:6,bottom:6})
                .onDragStart((event: DragEvent) => {
                  item.visible = false; // 拖拽时，设置子组件原位置图标不可见
                  this.isDragging = true
                  const e = event as DragEventEx
                  if (e?.setDragPreviewOptions) {
                    e.setDragPreviewOptions({
                      builder: () => {
                        this.dragPreviewBuilder(item, index)
                      },
                      offsetX: 0,
                      offsetY: 0
                    })
                    return
                  }
                  return () => {
                    this.dragPreviewBuilder(item, index)
                  }
                })
                .onDrop(() => {
                  // 当拖拽到当前位置时，使用当前项索引作为插入位置
                  if (this.dragIndex >= 0 && this.dragIndex < this.mainCardItemModels.length) {
                    this.mainCardItemModels[this.dragIndex].visible = true
                    this.changeIndex(this.dragIndex, index)
                    this.isDragging = false
                    this.dragIndex = -1
                  }
                })
                .onDragEnd(() => {
                  if (this.dragIndex >= 0 && this.dragIndex < this.mainCardItemModels.length) {
                    this.mainCardItemModels[this.dragIndex].visible = true
                  }
                  this.isDragging = false
                  this.dragIndex = -1
                })
                .onTouch((event: TouchEvent) => {
                  if (event.type === TouchType.Down) {
                    this.dragIndex = index;
                  }
                })

              }
            })
          }.width('100%').height('100%')
        }.width('100%').height('91%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.isDragging ? 'rgba(12,194,145,0.12)' : '#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isDragging ? 'rgba(12,194,145,0.12)' : '#F5F5F5')
  }

  toggleCardVisibility(item: MainCardItemModel, index: number) {
    const targetItem = this.mainCardItemModels[index]
    if (!targetItem) {
      return
    }

    const toggled = !targetItem.isAdded
    targetItem.isAdded = toggled
    targetItem.visible = true

    // 从原位置移除
    this.mainCardItemModels.splice(index, 1)

    // 重新插入到对应的分组位置
    const headDeleteIndex = this.getHeadIndex(MainCardManager.HEAD_DELETE)
    if (headDeleteIndex < 0) {
      Log.e('EditMainCardPage toggleCardVisibility: head delete index missing')
      return
    }

    if (toggled) {
      // 加入「已展示」列表，放在删除分隔符之前
      this.mainCardItemModels.splice(headDeleteIndex, 0, targetItem)
    } else {
      // 加入「未展示」列表，放在删除分隔符之后
      this.mainCardItemModels.splice(headDeleteIndex + 1, 0, targetItem)
    }

    Log.i(`Toggle card ${targetItem.title}: ${toggled ? 'added' : 'removed'}`)
    this.saveData()
  }

  changeIndex(dragIndex: number, insertIndex: number) {
    // 验证索引有效性
    if (dragIndex < 0 || dragIndex >= this.mainCardItemModels.length || 
        insertIndex < 0 || insertIndex >= this.mainCardItemModels.length) {
      Log.e(`EditMainCardPage changeIndex: Invalid index dragIndex=${dragIndex}, insertIndex=${insertIndex}`)
      return
    }

    let dragItem = this.mainCardItemModels[dragIndex]
    
    // 如果拖动的是分隔符，不允许移动
    if (dragItem.type === MainCardManager.HEAD_ADD || dragItem.type === MainCardManager.HEAD_DELETE) {
      Log.e(`EditMainCardPage changeIndex: Cannot drag header item`)
      return
    }

    const headDeleteIndex = this.getHeadIndex(MainCardManager.HEAD_DELETE)
    if (headDeleteIndex < 0) {
      Log.e(`EditMainCardPage changeIndex: Cannot find HEAD_DELETE index`)
      return
    }

    // 确定拖动前后所在的区域
    const dragInAdded = dragIndex < headDeleteIndex  // 拖动项是否在已展示区域
    let insertInAdded = insertIndex < headDeleteIndex  // 插入位置是否在已展示区域
    
    // 如果目标位置是分隔符，调整插入位置
    const targetItem = this.mainCardItemModels[insertIndex]
    if (targetItem.type === MainCardManager.HEAD_ADD || targetItem.type === MainCardManager.HEAD_DELETE) {
      // 拖动到分隔符位置，根据拖动方向决定插入位置
      if (dragInAdded) {
        // 从已展示区域拖动到分隔符，插入到分隔符前（保持在已展示）
        insertIndex = headDeleteIndex - 1
        insertInAdded = true
      } else {
        // 从未展示区域拖动到分隔符，插入到分隔符后（保持在未展示）
        insertIndex = headDeleteIndex + 1
        insertInAdded = false
      }
    }

    // 如果跨区域拖动，需要重新插入到对应区域
    if (dragInAdded !== insertInAdded) {
      Log.i(`EditMainCardPage changeIndex: Cross-region drag, dragInAdded=${dragInAdded}, insertInAdded=${insertInAdded}`)
      // 更新 isAdded 状态
      dragItem.isAdded = insertInAdded
      // 如果跨区域，需要从原位置删除，然后插入到新区域的正确位置
      this.mainCardItemModels.splice(dragIndex, 1)
      // 重新获取分隔符索引（因为删除了一个元素）
      const newHeadDeleteIndex = this.getHeadIndex(MainCardManager.HEAD_DELETE)
      if (newHeadDeleteIndex >= 0) {
        if (insertInAdded) {
          // 插入到已展示区域的最后（分隔符前）
          insertIndex = Math.max(0, newHeadDeleteIndex - 1)
        } else {
          // 插入到未展示区域的开始（分隔符后）
          insertIndex = newHeadDeleteIndex + 1
        }
      }
      this.mainCardItemModels.splice(insertIndex, 0, dragItem)
      this.saveData()
      return
    }

    // 同一区域内拖动，只改变顺序
    // 执行移动
    this.mainCardItemModels.splice(dragIndex, 1)
    // 如果插入位置在原位置之后，需要调整索引（因为删除了一个元素）
    if (insertIndex > dragIndex) {
      insertIndex -= 1
    }
    this.mainCardItemModels.splice(insertIndex, 0, dragItem);
    
    Log.i(`EditMainCardPage changeIndex: Moved item from ${dragIndex} to ${insertIndex} (same region)`)
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

  private getHeadIndex(type: number): number {
    for (let i = 0; i < this.mainCardItemModels.length; i++) {
      if (this.mainCardItemModels[i].type === type) {
        return i
      }
    }
    return -1
  }
}
