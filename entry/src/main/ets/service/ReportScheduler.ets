import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';

const REMINDER_PREFS_NAME = 'report_reminder_prefs';
const REMINDER_ID_KEY = 'daily_report_reminder_id';
const REPORT_NOTIFICATION_ID = 10002;
const DEFAULT_REPORT_HOUR = 21;
const DEFAULT_REPORT_MINUTE = 0;

interface ReminderTime {
  hour: number;
  minute: number;
}

export class ReportScheduler {
  private context: Context | null = null;
  private pref: preferences.Preferences | null = null;

  setContext(context: Context): void {
    this.context = context;
  }

  private async getPreferences(): Promise<preferences.Preferences> {
    if (this.pref !== null) {
      return this.pref;
    }
    if (this.context === null) {
      throw new Error('ReportScheduler context not set');
    }
    this.pref = await preferences.getPreferences(this.context, REMINDER_PREFS_NAME);
    return this.pref;
  }

  async getStoredReminderId(): Promise<number | null> {
    const pref = await this.getPreferences();
    const value = pref.getSync(REMINDER_ID_KEY, -1) as number;
    return value > 0 ? value : null;
  }

  private async storeReminderId(id: number): Promise<void> {
    const pref = await this.getPreferences();
    await pref.put(REMINDER_ID_KEY, id);
    await pref.flush();
  }

  private async clearReminderId(): Promise<void> {
    const pref = await this.getPreferences();
    await pref.delete(REMINDER_ID_KEY);
    await pref.flush();
  }

  parseReminderTime(timeString: string): ReminderTime {
    const parts = timeString.split(':');
    const hour = parseInt(parts[0] ?? `${DEFAULT_REPORT_HOUR}`, 10);
    const minute = parseInt(parts[1] ?? `${DEFAULT_REPORT_MINUTE}`, 10);
    return {
      hour: isNaN(hour) ? DEFAULT_REPORT_HOUR : Math.max(0, Math.min(23, hour)),
      minute: isNaN(minute) ? DEFAULT_REPORT_MINUTE : Math.max(0, Math.min(59, minute))
    };
  }

  async registerDailyReminder(timeString: string, bundleName: string, abilityName: string): Promise<void> {
    await this.cancelDailyReminder();

    const time = this.parseReminderTime(timeString);

    const reminderRequest: reminderAgentManager.ReminderRequestAlarm = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_ALARM,
      hour: time.hour,
      minute: time.minute,
      daysOfWeek: [0, 1, 2, 3, 4, 5, 6],
      title: '今日学习报告已送达',
      content: '今天你又学习了哪些英语？点击查看完整总结和练习～',
      expiredContent: '今日学习报告已过期',
      notificationId: REPORT_NOTIFICATION_ID,
      slotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
      wantAgent: {
        pkgName: bundleName,
        abilityName: abilityName
      },
      actionButton: [
        {
          title: '查看',
          type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_SNOOZE
        },
        {
          title: '关闭',
          type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE
        }
      ]
    };

    try {
      const reminderId = await reminderAgentManager.publishReminder(reminderRequest);
      await this.storeReminderId(reminderId);
      console.info('ReportScheduler registered daily reminder at ' + time.hour + ':' + time.minute.toString().padStart(2, '0') + ', id=' + reminderId);
    } catch (err) {
      const message = err instanceof Error ? err.message : JSON.stringify(err);
      console.error('ReportScheduler registerDailyReminder failed: ' + message);
      throw new Error('注册每日报告提醒失败：' + message);
    }
  }

  async cancelDailyReminder(): Promise<void> {
    const reminderId = await this.getStoredReminderId();
    if (reminderId === null) {
      return;
    }

    try {
      await reminderAgentManager.cancelReminder(reminderId);
      await this.clearReminderId();
      console.info('ReportScheduler cancelled daily reminder id=' + reminderId);
    } catch (err) {
      const message = err instanceof Error ? err.message : JSON.stringify(err);
      console.error('ReportScheduler cancelDailyReminder failed: ' + message);
      await this.clearReminderId();
    }
  }

  async ensureReminderEnabled(enabled: boolean, timeString: string, bundleName: string, abilityName: string): Promise<void> {
    if (enabled) {
      await this.registerDailyReminder(timeString, bundleName, abilityName);
    } else {
      await this.cancelDailyReminder();
    }
  }
}
