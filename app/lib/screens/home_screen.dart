import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../data/connectivity_service.dart';
import '../l10n/strings.dart';
import '../logic/categories.dart';
import '../models/scheme.dart';
import '../widgets/ad_banner.dart';
import '../widgets/scheme_rail.dart';
import 'bookmarks_screen.dart';
import 'compare_screen.dart';
import 'eligibility_screen.dart';
import 'no_connection_screen.dart';
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
      case AppStatus.offline:
        return NoConnectionScreen(onRetry: state.initialize);
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
        extendBody: true,
        body: IndexedStack(
          index: _tabIndex,
          children: const [
            _HomeTab(),
            EligibilityScreen(),
            BookmarksScreen(),
            CompareScreen(),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Material(
            elevation: 6,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            child: NavigationBar(
              height: 68,
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedIndex: _tabIndex,
              onDestinationSelected: (index) =>
                  setState(() => _tabIndex = index),
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

    return Scaffold(
      body: Column(
        children: [
          const _OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final updated = await state.refreshDatabase();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        updated ? s.get('updated') : s.get('upToDate'),
                      ),
                    ),
                  );
                }
              },
              child: ListView(
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top + 8,
                  bottom: 110,
                ),
                children: [
                  _Header(s: s),
                  _EligibilityBanner(s: s),
                  const AdBanner(),
                  SchemeRail(
                    title: s.get('featured'),
                    schemes: repo.featured(),
                    icon: Icons.workspace_premium,
                    iconColor: const Color(0xFF6C4DF0),
                    onViewAll: () => _openResults(
                      context,
                      s.get('featured'),
                      repo.featured(limit: 50),
                    ),
                  ),
                  SchemeRail(
                    title: s.get('trending'),
                    schemes: repo.trending(),
                    icon: Icons.star,
                    iconColor: const Color(0xFFF2A93B),
                    onViewAll: () => _openResults(
                      context,
                      s.get('trending'),
                      repo.trending(limit: 50),
                    ),
                  ),
                  SchemeRail(
                    title: s.get('recentlyUpdated'),
                    schemes: repo.recentlyUpdated(),
                    icon: Icons.bolt,
                    iconColor: const Color(0xFF2E86F0),
                    onViewAll: () => _openResults(
                      context,
                      s.get('recentlyUpdated'),
                      repo.recentlyUpdated(limit: 50),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      s.get('categories'),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
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
                          borderRadius: BorderRadius.circular(16),
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
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: 0.6),
                                child: Icon(
                                  category.icon,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openResults(
    BuildContext context,
    String title,
    List<Scheme> schemes,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SchemeResultsScreen(title: title, schemes: schemes),
      ),
    );
  }
}

/// Big greeting header with round action buttons, replacing the AppBar.
class _Header extends StatelessWidget {
  final S s;

  const _Header({required this.s});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final hasNotifications = state.store.notifications.isNotEmpty;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.get('appTitle'),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.get('appSubtitle'),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          _RoundAction(
            icon: Icons.search,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          _RoundAction(
            icon: Icons.notifications_none,
            showDot: hasNotifications,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          _RoundAction(
            icon: Icons.person_outline,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final bool showDot;
  final VoidCallback onTap;

  const _RoundAction({
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: const CircleBorder(),
        elevation: 1,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 22),
                if (showDot)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gradient hero card driving users into the eligibility checker.
class _EligibilityBanner extends StatelessWidget {
  final S s;

  const _EligibilityBanner({required this.s});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A2352), const Color(0xFF3A2E6E)]
              : [const Color(0xFFEFE9FD), const Color(0xFFE3D9FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EligibilityScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: theme.colorScheme.surface,
                child: Icon(
                  Icons.fact_check_outlined,
                  size: 34,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.get('eligibility'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.get('checkEligibility'),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EligibilityScreen(),
                        ),
                      ),
                      icon: Text(s.get('checkNow')),
                      label: const Icon(Icons.arrow_forward, size: 16),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.account_balance,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin banner shown at the top of Home while the device is offline. The app
/// still works from the cached database, so this is informational only.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    return StreamBuilder<bool>(
      stream: ConnectivityService.onStatusChange(),
      builder: (context, snapshot) {
        final online = snapshot.data ?? true;
        if (online) return const SizedBox.shrink();
        return Material(
          color: theme.colorScheme.errorContainer,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 16,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.get('offlineBanner'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
