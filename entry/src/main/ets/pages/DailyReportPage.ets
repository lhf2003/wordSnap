import { router } from '@kit.ArkUI';
import { DailyReport, Exercise } from '../model/Types';
import { ReportService } from '../service/ReportService';
import { AppStore } from '../store/AppStore';
import { DesignTokens } from '../components/DesignTokens';
import { BottomNav } from '../components/BottomNav';

@Entry
@Component
struct DailyReportPage {
  @State report: DailyReport | null = null;
  @State history: DailyReport[] = [];
  @State isLoading: boolean = true;
  @State errorMessage: string = '';
  @State selectedExerciseId: string = '';
  @State showAnswer: boolean = false;

  private reportService: ReportService = new ReportService();

  async aboutToAppear() {
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) {
        throw new Error('无法获取应用上下文');
      }
      await this.reportService.init(context);
      await this.loadTodayReport();
      await this.loadHistory();
    } catch (err) {
      const message = err instanceof Error ? err.message : '加载报告失败';
      console.error('DailyReportPage init failed: ' + message);
      this.errorMessage = message;
      this.isLoading = false;
    }
  }

  private async loadTodayReport(): Promise<void> {
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
      console.error('DailyReportPage loadTodayReport failed: ' + message);
      this.errorMessage = message;
    } finally {
      this.isLoading = false;
    }
  }

  private async loadHistory(): Promise<void> {
    try {
      this.history = await this.reportService.getRecentReports(30);
    } catch (err) {
      const message = err instanceof Error ? err.message : '加载历史失败';
      console.error('DailyReportPage loadHistory failed: ' + message);
    }
  }

  private selectReport(report: DailyReport): void {
    this.report = report;
    this.selectedExerciseId = '';
    this.showAnswer = false;
  }

  private backToToday(): void {
    this.loadTodayReport();
    this.selectedExerciseId = '';
    this.showAnswer = false;
  }

  private navigateBack(): void {
    router.back();
  }

  private onExerciseClick(exercise: Exercise): void {
    if (this.selectedExerciseId === exercise.id) {
      this.showAnswer = !this.showAnswer;
    } else {
      this.selectedExerciseId = exercise.id;
      this.showAnswer = true;
    }
  }

  @Builder
  Header() {
    Row() {
      Text('<')
        .fontSize(28)
        .fontColor(DesignTokens.textSecondary)
        .width(48)
        .height(48)
        .textAlign(TextAlign.Center)
        .onClick(() => this.navigateBack())

      Text('学习报告')
        .fontSize(DesignTokens.font20)
        .fontWeight(FontWeight.Bold)
        .fontColor(DesignTokens.textPrimary)
        .layoutWeight(1)

      if (this.report !== null && this.report.date !== this.todayKey()) {
        Text('今天')
          .fontSize(DesignTokens.font14)
          .fontColor(DesignTokens.primary)
          .onClick(() => this.backToToday())
      }
    }
    .width('100%')
    .padding({ left: DesignTokens.spacing8, right: DesignTokens.spacing16, top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center)
  }

  private todayKey(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = (now.getMonth() + 1).toString().padStart(2, '0');
    const day = now.getDate().toString().padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  @Builder
  StatCard(label: string, value: string, color: string, marginOption?: Margin) {
    Column() {
      Text(value)
        .fontSize(DesignTokens.font24)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(DesignTokens.font12)
        .fontColor(DesignTokens.textSecondary)
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .padding(DesignTokens.spacing12)
    .margin(marginOption ?? {})
    .backgroundColor(Color.Transparent)
    .systemMaterial(DesignTokens.materialRegular)
    .borderRadius(DesignTokens.radius16)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  StatsGrid() {
    Column() {
      Text(this.report?.date ?? this.todayKey())
        .fontSize(DesignTokens.font14)
        .fontColor(DesignTokens.textSecondary)
        .margin({ bottom: DesignTokens.spacing12 })

      Row() {
        this.StatCard('新词', `${this.report?.newWordsCount ?? 0}`, DesignTokens.success, { right: DesignTokens.spacing12 })
        this.StatCard('复习', `${this.report?.reviewedCount ?? 0}`, DesignTokens.primary)
      }
      .width('100%')

      Row() {
        this.StatCard('连续', `${this.report?.streakDays ?? 0} 天`, DesignTokens.warning, { right: DesignTokens.spacing12 })
        this.StatCard('时长', `${this.report?.studyMinutes ?? 0} 分`, DesignTokens.danger)
      }
      .width('100%')
      .margin({ top: DesignTokens.spacing12 })
    }
    .width('100%')
    .padding(DesignTokens.spacing16)
    .backgroundColor(DesignTokens.bgCard)
    .borderRadius({ topLeft: DesignTokens.radius24, topRight: DesignTokens.radius24 })
  }

  @Builder
  EncouragementCard() {
    Column() {
      Text('今日鼓励')
        .fontSize(DesignTokens.font16)
        .fontWeight(FontWeight.Bold)
        .fontColor(DesignTokens.textPrimary)
        .margin({ bottom: DesignTokens.spacing8 })

      Text(this.report?.suggestion ?? '坚持学习，每天进步一点点～')
        .fontSize(DesignTokens.font14)
        .fontColor(DesignTokens.textSecondary)
        .width('100%')
        .textAlign(TextAlign.Start)
        .lineHeight(22)
    }
    .width('100%')
    .padding(DesignTokens.spacing16)
    .margin({ top: DesignTokens.spacing12 })
    .backgroundColor('rgba(52, 211, 153, 0.08)')
    .borderRadius(DesignTokens.radius16)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  WordChip(word: string) {
    Text(word)
      .fontSize(DesignTokens.font14)
      .fontColor(DesignTokens.primary)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor('rgba(108, 122, 252, 0.10)')
      .borderRadius(DesignTokens.radiusFull)
      .margin({ right: 8, bottom: 8 })
  }

  @Builder
  HighFrequencyWords() {
    Column() {
      Text('今日高频词汇')
        .fontSize(DesignTokens.font16)
        .fontWeight(FontWeight.Bold)
        .fontColor(DesignTokens.textPrimary)
        .margin({ bottom: DesignTokens.spacing12 })
        .width('100%')

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        if (this.report !== null && this.report.highFrequencyWords.length > 0) {
          ForEach(this.report.highFrequencyWords, (word: string) => {
            this.WordChip(word)
          }, (word: string) => word)
        } else {
          Text('今日还没有高频词汇，快去记录新单词吧～')
            .fontSize(DesignTokens.font14)
            .fontColor(DesignTokens.textSecondary)
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(DesignTokens.spacing16)
    .margin({ top: DesignTokens.spacing12 })
    .backgroundColor(DesignTokens.bgCard)
    .borderRadius(DesignTokens.radius16)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ExerciseCard(exercise: Exercise) {
    Column() {
      Text(exercise.question)
        .fontSize(DesignTokens.font16)
        .fontColor(DesignTokens.textPrimary)
        .width('100%')

      if (exercise.options !== undefined && exercise.options.length > 0) {
        Column() {
          ForEach(exercise.options, (option: string) => {
            Text(option)
              .fontSize(DesignTokens.font14)
              .fontColor(DesignTokens.textSecondary)
              .width('100%')
              .padding({ top: 8, bottom: 8 })
              .textAlign(TextAlign.Start)
          }, (option: string, index: number) => `${option}-${index}`)
        }
        .width('100%')
        .margin({ top: DesignTokens.spacing8 })
        .padding({ left: DesignTokens.spacing8, right: DesignTokens.spacing8 })
        .backgroundColor(DesignTokens.bgBase)
        .borderRadius(DesignTokens.radius8)
      }

      if (this.selectedExerciseId === exercise.id && this.showAnswer) {
        Column() {
          Text('正确答案：' + exercise.correctAnswer)
            .fontSize(DesignTokens.font14)
            .fontWeight(FontWeight.Medium)
            .fontColor(DesignTokens.success)
            .width('100%')
          Text(exercise.explanation)
            .fontSize(DesignTokens.font12)
            .fontColor(DesignTokens.textSecondary)
            .width('100%')
            .margin({ top: 4 })
        }
        .width('100%')
        .margin({ top: DesignTokens.spacing8 })
        .padding(DesignTokens.spacing12)
        .backgroundColor('rgba(52, 211, 153, 0.08)')
        .borderRadius(DesignTokens.radius8)
      } else {
        Text('点击查看答案')
          .fontSize(DesignTokens.font12)
          .fontColor(DesignTokens.primary)
          .margin({ top: DesignTokens.spacing8 })
      }
    }
    .width('100%')
    .padding(DesignTokens.spacing16)
    .backgroundColor(DesignTokens.bgCard)
    .borderRadius(DesignTokens.radius16)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => this.onExerciseClick(exercise))
  }

  @Builder
  ExercisesSection() {
    Column() {
      Text('今日练习')
        .fontSize(DesignTokens.font16)
        .fontWeight(FontWeight.Bold)
        .fontColor(DesignTokens.textPrimary)
        .margin({ bottom: DesignTokens.spacing12 })
        .width('100%')

      if (this.report !== null && this.report.exercises.length > 0) {
        ForEach(this.report.exercises, (exercise: Exercise) => {
          this.ExerciseCard(exercise)
        }, (exercise: Exercise) => exercise.id)
      } else {
        Text('今日还没有生成练习，记录单词后会自动生成哦～')
          .fontSize(DesignTokens.font14)
          .fontColor(DesignTokens.textSecondary)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 24, bottom: 24 })
      }
    }
    .width('100%')
    .padding(DesignTokens.spacing16)
    .margin({ top: DesignTokens.spacing12 })
    .backgroundColor(DesignTokens.bgCard)
    .borderRadius(DesignTokens.radius16)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  HistoryItem(report: DailyReport) {
    Row() {
      Column() {
        Text(report.date)
          .fontSize(DesignTokens.font14)
          .fontWeight(FontWeight.Medium)
          .fontColor(DesignTokens.textPrimary)
        Text(`新学 ${report.newWordsCount} 词 · 连续 ${report.streakDays} 天`)
          .fontSize(DesignTokens.font12)
          .fontColor(DesignTokens.textSecondary)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('>')
        .fontSize(DesignTokens.font16)
        .fontColor(DesignTokens.textTertiary)
    }
    .width('100%')
    .padding(DesignTokens.spacing12)
    .backgroundColor(DesignTokens.bgCard)
    .borderRadius(DesignTokens.radius12)
    .onClick(() => this.selectReport(report))
  }

  @Builder
  HistorySection() {
    Column() {
      Text('历史报告')
        .fontSize(DesignTokens.font16)
        .fontWeight(FontWeight.Bold)
        .fontColor(DesignTokens.textPrimary)
        .margin({ bottom: DesignTokens.spacing12 })
        .width('100%')

      if (this.history.length > 0) {
        ForEach(this.history, (report: DailyReport) => {
          this.HistoryItem(report)
        }, (report: DailyReport) => report.id)
      } else {
        Text('暂无历史报告')
          .fontSize(DesignTokens.font14)
          .fontColor(DesignTokens.textSecondary)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 24, bottom: 24 })
      }
    }
    .width('100%')
    .padding(DesignTokens.spacing16)
    .margin({ top: DesignTokens.spacing12, bottom: DesignTokens.spacing24 })
    .backgroundColor(DesignTokens.bgCard)
    .borderRadius(DesignTokens.radius16)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  LoadingState() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .color(DesignTokens.primary)
      Text('正在生成今日报告...')
        .fontSize(DesignTokens.font14)
        .fontColor(DesignTokens.textSecondary)
        .margin({ top: 12 })
    }
    .width('100%')
    .padding({ top: 80, bottom: 80 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ErrorState() {
    Column() {
      Text('加载失败')
        .fontSize(DesignTokens.font16)
        .fontWeight(FontWeight.Medium)
        .fontColor(DesignTokens.danger)
      Text(this.errorMessage)
        .fontSize(DesignTokens.font14)
        .fontColor(DesignTokens.textSecondary)
        .margin({ top: 8 })
        .textAlign(TextAlign.Center)
      Button('重新生成')
        .fontSize(DesignTokens.font14)
        .fontColor(Color.White)
        .backgroundColor(DesignTokens.primary)
        .borderRadius(DesignTokens.radiusFull)
        .padding({ left: 24, right: 24, top: 10, bottom: 10 })
        .margin({ top: 16 })
        .onClick(() => this.loadTodayReport())
    }
    .width('100%')
    .padding({ top: 60, bottom: 60 })
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        this.Header()

        if (this.isLoading) {
          this.LoadingState()
        } else if (this.errorMessage.length > 0) {
          this.ErrorState()
        } else {
          List() {
            ListItem() {
              this.StatsGrid()
            }

            ListItem() {
              this.EncouragementCard()
            }
            .padding({ left: DesignTokens.spacing16, right: DesignTokens.spacing16 })

            ListItem() {
              this.HighFrequencyWords()
            }
            .padding({ left: DesignTokens.spacing16, right: DesignTokens.spacing16 })

            ListItem() {
              this.ExercisesSection()
            }
            .padding({ left: DesignTokens.spacing16, right: DesignTokens.spacing16 })

            ListItem() {
              this.HistorySection()
            }
            .padding({ left: DesignTokens.spacing16, right: DesignTokens.spacing16 })

            ListItem() {
              Column().width('100%').height(96)
            }
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .listDirection(Axis.Vertical)
          .edgeEffect(EdgeEffect.None)
          .backgroundColor(DesignTokens.bgBase)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(DesignTokens.bgBase)

      BottomNav({ activeIndex: 2 })
    }
    .width('100%')
    .height('100%')
  }
}
