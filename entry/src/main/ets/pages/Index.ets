import { LaunchState } from '../store/LaunchState';
import { HomePage } from './HomePage';
import { LibraryPage } from './LibraryPage';
import { DailyReportPage } from './DailyReportPage';
import { ProfilePage } from './ProfilePage';
import { WordDetailPage } from './WordDetailPage';
import { QuickCapturePage } from './QuickCapturePage';
import { LoginPage } from './LoginPage';

@Entry
@ComponentV2
struct Index {
  @Provider('navPath') navPath: NavPathStack = new NavPathStack();

  @Builder
  PageMap(name: string) {
    if (name === 'HomePage') {
      HomePage()
    } else if (name === 'LibraryPage') {
      LibraryPage()
    } else if (name === 'DailyReportPage') {
      DailyReportPage()
    } else if (name === 'ProfilePage') {
      ProfilePage()
    } else if (name === 'WordDetailPage') {
      WordDetailPage()
    } else if (name === 'QuickCapturePage') {
      QuickCapturePage()
    } else if (name === 'LoginPage') {
      LoginPage()
    }
  }

  async aboutToAppear() {
    try {
      // 开发阶段跳过登录页，直接进入主页；后续恢复登录校验时请判断 AuthService.isLoggedIn()
      this.navPath.replacePath({ name: 'HomePage' });

      const shortcutTarget = LaunchState.getInstance().getShortcutLaunchTarget();
      if (shortcutTarget.length > 0) {
        this.navPath.pushPathByName(shortcutTarget, null);
      }
    } finally {
      LaunchState.getInstance().clearShortcutLaunchTarget();
    }
  }

  build() {
    Navigation(this.navPath) {
      Column() {}
    }
    .mode(NavigationMode.Stack)
    .navDestination(this.PageMap)
    .hideNavBar(true)
    .hideTitleBar(true)
  }
}
