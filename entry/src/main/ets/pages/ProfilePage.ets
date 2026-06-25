import { ProfileViewModel } from '../viewmodel/ProfileViewModel';
import { DesignTokens } from '../components/DesignTokens';
import { BottomNav } from '../components/BottomNav';

@ComponentV2
export struct ProfilePage {
  @Local viewModel: ProfileViewModel = new ProfileViewModel();
  @Consumer('navPath') navPath: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      this.viewModel.init(context);
    }
  }

  onShown(): void {
    this.viewModel.refreshProfile();
  }

  private showToast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (e) {
      console.warn('ProfilePage showToast failed: ' + (e instanceof Error ? e.message : 'unknown'));
    }
  }

  private async logout(): Promise<void> {
    const success = await this.viewModel.logout();
    if (success) {
      this.navPath.replacePath({ name: 'LoginPage' });
    } else {
      this.showToast('退出失败');
    }
  }

  private async saveReminderSettings(): Promise<void> {
    const message = await this.viewModel.saveReminderSettings();
    if (message !== null) {
      this.showToast(message);
    }
  }

  private navigateToReport(): void {
    this.navPath.pushPathByName('DailyReportPage', null);
  }

  @Builder
  Header() {
    Text('我的')
      .fontSize(DesignTokens.font24)
      .fontWeight(FontWeight.Bold)
      .fontColor(DesignTokens.textPrimary)
      .width('100%')
      .padding(DesignTokens.spacing16)
  }

  @Builder
  UserCard() {
    Column() {
      if (this.viewModel.avatarUrl.length > 0) {
        Image(this.viewModel.avatarUrl)
          .width(80)
          .height(80)
          .borderRadius(DesignTokens.radiusFull)
      } else {
        Column() {
          Text(this.viewModel.nickname.substring(0, 1))
            .fontSize(DesignTokens.font32)
            .fontColor(DesignTokens.textOnPrimary)
        }
        .width(80)
        .height(80)
        .borderRadius(DesignTokens.radiusFull)
        .backgroundColor(DesignTokens.primary)
        .justifyContent(FlexAlign.Center)
      }

      Text(this.viewModel.nickname)
        .fontSize(DesignTokens.font20)
        .fontWeight(FontWeight.Bold)
        .fontColor(DesignTokens.textPrimary)
        .margin({ top: DesignTokens.spacing16 })
    }
    .width('100%')
    .padding(DesignTokens.spacing24)
    .margin({ top: DesignTokens.spacing24 })
    .backgroundColor(DesignTokens.bgCard)
    .borderRadius(DesignTokens.radius24)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  SettingsCard() {
    Column() {
      Text('每日报告')
        .fontSize(DesignTokens.font18)
        .fontWeight(FontWeight.Bold)
        .fontColor(DesignTokens.textPrimary)
        .width('100%')
        .margin({ bottom: DesignTokens.spacing16 })

      Row() {
        Text('开启每日报告提醒')
          .fontSize(DesignTokens.font16)
          .fontColor(DesignTokens.textPrimary)
          .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.viewModel.reportEnabled })
          .selectedColor(DesignTokens.primary)
          .onChange((isOn: boolean) => {
            this.viewModel.reportEnabled = isOn;
          })
      }
      .width('100%')
      .margin({ bottom: DesignTokens.spacing16 })

      Row() {
        Text('提醒时间')
          .fontSize(DesignTokens.font16)
          .fontColor(DesignTokens.textPrimary)
          .layoutWeight(1)

        TextInput({ text: this.viewModel.reportTime, placeholder: 'HH:MM' })
          .width(80)
          .height(36)
          .fontSize(DesignTokens.font14)
          .textAlign(TextAlign.Center)
          .backgroundColor(DesignTokens.bgInput)
          .borderRadius(DesignTokens.radius8)
          .onChange((value: string) => {
            this.viewModel.reportTime = value;
          })
      }
      .width('100%')
      .margin({ bottom: DesignTokens.spacing16 })

      Button(this.viewModel.isSavingReminder ? '保存中...' : '保存提醒设置')
        .width('100%')
        .height(48)
        .backgroundColor(DesignTokens.primary)
        .fontColor(DesignTokens.textOnPrimary)
        .borderRadius(DesignTokens.radiusFull)
        .enabled(!this.viewModel.isSavingReminder)
        .onClick(() => this.saveReminderSettings())
    }
    .width('100%')
    .padding(DesignTokens.spacing16)
    .margin({ top: DesignTokens.spacing16 })
    .backgroundColor(DesignTokens.bgCard)
    .borderRadius(DesignTokens.radius24)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ReportEntryCard() {
    Row() {
      Column() {
        Text('学习报告')
          .fontSize(DesignTokens.font16)
          .fontWeight(FontWeight.Medium)
          .fontColor(DesignTokens.textPrimary)
        Text('查看今日总结与历史记录')
          .fontSize(DesignTokens.font12)
          .fontColor(DesignTokens.textSecondary)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('>')
        .fontSize(DesignTokens.font20)
        .fontColor(DesignTokens.textTertiary)
    }
    .width('100%')
    .padding(DesignTokens.spacing16)
    .margin({ top: DesignTokens.spacing16 })
    .backgroundColor(DesignTokens.bgCard)
    .borderRadius(DesignTokens.radius24)
    .alignItems(VerticalAlign.Center)
    .onClick(() => this.navigateToReport())
  }

  @Builder
  LogoutButton() {
    Button(this.viewModel.isLoggingOut ? '退出中...' : '退出登录')
      .width('100%')
      .height(48)
      .backgroundColor(DesignTokens.danger)
      .fontColor(DesignTokens.textOnPrimary)
      .borderRadius(DesignTokens.radiusFull)
      .margin({ top: DesignTokens.spacing32 })
      .enabled(!this.viewModel.isLoggingOut)
      .onClick(() => this.logout())
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          this.Header()

          Column() {
            this.UserCard()
            this.SettingsCard()
            this.ReportEntryCard()
            this.LogoutButton()
          }
          .width('100%')
          .height('100%')
          .padding({ left: DesignTokens.spacing16, right: DesignTokens.spacing16 })
          .layoutWeight(1)
        }
        .width('100%')
        .height('100%')
        .backgroundColor(DesignTokens.bgBase)

        BottomNav({ activeIndex: 3 })
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .onShown(() => this.onShown())
    .onBackPressed(() => {
      this.navPath.pop();
      return true;
    })
  }
}
