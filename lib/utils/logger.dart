class Logger {
  static const _reset = '\x1B[0m';
  static const _red = '\x1B[31m';
  static const _green = '\x1B[32m';
  static const _yellow = '\x1B[33m';
  static const _blue = '\x1B[34m';
  static const _cyan = '\x1B[36m';

  static void info(String message) {
    print('$_blue[INFO]$_reset $message');
  }

  static void success(String message) {
    print('$_green[SUCCESS]$_reset $message');
  }

  static void warning(String message) {
    print('$_yellow[WARNING]$_reset $message');
  }

  static void error(String message) {
    print('$_red[ERROR]$_reset $message');
  }

  static void section(String title) {
    print('');
    print('$_cyan========================================$_reset');
    print('$_cyan$title$_reset');
    print('$_cyan========================================$_reset');
  }
}