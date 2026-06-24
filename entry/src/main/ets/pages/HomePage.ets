import { WordRecord, WordDetailParam } from '../model/Types';
import { WordService } from '../service/WordService';
import { AppStore } from '../store/AppStore';
import { DesignTokens } from '../components/DesignTokens';
import { BottomNav } from '../components/BottomNav';
import { TimeUtils } from '../utils/TimeUtils';
import { Context } from '@kit.AbilityKit';

@Styles
function pressedSubtle() {
  .opacity(0.85)
}

@Styles
function pressedCard() {
  .opacity(0.92)
}

@Styles
function pressedText() {
  .opacity(0.7)
}

interface MarginOption {
  top?: number;
  bottom?: number;
  left?: number;
  right?: number;
}

@ComponentV2
export struct HomePage {
  private wordService: WordService = new WordService();
  @Local wordList: WordRecord[] = [];
  @Local todayCount: number = 0;
  @Local totalCount: number = 0;
  @Local reviewCount: number = 0;
  @Local isLoading: boolean = true;
  @Local errorMessage: string = '';
  @Local userName: string = '朋友';
  @Consumer('navPath') navPath: NavPathStack = new NavPathStack();
  private isInitializing: boolean = false;
  private isInitialized: boolean = false;

  async aboutToAppear() {
    await this.initialize();
  }

  async onShown() {
    if (this.isInitializing) {
      return;
    }
    if (!this.isInitialized) {
      await this.initialize();
      return;
    }
    if (!this.isLoading) {
      await this.loadData();
    }
  }

  private async initAppStore(context: Context): Promise<void> {
    const store = AppStore.getInstance();
    store.setContext(context);
    await store.load();
    this.userName = store.userProfile.nickname?.trim() || '朋友';
  }

  private async initWordService(context: Context): Promise<void> {
    await this.wordService.init(context);
  }

  private async initialize(): Promise<void> {
    if (this.isInitializing) {
      return;
    }
    this.isInitializing = true;
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) {
        throw new Error('无法获取应用上下文');
      }
      await this.initAppStore(context);
      await this.initWordService(context);
      await this.loadData();
      this.isInitialized = true;
    } catch (err) {
      const message = err instanceof Error ? err.message : '加载数据失败';
      console.error('Failed to load index data: ' + message);
      this.errorMessage = message;
      this.isLoading = false;
    } finally {
      this.isInitializing = false;
    }
  }

  async loadData() {
    if (this.isLoading) {
      return;
    }
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const todayWords = await this.wordService.getTodayWords();
      const statistics = await this.wordService.getStatistics();
      this.wordList = todayWords;
      this.todayCount = statistics.todayWords;
      this.totalCount = statistics.totalWords;
      this.reviewCount = statistics.reviewWords;
      AppStore.getInstance().setStatistics(statistics.todayWords, statistics.totalWords, statistics.reviewWords);
    } catch (err) {
      const message = err instanceof Error ? err.message : '加载数据失败';
      console.error('Failed to load data:', message);
      this.errorMessage = message;
    } finally {
      this.isLoading = false;
    }
  }

  private async retryLoad(): Promise<void> {
    this.isInitialized = false;
    await this.initialize();
  }

  private navigateToCapture(): void {
    this.navPath.pushPathByName('QuickCapturePage', null);
  }

  private navigateToLibrary(): void {
    this.navPath.replacePath({ name: 'LibraryPage' });
  }

  private navigateToWordDetail(word: WordRecord): void {
    const param: WordDetailParam = { wordId: word.id };
    this.navPath.pushPathByName('WordDetailPage', param);
  }

  private greetingText(): string {
    const hour = new Date().getHours();
    let prefix = '早上好';
    if (hour >= 12 && hour < 18) {
      prefix = '下午好';
    } else if (hour >= 18) {
      prefix = '晚上好';
    }
    return `${prefix}，${this.userName}`;
  }

  private greetingSubtitle(): string {
    return '今天也继续收集新词吧';
  }

  private statusLabel(proficiency: number): string {
    if (proficiency >= 5) {
      return '已掌握';
    }
    if (proficiency < 3) {
      return '待复习';
    }
    return '学习中';
  }

  private statusIcon(proficiency: number): string {
    if (proficiency >= 5) {
      return '✓';
    }
    if (proficiency < 3) {
      return '↻';
    }
    return '•';
  }

  private statusColor(proficiency: number): string {
    if (proficiency >= 5) {
      return DesignTokens.success;
    }
    if (proficiency < 3) {
      return DesignTokens.warning;
    }
    return DesignTokens.primary;
  }

  private statusSurface(proficiency: number): string {
    if (proficiency >= 5) {
      return DesignTokens.successSurface;
    }
    if (proficiency < 3) {
      return DesignTokens.warningSurface;
    }
    return DesignTokens.primarySurface;
  }

  @Builder
  MicButton() {
    Button() {
      Column() {
        Row()
          .width(6)
          .height(10)
          .backgroundColor(DesignTokens.textPrimary)
          .borderRadius(3)
        Row()
          .width(12)
          .height(6)
          .backgroundColor(DesignTokens.textPrimary)
          .borderRadius({ topLeft: 6, topRight: 6 })
          .margin({ top: -3 })
      }
      .width(24)
      .height(24)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width(48)
    .height(48)
    .backgroundColor(Color.Transparent)
    .systemMaterial(DesignTokens.materialRegular)
    .borderRadius(DesignTokens.radiusFull)
    .stateStyles({
      pressed: pressedSubtle
    })
    .onClick(() => this.navigateToCapture())
  }

  @Builder
  Header() {
    Row() {
      Column() {
        Text(this.greetingText())
          .fontSize(DesignTokens.font24)
          .fontWeight(FontWeight.Bold)
          .fontColor(DesignTokens.textPrimary)
        Text(this.greetingSubtitle())
          .fontSize(DesignTokens.font14)
          .fontColor(DesignTokens.textSecondary)
          .margin({ top: DesignTokens.spacing4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      this.MicButton()
    }
    .width('100%')
    .padding(DesignTokens.spacing16)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  StatCard(label: string, value: string, color: string, margin?: MarginOption) {
    Column() {
      Text(value)
        .fontSize(DesignTokens.font28)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(DesignTokens.font12)
        .fontWeight(FontWeight.Medium)
        .fontColor(DesignTokens.textSecondary)
        .margin({ top: DesignTokens.spacing4 })
    }
    .layoutWeight(1)
    .margin(margin)
    .padding(DesignTokens.spacing16)
    .borderRadius(DesignTokens.radius24)
    .backgroundColor(Color.Transparent)
    .systemMaterial(DesignTokens.materialGlowPreset)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  StatsRow() {
    Row() {
      this.StatCard('今日', this.todayCount.toString(), DesignTokens.success,
        { right: DesignTokens.spacing8 })
      this.StatCard('累计', this.totalCount.toString(), DesignTokens.primary,
        { left: DesignTokens.spacing8, right: DesignTokens.spacing8 })
      this.StatCard('待复习', this.reviewCount.toString(), DesignTokens.warning,
        { left: DesignTokens.spacing8 })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ top: DesignTokens.spacing8, bottom: DesignTokens.spacing16 })
  }

  @Builder
  PlusButton() {
    Button() {
      Row() {
        Row()
          .width(16)
          .height(2)
          .backgroundColor(DesignTokens.textOnPrimary)
          .borderRadius(1)
        Row()
          .width(2)
          .height(16)
          .backgroundColor(DesignTokens.textOnPrimary)
          .borderRadius(1)
      }
      .width(24)
      .height(24)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    }
    .width(56)
    .height(56)
    .backgroundColor(DesignTokens.primary)
    .borderRadius(DesignTokens.radiusFull)
    .shadow({
      radius: 12,
      color: DesignTokens.shadow,
      offsetY: 4
    })
  }

  @Builder
  CaptureMomentCard() {
    Row() {
      Column() {
        Text('记录此刻')
          .fontSize(DesignTokens.font18)
          .fontWeight(FontWeight.Bold)
          .fontColor(DesignTokens.textPrimary)
        Text('今天看到了什么？')
          .fontSize(DesignTokens.font12)
          .fontColor(DesignTokens.textSecondary)
          .margin({ top: DesignTokens.spacing4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      this.PlusButton()
    }
    .width('100%')
    .height(96)
    .padding(DesignTokens.spacing16)
    .backgroundColor(Color.Transparent)
    .systemMaterial(DesignTokens.materialRegular)
    .borderRadius(DesignTokens.radius24)
    .stateStyles({
      pressed: pressedCard
    })
    .onClick(() => this.navigateToCapture())
  }

  @Builder
  StatusBadge(word: WordRecord) {
    Row() {
      Text(this.statusIcon(word.proficiency))
        .fontSize(DesignTokens.font10)
        .fontColor(this.statusColor(word.proficiency))
        .margin({ right: DesignTokens.spacing4 })
      Text(this.statusLabel(word.proficiency))
        .fontSize(DesignTokens.font10)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.statusColor(word.proficiency))
    }
    .backgroundColor(this.statusSurface(word.proficiency))
    .padding({ left: DesignTokens.spacing8, right: DesignTokens.spacing8, top: DesignTokens.spacing4, bottom: DesignTokens.spacing4 })
    .borderRadius(DesignTokens.radiusFull)
  }

  @Builder
  WordCard(word: WordRecord) {
    Row() {
      Column() {
        Text(word.word)
          .fontSize(DesignTokens.font18)
          .fontWeight(FontWeight.Medium)
          .fontColor(DesignTokens.textPrimary)
        Text(word.exampleSentence ?? '—')
          .fontSize(DesignTokens.font14)
          .fontColor(DesignTokens.textSecondary)
          .margin({ top: DesignTokens.spacing4 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(word.translation.length > 0 ? word.translation.join('；') : '暂无释义')
          .fontSize(DesignTokens.font12)
          .fontColor(DesignTokens.textTertiary)
          .margin({ top: 2 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(TimeUtils.formatRelativeTime(word.createdAt))
          .fontSize(DesignTokens.font10)
          .fontColor(DesignTokens.textTertiary)
          .margin({ top: 6 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      this.StatusBadge(word)
    }
    .width('100%')
    .padding(DesignTokens.spacing16)
    .backgroundColor(Color.Transparent)
    .systemMaterial(DesignTokens.materialThin)
    .borderRadius(DesignTokens.radius20)
    .stateStyles({
      pressed: pressedCard
    })
    .onClick(() => this.navigateToWordDetail(word))
  }

  @Builder
  SectionHeader() {
    Row() {
      Text('最近记录')
        .fontSize(DesignTokens.font18)
        .fontWeight(FontWeight.Bold)
        .fontColor(DesignTokens.textPrimary)
        .layoutWeight(1)
      Text('查看全部')
        .fontSize(DesignTokens.font12)
        .fontWeight(FontWeight.Medium)
        .fontColor(DesignTokens.primary)
        .stateStyles({
          pressed: pressedText
        })
        .onClick(() => this.navigateToLibrary())
    }
    .width('100%')
    .margin({ bottom: DesignTokens.spacing12 })
  }

  @Builder
  TopContent() {
    Column() {
      this.StatsRow()

      Column() {
        this.CaptureMomentCard()
      }
      .width('100%')
      .padding({ left: DesignTokens.spacing16, right: DesignTokens.spacing16, bottom: DesignTokens.spacing16 })
    }
    .width('100%')
  }

  @Builder
  SectionHeaderItem() {
    Column() {
      this.SectionHeader()
    }
    .width('100%')
    .padding(DesignTokens.spacing16)
  }

  @Builder
  ListFooter() {
    Blank().height(96)
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
        .margin({ top: DesignTokens.spacing8 })
        .textAlign(TextAlign.Center)
      Button('重新加载')
        .fontSize(DesignTokens.font14)
        .fontColor(DesignTokens.textOnPrimary)
        .backgroundColor(DesignTokens.primary)
        .borderRadius(DesignTokens.radiusFull)
        .padding({ left: DesignTokens.spacing24, right: DesignTokens.spacing24, top: 10, bottom: 10 })
        .margin({ top: DesignTokens.spacing16 })
        .onClick(() => this.retryLoad())
    }
    .width('100%')
    .padding({ top: 60, bottom: 60 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  EmptyState() {
    Column() {
      Text('今天还没有新词')
        .fontSize(DesignTokens.font16)
        .fontWeight(FontWeight.Medium)
        .fontColor(DesignTokens.textSecondary)
      Text('点击“记录此刻”，把看到的世界变成英语吧')
        .fontSize(DesignTokens.font14)
        .fontColor(DesignTokens.textSecondary)
        .margin({ top: DesignTokens.spacing8 })
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ top: 60, bottom: 60 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  LoadingState() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .color(DesignTokens.primary)
        .margin({ top: 40 })
    }
    .width('100%')
    .padding({ top: 40, bottom: 40 })
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          this.Header()

          List() {
            ListItem() {
              this.TopContent()
            }
            .backgroundColor(DesignTokens.bgBase)

            ListItem() {
              this.SectionHeaderItem()
            }
            .backgroundColor(DesignTokens.bgCard)
            .borderRadius({ topLeft: DesignTokens.radius24, topRight: DesignTokens.radius24 })

            if (this.isLoading) {
              ListItem() {
                this.LoadingState()
              }
              .backgroundColor(DesignTokens.bgCard)
            } else if (this.errorMessage.length > 0) {
              ListItem() {
                this.ErrorState()
              }
              .backgroundColor(DesignTokens.bgCard)
            } else if (this.wordList.length === 0) {
              ListItem() {
                this.EmptyState()
              }
              .backgroundColor(DesignTokens.bgCard)
            } else {
              ForEach(this.wordList, (word: WordRecord) => {
                ListItem() {
                  this.WordCard(word)
                }
                .backgroundColor(DesignTokens.bgCard)
                .margin({ bottom: DesignTokens.spacing12 })
              }, (word: WordRecord) => word.id)
            }

            ListItem() {
              this.ListFooter()
            }
            .backgroundColor(DesignTokens.bgCard)
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor(DesignTokens.bgCard)
          .scrollBar(BarState.Off)
          .listDirection(Axis.Vertical)
          .edgeEffect(EdgeEffect.None)
        }
        .width('100%')
        .height('100%')
        .backgroundColor(DesignTokens.bgBase)

        BottomNav({ activeIndex: 0 })
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
