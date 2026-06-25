import { WordRecord } from '../model/Types';
import { DesignTokens } from './DesignTokens';
import { TimeUtils } from '../utils/TimeUtils';

@ComponentV2
export struct HomeWordCard {
  @Require @Param word: WordRecord;
  @Require @Param isFirst: boolean;
  @Require @Param isLast: boolean;
  @Event onCardClick: () => void = () => {};

  private statusLabel(proficiency: number): string {
    if (proficiency >= 5) {
      return '已掌握';
    }
    if (proficiency < 3) {
      return '待复习';
    }
    return '学习中';
  }

  private statusIcon(proficiency: number): string {
    if (proficiency >= 5) {
      return '✓';
    }
    if (proficiency < 3) {
      return '↻';
    }
    return '•';
  }

  private statusColor(proficiency: number): string {
    if (proficiency >= 5) {
      return DesignTokens.success;
    }
    if (proficiency < 3) {
      return DesignTokens.warning;
    }
    return DesignTokens.primary;
  }

  private statusSurface(proficiency: number): string {
    if (proficiency >= 5) {
      return DesignTokens.successSurface;
    }
    if (proficiency < 3) {
      return DesignTokens.warningSurface;
    }
    return DesignTokens.primarySurface;
  }

  @Builder
  StatusBadge() {
    Row() {
      Text(this.statusIcon(this.word.proficiency))
        .fontSize(DesignTokens.font10)
        .fontColor(this.statusColor(this.word.proficiency))
        .margin({ right: DesignTokens.spacing4 })
      Text(this.statusLabel(this.word.proficiency))
        .fontSize(DesignTokens.font10)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.statusColor(this.word.proficiency))
    }
    .backgroundColor(this.statusSurface(this.word.proficiency))
    .padding({ left: DesignTokens.spacing8, right: DesignTokens.spacing8, top: DesignTokens.spacing4, bottom: DesignTokens.spacing4 })
    .borderRadius(DesignTokens.radiusFull)
  }

  build() {
    Row() {
      Column() {
        Row() {
          Text(this.word.word)
            .fontSize(this.isFirst ? DesignTokens.font18 : DesignTokens.font16)
            .fontWeight(this.isFirst ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(DesignTokens.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.word.translation.length > 0 ? this.word.translation.join('；') : '暂无释义')
            .fontSize(DesignTokens.font14)
            .fontColor(DesignTokens.textSecondary)
            .margin({ left: DesignTokens.spacing8 })
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Text(TimeUtils.formatRelativeTime(this.word.createdAt))
          .fontSize(DesignTokens.font10)
          .fontColor(DesignTokens.textTertiary)
          .margin({ top: DesignTokens.spacing4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      this.StatusBadge()
    }
    .width('100%')
    .padding({ left: DesignTokens.spacing16, right: DesignTokens.spacing16, top: DesignTokens.spacing12, bottom: DesignTokens.spacing12 })
    .backgroundColor(Color.Transparent)
    .systemMaterial(this.isFirst ? DesignTokens.materialRegular : DesignTokens.materialThin)
    .borderRadius(DesignTokens.radius20)
    .margin({ bottom: this.isLast ? 0 : DesignTokens.spacing8 })
    .onClick(() => this.onCardClick())
  }
}
