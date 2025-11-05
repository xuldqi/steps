/**
 * 华为账号登录工具类
 */
import { authentication } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';

export interface HuaweiUserInfo {
  unionID: string;
  openID: string;
  displayName: string;
  avatarUri?: string;
}

interface HuaweiAuthResponseData {
  unionID?: string;
  openID?: string;
  displayName?: string;
  avatarUri?: string;
}

export class HuaweiAuth {
  /**
   * 执行华为账号登录
   */
  static async login(): Promise<HuaweiUserInfo> {
    try {
      // 创建授权请求
      const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
      
      // 设置请求的权限范围
      authRequest.scopes = [
        'https://www.huawei.com/auth/account/base.profile',
        'openid'
      ];

      // 用于防跨站点请求伪造
      authRequest.state = util.generateRandomUUID();
      authRequest.forceAuthorization = false;

      // 执行认证请求
      const controller = new authentication.AuthenticationController();
      const response: authentication.AuthenticationResponse = await controller.executeRequest(authRequest);
      const payload: HuaweiAuthResponseData = HuaweiAuth.extractResponseData(response);

      const resolvedId = (payload.unionID ?? payload.openID ?? '').trim();
      if (resolvedId.length === 0) {
        throw new Error('未获取到华为账号 ID，请稍后再试');
      }

      const userInfo: HuaweiUserInfo = {
        unionID: (payload.unionID ?? resolvedId).trim() || resolvedId,
        openID: (payload.openID ?? resolvedId).trim() || resolvedId,
        displayName: payload.displayName ?? '华为账号用户',
        avatarUri: payload.avatarUri
      };

      console.info('[HuaweiAuth] 登录成功:', JSON.stringify(userInfo));
      return userInfo;

    } catch (error) {
      throw HuaweiAuth.transformError(error as BusinessError);
    }
  }

  private static extractResponseData(response: authentication.AuthenticationResponse): HuaweiAuthResponseData {
    const raw: unknown = response as unknown;
    if (typeof raw !== 'object' || raw === null) {
      return {};
    }
    const record = raw as Record<string, unknown>;
    const dataField: unknown = record['data'];
    if (typeof dataField !== 'object' || dataField === null) {
      return {};
    }
    const payload = dataField as Record<string, unknown>;
    const result: HuaweiAuthResponseData = {};
    if (typeof payload['unionID'] === 'string') {
      result.unionID = payload['unionID'] as string;
    }
    if (typeof payload['openID'] === 'string') {
      result.openID = payload['openID'] as string;
    }
    if (typeof payload['displayName'] === 'string') {
      result.displayName = payload['displayName'] as string;
    }
    if (typeof payload['avatarUri'] === 'string') {
      result.avatarUri = payload['avatarUri'] as string;
    }
    return result;
  }

  private static transformError(err: BusinessError | Error): Error {
    if (!err || typeof (err as BusinessError).code !== 'number') {
      return err instanceof Error ? err : new Error('登录失败');
    }
    const businessError = err as BusinessError;
    console.error('[HuaweiAuth] 登录失败:', businessError.code, businessError.message);

    switch (businessError.code) {
      case 1002:
        return new Error('网络连接失败，请检查网络设置');
      case 2001:
        return new Error('用户取消登录');
      case 2002:
        return new Error('请先登录华为账号');
      case 6003:
        return new Error('应用签名验证失败');
      case 6002:
        return new Error('应用配置错误');
      default:
        return new Error(`登录失败: ${businessError.message}`);
    }
  }
}
