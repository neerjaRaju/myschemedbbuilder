class DateUtils {
  static DateTime? parse(dynamic value) {
    if (value == null) return null;

    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  static String? format(DateTime? date) {
    return date?.toIso8601String();
  }
}