import Curves from '@ohos.curves'
import { display } from '@kit.ArkUI';
import { Log } from '../tools/Logger';

/**
* @Author Aleck
* @Date 8:53 2024/1/6
* @Desc 刻度尺控件
*/
@Entry
@Component
export default struct RuleView {
  @Prop mCurrentOffsetX: number = 0;
  private offsetX: number = 0;
  private mInit: boolean = false;
  private w: number = 0;
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private currentDate: Date = new Date();
  private unit:number = 4
  private unitNumer:number = 0;
  private currentValue:number = 5000
  private minX = 500;
  private maxX = 30000

  build() {
    Stack() {
      Column() {
        Canvas(this.context)
          .width('100%')
          .height('100%')
          .onReady(() => {
            let data = display.getDefaultDisplaySync()
            this.w = data.width
            this.unitNumer = Math.floor(this.w/this.unit)
            Log.i('onReady:'+this.offsetX);
            this.mInit = true;
            this.context.font = '20px sans-serif';
            this.onDraw()
          }).gesture(PanGesture().onActionStart(event => {
          Log.i('onActionStart0:'+this.offsetX);
          this.offsetX = event.offsetX;
          Log.i('onActionStart1:'+this.offsetX);
          this.currentDate = new Date();
        }).onActionUpdate(event => {
          this.mCurrentOffsetX += (event.offsetX - this.offsetX)
          this.offsetX = event.offsetX;
          const date = new Date();
          let cost = date.getTime() - this.currentDate.getTime();
          Log.i('onActionUpdate:'+this.offsetX+','+event.offsetX+','+this.offsetX);
          if (cost >= 50) {
            this.onDraw()
          }
        }).onActionEnd(event => {
          this.mCurrentOffsetX += (event.offsetX - this.offsetX)
          this.offsetX = event.offsetX;
          Log.i('onActionEnd:'+this.offsetX+','+event.offsetX+','+this.offsetX);
        }))
      }.width('100%').height(100)
      }

  }

  onDraw() {
    if (this.mInit) {
      this.context.clearRect(0,0,this.w,100)
      for(let i = 0;i<this.unitNumer;i++){
        this.context.beginPath();
        let xx = i*this.unit+this.unit+this.mCurrentOffsetX;
        this.context.moveTo(xx, 0);
        this.context.lineTo(xx, i%5==0?30:15);
        this.context.stroke();
        if(i%5==0){
          this.context.fillText(i+'', xx-2, 40);
        }
      }
    }
  }

}