import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../l10n/strings.dart';

/// Language selection and database refresh.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.get('settings'))),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              s.get('language'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          RadioGroup<String>(
            groupValue: state.languageCode,
            onChanged: (v) {
              if (v != null) state.setLanguage(v);
            },
            child: Column(
              children: [
                for (final (code, name) in kSupportedLanguages)
                  RadioListTile<String>(title: Text(name), value: code),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.sync),
            title: Text(s.get('refresh')),
            onTap: () async {
              final updated = await state.refreshDatabase();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(updated ? s.get('updated') : s.get('upToDate')),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
