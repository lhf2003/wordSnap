import { WordRecord, WordDetailParam } from '../model/Types';
import { LibraryViewModel, FilterTab } from '../viewmodel/LibraryViewModel';
import { DesignTokens } from '../components/DesignTokens';
import { BottomNav } from '../components/BottomNav';
import { LibraryWordCard } from '../components/LibraryWordCard';
import { TimeUtils } from '../utils/TimeUtils';

@Styles
function pressedLibraryCard() {
  .opacity(0.92)
}

@ComponentV2
export struct LibraryPage {
  @Local viewModel: LibraryViewModel = new LibraryViewModel();
  @Consumer('navPath') navPath: NavPathStack = new NavPathStack();
  private isInitializing: boolean = false;
  private isInitialized: boolean = false;
  private isFirstShown: boolean = true;

  async aboutToAppear() {
    await this.initialize();
  }

  async onShown() {
    console.info('LibraryPage onShown isFirstShown=' + this.isFirstShown + ' isInitializing=' + this.isInitializing + ' isLoading=' + this.viewModel.isLoading + ' isInitialized=' + this.isInitialized);
    if (this.isFirstShown) {
      this.isFirstShown = false;
      return;
    }
    if (this.isInitializing) {
      console.info('LibraryPage onShown skipped due to initializing');
      return;
    }
    if (!this.isInitialized) {
      await this.initialize();
      return;
    }
    await this.viewModel.loadData();
  }

  private async initialize(): Promise<void> {
    if (this.isInitializing) {
      return;
    }
    this.isInitializing = true;
    this.viewModel.isLoading = false;
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) {
        throw new Error('无法获取应用上下文');
      }
      await this.viewModel.init(context);
      await this.viewModel.loadData();
      this.isInitialized = true;
    } catch (err) {
      const message = err instanceof Error ? err.message : '加载数据失败';
      console.error('LibraryPage initialize failed: ' + message);
      this.viewModel.errorMessage = message;
      this.viewModel.isLoading = false;
    } finally {
      this.isInitializing = false;
    }
  }

  private onSearchChange(value: string): void {
    this.viewModel.setSearchQuery(value);
  }

  private onTabChange(tab: FilterTab): void {
    this.viewModel.setActiveTab(tab);
  }

  private navigateToDetail(word: WordRecord): void {
    console.info('LibraryPage navigateToDetail wordId=' + word.id);
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

  @Builder
  Header() {
    Row() {
      Text('Library')
        .fontSize(DesignTokens.font28)
        .fontWeight(FontWeight.Bold)
        .fontColor(DesignTokens.textPrimary)
        .layoutWeight(1)

      Text(`${this.viewModel.words.length} WORDS`)
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

        TextInput({ placeholder: 'Search captures...', text: this.viewModel.searchQuery })
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
      .fontColor(this.viewModel.activeTab === tab ? DesignTokens.textOnPrimary : DesignTokens.textSecondary)
      .backgroundColor(this.viewModel.activeTab === tab ? DesignTokens.primary : DesignTokens.primarySurfaceSubtle)
      .borderRadius(DesignTokens.radiusFull)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .onClick(() => this.onTabChange(tab))
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

              if (this.viewModel.isLoading) {
                this.LoadingState()
              } else if (this.viewModel.filteredWords.length === 0) {
                this.EmptyState()
              } else {
                Grid() {
                  Repeat<WordRecord>(this.viewModel.filteredWords)
                    .each((obj: RepeatItem<WordRecord>) => {
                      GridItem() {
                        LibraryWordCard({
                          word: obj.item,
                          onCardClick: () => this.navigateToDetail(obj.item)
                        })
                      }
                    })
                    .key((item: WordRecord) => item.id + '_' + item.word + '_' + (item.definition ?? item.translation.join(',')) + '_' + (item.exampleSentence ?? '') + '_' + item.proficiency + '_' + item.createdAt)
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
    .onShown(() => this.onShown())
    .onBackPressed(() => {
      this.navPath.pop();
      return true;
    })
  }
}
