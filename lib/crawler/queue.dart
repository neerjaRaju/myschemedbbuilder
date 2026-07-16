import 'dart:convert';
import 'dart:io';

/// Persistent URL queue enabling resumable, incremental crawls.
///
/// Pending and completed URL sets are stored as JSON on disk after every
/// mutation, so an interrupted crawl picks up exactly where it stopped and
/// URLs completed in earlier runs are never re-queued.
class CrawlerQueue {
  final File _file;
  final Set<String> _pending = {};
  final Set<String> _completed = {};

  CrawlerQueue({required String storagePath}) : _file = File(storagePath) {
    _loadState();
  }

  void _loadState() {
    if (!_file.existsSync()) return;

    try {
      final content = _file.readAsStringSync();
      if (content.trim().isEmpty) return;

      final data = json.decode(content) as Map<String, dynamic>;
      if (data['pending'] is List) {
        _pending.addAll(List<String>.from(data['pending'] as List));
      }
      if (data['completed'] is List) {
        _completed.addAll(List<String>.from(data['completed'] as List));
      }
    } catch (_) {
      // Recover gracefully from state-file corruption by starting fresh.
    }
  }

  void _saveState() {
    if (!_file.parent.existsSync()) {
      _file.parent.createSync(recursive: true);
    }
    final data = {
      'pending': _pending.toList(),
      'completed': _completed.toList(),
    };
    _file.writeAsStringSync(json.encode(data), flush: true);
  }

  /// Adds [url] unless it is already pending or was completed before.
  void add(String url) {
    if (_enqueue(url)) _saveState();
  }

  /// Adds every URL in [urls], persisting state once.
  void addAll(Iterable<String> urls) {
    var changed = false;
    for (final url in urls) {
      changed = _enqueue(url) || changed;
    }
    if (changed) _saveState();
  }

  bool _enqueue(String url) {
    if (_completed.contains(url) || _pending.contains(url)) return false;
    _pending.add(url);
    return true;
  }

  /// Removes and returns the next pending URL, or `null` when empty.
  String? next() {
    if (_pending.isEmpty) return null;
    final url = _pending.first;
    _pending.remove(url);
    _saveState();
    return url;
  }

  /// Marks [url] as done so it is skipped by all future runs.
  void complete(String url) {
    _pending.remove(url);
    _completed.add(url);
    _saveState();
  }

  /// Records a failure: the URL leaves the pending set without joining the
  /// completed set, so a later crawl run can retry it.
  void fail(String url) {
    _pending.remove(url);
    _saveState();
  }

  bool get isEmpty => _pending.isEmpty;

  int get pendingCount => _pending.length;

  int get completedCount => _completed.length;

  /// Clears all state and removes the backing file.
  void clear() {
    _pending.clear();
    _completed.clear();
    if (_file.existsSync()) {
      _file.deleteSync();
    }
  }
}
