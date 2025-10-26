import { router } from '@kit.ArkUI'
import promptAction from '@ohos.promptAction'
import { AppStateStore } from '../services/AppStateStore'

@Entry
@Component
struct LoginPage {
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  private appStore = AppStateStore.getInstance();

  /**
   * 处理华为账号登录
   */
  private handleHuaweiLogin = async (): Promise<void> => {
    if (this.isLoading) {
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      // 使用 AppStateStore 执行登录
      await this.appStore.login();

      // 登录成功提示
      promptAction.showToast({
        message: '登录成功！',
        duration: 2000
      });

      // 延迟返回，让用户看到提示
      setTimeout(() => {
        router.back();
      }, 500);

    } catch (error) {
      const err = error as Error;
      this.errorMessage = err.message || '登录失败，请重试';
      
      promptAction.showToast({
        message: this.errorMessage,
        duration: 2000
      });

      console.error('[LoginPage] 登录失败:', JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }


  private openPrivacy = (): void => {
    router.pushUrl({ url: 'pages/YSPage' })
  }

  private openAgreement = (): void => {
    router.pushUrl({ url: 'pages/XYPage' })
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.back_btn_dark'))
          .width(24)
          .height(24)
          .onClick(() => router.back())
        Text('账号登录')
          .fontSize(20)
          .fontWeight(600)
          .margin({ left: 12 })
        Blank().layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 12 })

      // 华为账号登录界面
      Column() {
        // Logo
        Image($r('app.media.icon'))
          .width(100)
          .height(100)
          .margin({ top: 80, bottom: 40 })

        // 标题
        Text('微步运动')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ bottom: 8 })

        Text('坚持运动 · 乐享生活')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ bottom: 60 })

        // 华为账号登录按钮
        Button({ type: ButtonType.Capsule }) {
          Row({ space: 12 }) {
            if (this.isLoading) {
              LoadingProgress()
                .width(20)
                .height(20)
                .color(Color.White);
            } else {
              Image($r('app.media.icon'))
                .width(24)
                .height(24)
                .borderRadius(12);
            }

            Text(this.isLoading ? '登录中...' : '华为账号登录')
              .fontSize(16)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Medium);
          }
        }
        .width('85%')
        .height(48)
        .backgroundColor('#FF6B00')
        .enabled(!this.isLoading)
        .onClick(() => this.handleHuaweiLogin());

        // 错误提示
        if (this.errorMessage) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#FF3B30')
            .maxLines(2)
            .textAlign(TextAlign.Center)
            .width('85%')
            .margin({ top: 16 });
        }

        Blank();

        // 用户协议
        Row({ space: 4 }) {
          Text('登录即表示同意')
            .fontSize(12)
            .fontColor('#999999');
          Text('《用户协议》')
            .fontSize(12)
            .fontColor('#0cc291')
            .onClick(() => this.openAgreement());
          Text('和')
            .fontSize(12)
            .fontColor('#999999');
          Text('《隐私政策》')
            .fontSize(12)
            .fontColor('#0cc291')
            .onClick(() => this.openPrivacy());
        }
        .margin({ bottom: 40 })
        .justifyContent(FlexAlign.Center);
      }
      .width('100%')
      .height('85%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFFFF')
  }
}
