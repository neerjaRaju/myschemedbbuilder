import 'dart:async';

class RateLimiter {
  final int maxRequests;
  final Duration interval;
  final List<Completer<void>> _queue = [];
  int _tokens;
  Timer? _refillTimer;

  RateLimiter({required this.maxRequests, required this.interval})
    : _tokens = maxRequests {
    _startRefillTimer();
  }

  void _startRefillTimer() {
    _refillTimer = Timer.periodic(interval, (timer) {
      _tokens = maxRequests;
      while (_queue.isNotEmpty && _tokens > 0) {
        _tokens--;
        final completer = _queue.removeAt(0);
        completer.complete();
      }
    });
  }

  /// Waits for a rate-limiting token to become available before resolving.
  Future<void> waitForToken() async {
    if (_tokens > 0) {
      _tokens--;
      return;
    }
    final completer = Completer<void>();
    _queue.add(completer);
    return completer.future;
  }

  /// Cleans up active timers when the crawler shuts down.
  void dispose() {
    _refillTimer?.cancel();
    for (var completer in _queue) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Rate limiter was disposed.'));
      }
    }
    _queue.clear();
  }
}
