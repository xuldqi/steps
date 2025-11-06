import { router } from '@kit.ArkUI'
import appDataManager from './AppDataManager'

export interface SportTarget {
  name: string
  value: number
  type: number
}

export class Utils {
  static getMainCardIcon(type: number): Resource {
    switch (type) {
      case 1:
        return $r('app.media.main_card_sport')
      case 2:
        return $r('app.media.main_card_cal')
      case 3:
        return $r('app.media.main_card_run')
      case 4:
        return $r('app.media.main_card_count_time')
      case 5:
        return $r('app.media.main_card_body_record')
      case 6:
        return $r('app.media.main_card_weight')
    }
    return $r('app.media.main_card_run')
  }

  static getMainCardStr(type: number): string {
    switch (type) {
      case 1:
        return '走路距离'
      case 2:
        return '热量消耗'
      case 3:
        return '运动记录'
      case 4:
        return '时间计时'
      case 5:
        return '身体数据'
      case 6:
        return '体重记录'
    }
    return '运动记录'
  }

  static toMainCardPage(type: number) {
    switch (type) {
      case 1:
        router.pushUrl({ url: 'pages/DistanceTrendPage' })
        return
      case 2:
        router.pushUrl({ url: 'pages/ChartPage' })
        return
      case 3:
        router.pushUrl({ url: 'pages/ExerciseRecordPage' })
        return
      case 4:
        router.pushUrl({ url: 'pages/CountTimePage' })
        return
      case 5:
        router.pushUrl({ url: 'pages/BodyDataPage' })
        return
      case 6:
        router.pushUrl({ url: 'pages/WeightTrendPage' })
        return
    }
  }

  static getSubSportStartIcon(type: number): Resource {
    switch (type) {
      case 1:
        return $r('app.media.sport_inside_run')
      case 2:
        return $r('app.media.sport_outside_run')
      case 3:
      case 4:
      case 5:
        return $r('app.media.start')
    }
    return $r('app.media.start')
  }

  static getSportTypeName(type: number): string {
    switch (type) {
      case 1:
        return '室内跑'
      case 2:
        return '室外跑'
      case 3:
        return '健走'
      case 4:
        return '徒步'
      case 5:
        return '登山'
      case 6:
        return '骑行'
      case 7:
        return '瑜伽'
      case 8:
        return '跳绳'
    }
    return '室外跑'
  }

  static getSportRecordTitle(type: number): string {
    switch (type) {
      case 0:
        return '所有记录'
      case 1:
        return '室内跑记录'
      case 2:
        return '室外跑记录'
      case 3:
        return '健走记录'
      case 4:
        return '徒步记录'
      case 5:
        return '登山记录'
      case 6:
        return '骑行记录'
      case 7:
        return '瑜伽记录'
      case 8:
        return '跳绳记录'
    }
    return '所有记录'
  }

  static getKalByStep(step: number): string {
    const kmiles = (step) * 0.6 / 1000
    const times = kmiles * 14
    return ((times / 60) * 240).toFixed(2)
  }

  static getDistanceByStep(step: number): string {
    const kmiles = (step) * 0.6 / 1000
    return kmiles.toFixed(2)
  }
}

