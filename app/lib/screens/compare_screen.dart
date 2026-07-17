import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../l10n/strings.dart';
import '../models/scheme.dart';

/// Side-by-side comparison of up to three selected schemes
/// (e.g. PM Kisan vs KCC vs PM Fasal Bima).
class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = S.of(context);
    final schemes = state.compareSchemes();

    return Scaffold(
      appBar: AppBar(title: Text(s.get('compare'))),
      body: schemes.length < 2
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(s.get('compareHint'), textAlign: TextAlign.center),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: _CompareTable(schemes: schemes, s: s),
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
              DataCell(SizedBox(
                width: 110,
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              )),
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
