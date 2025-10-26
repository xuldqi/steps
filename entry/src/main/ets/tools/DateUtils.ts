// import dayjs from "dayjs"; // 暂时注释，使用原生Date
// import { systemDateTime } from "@kit.BasicServicesKit"; // 暂时注释
import { Log } from "./Logger";

export class DateUtils{
  public static getYMD(){
    let calendar = new Date();
    let year = calendar.getFullYear();//获取年份
    let month = calendar.getMonth()+1;//获取月份
    let day = calendar.getDate();//获取日
    let temp = year.toString();
    if(month < 10){
      temp += "/0"+month;
    }else {
      temp += "/"+month;
    }
    if (day < 10){
      temp += "/0"+day;
    }else {
      temp += "/"+day;
    }
    return temp;
  }

  public static getYMD_(offset:number){
    let date = new Date(Date.now() - 24*60*60*1000*offset);
    let year = date.getFullYear();
    let month = date.getMonth() + 1;
    let day = date.getDate();
    return `${year}/${month.toString().padStart(2, '0')}/${day.toString().padStart(2, '0')}`;
  }

  public static getYMDCH(offset:number):string{
    let date = new Date(Date.now() - 24*60*60*1000*offset);
    let year = date.getFullYear();
    let month = date.getMonth() + 1;
    let day = date.getDate();
    return `${year}年${month}月${day}日`;
  }

  public static getWeek(pTime:string) {
    let date = new Date(pTime);
    let m = date.getDay();

    if (m == 0) {
      return "周日";
    }
    if (m == 1) {
      return "周一";
    }
    if (m == 2) {
      return "周二";
    }
    if (m == 3) {
      return "周三";
    }
    if (m == 4) {
      return "周四";
    }
    if (m == 5) {
      return "周五";
    }
    if (m == 6) {
      return "周六";
    }
    return "周一";
  }

  public static timeToDate(time:number){
    let calendar = new Date(time);
    let year = calendar.getFullYear();//获取年份
    let month = calendar.getMonth()+1;//获取月份
    let day = calendar.getDate();//获取日
    let hour = calendar.getHours();//获取日
    let min = calendar.getMinutes();//获取日
    let temp = year.toString();

    temp += "年"+month;
    temp += "月"+day;
    temp += "日 "+hour;
    temp += "时"+min+"分";

    return temp;
  }

  public static timeToDateNoYM(time:number){
    let calendar = new Date(time);
    let year = calendar.getFullYear();//获取年份
    let month = calendar.getMonth()+1;//获取月份
    let day = calendar.getDate();//获取日
    let hour = calendar.getHours();//获取日
    let temp = year.toString();

    temp += "年"+month;
    temp += "月"+day;
    temp += "日 "+hour;
    temp += "时"

    return temp;
  }

  public static timeToDateNoYM2(time:number){
    let calendar = new Date(time);
    let year = calendar.getFullYear();//获取年份
    let month = calendar.getMonth()+1;//获取月份
    let day = calendar.getDate();//获取日
    let temp = year.toString();
    if(month < 10){
      temp += "/0"+month;
    }else {
      temp += "/"+month;
    }
    if (day < 10){
      temp += "/0"+day;
    }else {
      temp += "/"+day;
    }
    return temp;
  }

  public static timeToDateNoY(time:number){
    let calendar = new Date(time);
    let month = calendar.getMonth()+1;//获取月份
    let day = calendar.getDate();//获取日
    let hour = calendar.getHours();//获取日
    let min = calendar.getMinutes();//获取日
    let temp = month.toString();

    temp += "月"+day;
    temp += "日 "+hour;
    temp += "时"+min+"分";

    return temp;
  }

  public static getMonthDateFirstWeekDate(offset:number):string{
    let numWithoutDecimal = (offset/12).toString().split(".")[0];
    let m = parseInt(numWithoutDecimal);
    offset = offset%12;

    let calendar = new Date();
    let year = calendar.getFullYear()+m;//获取年份
    let month = calendar.getMonth()+1;
    Log.i("getMonthDateFirstWeekDate m:"+m+","+offset+","+year+","+month);

    if(offset <0){
      if(month+offset>0){
      month = month +offset;
    }else{
      year = year - 1;
      month = 12-(-month-offset);
    }
    }else {
      if(month+offset>12){
        year = year + 1;
        month = month+offset - 12;
      }else{
        month = month +offset;
      }
    }
    let date="";
    if(month>9){
      date = year+"/"+month+"/01";
    }else{
      date = year+"/0"+month+"/01";
    }
    Log.i("getMontDateFirstWeek date:"+date);


    let weekIndex = new Date(date).getDay()+1;

    if(weekIndex == 2)
      return date;
    else if(weekIndex == 1){
      if(month>9){
        return year+"/"+month+"/02";
      }else{
        return year+"/0"+month+"/02";
      }
    }else {
      let days = 7-weekIndex+3;
      let daysStr = ""+days;
      if(days<10){
        daysStr="0"+daysStr;
      }
      if(month>9){
        return year+"/"+month+"/"+daysStr;
      }else{
        return year+"/0"+month+"/"+daysStr;
      }
    }
  }

  public static getMonthDateFirstWeekDateIndex(date:string):string{

    let c = new Date(date);
    c.setDate(c.getDate() + 7);
    let year = c.getFullYear();
    let month = c.getMonth() + 1;
    let day = c.getDate();
    return `${year}/${month.toString().padStart(2, '0')}/${day.toString().padStart(2, '0')}`;
  }

  public static dateToTimestamp(date:string):number{
    return new Date(date).getTime();
  }

  public static monthMoveOffset(date:string,i:number):string{
    let mm = new Date(date).getTime();
    mm = mm+24*60*60*1000*31*i;
    let newDate = new Date(mm);
    let year = newDate.getFullYear();
    let month = newDate.getMonth() + 1;
    return `${year}/${month.toString().padStart(2, '0')}`;
  }

  public static betweenDays(start:string,end:string){
    let days:Array<string> = new Array<string>();
    let date_start = new Date(start);
    let date_end = new Date(end);

    let s = ((date_end.getTime() - date_start.getTime())/ (24*60*60*1000));
    if(s>0){
      for(let i = 0;i<=s-1;i++){
        let todayDate = date_start.getTime() + i * (24*60*60*1000);
        days[i]= DateUtils.timeToDateNoYM2(todayDate);
        Log.i("打印日期"+days[i]);
      }
      return days;
    }
    return null;
  }

  public static getYByOffset(offset:number):string{
    let numWithoutDecimal = (offset/12).toString().split(".")[0];
    let m = parseInt(numWithoutDecimal);
    offset = offset%12;

    let calendar = new Date();
    let year = calendar.getFullYear()+m;//获取年份
    let month = calendar.getMonth()+1;
    //Log.i("getYByOffset m:"+m+","+offset+","+year+","+month);

    if(offset <0){
      if(month+offset>0){
        month = month +offset;
      }else{
        year = year - 1;
        month = 12-(-month-offset);
      }
    }else {
      if(month+offset>12){
        year = year + 1;
        month = month+offset - 12;
      }else{
        month = month +offset;
      }
    }

    if(month>9){
      return year + "/"+month;
    }else {
      return year + "/0"+month;
    }
  }

  /**
   * 计时器数字文本更新
   * */
  public static convertCountTime(timeNum:number){
    let text = "";
    let hour = Math.floor(timeNum/(60*60*1000));
    if(hour > 1) {
      text = hour + ":";
    }
    timeNum = timeNum - 60*60*1000*hour;
    let min = Math.floor(timeNum/(60*1000));
    if(min > 9) {
      text = text + min + ":";
    }else{
      text = text + "0" + min + ":";
    }
    timeNum = timeNum - 60*1000*min;
    let second = Math.floor(timeNum/1000);
    if(second > 9) {
      text = text + second + ":";
    }else{
      text = text + "0" + second + ":";
    }
    timeNum = timeNum - 1000*second;
    let millSecond = Math.floor(timeNum/10);
    if(millSecond > 9) {
      text = text + millSecond;
    }else{
      text = text + "0" + millSecond;
    }
    return text;
  }

  public static getHM(time:number):string{
    let calendar = new Date(time);
    let hour = calendar.getHours();
    let min = calendar.getMinutes();
    return `${hour.toString().padStart(2, '0')}:${min.toString().padStart(2, '0')}`;
  }

}