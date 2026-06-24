import { router } from '@kit.ArkUI';
import { WordService, AddWordParams } from '../service/WordService';
import { AppStore } from '../store/AppStore';
import { LaunchState } from '../store/LaunchState';
import { DesignTokens } from '../components/DesignTokens';

const TAG = 'QuickCapturePage';
const INPUT_ID = 'quickCaptureInput';

interface BackKeyEvent {
  keyCode: number;
}

@Entry
@Component
struct QuickCapturePage {
  @State wordInput: string = '';
  @State translationInput: string = '';
  @State selectedTags: string[] = [];
  @State isSaving: boolean = false;
  @State showSuccess: boolean = false;

  private wordService: WordService = new WordService();
  private successTimer: number = -1;

  private readonly presetTags: string[] = [
    '物品', '情绪', '动作', '场景', '食物', '动物', '植物', '日常'
  ];

  async aboutToAppear() {
    const shortcutStart = LaunchState.getInstance().getShortcutStartTime();
    if (shortcutStart > 0) {
      console.info(TAG, 'page aboutToAppear cost: ' + (Date.now() - shortcutStart) + 'ms');
    }

    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) {
        throw new Error('无法获取应用上下文');
      }
      await this.wordService.init(context);
    } catch (err) {
      const message = err instanceof Error ? err.message : '初始化失败';
      console.error(TAG, 'QuickCapturePage init failed: ' + message);
      this.showToast('服务初始化失败，请重试');
    }
  }

  onPageShow() {
    const shortcutStart = LaunchState.getInstance().getShortcutStartTime();
    if (shortcutStart > 0) {
      console.info(TAG, 'page shown cost: ' + (Date.now() - shortcutStart) + 'ms');
      LaunchState.getInstance().clearShortcutStartTime();
    }
  }

  onBackPress(): boolean {
    router.back();
    return true;
  }

  private showToast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (e) {
      console.warn(TAG, 'showToast failed: ' + (e instanceof Error ? e.message : 'unknown'));
    }
  }

  aboutToDisappear() {
    if (this.successTimer !== -1) {
      clearTimeout(this.successTimer);
      this.successTimer = -1;
    }
  }

  async saveWord() {
    const word = this.wordInput.trim();
    if (!word) {
      this.showToast('请输入英语单词或短语');
      return;
    }

    this.isSaving = true;
    this.showSuccess = false;
    try {
      const rawTranslations = this.translationInput.trim();
      let translations: string[] | undefined = undefined;
      if (rawTranslations.length > 0) {
        translations = rawTranslations.split(/[,，;；]/)
          .map((t: string): string => t.trim())
          .filter((t: string): boolean => t.length > 0);
      }

      const params: AddWordParams = {
        word: word,
        translation: translations,
        source: 'manual',
        tags: this.selectedTags
      };
      const record = await this.wordService.addWord(params);

      AppStore.getInstance().addWordToList(record);

      this.showSuccess = true;
      this.wordInput = '';
      this.translationInput = '';
      this.selectedTags = [];

      this.showToast('已保存: ' + record.word);

      if (this.successTimer !== -1) {
        clearTimeout(this.successTimer);
      }
      this.successTimer = setTimeout(() => {
        this.showSuccess = false;
        this.successTimer = -1;
      }, 1500);
    } catch (err) {
      const message = err instanceof Error ? err.message : '保存失败';
      console.error(TAG, 'Save word failed: ' + message);
      this.showToast('保存失败: ' + message);
      this.showSuccess = false;
    } finally {
      this.isSaving = false;
    }
  }

  toggleTag(tag: string) {
    if (this.selectedTags.includes(tag)) {
      this.selectedTags = this.selectedTags.filter((t: string): boolean => t !== tag);
    } else {
      this.selectedTags = [...this.selectedTags, tag];
    }
  }

  private handleBackKey(event: BackKeyEvent): boolean {
    if (event.keyCode === 2) {
      router.back();
      return true;
    }
    return false;
  }

  build() {
    Column() {
      Row() {
        Text('<')
          .fontSize(DesignTokens.font24)
          .fontColor(DesignTokens.textSecondary)
          .width(48)
          .height(48)
          .textAlign(TextAlign.Center)
          .margin({ right: 12 })
          .onClick(() => {
            router.back();
          })

        Text('快速记录')
          .fontSize(DesignTokens.font20)
          .fontWeight(FontWeight.Bold)
          .fontColor(DesignTokens.textPrimary)
          .layoutWeight(1)

        if (this.showSuccess) {
          Text('已保存')
            .fontSize(DesignTokens.font14)
            .fontColor(DesignTokens.success)
            .animation({ duration: 300 })
        }
      }
      .width('90%')
      .margin({ top: 24, bottom: 24 })

      Column() {
        Text('英语单词 / 短语')
          .fontSize(DesignTokens.font16)
          .fontColor(DesignTokens.textPrimary)
          .width('100%')
          .margin({ bottom: 8 })

        TextInput({ placeholder: '输入英语单词或短语...', text: this.wordInput })
          .id(INPUT_ID)
          .width('100%')
          .height(56)
          .backgroundColor(DesignTokens.bgInput)
          .borderRadius(DesignTokens.radius8)
          .fontSize(DesignTokens.font16)
          .placeholderColor(DesignTokens.textTertiary)
          .defaultFocus(true)
          .onChange((value: string) => {
            this.wordInput = value;
          })
          .onSubmit(() => this.saveWord())
          .onKeyPreIme((event: BackKeyEvent): boolean => this.handleBackKey(event))
      }
      .width('90%')
      .margin({ bottom: 20 })

      Column() {
        Text('中文释义（可选）')
          .fontSize(DesignTokens.font16)
          .fontColor(DesignTokens.textPrimary)
          .width('100%')
          .margin({ bottom: 8 })

        TextInput({ placeholder: '输入中文释义，多个用逗号分隔...', text: this.translationInput })
          .width('100%')
          .height(56)
          .backgroundColor(DesignTokens.bgInput)
          .borderRadius(DesignTokens.radius8)
          .fontSize(DesignTokens.font16)
          .placeholderColor(DesignTokens.textTertiary)
          .onChange((value: string) => {
            this.translationInput = value;
          })
          .onSubmit(() => this.saveWord())
          .onKeyPreIme((event: BackKeyEvent): boolean => this.handleBackKey(event))
      }
      .width('90%')
      .margin({ bottom: 20 })

      Column() {
        Text('分类标签')
          .fontSize(DesignTokens.font16)
          .fontColor(DesignTokens.textPrimary)
          .width('100%')
          .margin({ bottom: 12 })

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(this.presetTags, (tag: string) => {
            Text(tag)
              .fontSize(DesignTokens.font16)
              .padding({ left: 16, right: 16, top: 10, bottom: 10 })
              .backgroundColor(
                this.selectedTags.includes(tag) ? DesignTokens.success : DesignTokens.bgInput
              )
              .fontColor(
                this.selectedTags.includes(tag) ? Color.White : DesignTokens.textSecondary
              )
              .borderRadius(DesignTokens.radiusFull)
              .margin({ right: 12, bottom: 12 })
              .onClick(() => this.toggleTag(tag))
          }, (tag: string) => tag)
        }
        .width('100%')
      }
      .width('90%')
      .margin({ bottom: 32 })

      Button(this.isSaving ? '保存中...' : '保存')
        .width('90%')
        .height(56)
        .backgroundColor(this.isSaving ? DesignTokens.textTertiary : DesignTokens.primary)
        .enabled(!this.isSaving)
        .onClick(() => this.saveWord())

      Blank()
        .layoutWeight(1)

      Text('提示：双击智控键可快速唤起此页面')
        .fontSize(DesignTokens.font12)
        .fontColor(DesignTokens.textTertiary)
        .margin({ bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(DesignTokens.bgBase)
  }
}
