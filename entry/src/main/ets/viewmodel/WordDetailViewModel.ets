import { WordRecord, ExampleSentence } from '../model/Types';
import { WordService } from '../service/WordService';
import { Context } from '@kit.AbilityKit';

export interface WordEditFields {
  word?: string;
  translation?: string[];
  exampleSentence?: string;
  exampleTranslation?: string;
  phoneticUK?: string;
  phoneticUS?: string;
  originalQuery?: string;
  tags?: string[];
  definition?: string;
  examples?: ExampleSentence[];
}

interface WordToggleUpdate {
  isArchived?: boolean;
  isFavorite?: boolean;
}

@ObservedV2
export class WordDetailViewModel {
  @Trace wordId: string = '';
  @Trace word: WordRecord | null = null;
  @Trace isLoading: boolean = true;
  @Trace errorMessage: string = '';
  @Trace isEditing: boolean = false;
  @Trace editedWord: WordRecord | null = null;
  @Trace isSaving: boolean = false;
  @Trace hasChanged: boolean = false;

  private wordService: WordService = new WordService();
  private initialized: boolean = false;

  async init(context: Context): Promise<void> {
    if (this.initialized) {
      return;
    }
    await this.wordService.init(context);
    this.initialized = true;
  }

  async loadWord(): Promise<void> {
    if (this.wordId.length === 0) {
      this.errorMessage = '缺少单词 ID';
      this.isLoading = false;
      return;
    }
    try {
      const word = await this.wordService.getWordById(this.wordId);
      if (!word) {
        throw new Error('单词不存在');
      }
      this.word = word;
      this.errorMessage = '';
    } catch (err) {
      const message = err instanceof Error ? err.message : '加载失败';
      console.error('WordDetailViewModel loadWord failed: ' + message);
      this.errorMessage = message;
    } finally {
      this.isLoading = false;
    }
  }

  startEdit(): void {
    if (this.word === null) {
      return;
    }
    this.editedWord = this.cloneWord(this.word);
    this.isEditing = true;
  }

  cancelEdit(): void {
    this.isEditing = false;
    this.editedWord = null;
  }

  updateEditedWord(updates: WordEditFields): void {
    if (this.editedWord === null) {
      return;
    }
    if (updates.word !== undefined) {
      this.editedWord.word = updates.word;
    }
    if (updates.translation !== undefined) {
      this.editedWord.translation = updates.translation;
    }
    if (updates.exampleSentence !== undefined) {
      this.editedWord.exampleSentence = updates.exampleSentence;
    }
    if (updates.exampleTranslation !== undefined) {
      this.editedWord.exampleTranslation = updates.exampleTranslation;
    }
    if (updates.phoneticUK !== undefined) {
      this.editedWord.phoneticUK = updates.phoneticUK;
    }
    if (updates.phoneticUS !== undefined) {
      this.editedWord.phoneticUS = updates.phoneticUS;
    }
    if (updates.tags !== undefined) {
      this.editedWord.tags = updates.tags;
    }
    if (updates.definition !== undefined) {
      this.editedWord.definition = updates.definition;
    }
  }

  async saveEdit(): Promise<boolean> {
    if (this.editedWord === null || this.isSaving) {
      return false;
    }
    this.isSaving = true;
    try {
      const normalized = this.cloneWord(this.editedWord);
      await this.wordService.updateWord(normalized);
      this.word = normalized;
      this.hasChanged = true;
      this.isEditing = false;
      this.editedWord = null;
      return true;
    } catch (err) {
      const message = err instanceof Error ? err.message : '保存失败';
      console.error('WordDetailViewModel saveEdit failed: ' + message);
      return false;
    } finally {
      this.isSaving = false;
    }
  }

  async deleteWord(): Promise<boolean> {
    if (this.word === null) {
      return false;
    }
    try {
      await this.wordService.deleteWord(this.word.id);
      this.hasChanged = true;
      return true;
    } catch (err) {
      const message = err instanceof Error ? err.message : '删除失败';
      console.error('WordDetailViewModel deleteWord failed: ' + message);
      return false;
    }
  }

  async toggleFavorite(): Promise<void> {
    if (!this.word) {
      return;
    }
    try {
      const next = await this.wordService.toggleFavorite(this.word.id);
      this.word = this.copyWith({ isFavorite: next });
      this.hasChanged = true;
    } catch (err) {
      const message = err instanceof Error ? err.message : '操作失败';
      console.error('WordDetailViewModel toggleFavorite failed: ' + message);
    }
  }

  async toggleArchived(): Promise<void> {
    if (!this.word) {
      return;
    }
    try {
      const next = await this.wordService.toggleArchived(this.word.id);
      this.word = this.copyWith({ isArchived: next });
      this.hasChanged = true;
    } catch (err) {
      const message = err instanceof Error ? err.message : '操作失败';
      console.error('WordDetailViewModel toggleArchived failed: ' + message);
    }
  }

  private cloneWord(source: WordRecord): WordRecord {
    return new WordRecord({
      id: source.id,
      word: source.word,
      translation: source.translation.slice(),
      partOfSpeech: source.partOfSpeech,
      exampleSentence: source.exampleSentence,
      exampleTranslation: source.exampleTranslation,
      phoneticUK: source.phoneticUK,
      phoneticUS: source.phoneticUS,
      source: source.source,
      originalQuery: source.originalQuery,
      tags: source.tags.slice(),
      proficiency: source.proficiency,
      reviewCount: source.reviewCount,
      createdAt: source.createdAt,
      lastReviewedAt: source.lastReviewedAt,
      imageUri: source.imageUri,
      definition: source.definition,
      examples: source.examples ? source.examples.map((e: ExampleSentence): ExampleSentence => ({ en: e.en, zh: e.zh })) : undefined,
      isArchived: source.isArchived,
      isFavorite: source.isFavorite
    });
  }

  private copyWith(updates: WordToggleUpdate): WordRecord | null {
    if (!this.word) {
      return null;
    }
    return new WordRecord({
      id: this.word.id,
      word: this.word.word,
      translation: this.word.translation.slice(),
      partOfSpeech: this.word.partOfSpeech,
      exampleSentence: this.word.exampleSentence,
      exampleTranslation: this.word.exampleTranslation,
      phoneticUK: this.word.phoneticUK,
      phoneticUS: this.word.phoneticUS,
      source: this.word.source,
      originalQuery: this.word.originalQuery,
      tags: this.word.tags.slice(),
      proficiency: this.word.proficiency,
      reviewCount: this.word.reviewCount,
      createdAt: this.word.createdAt,
      lastReviewedAt: this.word.lastReviewedAt,
      imageUri: this.word.imageUri,
      definition: this.word.definition,
      examples: this.word.examples,
      isArchived: updates.isArchived ?? this.word.isArchived,
      isFavorite: updates.isFavorite ?? this.word.isFavorite
    });
  }
}
