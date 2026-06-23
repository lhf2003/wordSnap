import { AIProviderConfig } from './AIProviderConfig';
import { AIProvider } from './AIProvider';
import { MockAIProvider } from './MockAIProvider';
import { DeepSeekProvider } from './DeepSeekProvider';
import { TongyiProvider } from './TongyiProvider';

export class AIServiceFactory {
  static create(config: AIProviderConfig): AIProvider {
    switch (config.provider) {
      case 'deepseek':
        return new DeepSeekProvider(config);
      case 'tongyi':
        return new TongyiProvider(config);
      case 'mock':
      default:
        return new MockAIProvider();
    }
  }
}
