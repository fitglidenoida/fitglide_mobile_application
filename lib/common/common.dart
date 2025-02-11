import 'package:intl/intl.dart';

/// Formats a timestamp into a readable time string.
String getTime(int value, {String formatStr = "hh:mm a", bool isUtc = true}) {
  try {
    final format = DateFormat(formatStr);
    return format.format(
      DateTime.fromMillisecondsSinceEpoch(value * 60 * 1000, isUtc: isUtc),
    );
  } catch (e) {
    return "Invalid Time"; // Fallback for invalid inputs
  }
}

/// Converts a date string from one format to another.
String getStringDateToOtherFormate(
  String dateStr, {
  String inputFormatStr = "hh:mm a", // Match your input format
  String outFormatStr = "hh:mm a",
}) {
  try {
    final date = stringToDate(dateStr, formatStr: inputFormatStr);
    final format = DateFormat(outFormatStr);
    return format.format(date);
  } catch (e) {
    return "Invalid Date"; // Fallback for invalid inputs
  }
}

/// Parses a date string into a DateTime object.
DateTime stringToDate(String dateStr, {String formatStr = "hh:mm a"}) {
  try {
    final format = DateFormat(formatStr);
    return format.parse(dateStr);
  } catch (e) {
    throw FormatException("Invalid date format: $dateStr");
  }
}

/// Trims a DateTime to its start of the day (00:00:00).
DateTime dateToStartDate(DateTime date) => DateTime(date.year, date.month, date.day);

/// Formats a DateTime object into a string.
String dateToString(DateTime date, {String formatStr = "dd/MM/yyyy hh:mm a"}) {
  try {
    final format = DateFormat(formatStr);
    return format.format(date);
  } catch (e) {
    return "Invalid Date"; // Fallback for invalid inputs
  }
}

/// Returns a readable title for a given date (Today, Tomorrow, Yesterday, or Day of the Week).
String getDayTitle(
  String dateStr, {
  String formatStr = "dd/MM/yyyy hh:mm a",
}) {
  try {
    final date = stringToDate(dateStr, formatStr: formatStr);
    if (date.isToday) return "Today";
    if (date.isTomorrow) return "Tomorrow";
    if (date.isYesterday) return "Yesterday";
    return DateFormat("E").format(date); // Returns day of the week
  } catch (e) {
    return "Invalid Date"; // Fallback for invalid inputs
  }
}

/// Extension for DateTime helpers
extension DateHelpers on DateTime {
  /// Checks if the date is today.
  bool get isToday => _differenceInDays(0);

  /// Checks if the date is yesterday.
  bool get isYesterday => _differenceInDays(-1);

  /// Checks if the date is tomorrow.
  bool get isTomorrow => _differenceInDays(1);

  /// Utility function for day comparisons.
  bool _differenceInDays(int days) {
    final now = DateTime.now();
    final difference = DateTime(year, month, day).difference(DateTime(now.year, now.month, now.day));
    return difference.inDays == days;
  }
}
