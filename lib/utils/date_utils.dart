import 'package:intl/intl.dart';

class DateUtils {
  static String formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }
  
  static String formatDateTime(DateTime date) {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }
  
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
  
  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }
  
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
  
  static String getDayName(DateTime date) {
    final now = DateTime.now();
    if (isSameDay(date, now)) {
      return 'Сегодня';
    }
    if (isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Вчера';
    }
    if (isSameDay(date, now.add(const Duration(days: 1)))) {
      return 'Завтра';
    }
    return DateFormat('dd.MM').format(date);
  }
}