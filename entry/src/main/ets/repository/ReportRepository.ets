import { relationalStore } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { DailyReport, ReportStatus, Exercise } from '../model/Types';

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'english_assistant_reports.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

const REPORT_TABLE_SQL = `
  CREATE TABLE IF NOT EXISTS daily_reports (
    id TEXT PRIMARY KEY,
    date TEXT NOT NULL,
    generated_at INTEGER NOT NULL,
    new_words_count INTEGER NOT NULL,
    reviewed_count INTEGER NOT NULL,
    exercises_completed INTEGER NOT NULL,
    accuracy_rate INTEGER NOT NULL,
    streak_days INTEGER NOT NULL,
    study_minutes INTEGER NOT NULL,
    high_frequency_words TEXT NOT NULL,
    review_words TEXT NOT NULL,
    exercises TEXT NOT NULL,
    suggestion TEXT NOT NULL,
    status TEXT NOT NULL
  )
`;

export class ReportRepository {
  private static instance: ReportRepository | null = null;
  private store: relationalStore.RdbStore | null = null;

  static getInstance(): ReportRepository {
    if (ReportRepository.instance === null) {
      ReportRepository.instance = new ReportRepository();
    }
    return ReportRepository.instance;
  }

  private constructor() {}

  async init(context: Context): Promise<void> {
    if (this.store !== null) {
      return;
    }
    this.store = await relationalStore.getRdbStore(context, STORE_CONFIG);
    await this.store.executeSql(REPORT_TABLE_SQL);
    await this.store.executeSql(
      'CREATE INDEX IF NOT EXISTS idx_report_date ON daily_reports(date)'
    );
    await this.store.executeSql(
      'CREATE INDEX IF NOT EXISTS idx_report_generated ON daily_reports(generated_at)'
    );
  }

  async insert(report: DailyReport): Promise<void> {
    if (!this.store) {
      throw new Error('ReportRepository not initialized');
    }

    const values: relationalStore.ValuesBucket = {
      id: report.id,
      date: report.date,
      generated_at: report.generatedAt,
      new_words_count: report.newWordsCount,
      reviewed_count: report.reviewedCount,
      exercises_completed: report.exercisesCompleted,
      accuracy_rate: report.accuracyRate,
      streak_days: report.streakDays,
      study_minutes: report.studyMinutes,
      high_frequency_words: JSON.stringify(report.highFrequencyWords),
      review_words: JSON.stringify(report.reviewWords),
      exercises: JSON.stringify(report.exercises),
      suggestion: report.suggestion,
      status: report.status
    };

    await this.store.insert('daily_reports', values);
  }

  async updateStatus(id: string, status: ReportStatus): Promise<void> {
    if (!this.store) {
      throw new Error('ReportRepository not initialized');
    }

    const values: relationalStore.ValuesBucket = {
      status: status
    };
    const predicates = new relationalStore.RdbPredicates('daily_reports');
    predicates.equalTo('id', id);
    await this.store.update(values, predicates);
  }

  async findByDate(date: string): Promise<DailyReport | null> {
    if (!this.store) {
      throw new Error('ReportRepository not initialized');
    }

    const predicates = new relationalStore.RdbPredicates('daily_reports');
    predicates.equalTo('date', date);
    const resultSet = await this.store.query(predicates, ['*']);
    if (resultSet.goToNextRow()) {
      return this.mapToDailyReport(resultSet);
    }
    return null;
  }

  async findById(id: string): Promise<DailyReport | null> {
    if (!this.store) {
      throw new Error('ReportRepository not initialized');
    }

    const predicates = new relationalStore.RdbPredicates('daily_reports');
    predicates.equalTo('id', id);
    const resultSet = await this.store.query(predicates, ['*']);
    if (resultSet.goToNextRow()) {
      return this.mapToDailyReport(resultSet);
    }
    return null;
  }

  async findRecentReports(limit: number = 30): Promise<DailyReport[]> {
    if (!this.store) {
      throw new Error('ReportRepository not initialized');
    }

    const predicates = new relationalStore.RdbPredicates('daily_reports');
    predicates.orderByDesc('generated_at').limitAs(limit);
    const resultSet = await this.store.query(predicates, ['*']);
    return this.mapResultSet(resultSet);
  }

  async deleteOldReports(beforeDate: string): Promise<void> {
    if (!this.store) {
      throw new Error('ReportRepository not initialized');
    }

    const predicates = new relationalStore.RdbPredicates('daily_reports');
    predicates.lessThan('date', beforeDate);
    await this.store.delete(predicates);
  }

  private mapResultSet(resultSet: relationalStore.ResultSet): DailyReport[] {
    const reports: DailyReport[] = [];
    while (resultSet.goToNextRow()) {
      reports.push(this.mapToDailyReport(resultSet));
    }
    return reports;
  }

  private parseStringArray(json: string): string[] {
    let parsed: Object | null = null;
    try {
      parsed = JSON.parse(json);
    } catch {
      return [];
    }
    if (parsed instanceof Array) {
      const arr: Object[] = parsed as Object[];
      const result: string[] = [];
      for (const item of arr) {
        if (typeof item === 'string') {
          result.push(item);
        }
      }
      return result;
    }
    return [];
  }

  private parseExercises(json: string): Exercise[] {
    let parsed: Object | null = null;
    try {
      parsed = JSON.parse(json);
    } catch {
      return [];
    }
    if (parsed instanceof Array) {
      return parsed as Exercise[];
    }
    return [];
  }

  private normalizeStatus(value: string): ReportStatus {
    const valid: ReportStatus[] = ['generated', 'viewed', 'dismissed'];
    const found = valid.find((v: ReportStatus): boolean => v === value);
    return found ?? 'generated';
  }

  private mapToDailyReport(resultSet: relationalStore.ResultSet): DailyReport {
    const getString = (col: string): string =>
      resultSet.getString(resultSet.getColumnIndex(col));
    const getLong = (col: string): number =>
      resultSet.getLong(resultSet.getColumnIndex(col));

    return {
      id: getString('id'),
      date: getString('date'),
      generatedAt: getLong('generated_at'),
      newWordsCount: getLong('new_words_count'),
      reviewedCount: getLong('reviewed_count'),
      exercisesCompleted: getLong('exercises_completed'),
      accuracyRate: getLong('accuracy_rate'),
      streakDays: getLong('streak_days'),
      studyMinutes: getLong('study_minutes'),
      highFrequencyWords: this.parseStringArray(getString('high_frequency_words')),
      reviewWords: this.parseStringArray(getString('review_words')),
      exercises: this.parseExercises(getString('exercises')),
      suggestion: getString('suggestion'),
      status: this.normalizeStatus(getString('status'))
    };
  }
}
