import { loginComponentManager, LoginWithHuaweiIDButton } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AuthService } from '../service/auth/AuthService';
import { DesignTokens } from '../components/DesignTokens';

@ComponentV2
export struct LoginPage {
  @Local isLoading: boolean = false;
  @Local errorMessage: string = '';
  @Local isAgreementSelected: boolean = false;
  @Consumer('navPath') navPath: NavPathStack = new NavPathStack();
  private authService: AuthService = AuthService.getInstance();

  private loginButtonController: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
      .setAgreementStatus(loginComponentManager.AgreementStatus.NOT_ACCEPTED)
      .onClickLoginWithHuaweiIDButton((error: BusinessError | undefined, response: loginComponentManager.HuaweiIDCredential) => {
        this.handleLoginResponse(error, response);
      });

  private getLoginButtonParams(): loginComponentManager.LoginWithHuaweiIDButtonParams {
    return {
      loginType: loginComponentManager.LoginType.QUICK_LOGIN,
      style: loginComponentManager.Style.BUTTON_RED
    };
  }

  async aboutToAppear() {
    try {
      const context = this.getUIContext().getHostContext();
      if (context !== undefined) {
        await this.authService.init(context);
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : '初始化失败';
      console.error('LoginPage init failed: ' + message);
    }
  }

  private async handleLoginResponse(error: BusinessError | undefined, response: loginComponentManager.HuaweiIDCredential): Promise<void> {
    if (error !== undefined) {
      this.errorMessage = error.message;
      return;
    }
    this.isLoading = true;
    this.errorMessage = '';
    try {
      await this.authService.exchangeToken(response.authorizationCode);
      this.navPath.replacePath({ name: 'HomePage' });
    } catch (err) {
      const message = err instanceof Error ? err.message : '登录失败';
      console.error('LoginPage login failed: ' + message);
      this.errorMessage = message;
    } finally {
      this.isLoading = false;
    }
  }

  private onAgreementChange(selected: boolean): void {
    this.isAgreementSelected = selected;
    this.loginButtonController.setAgreementStatus(
      selected ? loginComponentManager.AgreementStatus.ACCEPTED : loginComponentManager.AgreementStatus.NOT_ACCEPTED
    );
  }

  @Builder
  LogoSection() {
    Column() {
      Text('English Assistant')
        .fontSize(DesignTokens.font32)
        .fontWeight(FontWeight.Bold)
        .fontColor(DesignTokens.textPrimary)
      Text('华为账号一键登录，开启学习之旅')
        .fontSize(DesignTokens.font14)
        .fontColor(DesignTokens.textSecondary)
        .margin({ top: DesignTokens.spacing12 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  AgreementRow() {
    Row() {
      Checkbox()
        .select(this.isAgreementSelected)
        .selectedColor(DesignTokens.primary)
        .width(18)
        .height(18)
        .onChange((value: boolean) => this.onAgreementChange(value))

      Text('我已阅读并同意相关协议')
        .fontSize(DesignTokens.font12)
        .fontColor(DesignTokens.textSecondary)
        .margin({ left: DesignTokens.spacing8 })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .margin({ top: DesignTokens.spacing24, bottom: DesignTokens.spacing16 })
  }

  @Builder
  ErrorBanner() {
    if (this.errorMessage.length > 0) {
      Text(this.errorMessage)
        .fontSize(DesignTokens.font14)
        .fontColor(DesignTokens.danger)
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding(DesignTokens.spacing12)
        .margin({ bottom: DesignTokens.spacing16 })
    }
  }

  build() {
    NavDestination() {
      Column() {
        Blank()
          .layoutWeight(1)

        this.LogoSection()

        Blank()
          .layoutWeight(1)

        Column() {
          this.ErrorBanner()

          if (this.isLoading) {
            LoadingProgress()
              .width(40)
              .height(40)
              .color(DesignTokens.primary)
          } else {
            LoginWithHuaweiIDButton({
              params: this.getLoginButtonParams(),
              controller: this.loginButtonController
            })
              .width('100%')
              .height(48)
          }

          this.AgreementRow()
        }
        .width('100%')
        .padding({ left: DesignTokens.spacing32, right: DesignTokens.spacing32 })

        Blank()
          .height(48)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(DesignTokens.bgBase)
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      this.navPath.pop();
      return true;
    })
  }
}
