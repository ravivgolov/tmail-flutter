
import 'dart:ui';

extension DateTimeExtension on DateTime {

  bool isToday() {
    final now = DateTime.now();
    return now.day == day && now.month == month && now.year == year;
  }

  bool isYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return yesterday.day == day && yesterday.month == month && yesterday.year == year;
  }

  bool isThisYear() {
    final now = DateTime.now();
    return now.year == year;
  }

  int daysBetween(DateTime from) {
    from = DateTime(from.year, from.month, from.day, from.hour);
    final to = DateTime(year, month, day, hour);
    return (to.difference(from).inHours / Duration.hoursPerDay).round().abs();
  }


  int minutesBetween(DateTime from) {
    from = DateTime(from.year, from.month, from.day, from.hour, from.minute);
    final to = DateTime(year, month, day, hour, minute);
    return to.difference(from).inMinutes.abs();
  }
}

extension DateTimeNullableExtension on DateTime? {

  String toPattern() {
    if (this != null) {
      if (this!.isToday()) {
        return 'H:mm';
      } else if (this!.isYesterday()) {
        return 'EEE';
      } else if (this!.isThisYear()) {
        return 'MMMd';
      } else {
        return 'yMMMd';
      }
    }
    return 'yMMMd';
  }

  String toPatternForEmailView() {
    if (this?.isThisYear() == true) {
      return 'dd MMM, HH:mm a';
    } else {
      return 'dd MMM yyyy, HH:mm a';
    }
  }

  String toPatternForPrinting(String locale) {
    if (locale == const Locale('en', 'US').toLanguageTag()) {
      return 'MMM dd y, HH:mm';
    } else {
      return 'dd MMM y, HH:mm';
    }
  }
}
