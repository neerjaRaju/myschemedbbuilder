import 'package:flutter/foundation.dart';

import 'data/database_service.dart';
import 'data/scheme_repository.dart';
import 'data/user_store.dart';
import 'models/scheme.dart';

enum AppStatus { loading, downloading, ready, error }

/// Root application state: database lifecycle, locale, bookmarks,
/// notifications and the compare basket.
class AppState extends ChangeNotifier {
  final DatabaseService _dbService;
  final UserStore store;
  late final SchemeRepository repository;

  AppStatus status = AppStatus.loading;
  double downloadProgress = 0;
  String errorMessage = '';
  final List<String> compareBasket = [];

  AppState({DatabaseService? dbService, required this.store})
      : _dbService = dbService ?? DatabaseService() {
    repository = SchemeRepository(_dbService);
  }

  String get languageCode => store.languageCode;

  Future<void> initialize() async {
    try {
      status = AppStatus.downloading;
      notifyListeners();
      await _dbService.ensureReady(onProgress: _onProgress);
      status = AppStatus.ready;
      notifyListeners();
      await _detectNewSchemes(firstRun: store.knownSchemeIds.isEmpty);
    } on Object catch (e) {
      status = AppStatus.error;
      errorMessage = '$e';
      notifyListeners();
    }
  }

  void _onProgress(double progress) {
    downloadProgress = progress;
    notifyListeners();
  }

  /// Pulls the latest weekly database from GitHub if it changed.
  Future<bool> refreshDatabase() async {
    try {
      final updated = await _dbService.refresh(onProgress: _onProgress);
      if (updated) {
        await _detectNewSchemes();
        await store.addNotification(
          AppNotification(
            title: 'Database updated',
            body: 'Latest schemes data installed '
                '(${repository.count()} schemes).',
            at: DateTime.now(),
          ),
        );
      }
      notifyListeners();
      return updated;
    } on Object catch (e) {
      errorMessage = '$e';
      notifyListeners();
      return false;
    }
  }

  /// Compares the fresh database against the previous snapshot of ids and
  /// records an in-app notification for newly added schemes.
  Future<void> _detectNewSchemes({bool firstRun = false}) async {
    final currentIds = repository.allIds();
    if (!firstRun) {
      final known = store.knownSchemeIds;
      final added = currentIds.where((id) => !known.contains(id)).toList();
      if (added.isNotEmpty) {
        await store.addNotification(
          AppNotification(
            title: 'New schemes available',
            body: '${added.length} new schemes were added.',
            at: DateTime.now(),
          ),
        );
      }
    }
    await store.saveKnownSchemeIds(currentIds);
  }

  /// Reminders whose deadline is within [window] produce notifications.
  Future<void> surfaceDueReminders({
    Duration window = const Duration(days: 3),
  }) async {
    final now = DateTime.now();
    for (final reminder in store.reminders) {
      final remaining = reminder.deadline.difference(now);
      if (remaining <= window) {
        await store.addNotification(
          AppNotification(
            title: 'Deadline approaching',
            body: '"${reminder.schemeTitle}" application deadline is '
                '${reminder.deadline.toIso8601String().substring(0, 10)}.',
            schemeId: reminder.schemeId,
            at: now,
          ),
        );
        await store.removeReminder(reminder.schemeId);
      }
    }
    notifyListeners();
  }

  /// Empties the in-app notification inbox.
  Future<void> clearNotifications() async {
    await store.clearNotifications();
    notifyListeners();
  }

  // Locale --------------------------------------------------------------

  Future<void> setLanguage(String code) async {
    await store.setLanguageCode(code);
    notifyListeners();
  }

  // Bookmarks ------------------------------------------------------------

  bool isBookmarked(String id) => store.isBookmarked(id);

  Future<void> toggleBookmark(String id) async {
    await store.toggleBookmark(id);
    notifyListeners();
  }

  List<Scheme> bookmarkedSchemes() =>
      repository.byIds(store.bookmarks.toList());

  // Compare --------------------------------------------------------------

  static const int maxCompare = 3;

  bool inCompare(String id) => compareBasket.contains(id);

  void toggleCompare(String id) {
    if (!compareBasket.remove(id) && compareBasket.length < maxCompare) {
      compareBasket.add(id);
    }
    notifyListeners();
  }

  List<Scheme> compareSchemes() => repository.byIds(compareBasket);

  @override
  void dispose() {
    _dbService.dispose();
    super.dispose();
  }
}
