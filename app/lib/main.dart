import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'app_state.dart';
import 'data/user_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw behind the system bars; AnnotatedRegion in SchemeApp styles them.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final store = await UserStore.load();
  final state = AppState(store: store);
  // Fire and forget: the UI shows download progress while this runs.
  state.initialize();
  runApp(
    ChangeNotifierProvider.value(value: state, child: const SchemeApp()),
  );
}
