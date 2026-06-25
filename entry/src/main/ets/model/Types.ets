import { Type } from '@kit.ArkUI';

export type PartOfSpeech = 'noun' | 'verb' | 'adjective' | 'adverb' |
  'pronoun' | 'preposition' | 'conjunction' | 'interjection' | 'phrase';

export type RecordSource = 'manual' | 'voice' | 'vision' | 'ai-suggest';

export type LogType = 'record' | 'review' | 'exercise' | 'report-view' |
  'voice-query' | 'vision-query' | 'reminder-trigger';

export type ReportStatus = 'generated' | 'viewed' | 'dismissed';

export type ExerciseType = 'choice-zh-to-en' | 'choice-en-to-zh' |
  'fill-blank' | 'spelling' | 'pronunciation';

export type AIProviderType = 'deepseek' | 'tongyi' | 'mock';

export interface ExampleSentence {
  en: string;
  zh: string;
}

export interface ExampleItem {
  en: string;
  zh: string;
}

export interface WordRecordInit {
  id: string;
  word: string;
  translation: string[];
  partOfSpeech: PartOfSpeech;
  exampleSentence?: string;
  exampleTranslation?: string;
  phoneticUK?: string;
  phoneticUS?: string;
  source: RecordSource;
  originalQuery?: string;
  tags: string[];
  proficiency: number;
  reviewCount: number;
  createdAt: number;
  lastReviewedAt?: number;
  imageUri?: string;
  definition?: string;
  examples?: ExampleSentence[];
  isArchived?: boolean;
  isFavorite?: boolean;
}

@ObservedV2
export class WordRecord {
  @Trace id: string = '';
  @Trace word: string = '';
  @Trace translation: string[] = [];
  @Trace partOfSpeech: PartOfSpeech = 'noun';
  @Trace exampleSentence?: string;
  @Trace exampleTranslation?: string;
  @Trace phoneticUK?: string;
  @Trace phoneticUS?: string;
  @Trace source: RecordSource = 'manual';
  @Trace originalQuery?: string;
  @Trace tags: string[] = [];
  @Trace proficiency: number = 0;
  @Trace reviewCount: number = 0;
  @Trace createdAt: number = 0;
  @Trace lastReviewedAt?: number;
  @Trace imageUri?: string;
  @Trace definition?: string;
  @Trace examples?: ExampleSentence[];
  @Trace isArchived?: boolean;
  @Trace isFavorite?: boolean;

  constructor(init?: WordRecordInit) {
    if (init) {
      this.id = init.id;
      this.word = init.word;
      this.translation = init.translation;
      this.partOfSpeech = init.partOfSpeech;
      this.exampleSentence = init.exampleSentence;
      this.exampleTranslation = init.exampleTranslation;
      this.phoneticUK = init.phoneticUK;
      this.phoneticUS = init.phoneticUS;
      this.source = init.source;
      this.originalQuery = init.originalQuery;
      this.tags = init.tags;
      this.proficiency = init.proficiency;
      this.reviewCount = init.reviewCount;
      this.createdAt = init.createdAt;
      this.lastReviewedAt = init.lastReviewedAt;
      this.imageUri = init.imageUri;
      this.definition = init.definition;
      this.examples = init.examples;
      this.isArchived = init.isArchived;
      this.isFavorite = init.isFavorite;
    }
  }
}

export interface LearningLog {
  id: string;
  date: string;
  type: LogType;
  wordId?: string;
  action: string;
  metadata?: string;
  createdAt: number;
}

export interface DailyReport {
  id: string;
  date: string;
  generatedAt: number;
  newWordsCount: number;
  reviewedCount: number;
  exercisesCompleted: number;
  accuracyRate: number;
  streakDays: number;
  studyMinutes: number;
  highFrequencyWords: string[];
  reviewWords: string[];
  exercises: Exercise[];
  suggestion: string;
  status: ReportStatus;
}

export interface AuthTokenInit {
  accessToken: string;
  refreshToken: string;
  expiresAt: number;
}

@ObservedV2
export class AuthToken {
  @Trace accessToken: string = '';
  @Trace refreshToken: string = '';
  @Trace expiresAt: number = 0;

  constructor(init?: AuthTokenInit) {
    if (init) {
      this.accessToken = init.accessToken;
      this.refreshToken = init.refreshToken;
      this.expiresAt = init.expiresAt;
    }
  }
}

export interface HuaweiUserInfo {
  openId: string;
  unionId?: string;
  nickname?: string;
  avatarUrl?: string;
}

export interface LoginResponse {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  user: HuaweiUserInfo;
}

export interface UserProfileInit {
  userId?: string;
  openId?: string;
  unionId?: string;
  nickname?: string;
  avatarUrl?: string;
  isLoggedIn?: boolean;
  authToken?: AuthToken;
  reportReminderTime?: string;
  reportEnabled?: boolean;
  wearReminderEnabled?: boolean;
  dailyNewWordGoal?: number;
  dailyReviewGoal?: number;
  aiProvider?: AIProviderType;
  aiApiKey?: string;
  targetLanguage?: string;
  autoPronunciation?: boolean;
  theme?: 'light' | 'dark' | 'system';
  updatedAt?: number;
}

@ObservedV2
export class UserProfile {
  @Trace userId: string = 'default';
  @Trace openId?: string;
  @Trace unionId?: string;
  @Trace nickname?: string;
  @Trace avatarUrl?: string;
  @Trace isLoggedIn: boolean = false;
  @Type(AuthToken)
  @Trace authToken?: AuthToken;
  @Trace reportReminderTime: string = '21:00';
  @Trace reportEnabled: boolean = true;
  @Trace wearReminderEnabled: boolean = false;
  @Trace dailyNewWordGoal: number = 10;
  @Trace dailyReviewGoal: number = 20;
  @Trace aiProvider: AIProviderType = 'mock';
  @Trace aiApiKey?: string;
  @Trace targetLanguage: string = 'zh';
  @Trace autoPronunciation: boolean = false;
  @Trace theme: 'light' | 'dark' | 'system' = 'system';
  @Trace updatedAt: number = Date.now();

  constructor(init?: UserProfileInit) {
    if (init) {
      if (init.userId !== undefined) {
        this.userId = init.userId;
      }
      if (init.openId !== undefined) {
        this.openId = init.openId;
      }
      if (init.unionId !== undefined) {
        this.unionId = init.unionId;
      }
      if (init.nickname !== undefined) {
        this.nickname = init.nickname;
      }
      if (init.avatarUrl !== undefined) {
        this.avatarUrl = init.avatarUrl;
      }
      if (init.isLoggedIn !== undefined) {
        this.isLoggedIn = init.isLoggedIn;
      }
      if (init.authToken !== undefined) {
        this.authToken = new AuthToken({
          accessToken: init.authToken.accessToken,
          refreshToken: init.authToken.refreshToken,
          expiresAt: init.authToken.expiresAt
        });
      }
      if (init.reportReminderTime !== undefined) {
        this.reportReminderTime = init.reportReminderTime;
      }
      if (init.reportEnabled !== undefined) {
        this.reportEnabled = init.reportEnabled;
      }
      if (init.wearReminderEnabled !== undefined) {
        this.wearReminderEnabled = init.wearReminderEnabled;
      }
      if (init.dailyNewWordGoal !== undefined) {
        this.dailyNewWordGoal = init.dailyNewWordGoal;
      }
      if (init.dailyReviewGoal !== undefined) {
        this.dailyReviewGoal = init.dailyReviewGoal;
      }
      if (init.aiProvider !== undefined) {
        this.aiProvider = init.aiProvider;
      }
      if (init.aiApiKey !== undefined) {
        this.aiApiKey = init.aiApiKey;
      }
      if (init.targetLanguage !== undefined) {
        this.targetLanguage = init.targetLanguage;
      }
      if (init.autoPronunciation !== undefined) {
        this.autoPronunciation = init.autoPronunciation;
      }
      if (init.theme !== undefined) {
        this.theme = init.theme;
      }
      if (init.updatedAt !== undefined) {
        this.updatedAt = init.updatedAt;
      }
    }
  }
}

export interface Exercise {
  id: string;
  wordId: string;
  type: ExerciseType;
  question: string;
  options?: string[];
  correctAnswer: string;
  userAnswer?: string;
  isCorrect?: boolean;
  answeredAt?: number;
  explanation: string;
}

export interface AITranslationResult {
  translatedText: string;
  sourceLang: string;
  confidence: number;
  alternatives?: string[];
}

export interface AIWordDetail {
  word: string;
  translations: string[];
  partOfSpeech: PartOfSpeech[];
  phoneticUK?: string;
  phoneticUS?: string;
  examples: Array<ExampleSentence>;
  synonyms?: string[];
  antonyms?: string[];
}

export interface VoiceIntent {
  action: 'translate' | 'describe' | 'define';
  queryText: string;
  sourceLanguage?: string;
}

export interface WordDetailParam {
  wordId: string;
}

export interface DailyDataPoint {
  date: string;
  newWords: number;
  reviewed: number;
  accuracy: number;
}

export interface LearningStatistics {
  totalWords: number;
  masteredWords: number;
  streakDays: number;
  averageAccuracy: number;
  dailyData: Array<DailyDataPoint>;
}
