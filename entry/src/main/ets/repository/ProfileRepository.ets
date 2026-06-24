import { relationalStore } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { UserProfile } from '../model/Types';

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'english_assistant_profile.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

const PROFILE_TABLE_SQL = `
  CREATE TABLE IF NOT EXISTS user_profile (
    user_id TEXT PRIMARY KEY,
    open_id TEXT,
    union_id TEXT,
    nickname TEXT,
    avatar_url TEXT,
    is_logged_in INTEGER NOT NULL,
    access_token TEXT,
    refresh_token TEXT,
    token_expires_at INTEGER,
    report_reminder_time TEXT NOT NULL,
    report_enabled INTEGER NOT NULL,
    wear_reminder_enabled INTEGER NOT NULL,
    daily_new_word_goal INTEGER NOT NULL,
    daily_review_goal INTEGER NOT NULL,
    ai_provider TEXT NOT NULL,
    ai_api_key TEXT,
    target_language TEXT NOT NULL,
    auto_pronunciation INTEGER NOT NULL,
    theme TEXT NOT NULL,
    updated_at INTEGER NOT NULL
  )
`;

export class ProfileRepository {
  private static instance: ProfileRepository | null = null;
  private store: relationalStore.RdbStore | null = null;

  static getInstance(): ProfileRepository {
    if (ProfileRepository.instance === null) {
      ProfileRepository.instance = new ProfileRepository();
    }
    return ProfileRepository.instance;
  }

  private constructor() {}

  async init(context: Context): Promise<void> {
    if (this.store !== null) {
      return;
    }
    this.store = await relationalStore.getRdbStore(context, STORE_CONFIG);
    await this.store.executeSql(PROFILE_TABLE_SQL);
    await this.migrateV2();
  }

  private async migrateV2(): Promise<void> {
    if (this.store === null) {
      return;
    }
    const migrations: string[] = [
      'ALTER TABLE user_profile ADD COLUMN open_id TEXT',
      'ALTER TABLE user_profile ADD COLUMN union_id TEXT',
      'ALTER TABLE user_profile ADD COLUMN nickname TEXT',
      'ALTER TABLE user_profile ADD COLUMN avatar_url TEXT',
      'ALTER TABLE user_profile ADD COLUMN is_logged_in INTEGER DEFAULT 0',
      'ALTER TABLE user_profile ADD COLUMN access_token TEXT',
      'ALTER TABLE user_profile ADD COLUMN refresh_token TEXT',
      'ALTER TABLE user_profile ADD COLUMN token_expires_at INTEGER'
    ];
    for (const sql of migrations) {
      try {
        await this.store.executeSql(sql);
      } catch (err) {
        console.info('ProfileRepository migration skipped: ' + (err instanceof Error ? err.message : 'unknown'));
      }
    }
  }

  async load(context: Context): Promise<UserProfile | null> {
    await this.init(context);
    if (this.store === null) {
      throw new Error('ProfileRepository not initialized');
    }

    const predicates = new relationalStore.RdbPredicates('user_profile');
    const resultSet = await this.store.query(predicates, ['*']);
    if (!resultSet.goToNextRow()) {
      return null;
    }

    const getString = (col: string): string =>
      resultSet.getString(resultSet.getColumnIndex(col));
    const getLong = (col: string): number =>
      resultSet.getLong(resultSet.getColumnIndex(col));
    const getOptString = (col: string): string | undefined => {
      const value = resultSet.getString(resultSet.getColumnIndex(col));
      return value.length > 0 ? value : undefined;
    };

    const isLoggedIn: boolean = getLong('is_logged_in') !== 0;
    const accessToken: string | undefined = getOptString('access_token');
    const refreshToken: string | undefined = getOptString('refresh_token');
    const tokenExpiresAt: number = getLong('token_expires_at');

    return {
      userId: getString('user_id'),
      openId: getOptString('open_id'),
      unionId: getOptString('union_id'),
      nickname: getOptString('nickname'),
      avatarUrl: getOptString('avatar_url'),
      isLoggedIn: isLoggedIn,
      authToken: accessToken !== undefined && refreshToken !== undefined && tokenExpiresAt > 0 ? {
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: tokenExpiresAt
      } : undefined,
      reportReminderTime: getString('report_reminder_time'),
      reportEnabled: getLong('report_enabled') !== 0,
      wearReminderEnabled: getLong('wear_reminder_enabled') !== 0,
      dailyNewWordGoal: getLong('daily_new_word_goal'),
      dailyReviewGoal: getLong('daily_review_goal'),
      aiProvider: this.normalizeProvider(getString('ai_provider')),
      aiApiKey: getOptString('ai_api_key'),
      targetLanguage: getString('target_language'),
      autoPronunciation: getLong('auto_pronunciation') !== 0,
      theme: this.normalizeTheme(getString('theme')),
      updatedAt: getLong('updated_at')
    };
  }

  async save(context: Context, profile: UserProfile): Promise<void> {
    await this.init(context);
    if (this.store === null) {
      throw new Error('ProfileRepository not initialized');
    }

    const deletePredicates = new relationalStore.RdbPredicates('user_profile');
    deletePredicates.equalTo('user_id', profile.userId);
    await this.store.delete(deletePredicates);

    const values: relationalStore.ValuesBucket = {
      user_id: profile.userId,
      open_id: profile.openId ?? '',
      union_id: profile.unionId ?? '',
      nickname: profile.nickname ?? '',
      avatar_url: profile.avatarUrl ?? '',
      is_logged_in: profile.isLoggedIn ? 1 : 0,
      access_token: profile.authToken?.accessToken ?? '',
      refresh_token: profile.authToken?.refreshToken ?? '',
      token_expires_at: profile.authToken?.expiresAt ?? 0,
      report_reminder_time: profile.reportReminderTime,
      report_enabled: profile.reportEnabled ? 1 : 0,
      wear_reminder_enabled: profile.wearReminderEnabled ? 1 : 0,
      daily_new_word_goal: profile.dailyNewWordGoal,
      daily_review_goal: profile.dailyReviewGoal,
      ai_provider: profile.aiProvider,
      ai_api_key: profile.aiApiKey ?? '',
      target_language: profile.targetLanguage,
      auto_pronunciation: profile.autoPronunciation ? 1 : 0,
      theme: profile.theme,
      updated_at: profile.updatedAt
    };

    await this.store.insert('user_profile', values);
  }

  private normalizeProvider(value: string): 'mock' | 'deepseek' | 'tongyi' {
    if (value === 'mock' || value === 'deepseek' || value === 'tongyi') {
      return value;
    }
    return 'mock';
  }

  private normalizeTheme(value: string): 'light' | 'dark' | 'system' {
    if (value === 'light' || value === 'dark' || value === 'system') {
      return value;
    }
    return 'system';
  }
}
