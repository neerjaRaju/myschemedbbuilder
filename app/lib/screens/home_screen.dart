import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Tab shell with system back-button handling: pressing back on any tab
/// returns to the Home tab first; on the Home tab a confirmation dialog
/// asks before closing the app.
class _ReadyHome extends StatefulWidget {
  final S s;

  const _ReadyHome({required this.s});

  @override
  State<_ReadyHome> createState() => _ReadyHomeState();
}

class _ReadyHomeState extends State<_ReadyHome> {
  int _tabIndex = 0;

  Future<void> _onBackPressed() async {
    if (_tabIndex != 0) {
      setState(() => _tabIndex = 0);
      return;
    }
    final s = widget.s;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.get('exitTitle')),
        content: Text(s.get('exitMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.get('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.get('exit')),
          ),
        ],
      ),
    );
    if (shouldExit ?? false) {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBackPressed();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _tabIndex,
          children: const [
            _HomeTab(),
            EligibilityScreen(),
            BookmarksScreen(),
            CompareScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tabIndex,
          onDestinationSelected: (index) => setState(() => _tabIndex = index),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: s.get('home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.checklist),
              label: s.get('eligibility'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.bookmark_outline),
              selectedIcon: const Icon(Icons.bookmark),
              label: s.get('bookmarks'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.compare_arrows),
              label: s.get('compare'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = S.of(context);
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
