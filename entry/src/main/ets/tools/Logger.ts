
export class Log{
  static e(msg:string){
    console.error('Steps error:'+msg)
  }

  static i(msg:string){
    console.log('Steps info:'+msg)
  }

  static d(msg:string){
      console.debug('Steps debug:'+msg)
  }
}