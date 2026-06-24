import { router } from '@kit.ArkUI';
import { WordRecord, ExampleSentence } from '../model/Types';
import { WordService } from '../service/WordService';
import { DesignTokens } from '../components/DesignTokens';

interface RouterParams {
  wordId?: string;
}

@Entry
@Component
struct WordDetailPage {
  private wordService: WordService = new WordService();
  @State word: WordRecord | null = null;
  @State isLoading: boolean = true;
  @State errorMessage: string = '';

  async aboutToAppear() {
    await this.initialize();
  }

  private async initialize(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) {
        throw new Error('无法获取应用上下文');
      }
      await this.wordService.init(context);

      const params = router.getParams() as RouterParams | undefined;
      const wordId = params?.wordId;
      if (!wordId) {
        throw new Error('缺少单词 ID');
      }

      const word = await this.wordService.getWordById(wordId);
      if (!word) {
        throw new Error('单词不存在');
      }
      this.word = word;
    } catch (err) {
      const message = err instanceof Error ? err.message : '加载失败';
      console.error('Failed to load word detail: ' + message);
      this.errorMessage = message;
    } finally {
      this.isLoading = false;
    }
  }

  private goBack(): void {
    router.back();
  }

  private copyWord(updates: Partial<WordRecord>): WordRecord | null {
    if (!this.word) {
      return null;
    }
    const w = this.word;
    return {
      id: w.id,
      word: w.word,
      translation: w.translation,
      partOfSpeech: w.partOfSpeech,
      exampleSentence: w.exampleSentence,
      exampleTranslation: w.exampleTranslation,
      phoneticUK: w.phoneticUK,
      phoneticUS: w.phoneticUS,
      source: w.source,
      originalQuery: w.originalQuery,
      tags: w.tags,
      proficiency: w.proficiency,
      reviewCount: w.reviewCount,
      createdAt: w.createdAt,
      lastReviewedAt: w.lastReviewedAt,
      imageUri: w.imageUri,
      definition: w.definition,
      examples: w.examples,
      isArchived: updates.isArchived ?? w.isArchived,
      isFavorite: updates.isFavorite ?? w.isFavorite
    };
  }

  private async toggleFavorite(): Promise<void> {
    if (!this.word) return;
    try {
      const next = await this.wordService.toggleFavorite(this.word.id);
      this.word = this.copyWord({ isFavorite: next });
    } catch (err) {
      const message = err instanceof Error ? err.message : '操作失败';
      console.error('Failed to toggle favorite: ' + message);
    }
  }

  private async toggleArchived(): Promise<void> {
    if (!this.word) return;
    try {
      const next = await this.wordService.toggleArchived(this.word.id);
      this.word = this.copyWord({ isArchived: next });
    } catch (err) {
      const message = err instanceof Error ? err.message : '操作失败';
      console.error('Failed to toggle archived: ' + message);
    }
  }

  private statusColor(): ResourceColor {
    const proficiency = this.word?.proficiency ?? 0;
    if (proficiency >= 5) {
      return DesignTokens.success;
    }
    if (proficiency >= 1) {
      return DesignTokens.warning;
    }
    return DesignTokens.primary;
  }

  private phoneticText(): string {
    if (!this.word) return '';
    return this.word.phoneticUS ?? this.word.phoneticUK ?? '';
  }

  private examples(): ExampleSentence[] {
    if (!this.word) return [];
    if (this.word.examples && this.word.examples.length > 0) {
      return this.word.examples;
    }
    if (this.word.exampleSentence) {
      return [{
        en: this.word.exampleSentence,
        zh: this.word.exampleTranslation ?? ''
      }];
    }
    return [];
  }

  private progressSegments(): number[] {
    const proficiency = this.word?.proficiency ?? 0;
    const filled = Math.min(5, Math.max(0, proficiency));
    const segments: number[] = [];
    for (let i = 0; i < 5; i++) {
      segments.push(i < filled ? 1 : 0);
    }
    return segments;
  }

  @Builder
  BackIcon() {
    Column() {
      Row()
        .width(10)
        .height(2)
        .backgroundColor(DesignTokens.textPrimary)
        .borderRadius(1)
        .rotate({ angle: -45 })
      Row()
        .width(10)
        .height(2)
        .backgroundColor(DesignTokens.textPrimary)
        .borderRadius(1)
        .rotate({ angle: 45 })
        .margin({ top: -4 })
    }
    .width(24)
    .height(24)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  MoreIcon() {
    Column() {
      Row()
        .width(4)
        .height(4)
        .backgroundColor(DesignTokens.textPrimary)
        .borderRadius(2)
      Row()
        .width(4)
        .height(4)
        .backgroundColor(DesignTokens.textPrimary)
        .borderRadius(2)
        .margin({ top: 4 })
      Row()
        .width(4)
        .height(4)
        .backgroundColor(DesignTokens.textPrimary)
        .borderRadius(2)
        .margin({ top: 4 })
    }
    .width(24)
    .height(24)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  TopBar() {
    Row() {
      Button() {
        this.BackIcon()
      }
      .width(40)
      .height(40)
      .systemMaterial(DesignTokens.materialUltraThin)
      .borderRadius(DesignTokens.radiusFull)
      .onClick(() => this.goBack())

      Blank().layoutWeight(1)

      Button() {
        this.MoreIcon()
      }
      .width(40)
      .height(40)
      .systemMaterial(DesignTokens.materialUltraThin)
      .borderRadius(DesignTokens.radiusFull)
    }
    .width('100%')
    .padding(DesignTokens.spacing16)
  }

  @Builder
  WordHeader() {
    Column() {
      Text(this.word?.word ?? '')
        .fontSize(40)
        .fontWeight(FontWeight.Bold)
        .fontColor(DesignTokens.textPrimary)
        .textAlign(TextAlign.Center)

      if (this.phoneticText().length > 0) {
        Text(`/${this.phoneticText()}/`)
          .fontSize(DesignTokens.font18)
          .fontColor(DesignTokens.primary)
          .margin({ top: 8 })
          .textAlign(TextAlign.Center)
      }

      Row({ space: DesignTokens.spacing8 }) {
        ForEach(this.word?.tags ?? [], (tag: string) => {
          Text(tag)
            .fontSize(DesignTokens.font12)
            .fontColor(DesignTokens.textSecondary)
            .backgroundColor('rgba(100, 116, 139, 0.10)')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(DesignTokens.radiusFull)
        }, (tag: string) => tag)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 16 })
    }
    .width('100%')
    .padding({ top: DesignTokens.spacing16, bottom: DesignTokens.spacing24 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  DefinitionSection() {
    Column() {
      Text('DEFINITION')
        .fontSize(DesignTokens.font10)
        .fontWeight(FontWeight.Medium)
        .fontColor(DesignTokens.textTertiary)
        .letterSpacing(1)
        .width('100%')
        .margin({ bottom: DesignTokens.spacing12 })

      Text(this.word?.definition ?? this.word?.translation.join('；') ?? '暂无释义')
        .fontSize(DesignTokens.font16)
        .fontColor(DesignTokens.textPrimary)
        .lineHeight(24)
        .width('100%')
    }
    .width('100%')
    .padding(DesignTokens.spacing20)
    .backgroundColor(Color.Transparent)
    .systemMaterial(DesignTokens.materialThin)
    .borderRadius(DesignTokens.radius24)
  }

  @Builder
  ExampleItem(example: ExampleSentence) {
    Column() {
      Text(`"${example.en}"`)
        .fontSize(DesignTokens.font14)
        .fontColor(DesignTokens.textPrimary)
        .fontStyle(FontStyle.Italic)
        .width('100%')

      if (example.zh.length > 0) {
        Text(example.zh)
          .fontSize(DesignTokens.font14)
          .fontColor(DesignTokens.textSecondary)
          .margin({ top: 6 })
          .width('100%')
      }
    }
    .width('100%')
    .margin({ bottom: DesignTokens.spacing16 })
  }

  @Builder
  ExamplesSection() {
    Column() {
      Text('CONTEXTUAL EXAMPLES')
        .fontSize(DesignTokens.font10)
        .fontWeight(FontWeight.Medium)
        .fontColor(DesignTokens.textTertiary)
        .letterSpacing(1)
        .width('100%')
        .margin({ bottom: DesignTokens.spacing12 })

      ForEach(this.examples(), (example: ExampleSentence, index: number) => {
        this.ExampleItem(example)
      }, (example: ExampleSentence, index: number) => index.toString())
    }
    .width('100%')
    .padding(DesignTokens.spacing20)
    .backgroundColor(Color.Transparent)
    .systemMaterial(DesignTokens.materialThin)
    .borderRadius(DesignTokens.radius24)
  }

  @Builder
  ProgressSection() {
    Column() {
      Text('MASTERY PROGRESS')
        .fontSize(DesignTokens.font10)
        .fontWeight(FontWeight.Medium)
        .fontColor(DesignTokens.textTertiary)
        .letterSpacing(1)
        .width('100%')
        .margin({ bottom: DesignTokens.spacing12 })

      Row({ space: DesignTokens.spacing8 }) {
        ForEach(this.progressSegments(), (filled: number, index: number) => {
          Row()
            .layoutWeight(1)
            .height(6)
            .backgroundColor(filled === 1 ? this.statusColor() : 'rgba(100, 116, 139, 0.15)')
            .borderRadius(DesignTokens.radiusFull)
        }, (filled: number, index: number) => index.toString())
      }
      .width('100%')
    }
    .width('100%')
    .padding(DesignTokens.spacing20)
    .backgroundColor(Color.Transparent)
    .systemMaterial(DesignTokens.materialThin)
    .borderRadius(DesignTokens.radius24)
  }

  @Builder
  StarIcon(filled: boolean) {
    Text(filled ? '★' : '☆')
      .fontSize(20)
      .fontColor(filled ? Color.White : DesignTokens.textPrimary)
      .textAlign(TextAlign.Center)
      .width(20)
      .height(20)
  }

  @Builder
  ArchiveIcon() {
    Column() {
      Row()
        .width(16)
        .height(2)
        .backgroundColor(Color.White)
        .borderRadius(1)
      Row()
        .width(12)
        .height(8)
        .backgroundColor(Color.White)
        .borderRadius(1)
        .margin({ top: 3 })
    }
    .width(20)
    .height(20)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ActionButtons() {
    Row({ space: DesignTokens.spacing12 }) {
      Button() {
        Row({ space: DesignTokens.spacing8 }) {
          this.StarIcon(this.word?.isFavorite ?? false)

          Text(this.word?.isFavorite ? 'Favorited' : 'Mark Review')
            .fontSize(DesignTokens.font14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.word?.isFavorite ? Color.White : DesignTokens.textPrimary)
        }
      }
      .layoutWeight(1)
      .height(48)
      .backgroundColor(this.word?.isFavorite ? DesignTokens.warning : 'rgba(100, 116, 139, 0.10)')
      .borderRadius(DesignTokens.radiusFull)
      .onClick(() => this.toggleFavorite())

      Button() {
        Row({ space: DesignTokens.spacing8 }) {
          this.ArchiveIcon()

          Text(this.word?.isArchived ? 'Archived' : 'Archive Word')
            .fontSize(DesignTokens.font14)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
      }
      .layoutWeight(1)
      .height(48)
      .backgroundColor(DesignTokens.primary)
      .borderRadius(DesignTokens.radiusFull)
      .onClick(() => this.toggleArchived())
    }
    .width('100%')
    .padding(DesignTokens.spacing16)
  }

  @Builder
  LoadingState() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .color(DesignTokens.primary)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ErrorState() {
    Column() {
      Text('加载失败')
        .fontSize(DesignTokens.font18)
        .fontWeight(FontWeight.Medium)
        .fontColor(DesignTokens.danger)
      Text(this.errorMessage)
        .fontSize(DesignTokens.font14)
        .fontColor(DesignTokens.textSecondary)
        .margin({ top: 8 })
        .textAlign(TextAlign.Center)
      Button('返回')
        .fontSize(DesignTokens.font14)
        .fontColor(Color.White)
        .backgroundColor(DesignTokens.primary)
        .borderRadius(DesignTokens.radiusFull)
        .padding({ left: 24, right: 24, top: 10, bottom: 10 })
        .margin({ top: 16 })
        .onClick(() => this.goBack())
    }
    .width('100%')
    .height('100%')
    .padding(DesignTokens.spacing16)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (this.isLoading) {
        this.LoadingState()
      } else if (this.errorMessage.length > 0) {
        this.ErrorState()
      } else if (this.word !== null) {
        Column() {
          this.TopBar()

          Scroll() {
            Column({ space: DesignTokens.spacing16 }) {
              this.WordHeader()
              this.DefinitionSection()
              this.ExamplesSection()
              this.ProgressSection()

              Blank().height(80)
            }
            .width('100%')
            .padding({ left: DesignTokens.spacing16, right: DesignTokens.spacing16 })
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .height('100%')
        .backgroundColor(DesignTokens.bgBase)

        this.ActionButtons()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(DesignTokens.bgBase)
  }
}
