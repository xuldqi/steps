import Curves from '@ohos.curves'

/**
* @Author Aleck
* @Date 8:53 2024/1/6
* @Desc 刻度尺控件
*/
@Entry
@Component
export default struct RuleView {
  //起始数值
  @Prop start:number|undefined = undefined;
  //终止数值
  @Prop end:number|undefined = undefined;
  //步长
  @Prop step:number|undefined = undefined;
  //当前刻度
  @Prop currentValue:number = 0
  //偏移量
  @State offsetX:number = 0;
  //刻度颜色
  @State ruleColor :string = '#c8c8c8';
  //中间标线颜色
  @State markColor :string = '#ff0000';

  //数值改变回调
  onUpdate:((value:string) => void)|undefined = undefined

  onFinish:((value:string) => void)|undefined = undefined


  //每个单位的步长
  private SPACING = 5;
  //标尺的宽度
  private RULE_WIDTH = 1;
  //阈值速度
  private MIN_INERTIA_SPEED = 200;
  //按下的时间
  private startPressTime:number = 0;
  //刻度总数
  private total:number|undefined = undefined;

  //按下的位置
  private lastTouchX : number|undefined = undefined;
  private pressDownX: number|undefined = undefined;

  private baseRuleHeight:number|undefined = undefined;
  //起始的绘制位置
  private startPaintX:number|undefined = undefined;
  //结束绘制位置
  private endPaintX:number|undefined = undefined
  //方向
  private symbol:number = 1

  //组件的宽和高
  private thisWidth:number|undefined = undefined;
  private thisHeight:number|undefined = undefined;

  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

  //惯性
  private inertiaCount = 80;
  private inertiaId:number|undefined = undefined
  private inertiaCurrent = 0;
  private inertiaStartSpeed = 10;

  private curve:ICurve|undefined = undefined
  startAutoAnimate() {
    if(this.inertiaId != undefined) {
      return
    }
    let curveValue = Curves.initCurve(Curve.EaseOut) // 创建一个默认先快后慢插值曲线
    this.inertiaId = setInterval(() => {
      this.inertiaCurrent++;
      if(this.inertiaCurrent == this.inertiaCount - 3) {
        //最后一帧补齐偏移量
        this.offsetX = this.computeRecentlyOffset();
        this.inertiaCurrent = this.inertiaCount;
        this.invalidate()
        return;
      }

      if(this.inertiaCurrent >= this.inertiaCount) {
        clearInterval(this.inertiaId)
        this.inertiaId = undefined;
        this.inertiaCurrent = 0;
        if(this.onUpdate != undefined) {
          this.onUpdate(this.computeValue())
        }
        return
      }
      let value: number = 1 - curveValue.interpolate(this.inertiaCurrent / this.inertiaCount);
      console.log(`startAutoAnimate : ${value} , ${this.symbol}`)
      this.offsetX += value * this.inertiaStartSpeed * this.symbol
      this.dealBoundary();
      if(this.onUpdate != undefined) {
        this.onUpdate(this.computeValue())
      }
      this.invalidate()
    },20)
  }


  /**
  * @Author Aleck
  * @Date 5:36 2024/1/7
  * @Desc 获取当前的位置
  */
  computeCurrentPos():number {
    let pos = Math.ceil(this.offsetX / (this.SPACING + this.RULE_WIDTH))
    pos = Math.abs(pos)
    let offside = Math.abs(this.offsetX % (this.SPACING + this.RULE_WIDTH)) - this.RULE_WIDTH

    if(Math.abs(offside) >= this.SPACING / 2) {
      pos++;
    }
    console.log(`computeRecentlyPos ${pos},${offside},${this.offsetX}`)
    return pos
  }


  /**
   * @Author Aleck
   * @Date 5:36 2024/1/7
   * @Desc 根据offset获取當前數值
   */
  computeValue():string {
    return (this.start!! + this.step!! * this.computeCurrentPos()).toFixed(1)
  }

  /**
  * @Author Aleck
  * @Date 6:30 2024/1/7
  * @Desc 根据当前的值计算位置
  */
  computeOffsetByValue():number {
    return (this.currentValue - this.start!!) / this.step!! * -(this.SPACING + this.RULE_WIDTH)
  }


  /**
  * @Author Aleck
  * @Date 5:39 2024/1/7
  * @Desc 获取自动吸附的偏移量
  */
  computeRecentlyOffset():number {
    let unitWidth = (this.SPACING + this.RULE_WIDTH)
    let pos = this.computeCurrentPos();
    return -pos * unitWidth;
  }

  /**
  * @Author Aleck
  * @Date 5:35 2024/1/7
  * @Desc 处理边界
  */
  dealBoundary() {
    if(this.offsetX >= 0) {
      this.offsetX = 0
    } else if(this.offsetX <= -this.endPaintX!!){
      this.offsetX = -this.endPaintX!!
    }
  }

  aboutToAppear() {
    this.curve = Curves.initCurve(Curve.EaseOut) // 创建一个默认先快后慢插值曲线
    console.log(`progress ${this.curve.interpolate(0.0)} , ${this.curve.interpolate(1.0)}`)
  }

  build() {
    Stack() {
      Column() {
        Canvas(this.context).onReady(() => {
        }).width('100%').height('100%')
          .onTouch((event) => {
            let touch = event.touches[0];
            if(touch.type == TouchType.Down) {
              clearInterval(this.inertiaId)
              this.lastTouchX = touch.x;
              this.pressDownX = touch.x
              this.inertiaId = undefined;
              this.inertiaCurrent = 0;
              this.startPressTime = Date.now()
            } else if(touch.type == TouchType.Move) {

              if(touch.x - this.lastTouchX!! >= 0) {
                this.symbol = 1;
              } else {
                this.symbol = -1;
              }
              this.offsetX += (touch.x - this.lastTouchX!!)
              if(this.offsetX >= 0) {
                this.offsetX = 0
              } else if(this.offsetX <= -this.endPaintX!!){
                this.offsetX = -this.endPaintX!!
              }
              if(this.onUpdate != undefined) {
                this.onUpdate(this.computeValue())
              }
              this.lastTouchX = touch.x
              this.invalidate();
            } else if(touch.type == TouchType.Up) {
              let between = Date.now() - this.startPressTime;
              console.log(`between ${between}`)
              let speed = Math.abs(touch.x - this.pressDownX!!) / (between / 1000);
              if(between < 500 && speed > this.MIN_INERTIA_SPEED) {
                //快速滑动
                this.inertiaStartSpeed = speed / (this.MIN_INERTIA_SPEED) * 5
                this.startAutoAnimate()
              } else {
                //吸附
                this.offsetX = this.computeRecentlyOffset();
                console.log(`computeRecentlyOffset ${this.offsetX} ,${(this.SPACING + this.RULE_WIDTH)}`)
                if(this.onUpdate != undefined) {
                  this.onUpdate(this.computeValue())
                }
                this.invalidate()
              }
              this.lastTouchX = undefined;
              this.pressDownX = undefined;
            }
            console.log(`touch ${touch.x} - ${touch.y}`)
          })
      }.onAreaChange((oldArea,newArea) => {
        this.thisWidth = newArea.width.valueOf() as number;
        this.thisHeight = newArea.height.valueOf() as number
        this.baseRuleHeight = 0.6 * this.thisHeight;
        this.startPaintX = this.thisWidth / 2;

        this.total = (this.end!! - this.start!!) / this.step!!;
        this.endPaintX = (this.SPACING + this.RULE_WIDTH) * this.total
        this.offsetX = this.computeOffsetByValue();
        console.log(`invalidate : ${this.offsetX} `)
        if(this.onUpdate != undefined) {
          this.onUpdate(this.computeValue())
        }
        this.invalidate()
      })
      Divider().backgroundColor(this.markColor).width(1).height('100%')
    }
  }

  //重绘
  invalidate() {
    //当前绘制位置
    let pos = this.startPaintX!! + this.offsetX;
    console.log(`invalidate : ${pos}`)

    this.context.clearRect(0,0,this.thisWidth,this.thisHeight);
    for(let index = 0;index <= this.total!! ;index++) {
        this.context.beginPath()
        this.context.lineWidth = this.RULE_WIDTH;
        this.context.strokeStyle = this.ruleColor
        this.context.fillStyle = this.ruleColor
        this.context.textAlign = 'center'
        this.context.font = '30px sans-serif'
         this.context.lineCap = 'round'
        this.context.moveTo(pos,0);
        let ruleHeight = this.baseRuleHeight
        if(index % 10 == 0) {
          //逢10
          let text = `${this.start!! + (index * this.step!!)}`
          this.context.fillText(text,pos,ruleHeight!! + 10)
        } else if(index % 5 == 0) {
          //逢5
          ruleHeight!! *= 0.8
        } else {
          //普通
          ruleHeight!! *= 0.5
        }
        this.context.lineTo(pos,ruleHeight);
        this.context.stroke()
      pos += this.SPACING + this.RULE_WIDTH;
    }
  }

}