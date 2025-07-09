import 'package:intl/intl.dart';

class TimezoneUtils {
  // Indian Standard Time offset (UTC+5:30)
  static const Duration _istOffset = Duration(hours: 5, minutes: 30);
  
  /// Get current Indian Standard Time
  static DateTime get nowIST {
    final utcNow = DateTime.now().toUtc();
    return utcNow.add(_istOffset);
  }
  
  /// Convert any DateTime to IST
  static DateTime toIST(DateTime dateTime) {
    if (dateTime.isUtc) {
      return dateTime.add(_istOffset);
    } else {
      // Assume local time, convert to UTC first then to IST
      return dateTime.toUtc().add(_istOffset);
    }
  }
  
  /// Get today's date in IST (date only, no time)
  static DateTime get todayIST {
    final ist = nowIST;
    return DateTime(ist.year, ist.month, ist.day);
  }
  
  /// Format DateTime to IST string
  static String formatIST(DateTime dateTime, {String pattern = 'yyyy-MM-dd HH:mm:ss'}) {
    final istTime = toIST(dateTime);
    final formatter = DateFormat(pattern);
    return '${formatter.format(istTime)} IST';
  }
  
  /// Format DateTime to IST date string
  static String formatISTDate(DateTime dateTime, {String pattern = 'yyyy-MM-dd'}) {
    final istTime = toIST(dateTime);
    final formatter = DateFormat(pattern);
    return formatter.format(istTime);
  }
  
  /// Format DateTime to IST time string
  static String formatISTTime(DateTime dateTime, {String pattern = 'HH:mm:ss'}) {
    final istTime = toIST(dateTime);
    final formatter = DateFormat(pattern);
    return formatter.format(istTime);
  }
  
  /// Check if a date is today in IST
  static bool isToday(DateTime dateTime) {
    final today = todayIST;
    final istDate = toIST(dateTime);
    return istDate.year == today.year && 
           istDate.month == today.month && 
           istDate.day == today.day;
  }
  
  /// Get date string in API format (YYYY-MM-DD) for IST
  static String getAPIDateString(DateTime dateTime) {
    final istTime = toIST(dateTime);
    return '${istTime.year}-${istTime.month.toString().padLeft(2, '0')}-${istTime.day.toString().padLeft(2, '0')}';
  }
  
  /// Parse date string and convert to IST
  static DateTime parseToIST(String dateString) {
    try {
      final parsed = DateTime.parse(dateString);
      return toIST(parsed);
    } catch (e) {
      print('❌ TIMEZONE: Error parsing date string: $dateString - $e');
      return nowIST;
    }
  }
}