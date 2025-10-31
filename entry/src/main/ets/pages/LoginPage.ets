import { router } from '@kit.ArkUI';
import promptAction from '@ohos.promptAction';
import { AppStateStore } from '../services/AppStateStore';
import { HuaweiAuth } from '../tools/HuaweiAuth';

@Entry
@Component
struct LoginPage {
  private store = AppStateStore.getInstance();
  @State private isProcessing: boolean = false;

  private goPrivacy() {
    router.push({ url: 'pages/YSPage' });
  }

  private goAgreement() {
    router.push({ url: 'pages/XYPage' });
  }

  private async performHuaweiLogin(): Promise<void> {
    if (this.isProcessing) {
      return;
    }
    this.isProcessing = true;
    try {
      const userInfo = await HuaweiAuth.login();
      await this.handleLogin(true, userInfo.unionID);
    } catch (error) {
      const message = (error as Error)?.message ?? '登录失败，请稍后重试';
      promptAction.showToast({ message, duration: 2000 });
      this.isProcessing = false;
    }
  }

  private async handleLogin(success: boolean, unionId?: string): Promise<void> {
    if (!success || !unionId) {
      this.isProcessing = false;
      return;
    }
    try {
      await this.store.loginWithUnionId(unionId);
      promptAction.showToast({ message: '登录成功', duration: 1500 });
      router.back();
    } catch (error) {
      const message = (error as Error)?.message ?? '登录失败，请稍后重试';
      promptAction.showToast({ message, duration: 2000 });
    } finally {
      this.isProcessing = false;
    }
  }

  build() {
    Column() {
      Text('欢迎使用')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ bottom: 8 })

      Text('使用华为账号登录，享受完整功能')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 40 })

      Button(this.isProcessing ? '登录中...' : '华为账号登录')
        .width('80%')
        .height(48)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor('#0cc291')
        .enabled(!this.isProcessing)
        .onClick(() => {
          void this.performHuaweiLogin();
        })
        .margin({ bottom: 20 })

      Button('返回')
        .width('80%')
        .height(48)
        .fontSize(16)
        .fontColor('#666666')
        .backgroundColor('#F0F0F0')
        .enabled(!this.isProcessing)
        .onClick(() => router.back())

      Row() {
        Text('查看《隐私政策》')
          .fontSize(12)
          .fontColor('#0cc291')
          .onClick(() => this.goPrivacy())
        Text('  |  ')
          .fontSize(12)
          .fontColor('#999999')
        Text('查看《用户协议》')
          .fontSize(12)
          .fontColor('#0cc291')
          .onClick(() => this.goAgreement())
      }
      .margin({ top: 40 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .padding({ left: 24, right: 24 })
  }
}
