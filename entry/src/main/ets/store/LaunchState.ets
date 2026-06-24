export class LaunchState {
  private static instance: LaunchState | null = null;
  private shortcutStartTime: number = 0;
  private shortcutLaunchTarget: string = '';

  static getInstance(): LaunchState {
    if (LaunchState.instance === null) {
      LaunchState.instance = new LaunchState();
    }
    return LaunchState.instance;
  }

  setShortcutStartTime(time: number): void {
    this.shortcutStartTime = time;
  }

  getShortcutStartTime(): number {
    return this.shortcutStartTime;
  }

  clearShortcutStartTime(): void {
    this.shortcutStartTime = 0;
  }

  setShortcutLaunchTarget(target: string): void {
    this.shortcutLaunchTarget = target;
  }

  getShortcutLaunchTarget(): string {
    return this.shortcutLaunchTarget;
  }

  clearShortcutLaunchTarget(): void {
    this.shortcutLaunchTarget = '';
  }
}
