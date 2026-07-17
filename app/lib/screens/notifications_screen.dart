import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../l10n/strings.dart';
import 'scheme_detail_screen.dart';

/// In-app notification inbox: new schemes, database updates and deadline
/// reminders.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = S.of(context);
    final notifications = state.store.notifications;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.get('notifications')),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: state.clearNotifications,
              child: Text(s.get('clearAll')),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(child: Text(s.get('noResults')))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                return ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(n.title),
                  subtitle: Text(n.body),
                  trailing: Text(
                    n.at.toIso8601String().substring(0, 10),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: n.schemeId.isEmpty
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  SchemeDetailScreen(schemeId: n.schemeId),
                            ),
                          ),
                );
              },
            ),
    );
  }
}
