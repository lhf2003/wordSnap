import { WordRecord, WordDetailParam } from '../model/Types';
import { WordService } from '../service/WordService';
import { DesignTokens } from '../components/DesignTokens';
import { BottomNav } from '../components/BottomNav';
import { TimeUtils } from '../utils/TimeUtils';

type FilterTab = 'all' | 'mastered' | 'reviewing' | 'new';

@ComponentV2
export struct LibraryPage {
  private wordService: WordService = new WordService();
  @Local words: WordRecord[] = [];
  @Local filteredWords: WordRecord[] = [];
  @Local searchQuery: string = '';
  @Local activeTab: FilterTab = 'all';
  @Local isLoading: boolean = true;
  @Local errorMessage: string = '';
  @Consumer('navPath') navPath: NavPathStack = new NavPathStack();
  private isInitializing: boolean = false;

  async aboutToAppear() {
    await this.initialize();
  }

  async onShown() {
    await this.initialize();
  }

  private async initWordService(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      throw new Error('无法获取应用上下文');
    }
    await this.wordService.init(context);
  }

  private async initialize(): Promise<void> {
    if (this.isInitializing) {
      return;
    }
    this.isInitializing = true;
    try {
      await this.initWordService();
      await this.loadData();
    } catch (err) {
      const message = err instanceof Error ? err.message : '加载数据失败';
      console.error('Failed to load library data: ' + message);
      this.errorMessage = message;
      this.isLoading = false;
    } finally {
      this.isInitializing = false;
    }
  }

  private async loadData(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      this.words = await this.wordService.getAllWords();
      this.applyFilters();
    } catch (err) {
      const message = err instanceof Error ? err.message : '加载数据失败';
      console.error('Failed to load library words:', message);
      this.errorMessage = message;
    } finally {
      this.isLoading = false;
    }
  }

  private applyFilters(): void {
    let result = this.words;

    if (this.activeTab === 'mastered') {
      result = result.filter(w => w.proficiency >= 5);
    } else if (this.activeTab === 'reviewing') {
      result = result.filter(w => w.proficiency >= 1 && w.proficiency <= 4);
    } else if (this.activeTab === 'new') {
      result = result.filter(w => w.proficiency === 0);
    }

    const query = this.searchQuery.trim().toLowerCase();
    if (query.length > 0) {
      result = result.filter(w =>
        w.word.toLowerCase().includes(query) ||
        w.translation.some(t => t.toLowerCase().includes(query)) ||
        w.tags.some(t => t.toLowerCase().includes(query))
      );
    }

    this.filteredWords = result;
  }

  private onSearchChange(value: string): void {
    this.searchQuery = value;
    this.applyFilters();
  }

  private onTabChange(tab: FilterTab): void {
    this.activeTab = tab;
    this.applyFilters();
  }

  private navigateToDetail(word: WordRecord): void {
    const param: WordDetailParam = { wordId: word.id };
    this.navPath.pushPathByName('WordDetailPage', param);
  }

  private statusColor(word: WordRecord): ResourceColor {
    if (word.proficiency >= 5) {
      return DesignTokens.success;
    }
    if (word.proficiency >= 1) {
      return DesignTokens.warning;
    }
    return DesignTokens.primary;
  }

  private statusLabel(word: WordRecord): string {
    if (word.proficiency >= 5) {
      return 'Mastered';
    }
    if (word.proficiency >= 1) {
      return 'Reviewing';
    }
    return 'New';
  }

  private shortDefinition(word: WordRecord): string {
    if (word.definition && word.definition.length > 0) {
      return word.definition;
    }
    if (word.translation.length > 0) {
      return word.translation.join('；');
    }
    return word.exampleSentence ?? '暂无释义';
  }

  @Builder
  Header() {
    Row() {
      Text('Library')
        .fontSize(DesignTokens.font28)
        .fontWeight(FontWeight.Bold)
        .fontColor(DesignTokens.textPrimary)
        .layoutWeight(1)

      Text(`${this.words.length} WORDS`)
        .fontSize(DesignTokens.font12)
        .fontWeight(FontWeight.Medium)
        .fontColor(DesignTokens.textTertiary)
    }
    .width('100%')
    .padding(DesignTokens.spacing16)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  SearchIcon() {
    Column() {
      Circle()
        .width(8)
        .height(8)
        .stroke(DesignTokens.textTertiary)
        .strokeWidth(1.5)
        .fill(Color.Transparent)
      Row()
        .width(6)
        .height(1.5)
        .backgroundColor(DesignTokens.textTertiary)
        .borderRadius(1)
        .rotate({ angle: 45 })
        .margin({ top: -4 })
    }
    .width(16)
    .height(16)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  FilterIcon() {
    Column() {
      Row()
        .width(14)
        .height(2)
        .backgroundColor(DesignTokens.textSecondary)
        .borderRadius(1)
      Row()
        .width(10)
        .height(2)
        .backgroundColor(DesignTokens.textSecondary)
        .borderRadius(1)
        .margin({ top: 4 })
      Row()
        .width(6)
        .height(2)
        .backgroundColor(DesignTokens.textSecondary)
        .borderRadius(1)
        .margin({ top: 4 })
    }
    .width(16)
    .height(16)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  SearchBar() {
    Row() {
      Row() {
        this.SearchIcon()

        TextInput({ placeholder: 'Search captures...', text: this.searchQuery })
          .placeholderColor(DesignTokens.textTertiary)
          .fontSize(DesignTokens.font14)
          .fontColor(DesignTokens.textPrimary)
          .backgroundColor(Color.Transparent)
          .padding(0)
          .layoutWeight(1)
          .margin({ left: DesignTokens.spacing8 })
          .onChange((value: string) => this.onSearchChange(value))
      }
      .layoutWeight(1)
      .height(40)
      .padding({ left: DesignTokens.spacing12, right: DesignTokens.spacing12 })
      .backgroundColor(Color.Transparent)
      .borderRadius(DesignTokens.radiusFull)

      Button() {
        this.FilterIcon()
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .borderRadius(DesignTokens.radiusFull)
    }
    .width('100%')
    .height(56)
    .padding({ left: DesignTokens.spacing16, right: DesignTokens.spacing16 })
    .backgroundColor(Color.Transparent)
    .systemMaterial(DesignTokens.materialRegular)
    .borderRadius(DesignTokens.radiusFull)
    .margin({ left: DesignTokens.spacing16, right: DesignTokens.spacing16, bottom: DesignTokens.spacing16 })
  }

  @Builder
  FilterTabs() {
    Row({ space: DesignTokens.spacing8 }) {
      this.FilterTabButton('All', 'all')
      this.FilterTabButton('Mastered', 'mastered')
      this.FilterTabButton('Reviewing', 'reviewing')
      this.FilterTabButton('New', 'new')
    }
    .width('100%')
    .padding({ left: DesignTokens.spacing16, right: DesignTokens.spacing16, bottom: DesignTokens.spacing16 })
  }

  @Builder
  FilterTabButton(label: string, tab: FilterTab) {
    Button(label)
      .fontSize(DesignTokens.font12)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.activeTab === tab ? DesignTokens.textOnPrimary : DesignTokens.textSecondary)
      .backgroundColor(this.activeTab === tab ? DesignTokens.primary : DesignTokens.primarySurfaceSubtle)
      .borderRadius(DesignTokens.radiusFull)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .onClick(() => this.onTabChange(tab))
  }

  @Builder
  WordCard(word: WordRecord) {
    Column() {
      Row() {
        Blank().layoutWeight(1)

        Row()
          .width(8)
          .height(8)
          .backgroundColor(this.statusColor(word))
          .borderRadius(DesignTokens.radiusFull)
      }
      .width('100%')
      .margin({ bottom: DesignTokens.spacing12 })

      Text(word.word)
        .fontSize(DesignTokens.font18)
        .fontWeight(FontWeight.Medium)
        .fontColor(DesignTokens.textPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Text(this.shortDefinition(word))
        .fontSize(DesignTokens.font12)
        .fontColor(DesignTokens.textSecondary)
        .margin({ top: 4 })
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Blank().layoutWeight(1)

      Text(TimeUtils.formatRelativeTime(word.createdAt).toUpperCase())
        .fontSize(DesignTokens.font10)
        .fontWeight(FontWeight.Medium)
        .fontColor(DesignTokens.textTertiary)
        .width('100%')
    }
    .width('100%')
    .aspectRatio(1)
    .padding(DesignTokens.spacing16)
    .backgroundColor(Color.Transparent)
    .systemMaterial(DesignTokens.materialThin)
    .borderRadius(DesignTokens.radius20)
    .alignItems(HorizontalAlign.Start)
    .stateStyles({
      pressed: {
        .opacity(0.92)
      }
    })
    .onClick(() => this.navigateToDetail(word))
  }

  @Builder
  EmptyState() {
    Column() {
      Text('No words found')
        .fontSize(DesignTokens.font16)
        .fontWeight(FontWeight.Medium)
        .fontColor(DesignTokens.textSecondary)
      Text('Try a different search or filter')
        .fontSize(DesignTokens.font14)
        .fontColor(DesignTokens.textTertiary)
        .margin({ top: 8 })
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

          Scroll() {
            Column() {
              this.SearchBar()
              this.FilterTabs()

              if (this.isLoading) {
                this.LoadingState()
              } else if (this.filteredWords.length === 0) {
                this.EmptyState()
              } else {
                Grid() {
                  ForEach(this.filteredWords, (word: WordRecord) => {
                    GridItem() {
                      this.WordCard(word)
                    }
                  }, (word: WordRecord) => word.id)
                }
                .columnsTemplate('1fr 1fr')
                .columnsGap(DesignTokens.spacing12)
                .rowsGap(DesignTokens.spacing12)
                .width('100%')
                .padding({ left: DesignTokens.spacing16, right: DesignTokens.spacing16 })
              }

              Blank().height(96)
            }
            .width('100%')
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .backgroundColor(DesignTokens.bgBase)
        }
        .width('100%')
        .height('100%')
        .backgroundColor(DesignTokens.bgBase)

        BottomNav({ activeIndex: 1 })
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
