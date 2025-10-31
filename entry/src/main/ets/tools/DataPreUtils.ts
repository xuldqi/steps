import preferences from '@ohos.data.preferences'
import { Context } from '@kit.AbilityKit';
import {Log} from '../tools/Logger'
import mainCardManager from './MainCardManager';

class DataPreUtils {

  preferencesMap: Map<string, preferences.Preferences> = new Map;

  async loadPreference(context:Context, name: string) {
    Log.i(`开始加载Preference [${name}]`);

    try {
      let preference = await preferences.getPreferences(context, name)

      this.preferencesMap.set(name, preference)
      Log.i(`加载Preference [${name}]成功`);
      mainCardManager.loadMainCardManager()

      return preference
    } catch (err) {
      Log.i(`加载Preference [${name}]失败:`+JSON.stringify(err));
      Promise.reject(`加载Preference [${name}]失败`)
    }
    return null
  }

  async putPreferenceValue(name: string, key: string, value: preferences.ValueType) {
    if (!this.preferencesMap.has(name)) {
      Log.e(`Preference[${name}]尚未初始化，无法保存数据`);
      return
    }
    try {
      let preference = this.preferencesMap.get(name)
      Log.i(`正在保存Preferences[${name}.${key}=${value}]`)
      //写入数据
      await preference!.put(key, value)
      //刷新磁盘
      await preference!.flush()
      Log.i(`成功保存Preferences[${name}.${key}=${value}]`)
    } catch (e) {
      Log.e(`保存Preferences[${name}.${key}=${value}]失败:`+JSON.stringify(e));
    }
  }

  //获取指定preference的指定数据
  async getPreferenceValue(name: string, key: string, defaultValue: preferences.ValueType) {
    if (!this.preferencesMap.has(name)) {
      Log.i(`Preference[${name}]尚未初始化`);

      //结束异步
      Log.i("`Preference[${name}]尚未初始化`")
    }
    try {
      let preference = this.preferencesMap.get(name)

      let value = await preference!.get(key, defaultValue)

      return value

    } catch (e) {
      Log.e(`获取Preferences[${name}.${key}]失败:`+JSON.stringify(e));
    }
    return ''
  }

  //删除指定preference的指定数据
  async deletePreferenceValue(name: string, key: string, defaultValue: preferences.ValueType) {

    try {
      let preference = this.preferencesMap.get(name)

      //删除数据
      preference!.delete(key)

      Log.i(`删除Preferences[${name}.${key}]成功`)

      return

    } catch (err) {
      Log.e(`删除Preferences[${name}.${key}]失败`)
    }
  }

  playBtnMedia(){

  }
}


const preferencesUtil = new DataPreUtils()

export default preferencesUtil as DataPreUtils