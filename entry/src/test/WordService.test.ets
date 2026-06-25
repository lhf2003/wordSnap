import { describe, it, expect } from '@ohos/hypium';
import { WordService, AddWordParams } from '../main/ets/service/WordService';
import { IWordRepository } from '../main/ets/repository/IWordRepository';
import { WordRecord } from '../main/ets/model/Types';

class MockWordRepository implements IWordRepository {
  private words: WordRecord[] = [];

  async init(): Promise<void> {}

  async insert(word: WordRecord): Promise<void> {
    this.words.push(word);
  }

  async findById(id: string): Promise<WordRecord | null> {
    return this.words.find(w => w.id === id) ?? null;
  }

  async findTodayWords(): Promise<WordRecord[]> {
    const startOfDay = new Date().setHours(0, 0, 0, 0);
    return this.words.filter(w => w.createdAt >= startOfDay);
  }

  async findByDateRange(startTime: number, endTime: number): Promise<WordRecord[]> {
    return this.words.filter(w => w.createdAt >= startTime && w.createdAt <= endTime);
  }

  async findReviewWords(limit?: number): Promise<WordRecord[]> {
    const result = this.words.filter(w => w.proficiency < 3);
    return limit !== undefined ? result.slice(0, limit) : result;
  }

  async getAllWords(): Promise<WordRecord[]> {
    return this.words.slice().sort((a, b) => b.createdAt - a.createdAt);
  }

  async findRandomWords(count: number): Promise<WordRecord[]> {
    return this.words.slice(0, count);
  }

  async updateProficiency(id: string, newProficiency: number): Promise<void> {
    const word = this.words.find(w => w.id === id);
    if (word) {
      word.proficiency = newProficiency;
      word.reviewCount += 1;
    }
  }

  async search(keyword: string): Promise<WordRecord[]> {
    const lower = keyword.toLowerCase();
    return this.words.filter(w =>
      w.word.toLowerCase().includes(lower) ||
      w.translation.some(t => t.toLowerCase().includes(lower))
    );
  }

  async delete(id: string): Promise<void> {
    this.words = this.words.filter(w => w.id !== id);
  }

  async updateFavorite(id: string, isFavorite: boolean): Promise<void> {
    const word = this.words.find(w => w.id === id);
    if (word) {
      word.isFavorite = isFavorite;
    }
  }

  async updateArchived(id: string, isArchived: boolean): Promise<void> {
    const word = this.words.find(w => w.id === id);
    if (word) {
      word.isArchived = isArchived;
    }
  }

  async getTotalCount(): Promise<number> {
    return this.words.length;
  }
}

export default function wordServiceTests() {
  describe('WordService', () => {
    it('addWord_should_store_word_with_defaults', 0, async () => {
      const repo = new MockWordRepository();
      const service = new WordService(repo);
      const params: AddWordParams = { word: 'coffee' };

      const record = await service.addWord(params);

      expect(record.word).assertEqual('coffee');
      expect(record.translation[0]).assertEqual('暂无释义');
      expect(record.source).assertEqual('manual');
      expect(record.proficiency).assertEqual(0);
      expect(record.tags.length).assertEqual(0);
    });

    it('addWord_should_store_word_with_translation_and_tags', 0, async () => {
      const repo = new MockWordRepository();
      const service = new WordService(repo);
      const params: AddWordParams = {
        word: 'iced Americano',
        translation: ['冰美式'],
        tags: ['食物']
      };

      const record = await service.addWord(params);

      expect(record.word).assertEqual('iced Americano');
      expect(record.translation[0]).assertEqual('冰美式');
      expect(record.tags[0]).assertEqual('食物');
    });

    it('getStatistics_should_reflect_recorded_words', 0, async () => {
      const repo = new MockWordRepository();
      const service = new WordService(repo);
      await service.addWord({ word: 'coffee', translation: ['咖啡'] });

      const stats = await service.getStatistics();

      expect(stats.totalWords).assertEqual(1);
      expect(stats.todayWords).assertEqual(1);
      expect(stats.reviewWords).assertEqual(1);
    });

    it('searchWords_should_match_word_and_translation', 0, async () => {
      const repo = new MockWordRepository();
      const service = new WordService(repo);
      await service.addWord({ word: 'cafe', translation: ['咖啡馆'] });
      await service.addWord({ word: 'tired', translation: ['疲惫'] });

      const results = await service.searchWords('咖啡馆');

      expect(results.length).assertEqual(1);
      expect(results[0].word).assertEqual('cafe');
    });

    it('updateProficiency_should_clamp_between_zero_and_five', 0, async () => {
      const repo = new MockWordRepository();
      const service = new WordService(repo);
      const record = await service.addWord({ word: 'test' });

      await service.updateProficiency(record.id, 10);
      const word = await service.getWordById(record.id);

      expect(word?.proficiency).assertEqual(5);
    });

    it('toggleFavorite_should_return_next_state', 0, async () => {
      const repo = new MockWordRepository();
      const service = new WordService(repo);
      const record = await service.addWord({ word: 'test' });

      const first = await service.toggleFavorite(record.id);
      const second = await service.toggleFavorite(record.id);

      expect(first).assertEqual(true);
      expect(second).assertEqual(false);
    });
  });
}
