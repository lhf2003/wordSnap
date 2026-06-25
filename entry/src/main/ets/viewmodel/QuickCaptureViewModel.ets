import { WordRecord, RecordSource } from '../model/Types';
import { WordService, AddWordParams } from '../service/WordService';
import { AppStore } from '../store/AppStore';
import { Context } from '@kit.AbilityKit';

@ObservedV2
export class QuickCaptureViewModel {
  @Trace wordInput: string = '';
  @Trace translationInput: string = '';
  @Trace selectedTags: string[] = [];
  @Trace isSaving: boolean = false;
  @Trace showSuccess: boolean = false;
  @Trace hasSaved: boolean = false;

  private wordService: WordService = new WordService();
  private initialized: boolean = false;
  private successTimer: number = -1;

  readonly presetTags: string[] = [
    '物品', '情绪', '动作', '场景', '食物', '动物', '植物', '日常'
  ];

  async init(context: Context): Promise<void> {
    if (this.initialized) {
      return;
    }
    await this.wordService.init(context);
    this.initialized = true;
  }

  toggleTag(tag: string): void {
    if (this.selectedTags.includes(tag)) {
      this.selectedTags = this.selectedTags.filter((t: string): boolean => t !== tag);
    } else {
      this.selectedTags = [...this.selectedTags, tag];
    }
  }

  async saveWord(): Promise<WordRecord | null> {
    const word = this.wordInput.trim();
    if (!word) {
      return null;
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
        source: 'manual' as RecordSource,
        tags: this.selectedTags
      };
      const record = await this.wordService.addWord(params);

      AppStore.getInstance().addWordToList(record);
      this.hasSaved = true;
      this.showSuccess = true;
      this.wordInput = '';
      this.translationInput = '';
      this.selectedTags = [];

      this.clearSuccessTimer();
      this.successTimer = setTimeout(() => {
        this.showSuccess = false;
        this.successTimer = -1;
      }, 1500);

      return record;
    } catch (err) {
      const message = err instanceof Error ? err.message : '保存失败';
      console.error('QuickCaptureViewModel saveWord failed: ' + message);
      this.showSuccess = false;
      return null;
    } finally {
      this.isSaving = false;
    }
  }

  resetSuccess(): void {
    this.showSuccess = false;
  }

  clearTimer(): void {
    this.clearSuccessTimer();
  }

  private clearSuccessTimer(): void {
    if (this.successTimer !== -1) {
      clearTimeout(this.successTimer);
      this.successTimer = -1;
    }
  }
}
