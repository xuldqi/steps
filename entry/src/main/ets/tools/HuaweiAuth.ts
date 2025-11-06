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
      const errorMsg = err instanceof Error ? err.message : '登录失败';
      console.error('[HuaweiAuth] 错误详情:', JSON.stringify(err));
      return new Error(errorMsg);
    }
    const businessError = err as BusinessError;
    console.error('[HuaweiAuth] 登录失败 - 错误码:', businessError.code, '错误信息:', businessError.message);
    console.error('[HuaweiAuth] 完整错误对象:', JSON.stringify(businessError));

    // 检查是否包含指纹验证相关错误
    const errorMessage = businessError.message || '';
    if (errorMessage.toLowerCase().includes('fingerprint') || errorMessage.toLowerCase().includes('gateway')) {
      console.error('[HuaweiAuth] 指纹验证失败，请检查：');
      console.error('1. AGC 中是否已配置正确的 SHA256 指纹');
      console.error('2. 应用签名证书是否与 AGC 配置一致');
      console.error('3. 等待 10-30 分钟让 AGC 配置生效');
    }

    switch (businessError.code) {
      case 1002:
        return new Error('网络连接失败，请检查网络设置');
      case 2001:
        return new Error('用户取消登录');
      case 2002:
        return new Error('请先登录华为账号');
      case 6003:
        return new Error('应用签名验证失败，请检查 AGC 中的指纹配置');
      case 6002:
        return new Error('应用配置错误，请检查 agconnect-services.json');
      default:
        return new Error(`登录失败: ${businessError.message}`);
    }
  }
}
