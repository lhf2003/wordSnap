import { DailyReport, Exercise } from '../model/Types';
import { DailyReportViewModel } from '../viewmodel/DailyReportViewModel';
import { DesignTokens } from '../components/DesignTokens';
import { BottomNav } from '../components/BottomNav';

@ComponentV2
export struct DailyReportPage {
  @Local viewModel: DailyReportViewModel = new DailyReportViewModel();
  @Consumer('navPath') navPath: NavPathStack = new NavPathStack();
  private isInitializing: boolean = false;

  async aboutToAppear() {
    await this.initialize();
  }

  async onShown() {
    await this.initialize();
  }

  private async initialize(): Promise<void> {
    if (this.isInitializing) {
      return;
    }
    this.isInitializing = true;
    this.viewModel.errorMessage = '';
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) {
        throw new Error('无法获取应用上下文');
      }
      await this.viewModel.init(context);
      await this.viewModel.initialize();
    } catch (err) {
      const message = err instanceof Error ? err.message : '加载报告失败';
      console.error('DailyReportPage initialize failed: ' + message);
      this.viewModel.errorMessage = message;
      this.viewModel.isLoading = false;
    } finally {
      this.isInitializing = false;
    }
  }

  private async retryLoad(): Promise<void> {
    this.viewModel.errorMessage = '';
    await this.viewModel.initialize();
  }

  private navigateBack(): void {
    this.navPath.pop();
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

      if (this.viewModel.report !== null && this.viewModel.report.date !== this.viewModel.todayKey()) {
        Text('今天')
          .fontSize(DesignTokens.font14)
          .fontColor(DesignTokens.primary)
          .onClick(() => this.viewModel.backToToday())
      }
    }
    .width('100%')
    .padding({ left: DesignTokens.spacing8, right: DesignTokens.spacing16, top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center)
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
      Text(this.viewModel.report?.date ?? this.viewModel.todayKey())
        .fontSize(DesignTokens.font14)
        .fontColor(DesignTokens.textSecondary)
        .margin({ bottom: DesignTokens.spacing12 })

      Row() {
        this.StatCard('新词', `${this.viewModel.report?.newWordsCount ?? 0}`, DesignTokens.success, { right: DesignTokens.spacing12 })
        this.StatCard('复习', `${this.viewModel.report?.reviewedCount ?? 0}`, DesignTokens.primary)
      }
      .width('100%')

      Row() {
        this.StatCard('连续', `${this.viewModel.report?.streakDays ?? 0} 天`, DesignTokens.warning, { right: DesignTokens.spacing12 })
        this.StatCard('时长', `${this.viewModel.report?.studyMinutes ?? 0} 分`, DesignTokens.danger)
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

      Text(this.viewModel.report?.suggestion ?? '坚持学习，每天进步一点点～')
        .fontSize(DesignTokens.font14)
        .fontColor(DesignTokens.textSecondary)
        .width('100%')
        .textAlign(TextAlign.Start)
        .lineHeight(22)
    }
    .width('100%')
    .padding(DesignTokens.spacing16)
    .margin({ top: DesignTokens.spacing12 })
    .backgroundColor(DesignTokens.successSurfaceSoft)
    .borderRadius(DesignTokens.radius16)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  WordChip(word: string) {
    Text(word)
      .fontSize(DesignTokens.font14)
      .fontColor(DesignTokens.primary)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor(DesignTokens.primarySurfaceSoft)
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
        if (this.viewModel.report !== null && this.viewModel.report.highFrequencyWords.length > 0) {
          Repeat<string>(this.viewModel.report.highFrequencyWords)
            .each((obj: RepeatItem<string>) => {
              this.WordChip(obj.item)
            })
            .key((item: string) => item)
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
          Repeat<string>(exercise.options)
            .each((obj: RepeatItem<string>) => {
              Text(obj.item)
                .fontSize(DesignTokens.font14)
                .fontColor(DesignTokens.textSecondary)
                .width('100%')
                .padding({ top: 8, bottom: 8 })
                .textAlign(TextAlign.Start)
            })
            .key((item: string, index: number) => `${item}-${index}`)
        }
        .width('100%')
        .margin({ top: DesignTokens.spacing8 })
        .padding({ left: DesignTokens.spacing8, right: DesignTokens.spacing8 })
        .backgroundColor(DesignTokens.bgBase)
        .borderRadius(DesignTokens.radius8)
      }

      if (this.viewModel.selectedExerciseId === exercise.id && this.viewModel.showAnswer) {
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
        .backgroundColor(DesignTokens.successSurfaceSoft)
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
    .onClick(() => this.viewModel.onExerciseClick(exercise))
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

      if (this.viewModel.report !== null && this.viewModel.report.exercises.length > 0) {
        Repeat<Exercise>(this.viewModel.report.exercises)
          .each((obj: RepeatItem<Exercise>) => {
            this.ExerciseCard(obj.item)
          })
          .key((item: Exercise) => item.id)
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
    .onClick(() => this.viewModel.selectReport(report))
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

      if (this.viewModel.history.length > 0) {
        Repeat<DailyReport>(this.viewModel.history)
          .each((obj: RepeatItem<DailyReport>) => {
            this.HistoryItem(obj.item)
          })
          .key((item: DailyReport) => item.id)
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
      Text(this.viewModel.errorMessage)
        .fontSize(DesignTokens.font14)
        .fontColor(DesignTokens.textSecondary)
        .margin({ top: 8 })
        .textAlign(TextAlign.Center)
      Button('重新生成')
        .fontSize(DesignTokens.font14)
        .fontColor(DesignTokens.textOnPrimary)
        .backgroundColor(DesignTokens.primary)
        .borderRadius(DesignTokens.radiusFull)
        .padding({ left: 24, right: 24, top: 10, bottom: 10 })
        .margin({ top: 16 })
        .onClick(() => this.retryLoad())
    }
    .width('100%')
    .padding({ top: 60, bottom: 60 })
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          this.Header()

          if (this.viewModel.isLoading) {
            this.LoadingState()
          } else if (this.viewModel.errorMessage.length > 0) {
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
    .hideTitleBar(true)
    .onBackPressed(() => {
      this.navPath.pop();
      return true;
    })
  }
}
