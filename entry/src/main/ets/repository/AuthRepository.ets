import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { AuthToken } from '../model/Types';

const PREFERENCE_NAME: string = 'auth_preferences';
const KEY_ACCESS_TOKEN: string = 'auth_access_token';
const KEY_REFRESH_TOKEN: string = 'auth_refresh_token';
const KEY_EXPIRES_AT: string = 'auth_expires_at';

export class AuthRepository {
  private static instance: AuthRepository | null = null;
  private pref: preferences.Preferences | null = null;
  private context: Context | null = null;

  static getInstance(): AuthRepository {
    if (AuthRepository.instance === null) {
      AuthRepository.instance = new AuthRepository();
    }
    return AuthRepository.instance;
  }

  private constructor() {}

  setContext(context: Context): void {
    this.context = context;
  }

  async init(): Promise<void> {
    if (this.pref !== null) {
      return;
    }
    if (this.context === null) {
      throw new Error('AuthRepository context not set');
    }
    this.pref = await preferences.getPreferences(this.context, PREFERENCE_NAME);
  }

  async saveToken(token: AuthToken): Promise<void> {
    await this.init();
    if (this.pref === null) {
      throw new Error('AuthRepository not initialized');
    }
    await this.pref.put(KEY_ACCESS_TOKEN, token.accessToken);
    await this.pref.put(KEY_REFRESH_TOKEN, token.refreshToken);
    await this.pref.put(KEY_EXPIRES_AT, token.expiresAt);
    await this.pref.flush();
  }

  async loadToken(): Promise<AuthToken | null> {
    await this.init();
    if (this.pref === null) {
      throw new Error('AuthRepository not initialized');
    }
    const accessToken: preferences.ValueType = await this.pref.get(KEY_ACCESS_TOKEN, '');
    const refreshToken: preferences.ValueType = await this.pref.get(KEY_REFRESH_TOKEN, '');
    const expiresAt: preferences.ValueType = await this.pref.get(KEY_EXPIRES_AT, 0);
    if (typeof accessToken !== 'string' || accessToken.length === 0) {
      return null;
    }
    if (typeof refreshToken !== 'string' || refreshToken.length === 0) {
      return null;
    }
    if (typeof expiresAt !== 'number' || expiresAt <= 0) {
      return null;
    }
    const token: AuthToken = new AuthToken({
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt
    });
    return token;
  }

  async clearToken(): Promise<void> {
    await this.init();
    if (this.pref === null) {
      throw new Error('AuthRepository not initialized');
    }
    await this.pref.delete(KEY_ACCESS_TOKEN);
    await this.pref.delete(KEY_REFRESH_TOKEN);
    await this.pref.delete(KEY_EXPIRES_AT);
    await this.pref.flush();
  }

  async isLoggedIn(): Promise<boolean> {
    const token: AuthToken | null = await this.loadToken();
    if (token === null) {
      return false;
    }
    return Date.now() < token.expiresAt;
  }
}
