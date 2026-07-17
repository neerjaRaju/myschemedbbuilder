import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    const seedColor = Color(0xFF6C4DF0);
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
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        scaffoldBackgroundColor: const Color(0xFFF5F3FC),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      builder: (context, child) {
        final isDark =
            MediaQuery.platformBrightnessOf(context) == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            // Honored on Android 14 and below only.
            systemNavigationBarColor:
                isDark ? Colors.transparent : Colors.white,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomeScreen(),
    );
  }
}
