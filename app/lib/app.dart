import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'l10n/strings.dart';
import 'screens/home_screen.dart';

class SchemeApp extends StatelessWidget {
  const SchemeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      title: 'My Schemes',
      debugShowCheckedModeBanner: false,
      locale: Locale(state.languageCode),
      supportedLocales: [
        for (final (code, _) in kSupportedLanguages) Locale(code),
      ],
      localizationsDelegates: const [
        SDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A5CA8)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
