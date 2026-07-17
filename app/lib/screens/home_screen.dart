import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../l10n/strings.dart';
import '../logic/categories.dart';
import '../widgets/scheme_rail.dart';
import 'bookmarks_screen.dart';
import 'compare_screen.dart';
import 'eligibility_screen.dart';
import 'notifications_screen.dart';
import 'scheme_list_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = S.of(context);

    switch (state.status) {
      case AppStatus.loading:
      case AppStatus.downloading:
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  value: state.downloadProgress > 0
                      ? state.downloadProgress
                      : null,
                ),
                const SizedBox(height: 16),
                Text(s.get('downloading')),
              ],
            ),
          ),
        );
      case AppStatus.error:
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 48),
                  const SizedBox(height: 12),
                  Text(state.errorMessage, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: state.initialize,
                    child: Text(s.get('refresh')),
                  ),
                ],
              ),
            ),
          ),
        );
      case AppStatus.ready:
        return _ReadyHome(s: s);
    }
  }
}

class _ReadyHome extends StatelessWidget {
  final S s;

  const _ReadyHome({required this.s});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final repo = state.repository;
    final notificationCount = state.store.notifications.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.get('appTitle')),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: notificationCount > 0,
              label: Text('$notificationCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final updated = await state.refreshDatabase();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(updated ? s.get('updated') : s.get('upToDate')),
              ),
            );
          }
        },
        child: ListView(
          children: [
            _EligibilityBanner(s: s),
            SchemeRail(title: s.get('featured'), schemes: repo.featured()),
            SchemeRail(
              title: s.get('trending'),
              schemes: repo.trending(),
            ),
            SchemeRail(
              title: s.get('recentlyUpdated'),
              schemes: repo.recentlyUpdated(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                s.get('categories'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              childAspectRatio: 1.1,
              children: [
                for (final category in kCategories)
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            SchemeListScreen(categoryKey: category.key),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          child: Icon(category.icon),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.get(category.key),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 1:
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EligibilityScreen()),
              );
            case 2:
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BookmarksScreen()),
              );
            case 3:
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CompareScreen()),
              );
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            label: s.get('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.checklist),
            label: s.get('eligibility'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.bookmark_outline),
            label: s.get('bookmarks'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.compare_arrows),
            label: s.get('compare'),
          ),
        ],
      ),
    );
  }
}

class _EligibilityBanner extends StatelessWidget {
  final S s;

  const _EligibilityBanner({required this.s});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ListTile(
        leading: const Icon(Icons.checklist),
        title: Text(s.get('eligibility')),
        subtitle: Text(s.get('checkEligibility')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EligibilityScreen()),
        ),
      ),
    );
  }
}
