import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A locally stored in-app notification.
class AppNotification {
  final String title;
  final String body;
  final String schemeId;
  final DateTime at;

  const AppNotification({
    required this.title,
    required this.body,
    this.schemeId = '',
    required this.at,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'scheme_id': schemeId,
        'at': at.toIso8601String(),
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        schemeId: json['scheme_id'] as String? ?? '',
        at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
      );
}

/// A user-set application deadline reminder for a scheme.
class DeadlineReminder {
  final String schemeId;
  final String schemeTitle;
  final DateTime deadline;

  const DeadlineReminder({
    required this.schemeId,
    required this.schemeTitle,
    required this.deadline,
  });

  Map<String, dynamic> toJson() => {
        'scheme_id': schemeId,
        'scheme_title': schemeTitle,
        'deadline': deadline.toIso8601String(),
      };

  factory DeadlineReminder.fromJson(Map<String, dynamic> json) =>
      DeadlineReminder(
        schemeId: json['scheme_id'] as String? ?? '',
        schemeTitle: json['scheme_title'] as String? ?? '',
        deadline: DateTime.tryParse(json['deadline'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// All user-local persistence: bookmarks, language, eligibility profile,
/// notifications, reminders and the known-scheme snapshot used to detect
/// new schemes after a database refresh.
///
/// Kept separate from `schemes.db`, which is replaced wholesale on update.
class UserStore {
  static const _kBookmarks = 'bookmarks';
  static const _kLanguage = 'language';
  static const _kKnownIds = 'known_scheme_ids';
  static const _kNotifications = 'notifications';
  static const _kReminders = 'reminders';
  static const _kProfile = 'eligibility_profile';

  final SharedPreferences _prefs;

  UserStore(this._prefs);

  static Future<UserStore> load() async =>
      UserStore(await SharedPreferences.getInstance());

  // Bookmarks -------------------------------------------------------------

  Set<String> get bookmarks =>
      (_prefs.getStringList(_kBookmarks) ?? const []).toSet();

  Future<void> toggleBookmark(String schemeId) async {
    final current = bookmarks;
    if (!current.remove(schemeId)) current.add(schemeId);
    await _prefs.setStringList(_kBookmarks, current.toList());
  }

  bool isBookmarked(String schemeId) => bookmarks.contains(schemeId);

  // Language ---------------------------------------------------------------

  String get languageCode => _prefs.getString(_kLanguage) ?? 'en';

  Future<void> setLanguageCode(String code) =>
      _prefs.setString(_kLanguage, code);

  // New-scheme detection ----------------------------------------------------

  Set<String> get knownSchemeIds =>
      (_prefs.getStringList(_kKnownIds) ?? const []).toSet();

  Future<void> saveKnownSchemeIds(Iterable<String> ids) =>
      _prefs.setStringList(_kKnownIds, ids.toList());

  // Notifications ------------------------------------------------------------

  List<AppNotification> get notifications => [
        for (final raw in _prefs.getStringList(_kNotifications) ?? const [])
          AppNotification.fromJson(
            json.decode(raw) as Map<String, dynamic>,
          ),
      ];

  Future<void> addNotification(AppNotification notification) async {
    final list = _prefs.getStringList(_kNotifications) ?? [];
    list.insert(0, json.encode(notification.toJson()));
    // Keep the inbox bounded.
    await _prefs.setStringList(_kNotifications, list.take(100).toList());
  }

  Future<void> clearNotifications() => _prefs.remove(_kNotifications);

  // Deadline reminders --------------------------------------------------------

  List<DeadlineReminder> get reminders => [
        for (final raw in _prefs.getStringList(_kReminders) ?? const [])
          DeadlineReminder.fromJson(json.decode(raw) as Map<String, dynamic>),
      ];

  Future<void> addReminder(DeadlineReminder reminder) async {
    final list = _prefs.getStringList(_kReminders) ?? [];
    list.add(json.encode(reminder.toJson()));
    await _prefs.setStringList(_kReminders, list);
  }

  Future<void> removeReminder(String schemeId) async {
    final kept = reminders
        .where((r) => r.schemeId != schemeId)
        .map((r) => json.encode(r.toJson()))
        .toList();
    await _prefs.setStringList(_kReminders, kept);
  }

  // Eligibility profile --------------------------------------------------------

  Map<String, String> get eligibilityProfile {
    final raw = _prefs.getString(_kProfile);
    if (raw == null) return {};
    return Map<String, String>.from(json.decode(raw) as Map);
  }

  Future<void> saveEligibilityProfile(Map<String, String> profile) =>
      _prefs.setString(_kProfile, json.encode(profile));
}
