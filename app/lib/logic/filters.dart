/// Smart filters applied on top of category/search results.
///
/// The database stores eligibility as free text, so most filters are
/// keyword predicates over the scheme's combined text. Level and state
/// filters use the structured `state` column.
library;

import '../models/scheme.dart';

enum SchemeLevel { any, central, state }

/// User-selectable smart filters.
class SmartFilters {
  SchemeLevel level;

  /// Exact state name (e.g. "Rajasthan"); empty means any state.
  String state;

  /// Applicant age; null means unspecified.
  int? age;

  /// 'female', 'male' or '' (any).
  String gender;

  /// Annual family income in rupees; null means unspecified.
  int? income;

  /// One of [kOccupations] or ''.
  String occupation;

  /// 'sc', 'st', 'obc' or '' (any/general).
  String casteCategory;

  SmartFilters({
    this.level = SchemeLevel.any,
    this.state = '',
    this.age,
    this.gender = '',
    this.income,
    this.occupation = '',
    this.casteCategory = '',
  });

  static const List<String> kOccupations = [
    'farmer',
    'student',
    'business owner',
  ];

  bool get isEmpty =>
      level == SchemeLevel.any &&
      state.isEmpty &&
      age == null &&
      gender.isEmpty &&
      income == null &&
      occupation.isEmpty &&
      casteCategory.isEmpty;

  /// Whether [scheme] passes every active filter.
  bool matches(Scheme scheme) {
    if (level == SchemeLevel.central && !scheme.isCentral) return false;
    if (level == SchemeLevel.state && scheme.isCentral) return false;
    if (state.isNotEmpty &&
        !scheme.isCentral &&
        scheme.state.toLowerCase() != state.toLowerCase()) {
      return false;
    }

    final blob = scheme.searchBlob;

    if (gender == 'female' && _mentionsMenOnly(blob)) return false;
    if (gender == 'male' && _mentionsWomenOnly(scheme)) return false;

    final userAge = age;
    if (userAge != null && !AgeRule.parse(scheme.eligibility).allows(userAge)) {
      return false;
    }

    final userIncome = income;
    if (userIncome != null) {
      final cap = IncomeRule.parseCap(scheme.eligibility);
      if (cap != null && userIncome > cap) return false;
    }

    if (occupation.isNotEmpty && !_occupationAllowed(blob)) return false;

    if (casteCategory.isNotEmpty && _casteMismatch(blob)) return false;

    return true;
  }

  bool _occupationAllowed(String blob) {
    // Only exclude when the scheme clearly targets a different occupation.
    const markers = {
      'farmer': ['farmer', 'kisan', 'agricultur'],
      'student': ['student', 'scholarship', 'education'],
      'business owner': ['business', 'entrepreneur', 'enterprise', 'msme'],
    };
    final targeted = markers.entries
        .where((e) => e.value.any(blob.contains))
        .map((e) => e.key)
        .toSet();
    if (targeted.isEmpty) return true; // General scheme.
    return targeted.contains(occupation);
  }

  bool _casteMismatch(String blob) {
    // If the scheme is restricted to specific groups the user is not in.
    final restricted = RegExp(
      r'\b(only|exclusively) for (scheduled castes?|scheduled tribes?|sc|st|obc)\b',
    ).hasMatch(blob);
    if (!restricted) return false;
    return !blob.contains(casteCategory);
  }

  static bool _mentionsMenOnly(String blob) =>
      RegExp(r'\bonly (for )?male\b').hasMatch(blob);

  static bool _mentionsWomenOnly(Scheme scheme) {
    final blob = scheme.searchBlob;
    return RegExp(r'\b(only (for )?(women|female|girls?))\b').hasMatch(blob) ||
        RegExp(r'\bwomen\b').hasMatch(scheme.title.toLowerCase()) &&
            RegExp(r'\b(women|female|girl)\b').hasMatch(blob);
  }
}

/// Age constraint parsed out of free-text eligibility.
class AgeRule {
  final int? min;
  final int? max;

  const AgeRule({this.min, this.max});

  bool allows(int age) {
    if (min != null && age < min!) return false;
    if (max != null && age > max!) return false;
    return true;
  }

  static final RegExp _between = RegExp(
    r'between (\d{1,3}) (?:and|to|-) ?(\d{1,3}) years',
    caseSensitive: false,
  );
  static final RegExp _range =
      RegExp(r'(\d{1,3})\s*(?:to|-)\s*(\d{1,3}) years', caseSensitive: false);
  static final RegExp _above = RegExp(
    r'(?:above|at least|minimum(?: age(?: of)?)?|not less than) (\d{1,3}) years',
    caseSensitive: false,
  );
  static final RegExp _below = RegExp(
    r'(?:below|under|up to|not (?:more|older) than|maximum(?: age(?: of)?)?) (\d{1,3}) years',
    caseSensitive: false,
  );

  /// Extracts an age window from eligibility text; unconstrained when no
  /// recognizable age wording is present.
  static AgeRule parse(String text) {
    final between = _between.firstMatch(text) ?? _range.firstMatch(text);
    if (between != null) {
      return AgeRule(
        min: int.parse(between.group(1)!),
        max: int.parse(between.group(2)!),
      );
    }
    int? min;
    int? max;
    final above = _above.firstMatch(text);
    if (above != null) min = int.parse(above.group(1)!);
    final below = _below.firstMatch(text);
    if (below != null) max = int.parse(below.group(1)!);
    return AgeRule(min: min, max: max);
  }
}

/// Annual-income ceiling parsed out of free-text eligibility.
class IncomeRule {
  static final RegExp _cap = RegExp(
    r'income[^.]{0,60}?(?:not exceed(?:ing)?|less than|below|up to|upto)'
    r'[^.]{0,20}?(?:rs\.?|₹|inr)\s*([\d,.]+)\s*(lakh|lac|crore)?',
    caseSensitive: false,
  );

  /// Returns the annual income cap in rupees, or `null` when the text does
  /// not state one.
  static int? parseCap(String text) {
    final match = _cap.firstMatch(text);
    if (match == null) return null;
    final raw = match.group(1)!.replaceAll(',', '');
    final value = double.tryParse(raw);
    if (value == null) return null;
    final unit = match.group(2)?.toLowerCase();
    if (unit == 'lakh' || unit == 'lac') return (value * 100000).round();
    if (unit == 'crore') return (value * 10000000).round();
    return value.round();
  }
}
