export type PartOfSpeech = 'noun' | 'verb' | 'adjective' | 'adverb' |
  'pronoun' | 'preposition' | 'conjunction' | 'interjection' | 'phrase';

export type RecordSource = 'manual' | 'voice' | 'vision' | 'ai-suggest';

export type LogType = 'record' | 'review' | 'exercise' | 'report-view' |
  'voice-query' | 'vision-query' | 'reminder-trigger';

export type ReportStatus = 'generated' | 'viewed' | 'dismissed';

export type ExerciseType = 'choice-zh-to-en' | 'choice-en-to-zh' |
  'fill-blank' | 'spelling' | 'pronunciation';

export type AIProviderType = 'deepseek' | 'tongyi' | 'mock';

export interface WordRecord {
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
  date: string;
  generatedAt: number;
  newWordsCount: number;
  reviewedCount: number;
  exercisesCompleted: number;
  accuracyRate: number;
  streakDays: number;
  studyMinutes: number;
  reviewWords: string[];
  exercises: Exercise[];
  suggestion: string;
  status: ReportStatus;
}

export interface UserProfile {
  userId: string;
  reportReminderTime: string;
  reportEnabled: boolean;
  wearReminderEnabled: boolean;
  dailyNewWordGoal: number;
  dailyReviewGoal: number;
  aiProvider: AIProviderType;
  aiApiKey?: string;
  targetLanguage: string;
  autoPronunciation: boolean;
  theme: 'light' | 'dark' | 'system';
  updatedAt: number;
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

export interface ExampleSentence {
  en: string;
  zh: string;
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
