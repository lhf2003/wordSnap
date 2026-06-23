import { AIWordDetail } from '../../model/Types';

export interface AIQueryContext {
  sourceLanguage?: string;
  scene?: string;
  tags?: string[];
  imageUri?: string;
}

export interface AIProvider {
  name(): string;

  describeWord(query: string, context?: AIQueryContext): Promise<AIWordDetail>;

  generateDailyReport(words: string[], date: string): Promise<string>;
}
