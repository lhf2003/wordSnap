import { WordRecord } from '../model/Types';
import { WordService } from '../service/WordService';
import { AppStore } from '../store/AppStore';
import { Context } from '@kit.AbilityKit';

@ObservedV2
export class HomeViewModel {
  @Trace wordList: WordRecord[] = [];
  @Trace todayCount: number = 0;
  @Trace totalCount: number = 0;
  @Trace reviewCount: number = 0;
  @Trace isLoading: boolean = true;
  @Trace errorMessage: string = '';
  @Trace userName: string = '朋友';

  private wordService: WordService = new WordService();
  private initialized: boolean = false;

  async init(context: Context): Promise<void> {
    if (this.initialized) {
      return;
    }
    await this.wordService.init(context);
    this.userName = AppStore.getInstance().userProfile.nickname?.trim() || '朋友';
    this.initialized = true;
  }

  async loadData(): Promise<void> {
    if (this.isLoading) {
      return;
    }
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
      console.error('HomeViewModel loadData failed: ' + message);
      this.errorMessage = message;
    } finally {
      this.isLoading = false;
    }
  }

  refreshUserName(): void {
    this.userName = AppStore.getInstance().userProfile.nickname?.trim() || '朋友';
  }
}
