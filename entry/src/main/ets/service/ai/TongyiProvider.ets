import { AIWordDetail } from '../../model/Types';
import { AIProvider, AIQueryContext } from './AIProvider';
import { AIProviderConfig } from './AIProviderConfig';

export class TongyiProvider implements AIProvider {
  private config: AIProviderConfig;

  constructor(config: AIProviderConfig) {
    this.config = config;
  }

  name(): string {
    return 'tongyi';
  }

  async describeWord(query: string, context?: AIQueryContext): Promise<AIWordDetail> {
    console.info('TongyiProvider describeWord not implemented, query=' + query);
    throw new Error('Tongyi provider is not implemented in Step 2');
  }

  async generateDailyReport(words: string[], date: string): Promise<string> {
    console.info('TongyiProvider generateDailyReport not implemented');
    throw new Error('Tongyi provider is not implemented in Step 2');
  }
}
