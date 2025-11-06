// 数据模型定义（与 HarmonyOS 版本保持一致）

export interface SportModel {
  id: number
  type: number // 运动类型：1-室内跑, 2-室外跑, 3-健走, 4-徒步, 5-登山, 0-全部
  sub_type: number
  start_time: number // 开始时间（时间戳，毫秒）
  use_time: number // 运动时长（秒）
  steps: number // 步数
  cal: string // 消耗热量（字符串，单位：千卡）
}

export interface PerStepModel {
  id: number
  state: number
  date: string
  steps: number
  backup: string
  time: number
}

export interface BodyRecordModel {
  id: number
  time: number
  type: number
  data: string
  unit: string
}

export interface MainCardItemModel {
  id: number
  title: string
  visible: boolean
  isAdded: boolean
  type: number
}

