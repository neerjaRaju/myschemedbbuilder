import 'dart:async';

import 'package:flutter/foundation.dart';

import 'data/connectivity_service.dart';
import 'data/database_service.dart';
import 'data/scheme_repository.dart';
import 'data/user_store.dart';
import 'models/scheme.dart';

enum AppStatus { loading, downloading, ready, error, offline }

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

  StreamSubscription<bool>? _connectivitySub;

  AppState({DatabaseService? dbService, required this.store})
      : _dbService = dbService ?? DatabaseService() {
    repository = SchemeRepository(_dbService);
  }

  String get languageCode => store.languageCode;

  Future<void> initialize() async {
    try {
      status = _dbService.isReady ? status : AppStatus.downloading;
      notifyListeners();
      await _dbService.ensureReady(onProgress: _onProgress);
      status = AppStatus.ready;
      notifyListeners();
      _connectivitySub?.cancel();
      await _detectNewSchemes(firstRun: store.knownSchemeIds.isEmpty);
    } on Object catch (e) {
      // The app is offline-first: it only *needs* the network to download the
      // database the very first time. If that fails while offline, show the
      // no-connection screen and auto-retry when the network returns.
      final online = await ConnectivityService.isOnline();
      status = online ? AppStatus.error : AppStatus.offline;
      errorMessage = '$e';
      notifyListeners();
      if (!online) _watchForReconnect();
    }
  }

  /// Auto-retries [initialize] once the device regains a network interface.
  void _watchForReconnect() {
    _connectivitySub?.cancel();
    _connectivitySub = ConnectivityService.onStatusChange().listen((online) {
      if (online && status == AppStatus.offline) {
        initialize();
      }
    });
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
    _connectivitySub?.cancel();
    _dbService.dispose();
    super.dispose();
  }
}
