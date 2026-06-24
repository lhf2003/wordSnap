import { WordRecord, DailyReport, UserProfile, AuthToken, HuaweiUserInfo } from '../model/Types';
import { ProfileRepository } from '../repository/ProfileRepository';
import { Context } from '@kit.AbilityKit';

@Observed
export class AppStore {
  private static instance: AppStore | null = null;

  wordList: WordRecord[] = [];
  todayWordCount: number = 0;
  totalWordCount: number = 0;
  reviewWordCount: number = 0;
  currentReport: DailyReport | null = null;
  userProfile: UserProfile = {
    userId: 'default',
    isLoggedIn: false,
    reportReminderTime: '21:00',
    reportEnabled: true,
    wearReminderEnabled: false,
    dailyNewWordGoal: 10,
    dailyReviewGoal: 20,
    aiProvider: 'mock',
    targetLanguage: 'zh',
    autoPronunciation: false,
    theme: 'system',
    updatedAt: Date.now()
  };
  isProfileLoaded: boolean = false;

  private profileRepo: ProfileRepository;

  private context: Context | null = null;

  static getInstance(): AppStore {
    if (AppStore.instance === null) {
      AppStore.instance = new AppStore();
    }
    return AppStore.instance;
  }

  private constructor() {
    this.profileRepo = ProfileRepository.getInstance();
  }

  setContext(context: Context): void {
    this.context = context;
  }

  async load(): Promise<void> {
    if (this.isProfileLoaded) {
      return;
    }
    if (this.context === null) {
      console.warn('AppStore.load called before setContext');
      this.isProfileLoaded = true;
      return;
    }
    try {
      const profile = await this.profileRepo.load(this.context);
      if (profile !== null) {
        this.userProfile = profile;
      }
      this.isProfileLoaded = true;
    } catch (err) {
      const message = err instanceof Error ? err.message : '加载配置失败';
      console.error('AppStore load failed: ' + message);
      this.isProfileLoaded = true;
    }
  }

  private async saveProfile(): Promise<void> {
    if (this.context === null) {
      console.warn('AppStore.saveProfile called before setContext');
      return;
    }
    try {
      await this.profileRepo.save(this.context, this.userProfile);
    } catch (err) {
      const message = err instanceof Error ? err.message : '保存配置失败';
      console.error('AppStore saveProfile failed: ' + message);
    }
  }

  setWordList(words: WordRecord[]): void {
    this.wordList = words;
  }

  addWordToList(word: WordRecord): void {
    this.wordList = [word, ...this.wordList];
    this.todayWordCount = this.todayWordCount + 1;
    this.totalWordCount = this.totalWordCount + 1;
  }

  removeWordFromList(id: string): void {
    this.wordList = this.wordList.filter((w: WordRecord): boolean => w.id !== id);
    this.totalWordCount = Math.max(0, this.totalWordCount - 1);
  }

  setStatistics(today: number, total: number, review: number): void {
    this.todayWordCount = today;
    this.totalWordCount = total;
    this.reviewWordCount = review;
  }

  setCurrentReport(report: DailyReport | null): void {
    this.currentReport = report;
  }

  setLoggedInUser(user: HuaweiUserInfo, token: AuthToken): void {
    const profile = this.userProfile;
    const updated: UserProfile = {
      userId: user.openId,
      openId: user.openId,
      unionId: user.unionId,
      nickname: user.nickname,
      avatarUrl: user.avatarUrl,
      isLoggedIn: true,
      authToken: token,
      reportReminderTime: profile.reportReminderTime,
      reportEnabled: profile.reportEnabled,
      wearReminderEnabled: profile.wearReminderEnabled,
      dailyNewWordGoal: profile.dailyNewWordGoal,
      dailyReviewGoal: profile.dailyReviewGoal,
      aiProvider: profile.aiProvider,
      aiApiKey: profile.aiApiKey,
      targetLanguage: profile.targetLanguage,
      autoPronunciation: profile.autoPronunciation,
      theme: profile.theme,
      updatedAt: Date.now()
    };
    this.userProfile = updated;
    this.saveProfile();
  }

  clearUser(): void {
    const profile = this.userProfile;
    const updated: UserProfile = {
      userId: 'default',
      isLoggedIn: false,
      reportReminderTime: profile.reportReminderTime,
      reportEnabled: profile.reportEnabled,
      wearReminderEnabled: profile.wearReminderEnabled,
      dailyNewWordGoal: profile.dailyNewWordGoal,
      dailyReviewGoal: profile.dailyReviewGoal,
      aiProvider: profile.aiProvider,
      aiApiKey: profile.aiApiKey,
      targetLanguage: profile.targetLanguage,
      autoPronunciation: profile.autoPronunciation,
      theme: profile.theme,
      updatedAt: Date.now()
    };
    this.userProfile = updated;
    this.saveProfile();
  }

  updateUserProfile(partial: Partial<UserProfile>): void {
    const profile = this.userProfile;
    const updated: UserProfile = {
      userId: partial.userId ?? profile.userId,
      openId: partial.openId ?? profile.openId,
      unionId: partial.unionId ?? profile.unionId,
      nickname: partial.nickname ?? profile.nickname,
      avatarUrl: partial.avatarUrl ?? profile.avatarUrl,
      isLoggedIn: partial.isLoggedIn ?? profile.isLoggedIn,
      authToken: partial.authToken ?? profile.authToken,
      reportReminderTime: partial.reportReminderTime ?? profile.reportReminderTime,
      reportEnabled: partial.reportEnabled ?? profile.reportEnabled,
      wearReminderEnabled: partial.wearReminderEnabled ?? profile.wearReminderEnabled,
      dailyNewWordGoal: partial.dailyNewWordGoal ?? profile.dailyNewWordGoal,
      dailyReviewGoal: partial.dailyReviewGoal ?? profile.dailyReviewGoal,
      aiProvider: partial.aiProvider ?? profile.aiProvider,
      aiApiKey: partial.aiApiKey ?? profile.aiApiKey,
      targetLanguage: partial.targetLanguage ?? profile.targetLanguage,
      autoPronunciation: partial.autoPronunciation ?? profile.autoPronunciation,
      theme: partial.theme ?? profile.theme,
      updatedAt: Date.now()
    };
    this.userProfile = updated;
    this.saveProfile();
  }
}
