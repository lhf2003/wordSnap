import { Context } from '@kit.AbilityKit';
import { DailyReport, Exercise, WordRecord, ReportStatus } from '../model/Types';
import { ReportRepository } from '../repository/ReportRepository';
import { WordRepository } from '../repository/WordRepository';

function formatDateKey(date: Date): string {
  const year = date.getFullYear();
  const month = (date.getMonth() + 1).toString().padStart(2, '0');
  const day = date.getDate().toString().padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function startOfDay(date: Date): number {
  const copy = new Date(date.getTime());
  copy.setHours(0, 0, 0, 0);
  return copy.getTime();
}

function endOfDay(date: Date): number {
  const copy = new Date(date.getTime());
  copy.setHours(23, 59, 59, 999);
  return copy.getTime();
}

export class ReportService {
  private reportRepo: ReportRepository;
  private wordRepo: WordRepository;
  private idCounter: number = 0;

  constructor() {
    this.reportRepo = ReportRepository.getInstance();
    this.wordRepo = WordRepository.getInstance();
  }

  async init(context: Context): Promise<void> {
    await this.reportRepo.init(context);
    await this.wordRepo.init(context);
  }

  async generateReport(targetDate: Date = new Date()): Promise<DailyReport> {
    const dateKey = formatDateKey(targetDate);
    const existing = await this.reportRepo.findByDate(dateKey);
    if (existing !== null) {
      return existing;
    }

    const words = await this.wordRepo.findByDateRange(startOfDay(targetDate), endOfDay(targetDate));
    const previousReport = (await this.reportRepo.findRecentReports(1))[0] ?? null;

    const report = await this.buildReport(dateKey, words, previousReport);
    await this.reportRepo.insert(report);
    return report;
  }

  async getReportForDate(date: Date): Promise<DailyReport | null> {
    const dateKey = formatDateKey(date);
    return this.reportRepo.findByDate(dateKey);
  }

  async getRecentReports(limit: number = 30): Promise<DailyReport[]> {
    return this.reportRepo.findRecentReports(limit);
  }

  async markAsViewed(id: string): Promise<void> {
    await this.reportRepo.updateStatus(id, 'viewed');
  }

  private async buildReport(
    dateKey: string,
    words: WordRecord[],
    previousReport: DailyReport | null
  ): Promise<DailyReport> {
    const newWordsCount = words.length;
    const reviewedCount = words.reduce((sum: number, w: WordRecord): number => sum + w.reviewCount, 0);
    const exercises = this.generateExercises(words);
    const streakDays = await this.calculateStreak(dateKey, previousReport);
    const studyMinutes = Math.max(5, newWordsCount * 2 + reviewedCount);
    const accuracyRate = this.estimateAccuracy(words);

    this.idCounter += 1;
    const id = `r-${dateKey}-${Date.now()}-${this.idCounter.toString(36).padStart(4, '0')}`;

    const highFrequencyWords = this.extractHighFrequencyWords(words);
    const reviewWords = words.filter((w: WordRecord): boolean => w.proficiency < 3).map((w: WordRecord): string => w.word);

    return {
      id: id,
      date: dateKey,
      generatedAt: Date.now(),
      newWordsCount: newWordsCount,
      reviewedCount: reviewedCount,
      exercisesCompleted: 0,
      accuracyRate: accuracyRate,
      streakDays: streakDays,
      studyMinutes: studyMinutes,
      highFrequencyWords: highFrequencyWords,
      reviewWords: reviewWords,
      exercises: exercises,
      suggestion: this.generateSuggestion(newWordsCount, reviewedCount, streakDays),
      status: 'generated'
    };
  }

  private extractHighFrequencyWords(words: WordRecord[]): string[] {
    const frequency = new Map<string, number>();
    for (const word of words) {
      const key = word.word.toLowerCase();
      frequency.set(key, (frequency.get(key) ?? 0) + 1);
    }

    const sorted = Array.from(frequency.entries())
      .sort((a: [string, number], b: [string, number]): number => b[1] - a[1])
      .slice(0, 5)
      .map((entry: [string, number]): string => entry[0]);

    if (sorted.length === 0 && words.length > 0) {
      return words.slice(0, 5).map((w: WordRecord): string => w.word);
    }
    return sorted;
  }

  private generateExercises(words: WordRecord[]): Exercise[] {
    const exercises: Exercise[] = [];
    const candidates = words.slice(0, Math.min(5, words.length));
    if (candidates.length === 0) {
      return exercises;
    }

    const allWords = words.map((w: WordRecord): string => w.word);
    const distractors = allWords.length > 3 ? allWords : ['apple', 'book', 'water', 'hello', 'world'];

    for (let i = 0; i < candidates.length; i++) {
      const word = candidates[i];
      const translation = word.translation[0] ?? '暂无释义';

      if (i % 2 === 0) {
        const options = this.shuffleAndPick(distractors.filter((w: string): boolean =>
          w.toLowerCase() !== word.word.toLowerCase()), 3);
        const finalOptions = this.shuffle([word.word, ...options]);

        exercises.push({
          id: `ex-${word.id}-zh`,
          wordId: word.id,
          type: 'choice-zh-to-en',
          question: `选择 "${translation}" 对应的英文：`,
          options: finalOptions,
          correctAnswer: word.word,
          explanation: `${word.word} 的中文释义为：${translation}`
        });
      } else {
        const options = this.shuffleAndPick(
          words.filter((w: WordRecord): boolean => w.id !== word.id).map((w: WordRecord): string =>
            w.translation[0] ?? '暂无释义'),
          3
        );
        const finalOptions = this.shuffle([translation, ...options]);

        exercises.push({
          id: `ex-${word.id}-en`,
          wordId: word.id,
          type: 'choice-en-to-zh',
          question: `"${word.word}" 的中文意思是？`,
          options: finalOptions,
          correctAnswer: translation,
          explanation: `${word.word} 的中文释义为：${translation}`
        });
      }
    }

    return exercises;
  }

  private shuffleAndPick(items: string[], count: number): string[] {
    const unique = Array.from(new Set(items.filter((item: string): boolean => item.length > 0)));
    const shuffled = this.shuffle(unique);
    return shuffled.slice(0, Math.min(count, shuffled.length));
  }

  private shuffle<T>(array: T[]): T[] {
    const copy = [...array];
    for (let i = copy.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      const temp = copy[i];
      copy[i] = copy[j];
      copy[j] = temp;
    }
    return copy;
  }

  private async calculateStreak(dateKey: string, previousReport: DailyReport | null): Promise<number> {
    if (previousReport === null) {
      return 1;
    }

    const previousDate = new Date(previousReport.date);
    const currentDate = new Date(dateKey);
    const diffDays = Math.round((currentDate.getTime() - previousDate.getTime()) / (24 * 60 * 60 * 1000));

    if (diffDays === 1) {
      return previousReport.streakDays + 1;
    } else if (diffDays === 0) {
      return previousReport.streakDays;
    } else {
      return 1;
    }
  }

  private estimateAccuracy(words: WordRecord[]): number {
    if (words.length === 0) {
      return 100;
    }
    const totalReviews = words.reduce((sum: number, w: WordRecord): number => sum + w.reviewCount, 0);
    if (totalReviews === 0) {
      return 100;
    }
    const totalProficiency = words.reduce((sum: number, w: WordRecord): number => sum + w.proficiency, 0);
    const rate = Math.round((totalProficiency / (words.length * 5)) * 100);
    return Math.min(100, Math.max(60, rate));
  }

  private generateSuggestion(newWords: number, reviewed: number, streak: number): string {
    if (newWords === 0) {
      return '今天还没有记录新单词，明天记得随手捕捉生活中的英语瞬间哦～';
    }
    if (streak >= 7) {
      return `太棒了！你已经连续学习 ${streak} 天，今天新学 ${newWords} 个单词，保持这个节奏！`;
    }
    if (newWords >= 10) {
      return `今日收获满满，新学 ${newWords} 个单词！记得复习巩固，明天见～`;
    }
    return `今天新学 ${newWords} 个单词，复习 ${reviewed} 次，继续加油！`;
  }
}
