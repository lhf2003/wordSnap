import { WordRecord, ExampleItem } from '../model/Types';
import { WordDetailViewModel, WordEditFields } from '../viewmodel/WordDetailViewModel';
import { DesignTokens } from '../components/DesignTokens';
import { WordDetailEditView } from '../components/WordDetailEditView';

@ComponentV2
export struct WordDetailPage {
  @Local viewModel: WordDetailViewModel = new WordDetailViewModel();
  @Consumer('navPath') navPath: NavPathStack = new NavPathStack();

  private goBack(): void {
    if (this.viewModel.hasChanged) {
      console.info('WordDetailPage goBack with refresh');
      this.navPath.pop({ refresh: true });
    } else {
      console.info('WordDetailPage goBack without refresh');
      this.navPath.pop();
    }
  }

  private showUnsavedConfirmDialog(): void {
    this.getUIContext().showAlertDialog({
      title: '修改未保存',
      message: '关闭后会丢失当前进度，是否继续？',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '继续',
        style: DialogButtonStyle.HIGHLIGHT,
        action: () => {
          this.viewModel.cancelEdit();
        }
      }
    });
  }

  private async saveEdit(): Promise<void> {
    const success = await this.viewModel.saveEdit();
    if (!success) {
      this.getUIContext().getPromptAction().showToast({ message: '保存失败' });
    }
  }

  private showDeleteConfirmDialog(): void {
    if (this.viewModel.word === null) {
      return;
    }
    this.getUIContext().showAlertDialog({
      title: '删除单词',
      message: '删除后无法恢复，是否继续删除',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '删除',
        style: DialogButtonStyle.HIGHLIGHT,
        action: () => {
          this.confirmDelete();
        }
      }
    });
  }

  private async confirmDelete(): Promise<void> {
    const success = await this.viewModel.deleteWord();
    if (success) {
      this.goBack();
    } else {
      this.getUIContext().getPromptAction().showToast({ message: '删除失败' });
    }
  }

  private updateEditedWord(updates: WordEditFields): void {
    this.viewModel.updateEditedWord(updates);
  }

  private statusColor(): ResourceColor {
    const proficiency = this.viewModel.word?.proficiency ?? 0;
    if (proficiency >= 5) {
      return DesignTokens.success;
    }
    if (proficiency >= 1) {
      return DesignTokens.warning;
    }
    return DesignTokens.primary;
  }

  private phoneticText(): string {
    if (!this.viewModel.word) return '';
    return this.viewModel.word.phoneticUS ?? this.viewModel.word.phoneticUK ?? '';
  }

  private examples(): ExampleItem[] {
    if (!this.viewModel.word) return [];
    if (this.viewModel.word.examples && this.viewModel.word.examples.length > 0) {
      return this.viewModel.word.examples;
    }
    if (this.viewModel.word.exampleSentence) {
      const item: ExampleItem = {
        en: this.viewModel.word.exampleSentence,
        zh: this.viewModel.word.exampleTranslation ?? ''
      };
      return [item];
    }
    return [];
  }

  private progressSegments(): number[] {
    const proficiency = this.viewModel.word?.proficiency ?? 0;
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
  MoreMenu() {
    Menu() {
      MenuItem({ content: '编辑' })
        .onClick(() => this.viewModel.startEdit())
      MenuItem({ content: '删除' })
        .onClick(() => this.showDeleteConfirmDialog())
    }
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

      if (!this.viewModel.isEditing) {
        Button() {
          this.MoreIcon()
        }
        .width(40)
        .height(40)
        .systemMaterial(DesignTokens.materialUltraThin)
        .borderRadius(DesignTokens.radiusFull)
        .bindMenu(this.MoreMenu)
      }
    }
    .width('100%')
    .padding(DesignTokens.spacing16)
  }
  @Builder
  WordHeader() {
    Column() {
      Text(this.viewModel.word?.word ?? '')
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
        Repeat<string>(this.viewModel.word?.tags ?? [])
          .each((obj: RepeatItem<string>) => {
            Text(obj.item)
              .fontSize(DesignTokens.font12)
              .fontColor(DesignTokens.textSecondary)
              .backgroundColor(DesignTokens.neutralSurface)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .borderRadius(DesignTokens.radiusFull)
          })
          .key((item: string) => item)
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

      Text(this.viewModel.word?.definition ?? this.viewModel.word?.translation.join('；') ?? '暂无释义')
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
  ExampleItem(example: ExampleItem) {
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

      Repeat<ExampleItem>(this.examples())
        .each((obj: RepeatItem<ExampleItem>) => {
          this.ExampleItem(obj.item)
        })
        .key((item: ExampleItem, index: number) => index.toString())
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
        Repeat<number>(this.progressSegments())
          .each((obj: RepeatItem<number>) => {
            Row()
              .layoutWeight(1)
              .height(6)
              .backgroundColor(obj.item === 1 ? this.statusColor() : DesignTokens.neutralSurfaceMedium)
              .borderRadius(DesignTokens.radiusFull)
          })
          .key((item: number, index: number) => index.toString())
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
      .fontColor(filled ? DesignTokens.textOnPrimary : DesignTokens.textPrimary)
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
        .backgroundColor(DesignTokens.textOnPrimary)
        .borderRadius(1)
      Row()
        .width(12)
        .height(8)
        .backgroundColor(DesignTokens.textOnPrimary)
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
          this.StarIcon(this.viewModel.word?.isFavorite ?? false)

          Text(this.viewModel.word?.isFavorite ? 'Favorited' : 'Mark Review')
            .fontSize(DesignTokens.font14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.viewModel.word?.isFavorite ? DesignTokens.textOnPrimary : DesignTokens.textPrimary)
        }
      }
      .layoutWeight(1)
      .height(48)
      .backgroundColor(this.viewModel.word?.isFavorite ? DesignTokens.warning : DesignTokens.neutralSurface)
      .borderRadius(DesignTokens.radiusFull)
      .onClick(() => this.viewModel.toggleFavorite())

      Button() {
        Row({ space: DesignTokens.spacing8 }) {
          this.ArchiveIcon()

          Text(this.viewModel.word?.isArchived ? 'Archived' : 'Archive Word')
            .fontSize(DesignTokens.font14)
            .fontWeight(FontWeight.Medium)
            .fontColor(DesignTokens.textOnPrimary)
        }
      }
      .layoutWeight(1)
      .height(48)
      .backgroundColor(DesignTokens.primary)
      .borderRadius(DesignTokens.radiusFull)
      .onClick(() => this.viewModel.toggleArchived())
    }
    .width('100%')
    .padding(DesignTokens.spacing16)
  }
@Builder
  EditActionButtons() {
    Row({ space: DesignTokens.spacing12 }) {
      Button('取消')
        .layoutWeight(1)
        .height(48)
        .fontSize(DesignTokens.font14)
        .fontWeight(FontWeight.Medium)
        .fontColor(DesignTokens.textPrimary)
        .backgroundColor(DesignTokens.neutralSurface)
        .borderRadius(DesignTokens.radiusFull)
        .enabled(!this.viewModel.isSaving)
        .onClick(() => this.viewModel.cancelEdit())

      Button('保存')
        .layoutWeight(1)
        .height(48)
        .fontSize(DesignTokens.font14)
        .fontWeight(FontWeight.Medium)
        .fontColor(DesignTokens.textOnPrimary)
        .backgroundColor(DesignTokens.primary)
        .borderRadius(DesignTokens.radiusFull)
        .enabled(!this.viewModel.isSaving)
        .onClick(() => this.saveEdit())
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
      Text(this.viewModel.errorMessage)
        .fontSize(DesignTokens.font14)
        .fontColor(DesignTokens.textSecondary)
        .margin({ top: 8 })
        .textAlign(TextAlign.Center)
      Button('返回')
        .fontSize(DesignTokens.font14)
        .fontColor(DesignTokens.textOnPrimary)
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
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        if (this.viewModel.isLoading) {
          this.LoadingState()
        } else if (this.viewModel.errorMessage.length > 0) {
          this.ErrorState()
        } else if (this.viewModel.word !== null) {
          Column() {
            this.TopBar()

            Scroll() {
              Column({ space: DesignTokens.spacing16 }) {
                if (this.viewModel.isEditing && this.viewModel.editedWord !== null) {
                  WordDetailEditView({
                    editedWord: this.viewModel.editedWord,
                    onFieldChange: (fields: WordEditFields) => this.updateEditedWord(fields),
                    onCancel: () => this.viewModel.cancelEdit(),
                    onSave: () => this.saveEdit(),
                    onBlankClick: () => this.showUnsavedConfirmDialog()
                  })
                } else {
                  this.WordHeader()
                  this.DefinitionSection()
                  this.ExamplesSection()
                  this.ProgressSection()
                }

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

          if (this.viewModel.isEditing) {
            this.EditActionButtons()
          } else {
            this.ActionButtons()
          }
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(DesignTokens.bgBase)
    }
    .hideTitleBar(true)
    .onReady(async (context: NavDestinationContext) => {
      const param = context.pathInfo.param as Record<string, string> | undefined;
      this.viewModel.wordId = param?.wordId ?? '';
      const ctx = this.getUIContext().getHostContext();
      if (ctx !== undefined) {
        await this.viewModel.init(ctx);
      }
      try {
        await this.viewModel.loadWord();
      } catch (err) {
        const message = err instanceof Error ? err.message : '加载失败';
        console.error('WordDetailPage onReady failed: ' + message);
        this.viewModel.errorMessage = message;
        this.viewModel.isLoading = false;
      }
    })
    .onBackPressed(() => {
      if (this.viewModel.hasChanged) {
        this.navPath.pop({ refresh: true });
      } else {
        this.navPath.pop();
      }
      return true;
    })
  }
}
