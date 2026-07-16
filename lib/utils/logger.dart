import 'dart:io';

/// Log severity levels, ordered from most to least verbose.
enum LogLevel { debug, info, warn, error }

/// Minimal structured logger writing to stdout/stderr.
///
/// All pipeline components share this logger so output stays uniform and
/// grep-able in CI logs: `[LEVEL] [name] message`.
class SimpleLogger {
  /// Component name included in every line.
  final String name;

  /// Messages below this level are suppressed.
  final LogLevel minLevel;

  const SimpleLogger({this.name = 'app', this.minLevel = LogLevel.info});

  void debug(String message) => _log(LogLevel.debug, message);

  void info(String message) => _log(LogLevel.info, message);

  void warn(String message) => _log(LogLevel.warn, message);

  void error(String message) => _log(LogLevel.error, message);

  void _log(LogLevel level, String message) {
    if (level.index < minLevel.index) return;
    final line = '[${level.name.toUpperCase()}] [$name] $message';
    if (level == LogLevel.error) {
      stderr.writeln(line);
    } else {
      stdout.writeln(line);
    }
  }
}
