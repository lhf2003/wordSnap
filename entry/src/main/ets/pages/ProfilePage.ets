import { AuthService } from '../service/auth/AuthService';
import { AppStore } from '../store/AppStore';
import { DesignTokens } from '../components/DesignTokens';
import { BottomNav } from '../components/BottomNav';
import { ReportScheduler } from '../service/ReportScheduler';

const BUNDLE_NAME = 'com.lhf.worksnap';
const ENTRY_ABILITY_NAME = 'EntryAbility';

@ComponentV2
export struct ProfilePage {
  @Local nickname: string = '';
  @Local avatarUrl: string = '';
  @Local isLoggingOut: boolean = false;
  @Local reportEnabled: boolean = true;
  @Local reportTime: string = '21:00';
  @Local isSavingReminder: boolean = false;
  @Consumer('navPath') navPath: NavPathStack = new NavPathStack();
  private authService: AuthService = AuthService.getInstance();
  private reportScheduler: ReportScheduler = new ReportScheduler();

  aboutToAppear(): void {
    const profile = AppStore.getInstance().userProfile;
    this.nickname = profile.nickname ?? '华为用户';
    this.avatarUrl = profile.avatarUrl ?? '';
    this.reportEnabled = profile.reportEnabled;
    this.reportTime = profile.reportReminderTime;
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      this.reportScheduler.setContext(context);
    }
  }

  private async logout(): Promise<void> {
    this.isLoggingOut = true;
    try {
      await this.authService.signOut();
      this.navPath.replacePath({ name: 'LoginPage' });
    } catch (err) {
      const message = err instanceof Error ? err.message : '退出失败';
      console.error('ProfilePage logout failed: ' + message);
    } finally {
      this.isLoggingOut = false;
    }
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
      if (this.avatarUrl.length > 0) {
        Image(this.avatarUrl)
          .width(80)
          .height(80)
          .borderRadius(DesignTokens.radiusFull)
      } else {
        Column() {
          Text(this.nickname.substring(0, 1))
            .fontSize(DesignTokens.font32)
            .fontColor(DesignTokens.textOnPrimary)
        }
        .width(80)
        .height(80)
        .borderRadius(DesignTokens.radiusFull)
        .backgroundColor(DesignTokens.primary)
        .justifyContent(FlexAlign.Center)
      }

      Text(this.nickname)
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

  private showToast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (e) {
      console.warn('ProfilePage showToast failed: ' + (e instanceof Error ? e.message : 'unknown'));
    }
  }

  private isValidTime(value: string): boolean {
    const regex = /^([01]?\d|2[0-3]):([0-5]\d)$/;
    return regex.test(value);
  }

  private async saveReminderSettings(): Promise<void> {
    if (!this.isValidTime(this.reportTime)) {
      this.showToast('时间格式不正确，请使用 HH:MM');
      return;
    }

    this.isSavingReminder = true;
    try {
      AppStore.getInstance().updateUserProfile({
        reportEnabled: this.reportEnabled,
        reportReminderTime: this.reportTime
      });

      await this.reportScheduler.ensureReminderEnabled(
        this.reportEnabled,
        this.reportTime,
        BUNDLE_NAME,
        ENTRY_ABILITY_NAME
      );

      this.showToast(this.reportEnabled ? '已保存并开启每日提醒' : '已关闭每日提醒');
    } catch (err) {
      const message = err instanceof Error ? err.message : '保存失败';
      console.error('ProfilePage saveReminderSettings failed: ' + message);
      this.showToast('提醒设置保存失败：' + message);
    } finally {
      this.isSavingReminder = false;
    }
  }

  private navigateToReport(): void {
    this.navPath.pushPathByName('DailyReportPage', null);
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

        Toggle({ type: ToggleType.Switch, isOn: this.reportEnabled })
          .selectedColor(DesignTokens.primary)
          .onChange((isOn: boolean) => {
            this.reportEnabled = isOn;
          })
      }
      .width('100%')
      .margin({ bottom: DesignTokens.spacing16 })

      Row() {
        Text('提醒时间')
          .fontSize(DesignTokens.font16)
          .fontColor(DesignTokens.textPrimary)
          .layoutWeight(1)

        TextInput({ text: this.reportTime, placeholder: 'HH:MM' })
          .width(80)
          .height(36)
          .fontSize(DesignTokens.font14)
          .textAlign(TextAlign.Center)
          .backgroundColor(DesignTokens.bgInput)
          .borderRadius(DesignTokens.radius8)
          .onChange((value: string) => {
            this.reportTime = value;
          })
      }
      .width('100%')
      .margin({ bottom: DesignTokens.spacing16 })

      Button(this.isSavingReminder ? '保存中...' : '保存提醒设置')
        .width('100%')
        .height(48)
        .backgroundColor(DesignTokens.primary)
        .fontColor(DesignTokens.textOnPrimary)
        .borderRadius(DesignTokens.radiusFull)
        .enabled(!this.isSavingReminder)
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
    Button(this.isLoggingOut ? '退出中...' : '退出登录')
      .width('100%')
      .height(48)
      .backgroundColor(DesignTokens.danger)
      .fontColor(DesignTokens.textOnPrimary)
      .borderRadius(DesignTokens.radiusFull)
      .margin({ top: DesignTokens.spacing32 })
      .enabled(!this.isLoggingOut)
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
    .onBackPressed(() => {
      this.navPath.pop();
      return true;
    })
  }
}
