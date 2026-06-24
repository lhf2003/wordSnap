export class TimeUtils {
  static formatRelativeTime(timestamp: number): string {
    const now = Date.now();
    const diff = now - timestamp;
    const minute = 60 * 1000;
    const hour = 60 * minute;
    const day = 24 * hour;

    if (diff < 0) {
      return 'JUST NOW';
    }
    if (diff < minute) {
      return 'JUST NOW';
    }
    if (diff < hour) {
      const mins = Math.floor(diff / minute);
      return `${mins} MIN${mins > 1 ? 'S' : ''} AGO`;
    }
    if (diff < day) {
      const hours = Math.floor(diff / hour);
      return `${hours} HOUR${hours > 1 ? 'S' : ''} AGO`;
    }
    if (TimeUtils.isSameDay(timestamp, now)) {
      return 'ADDED TODAY';
    }
    const days = Math.floor(diff / day);
    return `${days} DAY${days > 1 ? 'S' : ''} AGO`;
  }

  private static isSameDay(a: number, b: number): boolean {
    const da = new Date(a);
    const db = new Date(b);
    return da.getFullYear() === db.getFullYear() &&
      da.getMonth() === db.getMonth() &&
      da.getDate() === db.getDate();
  }
}
