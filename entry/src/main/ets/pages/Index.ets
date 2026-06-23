import { router } from '@kit.ArkUI';
import { WordRecord } from '../model/Types';
import { WordService } from '../service/WordService';
import { AppStore } from '../store/AppStore';
import { DesignTokens } from '../components/DesignTokens';
import { BottomNav } from '../components/BottomNav';

@Entry
@Component
struct Index {
  private wordService: WordService = new WordService();
  @State wordList: WordRecord[] = [];
  @State todayCount: number = 0;
  @State totalCount: number = 0;
  @State reviewCount: number = 0;
  @State isLoading: boolean = true;
  @State errorMessage: string = '';

  async aboutToAppear() {
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) {
        throw new Error('无法获取应用上下文');
      }
      await this.wordService.init(context);
      await this.loadData();
    } catch (err) {
      const message = err instanceof Error ? err.message : '加载数据失败';
      console.error('Failed to load index data: ' + message);
      this.errorMessage = message;
      this.isLoading = false;
    }
  }

  async loadData() {
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

  private retryLoad(): void {
    this.loadData();
  }

  private navigateToCapture(): void {
    router.pushUrl({ url: 'pages/QuickCapturePage' });
  }

  private greetingText(): string {
    const hour = new Date().getHours();
    let prefix = '早上好';
    if (hour >= 12 && hour < 18) {
      prefix = '下午好';
    } else if (hour >= 18) {
      prefix = '晚上好';
    }
    return `${prefix}，学习者`;
  }

  private dailyGoal(): number {
    return AppStore.getInstance().userProfile.dailyNewWordGoal;
  }

  @Builder
  Header() {
    Row() {
      Column() {
        Text(this.greetingText())
          .fontSize(DesignTokens.font24)
          .fontWeight(FontWeight.Bold)
          .fontColor(DesignTokens.textPrimary)
        Text(`今日目标 ${this.todayCount}/${this.dailyGoal()}`)
          .fontSize(DesignTokens.font14)
          .fontColor(DesignTokens.textSecondary)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Button() {
        Row() {
          Row()
            .width(14)
            .height(2)
            .backgroundColor(Color.White)
            .borderRadius(1)
          Row()
            .width(10)
            .height(2)
            .backgroundColor(Color.White)
            .borderRadius(1)
        }
        .width(20)
        .height(20)
        .justifyContent(FlexAlign.SpaceEvenly)
        .direction(Direction.Ltr)
        .alignItems(VerticalAlign.Center)
      }
      .width(48)
      .height(48)
      .backgroundColor(Color.Transparent)
      .systemMaterial(DesignTokens.materialRegular)
      .borderRadius(DesignTokens.radiusFull)
      .accessibilityText('快速记录')
      .accessibilityDescription('进入快速记录页面')
      .onClick(() => this.navigateToCapture())
    }
    .width('100%')
    .padding(DesignTokens.spacing16)
  }

  @Builder
  StatCard(label: string, value: string, color: string,
    margin?: { top?: number; bottom?: number; left?: number; right?: number }) {
    Column() {
      Text(value)
        .fontSize(DesignTokens.font28)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(DesignTokens.font12)
        .fontColor(DesignTokens.textSecondary)
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .margin(margin ?? {})
    .padding(DesignTokens.spacing16)
    .borderRadius(DesignTokens.radius20)
    .backgroundColor(Color.Transparent)
    .systemMaterial(DesignTokens.materialThin)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  QuickActionCard() {
    Row() {
      Column() {
        Text('快速记录')
          .fontSize(DesignTokens.font18)
          .fontWeight(FontWeight.Bold)
          .fontColor(DesignTokens.textPrimary)
        Text('双击智控键或点击开始')
          .fontSize(DesignTokens.font12)
          .fontColor(DesignTokens.textSecondary)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Button() {
        Row() {
          Row()
            .width(16)
            .height(2)
            .backgroundColor(Color.White)
            .borderRadius(1)
          Row()
            .width(2)
            .height(16)
            .backgroundColor(Color.White)
            .borderRadius(1)
            .position({ x: 7, y: -7 })
        }
        .width(24)
        .height(24)
        .justifyContent(FlexAlign.Center)
      }
      .width(56)
      .height(56)
      .backgroundColor(Color.Transparent)
      .systemMaterial(DesignTokens.materialRegular)
      .borderRadius(DesignTokens.radiusFull)
    }
    .width('100%')
    .height(96)
    .padding(DesignTokens.spacing16)
    .backgroundColor(Color.Transparent)
    .systemMaterial(DesignTokens.materialRegular)
    .borderRadius(DesignTokens.radius24)
    .accessibilityText('快速记录')
    .accessibilityDescription('进入快速记录页面，双击智控键也可唤起')
    .stateStyles({
      pressed: {
        .opacity(0.92)
      }
    })
    .onClick(() => this.navigateToCapture())
  }

  @Builder
  WordCard(word: WordRecord) {
    Row() {
      Column() {
        Text(word.word)
          .fontSize(DesignTokens.font18)
          .fontWeight(FontWeight.Medium)
          .fontColor(DesignTokens.textPrimary)
        Text(word.translation.join('；'))
          .fontSize(DesignTokens.font14)
          .fontColor(DesignTokens.textSecondary)
          .margin({ top: 4 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (word.proficiency > 0) {
        Text(`掌握度 ${word.proficiency}/5`)
          .fontSize(DesignTokens.font12)
          .fontColor(DesignTokens.success)
          .backgroundColor('rgba(52, 211, 153, 0.12)')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(DesignTokens.radiusFull)
      }
    }
    .width('100%')
    .padding(DesignTokens.spacing16)
    .backgroundColor(Color.Transparent)
    .systemMaterial(DesignTokens.materialThin)
    .borderRadius(DesignTokens.radius20)
    .margin({ bottom: DesignTokens.spacing12 })
    .accessibilityText(word.word)
    .accessibilityDescription(`中文释义：${word.translation.join('，')}`)
    .stateStyles({
      pressed: {
        .opacity(0.92)
      }
    })
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
      Button('重新加载')
        .fontSize(DesignTokens.font14)
        .fontColor(Color.White)
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

  @Builder
  EmptyState() {
    Column() {
      Text('今天还没有新词')
        .fontSize(DesignTokens.font16)
        .fontWeight(FontWeight.Medium)
        .fontColor(DesignTokens.textSecondary)
      Text('点上方快速记录，把看到的世界变成英语吧')
        .fontSize(DesignTokens.font14)
        .fontColor(DesignTokens.textSecondary)
        .margin({ top: 8 })
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ top: 60, bottom: 60 })
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        this.Header()

        Scroll() {
          Column() {
            // 统计卡片
            Row() {
              this.StatCard('今日新词', this.todayCount.toString(), DesignTokens.success,
                { right: DesignTokens.spacing6 })
              this.StatCard('总词汇量', this.totalCount.toString(), DesignTokens.primary,
                { left: DesignTokens.spacing6, right: DesignTokens.spacing6 })
              this.StatCard('待复习', this.reviewCount.toString(), DesignTokens.warning,
                { left: DesignTokens.spacing6 })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ top: DesignTokens.spacing16, bottom: DesignTokens.spacing16 })

            Column() {
              this.QuickActionCard()
            }
            .width('100%')
            .padding({ left: DesignTokens.spacing16, right: DesignTokens.spacing16, bottom: DesignTokens.spacing16 })

            // 今日记录
            Column() {
              Row() {
                Text('今日记录')
                  .fontSize(DesignTokens.font18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(DesignTokens.textPrimary)
                  .layoutWeight(1)
                Text(`${this.wordList.length} 条`)
                  .fontSize(DesignTokens.font12)
                  .fontColor(DesignTokens.textSecondary)
              }
              .width('100%')
              .margin({ bottom: DesignTokens.spacing12 })

              if (this.isLoading) {
                LoadingProgress()
                  .width(40)
                  .height(40)
                  .color(DesignTokens.primary)
                  .margin({ top: 40 })
              } else if (this.errorMessage.length > 0) {
                this.ErrorState()
              } else if (this.wordList.length === 0) {
                this.EmptyState()
              } else {
                ForEach(this.wordList, (word: WordRecord) => {
                  this.WordCard(word)
                }, (word: WordRecord) => word.id)
              }
            }
            .width('100%')
            .padding(DesignTokens.spacing16)
            .backgroundColor(DesignTokens.bgCard)
            .borderRadius({ topLeft: DesignTokens.radius24, topRight: DesignTokens.radius24 })
            .layoutWeight(1)
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        Blank().height(80)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(DesignTokens.bgBase)

      BottomNav({ activeIndex: 0 })
    }
    .width('100%')
    .height('100%')
  }
}
