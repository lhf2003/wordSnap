import { AIProviderType } from '../../model/Types';

export interface AIProviderConfig {
  provider: AIProviderType;
  apiKey?: string;
  endpoint?: string;
  model?: string;
  timeoutMs?: number;
}
