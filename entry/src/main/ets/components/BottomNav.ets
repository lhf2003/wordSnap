import { router, uiMaterial } from '@kit.ArkUI';
import { DesignTokens } from './DesignTokens';

export interface NavItem {
  page: string;
}

@Component
export struct BottomNav {
  @Prop activeIndex: number = 0;
  private readonly items: NavItem[] = [
    { page: 'pages/Index' },
    { page: 'pages/QuickCapturePage' },
    { page: 'pages/QuickCapturePage' },
    { page: 'pages/QuickCapturePage' }
  ];

  private onItemTap(index: number): void {
    if (index === this.activeIndex) {
      return;
    }
    const target = this.items[index].page;
    router.replaceUrl({ url: target });
  }

  @Builder
  HomeIcon(active: boolean) {
    Column() {
      Row()
        .width(20)
        .height(14)
        .backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary)
        .borderRadius({ topLeft: 3, topRight: 3 })
      Row()
        .width(8)
        .height(6)
        .backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary)
        .margin({ top: -12 })
    }
    .width(24)
    .height(24)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  NotesIcon(active: boolean) {
    Column() {
      Row()
        .width(18)
        .height(2)
        .backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary)
        .borderRadius(1)
      Row()
        .width(14)
        .height(2)
        .backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary)
        .borderRadius(1)
        .margin({ top: 5 })
      Row()
        .width(18)
        .height(2)
        .backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary)
        .borderRadius(1)
        .margin({ top: 5 })
    }
    .width(24)
    .height(24)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  InfoIcon(active: boolean) {
    Column() {
      Row()
        .width(4)
        .height(4)
        .backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary)
        .borderRadius(2)
      Row()
        .width(4)
        .height(10)
        .backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary)
        .borderRadius(2)
        .margin({ top: 3 })
    }
    .width(24)
    .height(24)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ProfileIcon(active: boolean) {
    Column() {
      Row()
        .width(9)
        .height(9)
        .backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary)
        .borderRadius(4.5)
      Row()
        .width(18)
        .height(8)
        .backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary)
        .borderRadius({ topLeft: 9, topRight: 9 })
        .margin({ top: 2 })
    }
    .width(24)
    .height(24)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  NavIcon(index: number, active: boolean) {
    if (index === 0) {
      this.HomeIcon(active)
    } else if (index === 1) {
      this.NotesIcon(active)
    } else if (index === 2) {
      this.InfoIcon(active)
    } else {
      this.ProfileIcon(active)
    }
  }

  build() {
    Row() {
      ForEach(this.items, (item: NavItem, index: number) => {
        Column() {
          this.NavIcon(index, index === this.activeIndex)
        }
        .layoutWeight(1)
        .height(56)
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.onItemTap(index))
      }, (item: NavItem, index: number) => index.toString())
    }
    .width('84%')
    .height(64)
    .padding({ left: 12, right: 12 })
    .margin({ bottom: 16 })
    .borderRadius(DesignTokens.radiusFull)
    .backgroundColor(Color.Transparent)
    .systemMaterial(DesignTokens.materialUltraThin)
  }
}
