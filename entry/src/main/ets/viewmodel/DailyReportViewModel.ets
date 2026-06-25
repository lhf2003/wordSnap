import { DailyReport, Exercise } from '../model/Types';
import { ReportService } from '../service/ReportService';
import { AppStore } from '../store/AppStore';
import { Context } from '@kit.AbilityKit';

@ObservedV2
export class DailyReportViewModel {
  @Trace report: DailyReport | null = null;
  @Trace history: DailyReport[] = [];
  @Trace isLoading: boolean = true;
  @Trace errorMessage: string = '';
  @Trace selectedExerciseId: string = '';
  @Trace showAnswer: boolean = false;

  private reportService: ReportService = new ReportService();
  private initialized: boolean = false;

  async init(context: Context): Promise<void> {
    if (this.initialized) {
      return;
    }
    await this.reportService.init(context);
    this.initialized = true;
  }

  async loadTodayReport(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const report = await this.reportService.generateReport(new Date());
      this.report = report;
      AppStore.getInstance().setCurrentReport(report);
      if (report.status === 'generated') {
        await this.reportService.markAsViewed(report.id);
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : '生成报告失败';
      console.error('DailyReportViewModel loadTodayReport failed: ' + message);
      this.errorMessage = message;
    } finally {
      this.isLoading = false;
    }
  }

  async loadHistory(): Promise<void> {
    try {
      this.history = await this.reportService.getRecentReports(30);
    } catch (err) {
      const message = err instanceof Error ? err.message : '加载历史失败';
      console.error('DailyReportViewModel loadHistory failed: ' + message);
    }
  }

  async initialize(): Promise<void> {
    await this.loadTodayReport();
    await this.loadHistory();
  }

  selectReport(report: DailyReport): void {
    this.report = report;
    this.selectedExerciseId = '';
    this.showAnswer = false;
  }

  backToToday(): void {
    this.loadTodayReport();
    this.selectedExerciseId = '';
    this.showAnswer = false;
  }

  onExerciseClick(exercise: Exercise): void {
    if (this.selectedExerciseId === exercise.id) {
      this.showAnswer = !this.showAnswer;
    } else {
      this.selectedExerciseId = exercise.id;
      this.showAnswer = true;
    }
  }

  todayKey(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = (now.getMonth() + 1).toString().padStart(2, '0');
    const day = now.getDate().toString().padStart(2, '0');
    return `${year}-${month}-${day}`;
  }
}
