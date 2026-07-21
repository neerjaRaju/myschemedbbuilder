import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../l10n/strings.dart';
import '../logic/categories.dart';
import '../logic/filters.dart';
import '../models/scheme.dart';
import '../widgets/scheme_card.dart';

/// Category listing with the smart filter sheet.
class SchemeListScreen extends StatefulWidget {
  final String categoryKey;

  const SchemeListScreen({super.key, required this.categoryKey});

  @override
  State<SchemeListScreen> createState() => _SchemeListScreenState();
}

class _SchemeListScreenState extends State<SchemeListScreen> {
  final SmartFilters _filters = SmartFilters();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = S.of(context);
    final category = categoryByKey(widget.categoryKey);
    final all = state.repository.byCategory(category);
    final schemes = state.repository.applyFilters(all, _filters);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.get(category.key)),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: !_filters.isEmpty,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _openFilters(context, s, state),
          ),
        ],
      ),
      body: schemes.isEmpty
          ? Center(child: Text(s.get('noResults')))
          : SafeArea(
              child: ListView.builder(
              itemCount: schemes.length,
              itemBuilder: (context, index) => SchemeCard(
                scheme: schemes[index],
                showCompareToggle: true,
              ),
            )),
    );
  }

  Future<void> _openFilters(
    BuildContext context,
    S s,
    AppState state,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterSheet(
        filters: _filters,
        states: state.repository.states(),
      ),
    );
    setState(() {});
  }
}

/// Bottom sheet editing a [SmartFilters] instance in place.
class FilterSheet extends StatefulWidget {
  final SmartFilters filters;
  final List<String> states;

  const FilterSheet({super.key, required this.filters, required this.states});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final f = widget.filters;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.get('filters'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SegmentedButton<SchemeLevel>(
              segments: [
                ButtonSegment(
                  value: SchemeLevel.any,
                  label: Text(s.get('anyLevel')),
                ),
                ButtonSegment(
                  value: SchemeLevel.central,
                  label: Text(s.get('centralScheme')),
                ),
                ButtonSegment(
                  value: SchemeLevel.state,
                  label: Text(s.get('stateScheme')),
                ),
              ],
              selected: {f.level},
              onSelectionChanged: (selection) => setState(() => f.level = selection.first),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: f.state.isEmpty ? null : f.state,
              decoration: InputDecoration(labelText: s.get('state')),
              items: [
                DropdownMenuItem(value: '', child: Text(s.get('any'))),
                for (final st in widget.states) DropdownMenuItem(value: st, child: Text(st)),
              ],
              onChanged: (v) => setState(() => f.state = v ?? ''),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: f.age?.toString() ?? '',
              decoration: InputDecoration(labelText: s.get('age')),
              keyboardType: TextInputType.number,
              onChanged: (v) => f.age = int.tryParse(v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: f.gender.isEmpty ? '' : f.gender,
              decoration: InputDecoration(labelText: s.get('gender')),
              items: [
                DropdownMenuItem(value: '', child: Text(s.get('any'))),
                DropdownMenuItem(
                  value: 'female',
                  child: Text(s.get('female')),
                ),
                DropdownMenuItem(value: 'male', child: Text(s.get('male'))),
              ],
              onChanged: (v) => f.gender = v ?? '',
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: f.income?.toString() ?? '',
              decoration: InputDecoration(labelText: s.get('income')),
              keyboardType: TextInputType.number,
              onChanged: (v) => f.income = int.tryParse(v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: f.occupation,
              decoration: InputDecoration(labelText: s.get('occupation')),
              items: [
                DropdownMenuItem(value: '', child: Text(s.get('any'))),
                DropdownMenuItem(
                  value: 'farmer',
                  child: Text(s.get('farmer')),
                ),
                DropdownMenuItem(
                  value: 'student',
                  child: Text(s.get('student')),
                ),
                DropdownMenuItem(
                  value: 'business owner',
                  child: Text(s.get('businessOwner')),
                ),
              ],
              onChanged: (v) => f.occupation = v ?? '',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: f.casteCategory,
              decoration: InputDecoration(labelText: s.get('casteCategory')),
              items: [
                DropdownMenuItem(value: '', child: Text(s.get('general'))),
                const DropdownMenuItem(value: 'sc', child: Text('SC')),
                const DropdownMenuItem(value: 'st', child: Text('ST')),
                const DropdownMenuItem(value: 'obc', child: Text('OBC')),
              ],
              onChanged: (v) => f.casteCategory = v ?? '',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        f
                          ..level = SchemeLevel.any
                          ..state = ''
                          ..age = null
                          ..gender = ''
                          ..income = null
                          ..occupation = ''
                          ..casteCategory = '';
                      });
                    },
                    child: Text(s.get('reset')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(s.get('apply')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple list screen reused by search results and eligibility results.
class SchemeResultsScreen extends StatelessWidget {
  final String title;
  final List<Scheme> schemes;

  const SchemeResultsScreen({
    super.key,
    required this.title,
    required this.schemes,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: schemes.isEmpty
          ? Center(child: Text(s.get('noResults')))
          : ListView.builder(
              itemCount: schemes.length,
              itemBuilder: (context, index) => SchemeCard(
                scheme: schemes[index],
                showCompareToggle: true,
              ),
            ),
    );
  }
}
