import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../data/user_store.dart';
import '../l10n/strings.dart';
import '../models/scheme.dart';
import '../widgets/scheme_card.dart';

class SchemeDetailScreen extends StatelessWidget {
  final String schemeId;

  const SchemeDetailScreen({super.key, required this.schemeId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = S.of(context);
    final theme = Theme.of(context);
    final scheme = state.repository.byId(schemeId);
    if (scheme == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(s.get('noResults'))),
      );
    }
    final related = state.repository.related(scheme);
    final bookmarked = state.isBookmarked(scheme.id);

    return Scaffold(
      body: SafeArea(
          child: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(scheme.title),
            actions: [
              IconButton(
                icon:
                    Icon(bookmarked ? Icons.bookmark : Icons.bookmark_outline),
                onPressed: () => state.toggleBookmark(scheme.id),
              ),
              IconButton(
                icon: const Icon(Icons.alarm_add),
                tooltip: s.get('addReminder'),
                onPressed: () => _pickReminder(context, state, scheme, s),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text(scheme.isCentral ? 'Central' : scheme.state),
                      onSelected: (_) {},
                      selected: true,
                    ),
                    if (scheme.category.isNotEmpty)
                      FilterChip(
                        label: Text(scheme.category),
                        onSelected: (_) {},
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (scheme.ministry.isNotEmpty)
                  _Section(
                    title: s.get('ministry'),
                    body: scheme.ministry,
                    icon: Icons.account_balance,
                  ),
                if (scheme.description.isNotEmpty)
                  _Section(
                    title: s.get('objective'),
                    body: scheme.description,
                    icon: Icons.info_outline,
                  ),
                if (scheme.benefits.isNotEmpty)
                  _Section(
                    title: s.get('benefits'),
                    body: scheme.benefits,
                    icon: Icons.card_giftcard,
                  ),
                if (scheme.eligibility.isNotEmpty)
                  _Section(
                    title: s.get('eligibilityCriteria'),
                    body: scheme.eligibility,
                    icon: Icons.check_circle_outline,
                  ),
                if (scheme.documents.isNotEmpty)
                  _Section(
                    title: s.get('documents'),
                    body: scheme.documents.map((d) => '• $d').join('\n'),
                    icon: Icons.description_outlined,
                  ),
                if (scheme.applicationProcess.isNotEmpty)
                  _Section(
                    title: s.get('howToApply'),
                    body: scheme.applicationProcess,
                    icon: Icons.app_registration,
                  ),
                if (scheme.officialUrl.isNotEmpty)
                  _Section(
                    title: s.get('officialWebsite'),
                    body: scheme.officialUrl,
                    icon: Icons.language,
                  ),
                if (scheme.helpline.isNotEmpty)
                  _Section(
                    title: s.get('helpline'),
                    body: scheme.helpline,
                    icon: Icons.phone_in_talk,
                  ),
                if (scheme.lastUpdated.isNotEmpty)
                  _Section(
                    title: s.get('lastUpdated'),
                    body: scheme.lastUpdated,
                    icon: Icons.update,
                  ),
                if (scheme.faq.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.question_answer_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          s.get('faqs'),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final entry in scheme.faq.entries)
                          ExpansionTile(
                            title: Text(entry.key,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500)),
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: MarkdownBody(
                                  data: entry.value,
                                  selectable: true,
                                  styleSheet:
                                      MarkdownStyleSheet.fromTheme(theme)
                                          .copyWith(
                                    p: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.6,
                                      fontSize: 16,
                                    ),
                                    h1: theme.textTheme.headlineMedium,
                                    h2: theme.textTheme.headlineSmall,
                                    h3: theme.textTheme.titleLarge,
                                    strong: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    a: const TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
                if (related.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.library_books_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          s.get('relatedSchemes'),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  for (final other in related) SchemeCard(scheme: other),
                ],
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      )),
    );
  }

  Future<void> _pickReminder(
    BuildContext context,
    AppState state,
    Scheme scheme,
    S s,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked == null) return;
    await state.store.addReminder(
      DeadlineReminder(
        schemeId: scheme.id,
        schemeTitle: scheme.title,
        deadline: picked,
      ),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.get('reminderSet'))));
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;

  const _Section({
    required this.title,
    required this.body,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            MarkdownBody(
              data: body,
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                p: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  fontSize: 16,
                ),
                h1: theme.textTheme.headlineMedium,
                h2: theme.textTheme.headlineSmall,
                h3: theme.textTheme.titleLarge,
                listBullet: theme.textTheme.bodyMedium,
                a: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
