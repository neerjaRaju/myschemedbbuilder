import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../l10n/strings.dart';
import '../models/scheme.dart';
import 'search_screen.dart';

/// Side-by-side comparison of up to three selected schemes
/// (e.g. PM Kisan vs KCC vs PM Fasal Bima).
///
/// Schemes are added either by ticking the compare box on any scheme card,
/// or via the "Add schemes" button here (which opens search with those
/// checkboxes). Current selections are always shown as removable chips.
class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = S.of(context);
    final schemes = state.compareSchemes();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.get('compare')),
        actions: [
          if (schemes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: s.get('clearAll'),
              onPressed: () {
                for (final scheme in List<Scheme>.of(schemes)) {
                  state.toggleCompare(scheme.id);
                }
              },
            ),
        ],
      ),
      body: SafeArea(
          child: Column(
        children: [
          _SelectionBar(schemes: schemes, s: s),
          const Divider(height: 1),
          Expanded(
            child: schemes.length < 2
                ? _EmptyCompare(s: s)
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: _CompareTable(schemes: schemes, s: s),
                    ),
                  ),
          ),
        ],
      )),
      floatingActionButton: schemes.length < AppState.maxCompare
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              ),
              icon: const Icon(Icons.add),
              label: Text(s.get('addSchemes')),
            )
          : null,
    );
  }
}

/// Shows the currently selected schemes as removable chips plus a counter.
class _SelectionBar extends StatelessWidget {
  final List<Scheme> schemes;
  final S s;

  const _SelectionBar({required this.schemes, required this.s});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    if (schemes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${schemes.length}/${AppState.maxCompare}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final scheme in schemes)
                InputChip(
                  label: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      scheme.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  onDeleted: () => state.toggleCompare(scheme.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCompare extends StatelessWidget {
  final S s;

  const _EmptyCompare({required this.s});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.compare_arrows,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              s.get('compareHint'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              s.get('compareAddHint'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              ),
              icon: const Icon(Icons.add),
              label: Text(s.get('addSchemes')),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareTable extends StatelessWidget {
  final List<Scheme> schemes;
  final S s;

  const _CompareTable({required this.schemes, required this.s});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String Function(Scheme))>[
      (s.get('ministry'), (x) => x.ministry),
      (s.get('state'), (x) => x.isCentral ? 'Central' : x.state),
      (s.get('objective'), (x) => x.description),
      (s.get('benefits'), (x) => x.benefits),
      (s.get('eligibilityCriteria'), (x) => x.eligibility),
      (s.get('documents'), (x) => x.documents.join('\n')),
      (s.get('howToApply'), (x) => x.applicationProcess),
      (s.get('officialWebsite'), (x) => x.officialUrl),
    ];

    const cellWidth = 260.0;
    return DataTable(
      columnSpacing: 16,
      dataRowMaxHeight: double.infinity,
      columns: [
        const DataColumn(label: SizedBox(width: 110, child: Text(''))),
        for (final scheme in schemes)
          DataColumn(
            label: SizedBox(
              width: cellWidth,
              child: Text(
                scheme.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
      rows: [
        for (final (label, valueOf) in rows)
          DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 110,
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              for (final scheme in schemes)
                DataCell(
                  SizedBox(
                    width: cellWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        valueOf(scheme).isEmpty ? '—' : valueOf(scheme),
                        maxLines: 12,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
