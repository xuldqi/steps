import { DrawContext, RenderNode } from '@ohos.arkui.node';
import drawing from "@ohos.graphics.drawing"
import display from '@ohos.display';


export class RuleRenderNode extends RenderNode{


  draw(context : DrawContext) {
    let data = display.getDefaultDisplaySync()
    let w =data.width
    let h =data.width
    let dpi =data.densityDPI
    let dpiP =data.densityPixels //一英寸的像素点，一英寸等于2.45cm

    let m = dpi/25.4 //
    let n = dpi/10 //

    const canvas = context.canvas;
    const pen = new drawing.Pen();
    pen.setColor({alpha: 255, red: 0, green: 0, blue: 0});
    pen.setStrokeWidth(1);
    canvas.attachPen(pen);
    const font = new drawing.Font();
    font.setSize(30);
    let x = 15
    for(let i = 0;i<200;i++){ //偏移5像素
      if(i%5 ==0){
        if(i%10 ==0){
          const textBlob1 = drawing.TextBlob.makeFromString(i/10+'cm', font, drawing.TextEncoding.TEXT_ENCODING_UTF8);
          const textBlob2 = drawing.TextBlob.makeFromString(i/10+'inch', font, drawing.TextEncoding.TEXT_ENCODING_UTF8);
          canvas.drawTextBlob(textBlob1,135,i*m+x+7)
          canvas.drawTextBlob(textBlob2,w-210,i*n+x+7)
        }
        canvas.drawLine(0, i*m+x, 120, i*m+x);
        canvas.drawLine(w-120, i*n+x, w, i*n+x);
      }else{
        canvas.drawLine(0, i*m+x, 60, i*m+x);
        canvas.drawLine(w-60, i*n+x, w, i*n+x);
      }

    }


    canvas.detachPen();
  }
}
