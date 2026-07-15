import 'dart:convert';
import 'dart:io';

class CrawlerQueue {
  final File _file;
  final Set<String> _pending = {};
  final Set<String> _completed = {};

  CrawlerQueue({required String storagePath}) : _file = File(storagePath) {
    _loadState();
  }

  /// Loads previous pending and completed states from disk if they exist.
  void _loadState() {
    if (!_file.existsSync()) return;

    try {
      final content = _file.readAsStringSync();
      if (content.trim().isEmpty) return;

      final Map<String, dynamic> data = json.decode(content);
      if (data['pending'] is List) {
        _pending.addAll(List<String>.from(data['pending']));
      }
      if (data['completed'] is List) {
        _completed.addAll(List<String>.from(data['completed']));
      }
    } catch (_) {
      // Fallback gracefully on parsing corruption
    }
  }

  /// Saves current state transactionally back to disk.
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

  void add(String url) {
    if (!_completed.contains(url) && !_pending.contains(url)) {
      _pending.add(url);
      _saveState();
    }
  }

  String? next() {
    if (_pending.isEmpty) return null;
    final url = _pending.first;
    _pending.remove(url);
    _saveState();
    return url;
  }

  void complete(String url) {
    _pending.remove(url);
    _completed.add(url);
    _saveState();
  }

  void fail(String url) {
    // If a URL fails, we remove it from pending and do not add to completed,
    // allowing it to be queued again on subsequent crawler runs.
    _pending.remove(url);
    _saveState();
  }

  bool get isEmpty => _pending.isEmpty;

  int get pendingCount => _pending.length;

  int get completedCount => _completed.length;

  void clear() {
    _pending.clear();
    _completed.clear();
    if (_file.existsSync()) {
      _file.deleteSync();
    }
  }
}
