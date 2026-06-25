import { WordRecord } from '../model/Types';
import { WordService } from '../service/WordService';
import { Context } from '@kit.AbilityKit';

export type FilterTab = 'all' | 'mastered' | 'reviewing' | 'new';

@ObservedV2
export class LibraryViewModel {
  @Trace words: WordRecord[] = [];
  @Trace filteredWords: WordRecord[] = [];
  @Trace searchQuery: string = '';
  @Trace activeTab: FilterTab = 'all';
  @Trace isLoading: boolean = true;
  @Trace errorMessage: string = '';

  private wordService: WordService = new WordService();
  private initialized: boolean = false;

  async init(context: Context): Promise<void> {
    if (this.initialized) {
      return;
    }
    await this.wordService.init(context);
    this.initialized = true;
  }

  async loadData(): Promise<void> {
    if (this.isLoading) {
      return;
    }
    this.isLoading = true;
    this.errorMessage = '';
    try {
      this.words = await this.wordService.getAllWords();
      this.applyFilters();
    } catch (err) {
      const message = err instanceof Error ? err.message : '加载数据失败';
      console.error('LibraryViewModel loadData failed: ' + message);
      this.errorMessage = message;
    } finally {
      this.isLoading = false;
    }
  }

  setSearchQuery(value: string): void {
    this.searchQuery = value;
    this.applyFilters();
  }

  setActiveTab(tab: FilterTab): void {
    this.activeTab = tab;
    this.applyFilters();
  }

  private applyFilters(): void {
    let result = this.words;

    if (this.activeTab === 'mastered') {
      result = result.filter((w: WordRecord): boolean => w.proficiency >= 5);
    } else if (this.activeTab === 'reviewing') {
      result = result.filter((w: WordRecord): boolean => w.proficiency >= 1 && w.proficiency <= 4);
    } else if (this.activeTab === 'new') {
      result = result.filter((w: WordRecord): boolean => w.proficiency === 0);
    }

    const query = this.searchQuery.trim().toLowerCase();
    if (query.length > 0) {
      result = result.filter((w: WordRecord): boolean =>
        w.word.toLowerCase().includes(query) ||
        w.translation.some((t: string): boolean => t.toLowerCase().includes(query)) ||
        w.tags.some((t: string): boolean => t.toLowerCase().includes(query))
      );
    }

    this.filteredWords = result;
  }
}
