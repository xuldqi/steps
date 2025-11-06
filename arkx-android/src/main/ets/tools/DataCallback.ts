// 数据回调接口
import { SportModel } from '../appdata/Model'

export interface DataCallback<T> {
  onDataResult: (type: number, result: T[], isReturnFirstData: boolean) => void
}

