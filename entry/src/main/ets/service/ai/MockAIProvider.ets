import { AIWordDetail, PartOfSpeech } from '../../model/Types';
import { AIProvider, AIQueryContext } from './AIProvider';

export class MockAIProvider implements AIProvider {
  name(): string {
    return 'mock';
  }

  async describeWord(query: string, context?: AIQueryContext): Promise<AIWordDetail> {
    const lowerQuery = query.toLowerCase().trim();
    const partOfSpeech: PartOfSpeech = this.guessPartOfSpeech(lowerQuery);
    return {
      word: query,
      translations: [this.mockTranslation(query)],
      partOfSpeech: [partOfSpeech],
      phoneticUS: '/mɒk/',
      examples: [
        { en: 'This is a mock example for ' + query + '.', zh: '这是 ' + query + ' 的模拟例句。' }
      ],
      synonyms: [lowerQuery + '-like']
    };
  }

  async generateDailyReport(words: string[], date: string): Promise<string> {
    return '今日共记录 ' + words.length + ' 个表达，继续加油！';
  }

  private guessPartOfSpeech(query: string): PartOfSpeech {
    if (query.startsWith('to ')) {
      return 'verb';
    }
    if (query.endsWith('ly')) {
      return 'adverb';
    }
    if (query.endsWith('ful') || query.endsWith('ous') || query.endsWith('ive')) {
      return 'adjective';
    }
    if (query.split(' ').length > 1) {
      return 'phrase';
    }
    return 'noun';
  }

  private mockTranslation(query: string): string {
    return '【模拟】' + query + ' 的中文释义';
  }
}
