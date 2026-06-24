import { Context } from '@kit.AbilityKit';
import { WordRecord } from '../model/Types';

export interface IWordRepository {
  init(context: Context): Promise<void>;
  insert(word: WordRecord): Promise<void>;
  findById(id: string): Promise<WordRecord | null>;
  findTodayWords(): Promise<WordRecord[]>;
  findByDateRange(startTime: number, endTime: number): Promise<WordRecord[]>;
  findReviewWords(limit?: number): Promise<WordRecord[]>;
  getAllWords(): Promise<WordRecord[]>;
  findRandomWords(count: number): Promise<WordRecord[]>;
  updateProficiency(id: string, newProficiency: number): Promise<void>;
  search(keyword: string): Promise<WordRecord[]>;
  delete(id: string): Promise<void>;
  updateFavorite(id: string, isFavorite: boolean): Promise<void>;
  updateArchived(id: string, isArchived: boolean): Promise<void>;
  getTotalCount(): Promise<number>;
}
