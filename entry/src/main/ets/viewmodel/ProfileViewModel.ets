import { AuthService } from '../service/auth/AuthService';
import { AppStore } from '../store/AppStore';
import { ReportScheduler } from '../service/ReportScheduler';
import { Context } from '@kit.AbilityKit';

const BUNDLE_NAME = 'com.lhf.worksnap';
const ENTRY_ABILITY_NAME = 'EntryAbility';

@ObservedV2
export class ProfileViewModel {
  @Trace nickname: string = '华为用户';
  @Trace avatarUrl: string = '';
  @Trace isLoggingOut: boolean = false;
  @Trace reportEnabled: boolean = true;
  @Trace reportTime: string = '21:00';
  @Trace isSavingReminder: boolean = false;

  private authService: AuthService = AuthService.getInstance();
  private reportScheduler: ReportScheduler = new ReportScheduler();
  private context: Context | null = null;

  init(context: Context): void {
    this.context = context;
    this.reportScheduler.setContext(context);
    const profile = AppStore.getInstance().userProfile;
    this.nickname = profile.nickname ?? '华为用户';
    this.avatarUrl = profile.avatarUrl ?? '';
    this.reportEnabled = profile.reportEnabled;
    this.reportTime = profile.reportReminderTime;
  }

  refreshProfile(): void {
    const profile = AppStore.getInstance().userProfile;
    this.nickname = profile.nickname ?? '华为用户';
    this.avatarUrl = profile.avatarUrl ?? '';
    this.reportEnabled = profile.reportEnabled;
    this.reportTime = profile.reportReminderTime;
  }

  async logout(): Promise<boolean> {
    this.isLoggingOut = true;
    try {
      await this.authService.signOut();
      return true;
    } catch (err) {
      const message = err instanceof Error ? err.message : '退出失败';
      console.error('ProfileViewModel logout failed: ' + message);
      return false;
    } finally {
      this.isLoggingOut = false;
    }
  }

  async saveReminderSettings(): Promise<string | null> {
    if (!this.isValidTime(this.reportTime)) {
      return '时间格式不正确，请使用 HH:MM';
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

      return this.reportEnabled ? '已保存并开启每日提醒' : '已关闭每日提醒';
    } catch (err) {
      const message = err instanceof Error ? err.message : '保存失败';
      console.error('ProfileViewModel saveReminderSettings failed: ' + message);
      return '提醒设置保存失败：' + message;
    } finally {
      this.isSavingReminder = false;
    }
  }

  private isValidTime(value: string): boolean {
    const regex = /^([01]?\d|2[0-3]):([0-5]\d)$/;
    return regex.test(value);
  }
}
