import { AIWordDetail } from '../../model/Types';
import { AIProvider, AIQueryContext } from './AIProvider';
import { AIProviderConfig } from './AIProviderConfig';

export class DeepSeekProvider implements AIProvider {
  private config: AIProviderConfig;

  constructor(config: AIProviderConfig) {
    this.config = config;
  }

  name(): string {
    return 'deepseek';
  }

  async describeWord(query: string, context?: AIQueryContext): Promise<AIWordDetail> {
    console.info('DeepSeekProvider describeWord not implemented, query=' + query);
    throw new Error('DeepSeek provider is not implemented in Step 2');
  }

  async generateDailyReport(words: string[], date: string): Promise<string> {
    console.info('DeepSeekProvider generateDailyReport not implemented');
    throw new Error('DeepSeek provider is not implemented in Step 2');
  }
}
