import { WordRecord } from '../model/Types';
import { DesignTokens } from './DesignTokens';
import { TimeUtils } from '../utils/TimeUtils';

@ComponentV2
export struct LibraryWordCard {
  @Require @Param word: WordRecord;
  @Event onCardClick: () => void = () => {};

  private statusColor(): ResourceColor {
    if (this.word.proficiency >= 5) {
      return DesignTokens.success;
    }
    if (this.word.proficiency >= 1) {
      return DesignTokens.warning;
    }
    return DesignTokens.primary;
  }

  private shortDefinition(): string {
    if (this.word.definition && this.word.definition.length > 0) {
      return this.word.definition;
    }
    if (this.word.translation.length > 0) {
      return this.word.translation.join('；');
    }
    return this.word.exampleSentence ?? '暂无释义';
  }

  build() {
    Column() {
      Row() {
        Blank().layoutWeight(1)

        Row()
          .width(8)
          .height(8)
          .backgroundColor(this.statusColor())
          .borderRadius(DesignTokens.radiusFull)
      }
      .width('100%')
      .margin({ bottom: DesignTokens.spacing12 })

      Text(this.word.word)
        .fontSize(DesignTokens.font18)
        .fontWeight(FontWeight.Medium)
        .fontColor(DesignTokens.textPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Text(this.shortDefinition())
        .fontSize(DesignTokens.font12)
        .fontColor(DesignTokens.textSecondary)
        .margin({ top: 4 })
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Blank().layoutWeight(1)

      Text(TimeUtils.formatRelativeTime(this.word.createdAt).toUpperCase())
        .fontSize(DesignTokens.font10)
        .fontWeight(FontWeight.Medium)
        .fontColor(DesignTokens.textTertiary)
        .width('100%')
    }
    .width('100%')
    .aspectRatio(1)
    .padding(DesignTokens.spacing16)
    .backgroundColor(Color.Transparent)
    .systemMaterial(DesignTokens.materialThin)
    .borderRadius(DesignTokens.radius20)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => this.onCardClick())
  }
}
