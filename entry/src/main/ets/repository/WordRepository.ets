import { relationalStore } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { WordRecord, PartOfSpeech, RecordSource, ExampleSentence } from '../model/Types';
import { IWordRepository } from './IWordRepository';

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'english_assistant.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

const WORD_TABLE_SQL = `
  CREATE TABLE IF NOT EXISTS word_records (
    id TEXT PRIMARY KEY,
    word TEXT NOT NULL,
    translation TEXT NOT NULL,
    part_of_speech TEXT,
    example_sentence TEXT,
    example_translation TEXT,
    phonetic_uk TEXT,
    phonetic_us TEXT,
    source TEXT NOT NULL,
    original_query TEXT,
    tags TEXT,
    proficiency INTEGER DEFAULT 0,
    review_count INTEGER DEFAULT 0,
    created_at INTEGER NOT NULL,
    last_reviewed_at INTEGER,
    image_uri TEXT,
    definition TEXT,
    examples TEXT,
    is_archived INTEGER DEFAULT 0,
    is_favorite INTEGER DEFAULT 0
  )
`;

export class WordRepository implements IWordRepository {
  private static instance: WordRepository;
  private store: relationalStore.RdbStore | null = null;
  private initPromise: Promise<void> | null = null;

  static getInstance(): WordRepository {
    if (!WordRepository.instance) {
      WordRepository.instance = new WordRepository();
    }
    return WordRepository.instance;
  }

  async init(context: Context): Promise<void> {
    if (this.store !== null) {
      return;
    }
    if (this.initPromise !== null) {
      return this.initPromise;
    }
    this.initPromise = this.doInit(context);
    return this.initPromise;
  }

  private async doInit(context: Context): Promise<void> {
    try {
      this.store = await relationalStore.getRdbStore(context, STORE_CONFIG);
      await this.store.executeSql(WORD_TABLE_SQL);
      await this.migrateWordTable();
      await this.store.executeSql(
        'CREATE INDEX IF NOT EXISTS idx_word_created ON word_records(created_at)'
      );
      await this.store.executeSql(
        'CREATE INDEX IF NOT EXISTS idx_word_proficiency ON word_records(proficiency, last_reviewed_at)'
      );
    } catch (err) {
      this.initPromise = null;
      const message = err instanceof Error ? err.message : '数据库初始化失败';
      throw new Error(message);
    }
  }

  private async migrateWordTable(): Promise<void> {
    if (!this.store) return;
    const migrations = [
      'ALTER TABLE word_records ADD COLUMN definition TEXT',
      'ALTER TABLE word_records ADD COLUMN examples TEXT',
      'ALTER TABLE word_records ADD COLUMN is_archived INTEGER DEFAULT 0',
      'ALTER TABLE word_records ADD COLUMN is_favorite INTEGER DEFAULT 0'
    ];
    for (const sql of migrations) {
      try {
        await this.store.executeSql(sql);
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        if (message.includes('duplicate column name') || message.includes('already exists')) {
          continue;
        }
        console.error('Word table migration failed: ' + message);
      }
    }
  }

  async insert(word: WordRecord): Promise<void> {
    if (!this.store) throw new Error('Repository not initialized');

    const values: relationalStore.ValuesBucket = {
      id: word.id,
      word: word.word,
      translation: JSON.stringify(word.translation),
      part_of_speech: word.partOfSpeech,
      example_sentence: word.exampleSentence ?? '',
      example_translation: word.exampleTranslation ?? '',
      phonetic_uk: word.phoneticUK ?? '',
      phonetic_us: word.phoneticUS ?? '',
      source: word.source,
      original_query: word.originalQuery ?? '',
      tags: JSON.stringify(word.tags),
      proficiency: word.proficiency,
      review_count: word.reviewCount,
      created_at: word.createdAt,
      last_reviewed_at: word.lastReviewedAt ?? 0,
      image_uri: word.imageUri ?? '',
      definition: word.definition ?? '',
      examples: JSON.stringify(word.examples ?? []),
      is_archived: word.isArchived ? 1 : 0,
      is_favorite: word.isFavorite ? 1 : 0
    };

    await this.store.insert('word_records', values);
  }

  async findById(id: string): Promise<WordRecord | null> {
    if (!this.store) throw new Error('Repository not initialized');

    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('word_records');
    predicates.equalTo('id', id);

    const resultSet: relationalStore.ResultSet = await this.store.query(predicates, ['*']);
    if (resultSet.goToNextRow()) {
      return this.mapToWordRecord(resultSet);
    }
    return null;
  }

  async findTodayWords(): Promise<WordRecord[]> {
    if (!this.store) throw new Error('Repository not initialized');

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const startOfDay = today.getTime();

    const predicates = new relationalStore.RdbPredicates('word_records');
    predicates.greaterThanOrEqualTo('created_at', startOfDay);

    const resultSet = await this.store.query(predicates, ['*']);
    return this.mapResultSet(resultSet);
  }

  async findByDateRange(startTime: number, endTime: number): Promise<WordRecord[]> {
    if (!this.store) throw new Error('Repository not initialized');

    const predicates = new relationalStore.RdbPredicates('word_records');
    predicates.greaterThanOrEqualTo('created_at', startTime)
      .and()
      .lessThanOrEqualTo('created_at', endTime);

    const resultSet = await this.store.query(predicates, ['*']);
    return this.mapResultSet(resultSet);
  }

  async findReviewWords(limit: number = 20): Promise<WordRecord[]> {
    if (!this.store) throw new Error('Repository not initialized');

    const oneDayAgo = Date.now() - 24 * 60 * 60 * 1000;

    const predicates = new relationalStore.RdbPredicates('word_records');
    predicates.lessThan('proficiency', 3)
      .or()
      .lessThanOrEqualTo('last_reviewed_at', oneDayAgo)
      .orderByAsc('proficiency')
      .orderByAsc('last_reviewed_at')
      .limitAs(limit);

    const resultSet = await this.store.query(predicates, ['*']);
    return this.mapResultSet(resultSet);
  }

  async getAllWords(): Promise<WordRecord[]> {
    if (!this.store) throw new Error('Repository not initialized');

    const predicates = new relationalStore.RdbPredicates('word_records');
    predicates.orderByDesc('created_at');

    const resultSet = await this.store.query(predicates, ['*']);
    return this.mapResultSet(resultSet);
  }

  async findRandomWords(count: number): Promise<WordRecord[]> {
    if (!this.store) throw new Error('Repository not initialized');

    const predicates = new relationalStore.RdbPredicates('word_records');
    const resultSet = await this.store.query(predicates, ['*']);
    const words = this.mapResultSet(resultSet);
    const shuffled = [...words];

    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      const temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }
    return shuffled.slice(0, Math.min(count, shuffled.length));
  }

  async updateProficiency(id: string, newProficiency: number): Promise<void> {
    if (!this.store) throw new Error('Repository not initialized');

    const current = await this.findById(id);
    const newReviewCount = (current?.reviewCount ?? 0) + 1;

    const values: relationalStore.ValuesBucket = {
      proficiency: Math.min(5, Math.max(0, newProficiency)),
      review_count: newReviewCount,
      last_reviewed_at: Date.now()
    };

    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('word_records');
    predicates.equalTo('id', id);

    await this.store.update(values, predicates);
  }

  async search(keyword: string): Promise<WordRecord[]> {
    if (!this.store) throw new Error('Repository not initialized');

    const predicates = new relationalStore.RdbPredicates('word_records');
    predicates.contains('word', keyword)
      .or()
      .contains('translation', keyword);

    const resultSet = await this.store.query(predicates, ['*']);
    return this.mapResultSet(resultSet);
  }

  async delete(id: string): Promise<void> {
    if (!this.store) throw new Error('Repository not initialized');

    const predicates = new relationalStore.RdbPredicates('word_records');
    predicates.equalTo('id', id);

    await this.store.delete(predicates);
  }

  async updateFavorite(id: string, isFavorite: boolean): Promise<void> {
    if (!this.store) throw new Error('Repository not initialized');

    const values: relationalStore.ValuesBucket = {
      is_favorite: isFavorite ? 1 : 0
    };
    const predicates = new relationalStore.RdbPredicates('word_records');
    predicates.equalTo('id', id);
    await this.store.update(values, predicates);
  }

  async updateArchived(id: string, isArchived: boolean): Promise<void> {
    if (!this.store) throw new Error('Repository not initialized');

    const values: relationalStore.ValuesBucket = {
      is_archived: isArchived ? 1 : 0
    };
    const predicates = new relationalStore.RdbPredicates('word_records');
    predicates.equalTo('id', id);
    await this.store.update(values, predicates);
  }

  async getTotalCount(): Promise<number> {
    if (!this.store) throw new Error('Repository not initialized');

    const predicates = new relationalStore.RdbPredicates('word_records');
    const resultSet = await this.store.query(predicates, ['COUNT(*) as count']);
    if (resultSet.goToNextRow()) {
      return resultSet.getLong(resultSet.getColumnIndex('count'));
    }
    return 0;
  }

  private mapResultSet(resultSet: relationalStore.ResultSet): WordRecord[] {
    const words: WordRecord[] = [];
    while (resultSet.goToNextRow()) {
      words.push(this.mapToWordRecord(resultSet));
    }
    return words;
  }

  private parseStringArray(json: string): string[] {
    let parsed: Object | null = null;
    try {
      parsed = JSON.parse(json);
    } catch {
      return [];
    }
    if (parsed instanceof Array) {
      const arr: Object[] = parsed as Object[];
      const result: string[] = [];
      for (const item of arr) {
        if (typeof item === 'string') {
          result.push(item);
        }
      }
      return result;
    }
    return [];
  }

  private parseExamples(json: string): ExampleSentence[] {
    let parsed: Object | null = null;
    try {
      parsed = JSON.parse(json);
    } catch {
      return [];
    }
    if (parsed instanceof Array) {
      const arr: Object[] = parsed as Object[];
      const result: ExampleSentence[] = [];
      for (const item of arr) {
        if (item && typeof item === 'object') {
          const obj = item as Record<string, Object>;
          const en = obj['en'];
          const zh = obj['zh'];
          if (typeof en === 'string' && typeof zh === 'string') {
            result.push({ en, zh });
          }
        }
      }
      return result;
    }
    return [];
  }

  private normalizePartOfSpeech(value: string): PartOfSpeech {
    const valid: PartOfSpeech[] = [
      'noun', 'verb', 'adjective', 'adverb',
      'pronoun', 'preposition', 'conjunction', 'interjection', 'phrase'
    ];
    const normalized = value.toLowerCase().trim();
    const found = valid.find((v: PartOfSpeech): boolean => v === normalized);
    return found ?? 'noun';
  }

  private normalizeRecordSource(value: string): RecordSource {
    const valid: RecordSource[] = ['manual', 'voice', 'vision', 'ai-suggest'];
    const normalized = value.toLowerCase().trim();
    const found = valid.find((v: RecordSource): boolean => v === normalized);
    return found ?? 'manual';
  }

  private mapToWordRecord(resultSet: relationalStore.ResultSet): WordRecord {
    const getString = (col: string): string =>
      resultSet.getString(resultSet.getColumnIndex(col));
    const getLong = (col: string): number =>
      resultSet.getLong(resultSet.getColumnIndex(col));
    const getOptString = (col: string): string | undefined => {
      const idx = resultSet.getColumnIndex(col);
      const val = resultSet.getString(idx);
      return val === '' ? undefined : val;
    };
    const getOptLong = (col: string): number | undefined => {
      const idx = resultSet.getColumnIndex(col);
      const val = resultSet.getLong(idx);
      return val === 0 ? undefined : val;
    };

    return {
      id: getString('id'),
      word: getString('word'),
      translation: this.parseStringArray(getString('translation')),
      partOfSpeech: this.normalizePartOfSpeech(getString('part_of_speech')),
      exampleSentence: getOptString('example_sentence'),
      exampleTranslation: getOptString('example_translation'),
      phoneticUK: getOptString('phonetic_uk'),
      phoneticUS: getOptString('phonetic_us'),
      source: this.normalizeRecordSource(getString('source')),
      originalQuery: getOptString('original_query'),
      tags: this.parseStringArray(getString('tags') || '[]'),
      proficiency: getLong('proficiency'),
      reviewCount: getLong('review_count'),
      createdAt: getLong('created_at'),
      lastReviewedAt: getOptLong('last_reviewed_at'),
      imageUri: getOptString('image_uri'),
      definition: getOptString('definition'),
      examples: this.parseExamples(getString('examples')),
      isArchived: getLong('is_archived') === 1,
      isFavorite: getLong('is_favorite') === 1
    };
  }
}
