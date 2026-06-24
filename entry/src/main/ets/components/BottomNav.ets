import { DesignTokens } from './DesignTokens';

@Styles
function pressedNavItem() {
  .opacity(0.75)
}

export interface NavItem {
  name: string;
  label: string;
}

@ComponentV2
export struct BottomNav {
  @Param activeIndex: number = 0;
  @Consumer('navPath') navPath: NavPathStack = new NavPathStack();
  private readonly items: NavItem[] = [
    { name: 'HomePage', label: '首页' },
    { name: 'LibraryPage', label: '词库' },
    { name: 'DailyReportPage', label: '报告' },
    { name: 'ProfilePage', label: '我的' }
  ];

  private onItemTap(index: number): void {
    if (index === this.activeIndex) {
      return;
    }
    this.navPath.replacePath({ name: this.items[index].name });
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
  LibraryIcon(active: boolean) {
    Column() {
      Row() {
        Row()
          .width(7)
          .height(16)
          .backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary)
          .borderRadius({ topLeft: 2, bottomLeft: 2 })
        Row()
          .width(7)
          .height(16)
          .backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary)
          .borderRadius({ topRight: 2, bottomRight: 2 })
          .margin({ left: 2 })
      }
      .width(16)
      .height(16)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    }
    .width(24)
    .height(24)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  ReportIcon(active: boolean) {
    Column() {
      Row()
        .width(14)
        .height(10)
        .backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary)
        .borderRadius(2)
      Row()
        .width(18)
        .height(2)
        .backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary)
        .borderRadius(1)
        .margin({ top: 4 })
      Row()
        .width(14)
        .height(2)
        .backgroundColor(active ? DesignTokens.primary : DesignTokens.textTertiary)
        .borderRadius(1)
        .margin({ top: 2 })
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
      this.LibraryIcon(active)
    } else if (index === 2) {
      this.ReportIcon(active)
    } else {
      this.ProfileIcon(active)
    }
  }

  @Builder
  NavItemContent(item: NavItem, index: number, active: boolean) {
    Column() {
      this.NavIcon(index, active)
      Text(item.label)
        .fontSize(DesignTokens.font12)
        .fontColor(active ? DesignTokens.primary : DesignTokens.textSecondary)
        .fontWeight(active ? FontWeight.Medium : FontWeight.Regular)
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .height(56)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .stateStyles({
      pressed: pressedNavItem
    })
    .onClick(() => this.onItemTap(index))
  }

  build() {
    Row() {
      ForEach(this.items, (item: NavItem, index: number) => {
        this.NavItemContent(item, index, index === this.activeIndex)
      }, (item: NavItem) => item.name)
    }
    .width('84%')
    .height(64)
    .padding({ left: DesignTokens.spacing12, right: DesignTokens.spacing12 })
    .margin({ bottom: DesignTokens.spacing16 })
    .borderRadius(DesignTokens.radiusFull)
    .backgroundColor(Color.Transparent)
    .systemMaterial(DesignTokens.materialUltraThin)
  }
}
