import 'dart:io';

class SimpleLogger {
  void info(String message) {
    stdout.writeln('[INFO] $message');
  }

  void warn(String message) {
    stdout.writeln('[WARN] $message');
  }

  void error(String message) {
    stderr.writeln('[ERROR] $message');
  }

  void debug(String message) {
    stdout.writeln('[DEBUG] $message');
  }
}
