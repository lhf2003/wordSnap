import { relationalStore } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { WordRecord, PartOfSpeech, RecordSource } from '../model/Types';

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
    image_uri TEXT
  )
`;

export class WordRepository {
  private static instance: WordRepository;
  private store: relationalStore.RdbStore | null = null;

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
    this.store = await relationalStore.getRdbStore(context, STORE_CONFIG);
    await this.store.executeSql(WORD_TABLE_SQL);
    await this.store.executeSql(
      'CREATE INDEX IF NOT EXISTS idx_word_created ON word_records(created_at)'
    );
    await this.store.executeSql(
      'CREATE INDEX IF NOT EXISTS idx_word_proficiency ON word_records(proficiency, last_reviewed_at)'
    );
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
      image_uri: word.imageUri ?? ''
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

    // Fisher-Yates 洗牌算法
    for (let i = words.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      const temp = words[i];
      words[i] = words[j];
      words[j] = temp;
    }
    return words.slice(0, Math.min(count, words.length));
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
      imageUri: getOptString('image_uri')
    };
  }
}
