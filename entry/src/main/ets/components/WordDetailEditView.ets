import { WordRecord, ExampleSentence } from '../model/Types';
import { DesignTokens } from './DesignTokens';

export interface WordEditFields {
  word?: string;
  translation?: string[];
  exampleSentence?: string;
  exampleTranslation?: string;
  phoneticUK?: string;
  phoneticUS?: string;
  originalQuery?: string;
  tags?: string[];
  definition?: string;
  examples?: ExampleSentence[];
}

@ComponentV2
export struct WordDetailEditView {
  @Require @Param editedWord: WordRecord;
  @Event onFieldChange: (fields: WordEditFields) => void;
  @Event onCancel: () => void;
  @Event onSave: () => void;
  @Event onBlankClick: () => void = () => {};
  @Local private isInputClicked: boolean = false;

  private markInputClicked(): void {
    this.isInputClicked = true;
  }

  private handleBlankClick(): void {
    if (this.isInputClicked) {
      this.isInputClicked = false;
      return;
    }
    this.onBlankClick();
  }

  private updateField(fields: WordEditFields): void {
    this.onFieldChange(fields);
  }

  @Builder
  EditWordHeader() {
    Column({ space: DesignTokens.spacing12 }) {
      TextInput({
        text: this.editedWord.word,
        placeholder: '单词'
      })
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor(DesignTokens.textPrimary)
        .backgroundColor(DesignTokens.bgInput)
        .borderRadius(DesignTokens.radius12)
        .padding(12)
        .width('100%')
        .onClick(() => this.markInputClicked())
        .onChange((value: string) => this.updateField({ word: value }))

      Row({ space: DesignTokens.spacing12 }) {
        TextInput({
          text: this.editedWord.phoneticUK ?? '',
          placeholder: '英式音标'
        })
          .fontSize(DesignTokens.font14)
          .fontColor(DesignTokens.textPrimary)
          .backgroundColor(DesignTokens.bgInput)
          .borderRadius(DesignTokens.radius12)
          .padding(12)
          .layoutWeight(1)
          .onClick(() => this.markInputClicked())
          .onChange((value: string) => this.updateField({ phoneticUK: value || undefined }))

        TextInput({
          text: this.editedWord.phoneticUS ?? '',
          placeholder: '美式音标'
        })
          .fontSize(DesignTokens.font14)
          .fontColor(DesignTokens.textPrimary)
          .backgroundColor(DesignTokens.bgInput)
          .borderRadius(DesignTokens.radius12)
          .padding(12)
          .layoutWeight(1)
          .onClick(() => this.markInputClicked())
          .onChange((value: string) => this.updateField({ phoneticUS: value || undefined }))
      }
      .width('100%')
    }
    .width('100%')
    .padding({ top: DesignTokens.spacing16, bottom: DesignTokens.spacing24 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  EditDefinitionSection() {
    Column({ space: DesignTokens.spacing12 }) {
      Text('DEFINITION')
        .fontSize(DesignTokens.font10)
        .fontWeight(FontWeight.Medium)
        .fontColor(DesignTokens.textTertiary)
        .letterSpacing(1)
        .width('100%')

      TextInput({
        text: this.editedWord.definition ?? '',
        placeholder: '定义（可选）'
      })
        .fontSize(DesignTokens.font16)
        .fontColor(DesignTokens.textPrimary)
        .backgroundColor(DesignTokens.bgInput)
        .borderRadius(DesignTokens.radius12)
        .padding(12)
        .width('100%')
        .onClick(() => this.markInputClicked())
        .onChange((value: string) => this.updateField({ definition: value || undefined }))

      TextInput({
        text: this.editedWord.translation.join('；'),
        placeholder: '释义，用“；”分隔'
      })
        .fontSize(DesignTokens.font16)
        .fontColor(DesignTokens.textPrimary)
        .backgroundColor(DesignTokens.bgInput)
        .borderRadius(DesignTokens.radius12)
        .padding(12)
        .width('100%')
        .onClick(() => this.markInputClicked())
        .onChange((value: string) => {
          const translation = value.split('；')
            .map((t: string) => t.trim())
            .filter((t: string) => t.length > 0);
          this.updateField({ translation });
        })
    }
    .width('100%')
    .padding(DesignTokens.spacing20)
    .backgroundColor(Color.Transparent)
    .systemMaterial(DesignTokens.materialThin)
    .borderRadius(DesignTokens.radius24)
  }

  @Builder
  EditExamplesSection() {
    Column({ space: DesignTokens.spacing12 }) {
      Text('CONTEXTUAL EXAMPLES')
        .fontSize(DesignTokens.font10)
        .fontWeight(FontWeight.Medium)
        .fontColor(DesignTokens.textTertiary)
        .letterSpacing(1)
        .width('100%')

      TextInput({
        text: this.editedWord.exampleSentence ?? '',
        placeholder: '英文例句'
      })
        .fontSize(DesignTokens.font14)
        .fontColor(DesignTokens.textPrimary)
        .fontStyle(FontStyle.Italic)
        .backgroundColor(DesignTokens.bgInput)
        .borderRadius(DesignTokens.radius12)
        .padding(12)
        .width('100%')
        .onClick(() => this.markInputClicked())
        .onChange((value: string) => this.updateField({ exampleSentence: value || undefined }))

      TextInput({
        text: this.editedWord.exampleTranslation ?? '',
        placeholder: '中文翻译'
      })
        .fontSize(DesignTokens.font14)
        .fontColor(DesignTokens.textSecondary)
        .backgroundColor(DesignTokens.bgInput)
        .borderRadius(DesignTokens.radius12)
        .padding(12)
        .width('100%')
        .onClick(() => this.markInputClicked())
        .onChange((value: string) => this.updateField({ exampleTranslation: value || undefined }))
    }
    .width('100%')
    .padding(DesignTokens.spacing20)
    .backgroundColor(Color.Transparent)
    .systemMaterial(DesignTokens.materialThin)
    .borderRadius(DesignTokens.radius24)
  }

  @Builder
  EditTagsSection() {
    Column({ space: DesignTokens.spacing12 }) {
      Text('TAGS')
        .fontSize(DesignTokens.font10)
        .fontWeight(FontWeight.Medium)
        .fontColor(DesignTokens.textTertiary)
        .letterSpacing(1)
        .width('100%')

      TextInput({
        text: this.editedWord.tags.join(', '),
        placeholder: '标签，用逗号分隔'
      })
        .fontSize(DesignTokens.font16)
        .fontColor(DesignTokens.textPrimary)
        .backgroundColor(DesignTokens.bgInput)
        .borderRadius(DesignTokens.radius12)
        .padding(12)
        .width('100%')
        .onClick(() => this.markInputClicked())
        .onChange((value: string) => {
          const tags = value.split(',')
            .map((t: string) => t.trim())
            .filter((t: string) => t.length > 0);
          this.updateField({ tags });
        })
    }
    .width('100%')
    .padding(DesignTokens.spacing20)
    .backgroundColor(Color.Transparent)
    .systemMaterial(DesignTokens.materialThin)
    .borderRadius(DesignTokens.radius24)
  }

  build() {
    Column({ space: DesignTokens.spacing16 }) {
      this.EditWordHeader()
      this.EditDefinitionSection()
      this.EditExamplesSection()
      this.EditTagsSection()
    }
    .width('100%')
    .onClick(() => this.handleBlankClick())
  }
}
