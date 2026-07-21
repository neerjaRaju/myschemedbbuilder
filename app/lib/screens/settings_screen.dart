import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ads/ads_service.dart';
import '../ads/consent_manager.dart';
import '../app_state.dart';
import '../l10n/strings.dart';

/// Language selection, database refresh, ad privacy and legal links.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _privacyOptionsRequired = false;

  @override
  void initState() {
    super.initState();
    ConsentManager.isPrivacyOptionsRequired().then((required) {
      if (mounted) setState(() => _privacyOptionsRequired = required);
    }).catchError((_) => false);
  }

  /// Replace with your hosted privacy policy URL (required by Play + AdMob).
  static const String _privacyPolicyUrl =
      'https://neerjaRaju.github.io/myschemedbbuilder/privacy.html';

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
          const Divider(),
          if (_privacyOptionsRequired)
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(s.get('adPrivacy')),
              subtitle: Text(s.get('adPrivacySubtitle')),
              onTap: () async {
                await ConsentManager.showPrivacyOptionsForm();
                await AdsService.instance.refreshConsent();
              },
            ),
          ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: Text(s.get('privacyPolicy')),
            onTap: () => launchUrl(
              Uri.parse(_privacyPolicyUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
    );
  }
}
