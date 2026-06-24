import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { WordService } from '../service/WordService';
import { AppStore } from '../store/AppStore';
import { AuthService } from '../service/auth/AuthService';
import { ReportScheduler } from '../service/ReportScheduler';

const BUNDLE_NAME = 'com.lhf.worksnap';
const ENTRY_ABILITY_NAME = 'EntryAbility';

export default class EntryAbility extends UIAbility {
  private wordService: WordService = new WordService();
  private authService: AuthService = AuthService.getInstance();
  private reportScheduler: ReportScheduler = new ReportScheduler();

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    try {
      const context = this.context;
      await this.wordService.init(context);
      AppStore.getInstance().setContext(context);
      await AppStore.getInstance().load();
      await this.authService.init(context);
      await this.registerDailyReportReminder(context);
    } catch (err) {
      const message = err instanceof Error ? err.message : '数据库初始化失败';
      console.error('Failed to initialize app: ' + message);
    }
  }

  private async registerDailyReportReminder(context: Context): Promise<void> {
    try {
      this.reportScheduler.setContext(context);
      const profile = AppStore.getInstance().userProfile;
      await this.reportScheduler.ensureReminderEnabled(
        profile.reportEnabled,
        profile.reportReminderTime,
        BUNDLE_NAME,
        ENTRY_ABILITY_NAME
      );
    } catch (err) {
      const message = err instanceof Error ? err.message : '注册提醒失败';
      console.error('Failed to register daily report reminder: ' + message);
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.loadEntryPage(windowStage);
  }

  private async loadEntryPage(windowStage: window.WindowStage): Promise<void> {
    // 开发阶段跳过登录页，直接进入主页；后续接入华为账号市场配置后恢复登录校验
    const targetPage: string = 'pages/Index';
    windowStage.loadContent(targetPage, (err) => {
      if (err) {
        console.error('Failed to load ' + targetPage + ': ' + JSON.stringify(err));
      }
    });
  }
}
