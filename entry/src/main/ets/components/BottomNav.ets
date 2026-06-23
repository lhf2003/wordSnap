import { uiMaterial } from '@kit.ArkUI';
import { DesignTokens } from './DesignTokens';

export interface NavItem {
  label: string;
  page: string;
}

@Component
export struct BottomNav {
  @Prop activeIndex: number = 0;
  private readonly items: NavItem[] = [
    { label: '首页', page: 'pages/Index' },
    { label: '记录', page: 'pages/QuickCapturePage' },
    { label: '词库', page: 'pages/LibraryPage' },
    { label: '我的', page: 'pages/ProfilePage' }
  ];

  private onItemTap(index: number): void {
    if (index === this.activeIndex) {
      return;
    }
    const target = this.items[index].page;
    import('@kit.ArkUI').then((m) => {
      m.router.replaceUrl({ url: target });
    }).catch((err: Error) => {
      console.error('BottomNav router import failed: ' + err.message);
    });
  }

  @Builder
  HomeIcon(active: boolean) {
    Column() {
      Row()
        .width(20)
        .height(16)
        .backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary)
        .borderRadius(2)
      Row()
        .width(8)
        .height(6)
        .backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary)
        .margin({ top: -14 })
    }
    .width(24)
    .height(24)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  RecordIcon(active: boolean) {
    Row() {
      Row()
        .width(14)
        .height(2)
        .backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary)
      Row()
        .width(10)
        .height(2)
        .backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary)
      Row()
        .width(14)
        .height(2)
        .backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary)
    }
    .width(24)
    .height(24)
    .justifyContent(FlexAlign.SpaceEvenly)
    .alignItems(VerticalAlign.Center)
    .direction(Direction.Ltr)
  }

  @Builder
  LibraryIcon(active: boolean) {
    Row() {
      Column() {
        Row().width(6).height(6).backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary).borderRadius(1)
        Row().width(6).height(6).backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary).borderRadius(1)
      }.justifyContent(FlexAlign.SpaceEvenly).height(16)
      Column() {
        Row().width(6).height(6).backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary).borderRadius(1)
        Row().width(6).height(6).backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary).borderRadius(1)
      }.justifyContent(FlexAlign.SpaceEvenly).height(16)
    }
    .width(24)
    .height(24)
    .justifyContent(FlexAlign.SpaceEvenly)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  ProfileIcon(active: boolean) {
    Column() {
      Row()
        .width(8)
        .height(8)
        .backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary)
        .borderRadius(4)
      Row()
        .width(16)
        .height(7)
        .backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary)
        .borderRadius({ topLeft: 8, topRight: 8 })
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
      this.RecordIcon(active)
    } else if (index === 2) {
      this.LibraryIcon(active)
    } else {
      this.ProfileIcon(active)
    }
  }

  build() {
    Row() {
      ForEach(this.items, (item: NavItem, index: number) => {
        Column() {
          this.NavIcon(index, index === this.activeIndex)
          Text(item.label)
            .fontSize(DesignTokens.font12)
            .fontColor(index === this.activeIndex ? DesignTokens.primary : DesignTokens.textSecondary)
            .fontWeight(index === this.activeIndex ? FontWeight.Medium : FontWeight.Normal)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .height(56)
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.onItemTap(index))
      }, (item: NavItem) => item.label)
    }
    .width('92%')
    .height(64)
    .padding({ top: 4, bottom: 8 })
    .margin({ bottom: 12 })
    .borderRadius(DesignTokens.radiusFull)
    .backgroundColor(Color.Transparent)
    .systemMaterial(DesignTokens.materialUltraThin)
  }
}
