import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'app_state.dart';
import 'data/user_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await UserStore.load();
  final state = AppState(store: store);
  // Fire and forget: the UI shows download progress while this runs.
  state.initialize();
  runApp(
    ChangeNotifierProvider.value(value: state, child: const SchemeApp()),
  );
}
