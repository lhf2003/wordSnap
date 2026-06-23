import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { LaunchState } from '../store/LaunchState';

const TAG = 'ShortcutKeyAbility';

export default class ShortcutKeyAbility extends UIAbility {
  private startTime: number = 0;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.startTime = Date.now();
    const parameters = want.parameters;
    const triggerSource = parameters !== undefined ? parameters['ohos.ability.params.shortcutKey'] : undefined;
    if (triggerSource === 'double_click' || triggerSource === true) {
      LaunchState.getInstance().setShortcutStartTime(this.startTime);
    }
    console.info(TAG, 'onCreate cost: ' + (Date.now() - this.startTime) + 'ms');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    console.info(TAG, 'before loadContent cost: ' + (Date.now() - this.startTime) + 'ms');
    windowStage.loadContent('pages/QuickCapturePage', (err) => {
      if (err) {
        console.error(TAG, 'Failed to load QuickCapturePage: ' + JSON.stringify(err));
      } else {
        console.info(TAG, 'loadContent done cost: ' + (Date.now() - this.startTime) + 'ms');
      }
    });
  }
}
