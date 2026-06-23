import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { WordService } from '../service/WordService';
import { AppStore } from '../store/AppStore';

export default class EntryAbility extends UIAbility {
  private wordService: WordService = new WordService();

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    try {
      const context = this.context;
      await this.wordService.init(context);
      AppStore.getInstance().setContext(context);
      await AppStore.getInstance().load();
    } catch (err) {
      const message = err instanceof Error ? err.message : '数据库初始化失败';
      console.error('Failed to initialize app: ' + message);
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err) {
        console.error('Failed to load Index page: ' + JSON.stringify(err));
      }
    });
  }
}
