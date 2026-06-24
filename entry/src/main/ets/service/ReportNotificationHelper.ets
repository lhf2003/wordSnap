import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { DailyReport } from '../model/Types';

const REPORT_NOTIFICATION_ID = 10001;
const REPORT_CHANNEL_ID = 'daily_report_channel';

export class ReportNotificationHelper {
  static async ensureChannel(): Promise<void> {
    try {
      const slot: notificationManager.NotificationSlot = {
        type: notificationManager.SlotType.SOCIAL_COMMUNICATION,
        level: notificationManager.SlotLevel.LEVEL_DEFAULT,
        desc: '每日学习总结报告',
        bypassDnd: false,
        lockscreenVisibility: notificationManager.VisiblenessType.VISIBLENESS_TYPE_PUBLIC,
        vibrationEnabled: false,
        sound: ''
      };
      await notificationManager.addSlot(slot);
    } catch (err) {
      console.info('ReportNotificationHelper addSlot skipped: ' +
        (err instanceof Error ? err.message : JSON.stringify(err)));
    }
  }

  static async publishReportNotification(report: DailyReport): Promise<void> {
    await this.ensureChannel();

    const title = `今日学习报告 · ${report.date}`;
    const text = report.newWordsCount > 0
      ? `今日新学 ${report.newWordsCount} 个单词，连续学习 ${report.streakDays} 天，点击查看详情～`
      : '今天还没有记录新单词，明天继续加油哦～';

    const request: notificationManager.NotificationRequest = {
      id: REPORT_NOTIFICATION_ID,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: title,
          text: text,
          additionalText: `学习时长 ${report.studyMinutes} 分钟`
        }
      },
      notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
      groupName: 'daily_report'
    };

    try {
      await notificationManager.publish(request);
      console.info('ReportNotificationHelper published daily report notification');
    } catch (err) {
      const message = err instanceof BusinessError
        ? `code=${err.code}, message=${err.message}`
        : (err instanceof Error ? err.message : JSON.stringify(err));
      console.error('ReportNotificationHelper publish failed: ' + message);
      throw err;
    }
  }

  static async cancelReportNotification(): Promise<void> {
    try {
      await notificationManager.cancel(REPORT_NOTIFICATION_ID, 'daily_report');
    } catch (err) {
      console.info('ReportNotificationHelper cancel skipped: ' +
        (err instanceof Error ? err.message : JSON.stringify(err)));
    }
  }
}
