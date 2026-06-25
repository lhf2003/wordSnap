import { WordRecord, WordDetailParam } from '../model/Types';
import { HomeViewModel } from '../viewmodel/HomeViewModel';
import { DesignTokens } from '../components/DesignTokens';
import { BottomNav } from '../components/BottomNav';
import { HomeWordCard } from '../components/HomeWordCard';
import { Context } from '@kit.AbilityKit';

@Styles
function pressedSubtle() {
  .opacity(0.85)
}

@Styles
function pressedCard() {
  .opacity(0.92)
}

interface MarginOption {
  top?: number;
  bottom?: number;
  left?: number;
  right?: number;
}

@ComponentV2
export struct HomePage {
  @Local viewModel: HomeViewModel = new HomeViewModel();
  @Consumer('navPath') navPath: NavPathStack = new NavPathStack();
  private isInitializing: boolean = false;
  private isInitialized: boolean = false;
  private isFirstShown: boolean = true;

  async aboutToAppear() {
    await this.initialize();
  }

  async onShown() {
    if (this.isFirstShown) {
      this.isFirstShown = false;
      return;
    }
    if (this.isInitializing || this.viewModel.isLoading) {
      return;
    }
    if (!this.isInitialized) {
      await this.initialize();
      return;
    }
    this.viewModel.refreshUserName();
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
      console.error('HomePage initialize failed: ' + message);
      this.viewModel.errorMessage = message;
      this.viewModel.isLoading = false;
    } finally {
      this.isInitializing = false;
    }
  }

  private async retryLoad(): Promise<void> {
    this.isInitialized = false;
    await this.initialize();
  }

  private navigateToCapture(): void {
    this.navPath.pushPathByName('QuickCapturePage', null);
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
    return `${prefix}，${this.viewModel.userName}`;
  }

  private greetingSubtitle(): string {
    return '今天也继续收集新词吧';
  }

  private captureSubtitle(): string {
    const hour = new Date().getHours();
    if (hour < 12) {
      return '早晨遇到的新词，记下来吧';
    }
    if (hour < 18) {
      return '午后看到的，用英语怎么说？';
    }
    return '睡前回顾今天学到的新词';
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
    .padding({
      left: DesignTokens.spacing16,
      right: DesignTokens.spacing16,
      top: DesignTokens.spacing16,
      bottom: DesignTokens.spacing24
    })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  StatCard(label: string, value: number, color: string, margin?: MarginOption) {
    Column() {
      Text(value.toString())
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
      this.StatCard('今日', this.viewModel.todayCount, DesignTokens.success,
        { right: DesignTokens.spacing8 })
      this.StatCard('累计', this.viewModel.totalCount, DesignTokens.primary,
        { left: DesignTokens.spacing8, right: DesignTokens.spacing8 })
      this.StatCard('待复习', this.viewModel.reviewCount, DesignTokens.warning,
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
          .fontSize(DesignTokens.font20)
          .fontWeight(FontWeight.Bold)
          .fontColor(DesignTokens.textPrimary)
        Text(this.captureSubtitle())
          .fontSize(DesignTokens.font14)
          .fontColor(DesignTokens.textSecondary)
          .margin({ top: DesignTokens.spacing4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      this.PlusButton()
    }
    .width('100%')
    .height(108)
    .padding(DesignTokens.spacing20)
    .backgroundColor(Color.Transparent)
    .systemMaterial(DesignTokens.materialRegular)
    .borderRadius(DesignTokens.radius24)
    .stateStyles({
      pressed: pressedCard
    })
    .onClick(() => this.navigateToCapture())
  }

  @Builder
  SectionHeader() {
    Row() {
      Text('最近记录')
        .fontSize(DesignTokens.font18)
        .fontWeight(FontWeight.Bold)
        .fontColor(DesignTokens.textPrimary)
        .layoutWeight(1)
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
      .margin({ top: DesignTokens.spacing24, left: DesignTokens.spacing16, right: DesignTokens.spacing16 })
    }
    .width('100%')
    .padding({ bottom: DesignTokens.spacing24 })
  }

  @Builder
  WordListSection() {
    Column() {
      this.SectionHeader()

      if (this.viewModel.isLoading) {
        Column() {
          this.LoadingState()
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.viewModel.errorMessage.length > 0) {
        Column() {
          this.ErrorState()
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.viewModel.wordList.length === 0) {
        Column() {
          this.EmptyState()
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          Repeat<WordRecord>(this.viewModel.wordList)
            .each((obj: RepeatItem<WordRecord>) => {
              ListItem() {
                HomeWordCard({
                  word: obj.item,
                  isFirst: obj.index === 0,
                  isLast: obj.index === this.viewModel.wordList.length - 1,
                  onCardClick: () => this.navigateToWordDetail(obj.item)
                })
              }
            })
            .key((item: WordRecord) => item.id + '_' + item.word + '_' + item.translation.join(',') + '_' + item.proficiency + '_' + item.createdAt)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .listDirection(Axis.Vertical)
        .edgeEffect(EdgeEffect.None)
      }
    }
    .width('100%')
    .layoutWeight(1)
    .margin({ left: DesignTokens.spacing16, right: DesignTokens.spacing16 })
    .padding(DesignTokens.spacing16)
    .backgroundColor(DesignTokens.bgCard)
    .borderRadius(DesignTokens.radius24)
    .alignItems(HorizontalAlign.Start)
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
          this.TopContent()
          this.WordListSection()
        }
        .width('100%')
        .height('100%')
        .padding({ bottom: 96 })
        .backgroundColor(DesignTokens.bgBase)

        BottomNav({ activeIndex: 0 })
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
