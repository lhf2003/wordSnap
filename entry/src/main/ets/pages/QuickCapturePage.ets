import { WordRecord } from '../model/Types';
import { QuickCaptureViewModel } from '../viewmodel/QuickCaptureViewModel';
import { LaunchState } from '../store/LaunchState';
import { DesignTokens } from '../components/DesignTokens';
import { KeyCode } from '@kit.InputKit';

const TAG = 'QuickCapturePage';
const INPUT_ID = 'quickCaptureInput';

interface BackKeyEvent {
  keyCode: number;
}

@ComponentV2
export struct QuickCapturePage {
  @Local viewModel: QuickCaptureViewModel = new QuickCaptureViewModel();
  @Consumer('navPath') navPath: NavPathStack = new NavPathStack();

  async aboutToAppear() {
    const shortcutStart = LaunchState.getInstance().getShortcutStartTime();
    if (shortcutStart > 0) {
      console.info(TAG, 'page aboutToAppear cost: ' + (Date.now() - shortcutStart) + 'ms');
    }

    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) {
        throw new Error('无法获取应用上下文');
      }
      await this.viewModel.init(context);
    } catch (err) {
      const message = err instanceof Error ? err.message : '初始化失败';
      console.error(TAG, 'QuickCapturePage init failed: ' + message);
      this.showToast('服务初始化失败，请重试');
    }
  }

  onShown() {
    const shortcutStart = LaunchState.getInstance().getShortcutStartTime();
    if (shortcutStart > 0) {
      console.info(TAG, 'page shown cost: ' + (Date.now() - shortcutStart) + 'ms');
      LaunchState.getInstance().clearShortcutStartTime();
    }
  }

  aboutToDisappear() {
    this.viewModel.clearTimer();
  }

  private showToast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (e) {
      console.warn(TAG, 'showToast failed: ' + (e instanceof Error ? e.message : 'unknown'));
    }
  }

  private async saveWord() {
    const record = await this.viewModel.saveWord();
    if (record === null) {
      this.showToast('请输入英语单词或短语');
      return;
    }
    this.showToast('已保存: ' + record.word);
  }

  private goBack(): void {
    if (this.viewModel.hasSaved) {
      this.navPath.pop({ refresh: true });
    } else {
      this.navPath.pop();
    }
  }

  private handleBackKey(event: BackKeyEvent): boolean {
    if (event.keyCode === KeyCode.KEYCODE_BACK) {
      this.goBack();
      return true;
    }
    return false;
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Text('<')
            .fontSize(DesignTokens.font24)
            .fontColor(DesignTokens.textSecondary)
            .width(48)
            .height(48)
            .textAlign(TextAlign.Center)
            .margin({ right: 12 })
            .onClick(() => {
              this.goBack();
            })

          Text('快速记录')
            .fontSize(DesignTokens.font20)
            .fontWeight(FontWeight.Bold)
            .fontColor(DesignTokens.textPrimary)
            .layoutWeight(1)

          if (this.viewModel.showSuccess) {
            Text('已保存')
              .fontSize(DesignTokens.font14)
              .fontColor(DesignTokens.success)
              .animation({ duration: 300 })
          }
        }
        .width('90%')
        .margin({ top: 24, bottom: 24 })

        Column() {
          Text('英语单词 / 短语')
            .fontSize(DesignTokens.font16)
            .fontColor(DesignTokens.textPrimary)
            .width('100%')
            .margin({ bottom: 8 })

          TextInput({ placeholder: '输入英语单词或短语...', text: this.viewModel.wordInput })
            .id(INPUT_ID)
            .width('100%')
            .height(56)
            .backgroundColor(DesignTokens.bgInput)
            .borderRadius(DesignTokens.radius8)
            .fontSize(DesignTokens.font16)
            .placeholderColor(DesignTokens.textTertiary)
            .defaultFocus(true)
            .onChange((value: string) => {
              this.viewModel.wordInput = value;
            })
            .onSubmit(() => this.saveWord())
            .onKeyPreIme((event: BackKeyEvent): boolean => this.handleBackKey(event))
        }
        .width('90%')
        .margin({ bottom: 20 })

        Column() {
          Text('中文释义（可选）')
            .fontSize(DesignTokens.font16)
            .fontColor(DesignTokens.textPrimary)
            .width('100%')
            .margin({ bottom: 8 })

          TextInput({ placeholder: '输入中文释义，多个用逗号分隔...', text: this.viewModel.translationInput })
            .width('100%')
            .height(56)
            .backgroundColor(DesignTokens.bgInput)
            .borderRadius(DesignTokens.radius8)
            .fontSize(DesignTokens.font16)
            .placeholderColor(DesignTokens.textTertiary)
            .onChange((value: string) => {
              this.viewModel.translationInput = value;
            })
            .onSubmit(() => this.saveWord())
            .onKeyPreIme((event: BackKeyEvent): boolean => this.handleBackKey(event))
        }
        .width('90%')
        .margin({ bottom: 20 })

        Column() {
          Text('分类标签')
            .fontSize(DesignTokens.font16)
            .fontColor(DesignTokens.textPrimary)
            .width('100%')
            .margin({ bottom: 12 })

          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
            Repeat<string>(this.viewModel.presetTags)
              .each((obj: RepeatItem<string>) => {
                Text(obj.item)
                  .fontSize(DesignTokens.font16)
                  .padding({ left: 16, right: 16, top: 10, bottom: 10 })
                  .backgroundColor(
                    this.viewModel.selectedTags.includes(obj.item) ? DesignTokens.success : DesignTokens.bgInput
                  )
                  .fontColor(
                    this.viewModel.selectedTags.includes(obj.item) ? DesignTokens.textOnPrimary : DesignTokens.textSecondary
                  )
                  .borderRadius(DesignTokens.radiusFull)
                  .margin({ right: 12, bottom: 12 })
                  .onClick(() => this.viewModel.toggleTag(obj.item))
              })
              .key((item: string) => item)
          }
          .width('100%')
        }
        .width('90%')
        .margin({ bottom: 32 })

        Button(this.viewModel.isSaving ? '保存中...' : '保存')
          .width('90%')
          .height(56)
          .backgroundColor(this.viewModel.isSaving ? DesignTokens.textTertiary : DesignTokens.primary)
          .enabled(!this.viewModel.isSaving)
          .onClick(() => this.saveWord())

        Blank()
          .layoutWeight(1)

        Text('提示：双击智控键可快速唤起此页面')
          .fontSize(DesignTokens.font12)
          .fontColor(DesignTokens.textTertiary)
          .margin({ bottom: 24 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(DesignTokens.bgBase)
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      this.goBack();
      return true;
    })
  }
}
