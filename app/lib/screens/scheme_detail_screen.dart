import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../data/user_store.dart';
import '../l10n/strings.dart';
import '../models/scheme.dart';
import '../widgets/scheme_card.dart';

/// Full scheme details: objective, benefits, eligibility, documents,
/// application process, official website, helpline, FAQs and related
/// schemes.
class SchemeDetailScreen extends StatelessWidget {
  final String schemeId;

  const SchemeDetailScreen({super.key, required this.schemeId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = S.of(context);
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
      appBar: AppBar(
        title: Text(scheme.title, maxLines: 1, overflow: TextOverflow.fade),
        actions: [
          IconButton(
            icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_outline),
            onPressed: () => state.toggleBookmark(scheme.id),
          ),
          IconButton(
            icon: const Icon(Icons.alarm_add),
            tooltip: s.get('addReminder'),
            onPressed: () => _pickReminder(context, state, scheme, s),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(scheme.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text(scheme.isCentral ? 'Central' : scheme.state)),
              if (scheme.category.isNotEmpty)
                Chip(label: Text(scheme.category)),
            ],
          ),
          if (scheme.ministry.isNotEmpty)
            _Section(title: s.get('ministry'), body: scheme.ministry),
          if (scheme.description.isNotEmpty)
            _Section(title: s.get('objective'), body: scheme.description),
          if (scheme.benefits.isNotEmpty)
            _Section(title: s.get('benefits'), body: scheme.benefits),
          if (scheme.eligibility.isNotEmpty)
            _Section(
              title: s.get('eligibilityCriteria'),
              body: scheme.eligibility,
            ),
          if (scheme.documents.isNotEmpty)
            _Section(
              title: s.get('documents'),
              body: scheme.documents.map((d) => '• $d').join('\n'),
            ),
          if (scheme.applicationProcess.isNotEmpty)
            _Section(
              title: s.get('howToApply'),
              body: scheme.applicationProcess,
            ),
          if (scheme.officialUrl.isNotEmpty)
            _Section(title: s.get('officialWebsite'), body: scheme.officialUrl),
          if (scheme.helpline.isNotEmpty)
            _Section(title: s.get('helpline'), body: scheme.helpline),
          if (scheme.lastUpdated.isNotEmpty)
            _Section(title: s.get('lastUpdated'), body: scheme.lastUpdated),
          if (scheme.faq.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: Text(
                s.get('faqs'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final entry in scheme.faq.entries)
              ExpansionTile(
                title: Text(entry.key),
                tilePadding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(entry.value),
                  ),
                ],
              ),
          ],
          if (related.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: Text(
                s.get('relatedSchemes'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final other in related) SchemeCard(scheme: other),
          ],
          const SizedBox(height: 32),
        ],
      ),
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

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          SelectableText(body),
        ],
      ),
    );
  }
}
