import 'package:flutter/material.dart';

import '../l10n/strings.dart';

/// Shown when the app cannot proceed because there is no network **and** no
/// locally cached database yet (i.e. the very first launch is offline).
///
/// Once the database has been downloaded the app runs fully offline and this
/// screen is never shown again.
class NoConnectionScreen extends StatelessWidget {
  final Future<void> Function() onRetry;
  final bool retrying;

  const NoConnectionScreen({
    super.key,
    required this.onRetry,
    this.retrying = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor:
                      theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 52,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  s.get('noInternet'),
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  s.get('noInternetMessage'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: retrying ? null : onRetry,
                  icon: retrying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(s.get('retry')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
