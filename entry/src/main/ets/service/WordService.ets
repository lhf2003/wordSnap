import { WordRecord, RecordSource, PartOfSpeech, AIWordDetail } from '../model/Types';
import { Context } from '@kit.AbilityKit';
import { WordRepository } from '../repository/WordRepository';
import { IWordRepository } from '../repository/IWordRepository';

export interface AddWordParams {
  word: string;
  translation?: string[];
  partOfSpeech?: string;
  source?: RecordSource;
  tags?: string[];
  originalQuery?: string;
  imageUri?: string;
  aiDetail?: AIWordDetail;
}

interface StatisticsResult {
  totalWords: number;
  todayWords: number;
  reviewWords: number;
}

export class WordService {
  private wordRepo: IWordRepository;

  constructor(repo?: IWordRepository) {
    this.wordRepo = repo ?? WordRepository.getInstance();
  }

  async init(context: Context): Promise<void> {
    await this.wordRepo.init(context);
  }

  async addWord(params: AddWordParams): Promise<WordRecord> {
    const now = Date.now();
    const entropy = Math.random().toString(36).substring(2, 6);

    const aiDetail = params.aiDetail;
    const translations = aiDetail?.translations ?? params.translation ?? ['暂无释义'];
    const firstPos = aiDetail?.partOfSpeech?.[0];

    const wordRecord: WordRecord = {
      id: 'w-' + now + '-' + entropy,
      word: params.word.trim(),
      translation: translations,
      partOfSpeech: this.normalizePartOfSpeech(firstPos ?? params.partOfSpeech),
      exampleSentence: aiDetail?.examples?.[0]?.en,
      exampleTranslation: aiDetail?.examples?.[0]?.zh,
      phoneticUK: aiDetail?.phoneticUK,
      phoneticUS: aiDetail?.phoneticUS,
      source: params.source ?? 'manual',
      tags: params.tags ?? [],
      proficiency: 0,
      reviewCount: 0,
      createdAt: now,
      originalQuery: params.originalQuery,
      imageUri: params.imageUri,
      examples: aiDetail?.examples ?? [],
      isArchived: false,
      isFavorite: false
    };

    await this.wordRepo.insert(wordRecord);
    return wordRecord;
  }

  async getWordById(id: string): Promise<WordRecord | null> {
    return this.wordRepo.findById(id);
  }

  async getAllWords(): Promise<WordRecord[]> {
    return this.wordRepo.getAllWords();
  }

  async getTodayWords(): Promise<WordRecord[]> {
    return this.wordRepo.findTodayWords();
  }

  async getReviewWords(limit?: number): Promise<WordRecord[]> {
    return this.wordRepo.findReviewWords(limit);
  }

  async updateProficiency(id: string, delta: number): Promise<void> {
    const word = await this.wordRepo.findById(id);
    if (!word) throw new Error('Word not found: ' + id);

    const newProficiency = Math.min(5, Math.max(0, word.proficiency + delta));
    await this.wordRepo.updateProficiency(id, newProficiency);
  }

  async deleteWord(id: string): Promise<void> {
    await this.wordRepo.delete(id);
  }

  async toggleFavorite(id: string): Promise<boolean> {
    const word = await this.wordRepo.findById(id);
    if (!word) throw new Error('Word not found: ' + id);
    const next = !word.isFavorite;
    await this.wordRepo.updateFavorite(id, next);
    return next;
  }

  async toggleArchived(id: string): Promise<boolean> {
    const word = await this.wordRepo.findById(id);
    if (!word) throw new Error('Word not found: ' + id);
    const next = !word.isArchived;
    await this.wordRepo.updateArchived(id, next);
    return next;
  }

  async searchWords(keyword: string): Promise<WordRecord[]> {
    if (!keyword.trim()) return [];
    return this.wordRepo.search(keyword.trim());
  }

  async getWordsByTag(tag: string): Promise<WordRecord[]> {
    const allWords = await this.wordRepo.getAllWords();
    return allWords.filter(w => w.tags.includes(tag));
  }

  async getStatistics(): Promise<StatisticsResult> {
    const totalWords = await this.wordRepo.getTotalCount();
    const todayWords = (await this.wordRepo.findTodayWords()).length;
    const reviewWords = (await this.wordRepo.findReviewWords(100)).length;

    const stat: StatisticsResult = {
      totalWords: totalWords,
      todayWords: todayWords,
      reviewWords: reviewWords
    };
    return stat;
  }

  private normalizePartOfSpeech(pos?: string): PartOfSpeech {
    const valid: PartOfSpeech[] = [
      'noun', 'verb', 'adjective', 'adverb',
      'pronoun', 'preposition', 'conjunction', 'interjection', 'phrase'
    ];
    const normalized = pos?.toLowerCase().trim();
    return valid.find(v => v === normalized) ?? 'noun';
  }
}
