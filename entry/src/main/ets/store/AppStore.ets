import { WordRecord, DailyReport, UserProfile, UserProfileInit, AuthToken, HuaweiUserInfo } from '../model/Types';
import { ProfileRepository } from '../repository/ProfileRepository';
import { Context } from '@kit.AbilityKit';

@ObservedV2
export class AppStore {
  private static instance: AppStore | null = null;

  @Trace wordList: WordRecord[] = [];
  @Trace todayWordCount: number = 0;
  @Trace totalWordCount: number = 0;
  @Trace reviewWordCount: number = 0;
  @Trace currentReport: DailyReport | null = null;
  @Trace userProfile: UserProfile = new UserProfile();
  @Trace isProfileLoaded: boolean = false;

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
        this.userProfile = new UserProfile({
          userId: profile.userId,
          openId: profile.openId,
          unionId: profile.unionId,
          nickname: profile.nickname,
          avatarUrl: profile.avatarUrl,
          isLoggedIn: profile.isLoggedIn,
          authToken: profile.authToken,
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
          updatedAt: profile.updatedAt
        });
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
      this.userProfile.updatedAt = Date.now();
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
    this.userProfile = new UserProfile({
      userId: user.openId,
      openId: user.openId,
      unionId: user.unionId,
      nickname: user.nickname,
      avatarUrl: user.avatarUrl,
      isLoggedIn: true,
      authToken: token,
      reportReminderTime: this.userProfile.reportReminderTime,
      reportEnabled: this.userProfile.reportEnabled,
      wearReminderEnabled: this.userProfile.wearReminderEnabled,
      dailyNewWordGoal: this.userProfile.dailyNewWordGoal,
      dailyReviewGoal: this.userProfile.dailyReviewGoal,
      aiProvider: this.userProfile.aiProvider,
      aiApiKey: this.userProfile.aiApiKey,
      targetLanguage: this.userProfile.targetLanguage,
      autoPronunciation: this.userProfile.autoPronunciation,
      theme: this.userProfile.theme,
      updatedAt: Date.now()
    });
    this.saveProfile();
  }

  clearUser(): void {
    this.userProfile = new UserProfile({
      userId: 'default',
      isLoggedIn: false,
      reportReminderTime: this.userProfile.reportReminderTime,
      reportEnabled: this.userProfile.reportEnabled,
      wearReminderEnabled: this.userProfile.wearReminderEnabled,
      dailyNewWordGoal: this.userProfile.dailyNewWordGoal,
      dailyReviewGoal: this.userProfile.dailyReviewGoal,
      aiProvider: this.userProfile.aiProvider,
      aiApiKey: this.userProfile.aiApiKey,
      targetLanguage: this.userProfile.targetLanguage,
      autoPronunciation: this.userProfile.autoPronunciation,
      theme: this.userProfile.theme,
      updatedAt: Date.now()
    });
    this.saveProfile();
  }

  updateUserProfile(partial: UserProfileInit): void {
    const current = this.userProfile;
    this.userProfile = new UserProfile({
      userId: partial.userId ?? current.userId,
      openId: partial.openId ?? current.openId,
      unionId: partial.unionId ?? current.unionId,
      nickname: partial.nickname ?? current.nickname,
      avatarUrl: partial.avatarUrl ?? current.avatarUrl,
      isLoggedIn: partial.isLoggedIn ?? current.isLoggedIn,
      authToken: partial.authToken ?? current.authToken,
      reportReminderTime: partial.reportReminderTime ?? current.reportReminderTime,
      reportEnabled: partial.reportEnabled ?? current.reportEnabled,
      wearReminderEnabled: partial.wearReminderEnabled ?? current.wearReminderEnabled,
      dailyNewWordGoal: partial.dailyNewWordGoal ?? current.dailyNewWordGoal,
      dailyReviewGoal: partial.dailyReviewGoal ?? current.dailyReviewGoal,
      aiProvider: partial.aiProvider ?? current.aiProvider,
      aiApiKey: partial.aiApiKey ?? current.aiApiKey,
      targetLanguage: partial.targetLanguage ?? current.targetLanguage,
      autoPronunciation: partial.autoPronunciation ?? current.autoPronunciation,
      theme: partial.theme ?? current.theme,
      updatedAt: Date.now()
    });
    this.saveProfile();
  }
}
