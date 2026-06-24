import { http } from '@kit.NetworkKit';

const BASE_URL: string = 'https://your-api.example.com';

export class AuthHttpClient {
  private static instance: AuthHttpClient | null = null;

  static getInstance(): AuthHttpClient {
    if (AuthHttpClient.instance === null) {
      AuthHttpClient.instance = new AuthHttpClient();
    }
    return AuthHttpClient.instance;
  }

  private constructor() {}

  async post(path: string, body: object): Promise<string> {
    const httpRequest: http.HttpRequest = http.createHttp();
    const url: string = BASE_URL + path;
    const options: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json'
      },
      extraData: JSON.stringify(body)
    };
    try {
      const response = await httpRequest.request(url, options);
      if (response.responseCode !== 200) {
        throw new Error('Http error: ' + response.responseCode.toString());
      }
      if (typeof response.result !== 'string') {
        throw new Error('Invalid http response');
      }
      return response.result;
    } finally {
      httpRequest.destroy();
    }
  }
}
