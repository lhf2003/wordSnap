import { Context } from '@kit.AbilityKit';
import { AuthToken, HuaweiUserInfo, LoginResponse } from '../../model/Types';
import { AuthRepository } from '../../repository/AuthRepository';
import { AppStore } from '../../store/AppStore';
import { AuthHttpClient } from './AuthHttpClient';

const USE_MOCK: boolean = true;

interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
}

interface HuaweiLoginRequest {
  authorizationCode: string;
}

export class AuthService {
  private static instance: AuthService | null = null;
  private authRepo: AuthRepository;
  private httpClient: AuthHttpClient;

  static getInstance(): AuthService {
    if (AuthService.instance === null) {
      AuthService.instance = new AuthService();
    }
    return AuthService.instance;
  }

  private constructor() {
    this.authRepo = AuthRepository.getInstance();
    this.httpClient = AuthHttpClient.getInstance();
  }

  async init(context: Context): Promise<void> {
    this.authRepo.setContext(context);
    await this.authRepo.init();
  }

  async exchangeToken(authorizationCode: string): Promise<void> {
    let response: LoginResponse;
    if (USE_MOCK) {
      response = this.createMockResponse(authorizationCode);
    } else {
      response = await this.callBackend(authorizationCode);
    }
    const expiresAt: number = Date.now() + response.expiresIn * 1000;
    const token: AuthToken = {
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      expiresAt: expiresAt
    };
    await this.authRepo.saveToken(token);
    this.updateAppStore(response.user, token);
  }

  async signOut(): Promise<void> {
    try {
      await this.authRepo.clearToken();
      this.clearAppStoreUser();
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Sign out failed';
      console.error('AuthService.signOut failed: ' + message);
      throw new Error(message);
    }
  }

  async isLoggedIn(): Promise<boolean> {
    return this.authRepo.isLoggedIn();
  }

  private async callBackend(authorizationCode: string): Promise<LoginResponse> {
    const body: HuaweiLoginRequest = {
      authorizationCode: authorizationCode
    };
    const result: string = await this.httpClient.post('/api/auth/huawei/login', body);
    const wrapper: ApiResponse<LoginResponse> = JSON.parse(result) as ApiResponse<LoginResponse>;
    if (wrapper.code !== 0) {
      throw new Error(wrapper.message);
    }
    return wrapper.data;
  }

  private createMockResponse(authorizationCode: string): LoginResponse {
    const suffix: string = authorizationCode.length > 8 ? authorizationCode.substring(0, 8) : authorizationCode;
    const user: HuaweiUserInfo = {
      openId: 'mock-openid-' + suffix,
      nickname: '华为用户',
      avatarUrl: ''
    };
    const response: LoginResponse = {
      accessToken: 'mock-access-token-' + suffix,
      refreshToken: 'mock-refresh-token',
      expiresIn: 7200,
      user: user
    };
    return response;
  }

  private updateAppStore(user: HuaweiUserInfo, token: AuthToken): void {
    AppStore.getInstance().setLoggedInUser(user, token);
  }

  private clearAppStoreUser(): void {
    AppStore.getInstance().clearUser();
  }
}
