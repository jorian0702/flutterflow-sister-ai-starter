// 日付関連のユーティリティ
import 'package:intl/intl.dart';

class DateUtils {
  // 日本語の日付フォーマット
  static String formatDateJapanese(DateTime date) {
    return DateFormat('yyyy年MM月dd日').format(date);
  }

  // 相対的な日付表示（「今日」「昨日」「3日前」など）
  static String getRelativeDateString(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(targetDate).inDays;

    if (difference == 0) {
      return '今日';
    } else if (difference == 1) {
      return '昨日';
    } else if (difference == -1) {
      return '明日';
    } else if (difference > 1 && difference <= 7) {
      return '${difference}日前';
    } else if (difference < -1 && difference >= -7) {
      return '${-difference}日後';
    } else if (difference > 7) {
      return DateFormat('MM/dd').format(date);
    } else {
      return DateFormat('MM/dd').format(date);
    }
  }

  // 期限までの残り時間を文字列で取得
  static String getTimeUntilDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      final pastDifference = now.difference(deadline);
      if (pastDifference.inDays > 0) {
        return '${pastDifference.inDays}日経過';
      } else if (pastDifference.inHours > 0) {
        return '${pastDifference.inHours}時間経過';
      } else {
        return '${pastDifference.inMinutes}分経過';
      }
    }

    if (difference.inDays > 0) {
      return 'あと${difference.inDays}日';
    } else if (difference.inHours > 0) {
      return 'あと${difference.inHours}時間';
    } else if (difference.inMinutes > 0) {
      return 'あと${difference.inMinutes}分';
    } else {
      return 'まもなく期限';
    }
  }

  // 曜日を日本語で取得
  static String getWeekdayJapanese(DateTime date) {
    const weekdays = ['日', '月', '火', '水', '木', '金', '土'];
    return weekdays[date.weekday % 7];
  }

  // 月初と月末を取得
  static Map<String, DateTime> getMonthRange(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);
    return {
      'start': firstDay,
      'end': lastDay,
    };
  }

  // 週初と週末を取得（月曜日始まり）
  static Map<String, DateTime> getWeekRange(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return {
      'start': DateTime(monday.year, monday.month, monday.day),
      'end': DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59),
    };
  }

  // 営業日かどうかを判定（土日を除く）
  static bool isWorkingDay(DateTime date) {
    return date.weekday >= 1 && date.weekday <= 5;
  }

  // 次の営業日を取得
  static DateTime getNextWorkingDay(DateTime date) {
    DateTime nextDay = date.add(const Duration(days: 1));
    while (!isWorkingDay(nextDay)) {
      nextDay = nextDay.add(const Duration(days: 1));
    }
    return nextDay;
  }

  // 前の営業日を取得
  static DateTime getPreviousWorkingDay(DateTime date) {
    DateTime previousDay = date.subtract(const Duration(days: 1));
    while (!isWorkingDay(previousDay)) {
      previousDay = previousDay.subtract(const Duration(days: 1));
    }
    return previousDay;
  }

  // 時間を含む詳細な相対時間表示
  static String getDetailedRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}日前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }

  // 期間の文字列表現
  static String getDurationString(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}日';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}時間';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分';
    } else {
      return '${duration.inSeconds}秒';
    }
  }

  // 日付範囲の文字列表現
  static String getDateRangeString(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return formatDateJapanese(start);
    } else if (start.year == end.year && start.month == end.month) {
      return '${start.year}年${start.month}月${start.day}日〜${end.day}日';
    } else if (start.year == end.year) {
      return '${start.year}年${start.month}月${start.day}日〜${end.month}月${end.day}日';
    } else {
      return '${formatDateJapanese(start)}〜${formatDateJapanese(end)}';
    }
  }

  // 年齢を計算
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // タイムゾーンを考慮した日付変換
  static DateTime toLocalTime(DateTime utcTime) {
    return utcTime.toLocal();
  }

  static DateTime toUtcTime(DateTime localTime) {
    return localTime.toUtc();
  }

  // 日付の妥当性チェック
  static bool isValidDate(int year, int month, int day) {
    try {
      final date = DateTime(year, month, day);
      return date.year == year && date.month == month && date.day == day;
    } catch (e) {
      return false;
    }
  }

  // 月の日数を取得
  static int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  // うるう年かどうかを判定
  static bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }
}
