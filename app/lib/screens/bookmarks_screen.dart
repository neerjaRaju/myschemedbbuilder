import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../l10n/strings.dart';
import '../widgets/scheme_card.dart';

/// Saved schemes, fully available offline.
class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = S.of(context);
    final schemes = List.of(state.bookmarkedSchemes())
      ..sort((a, b) => a.title.compareTo(b.title));

    return Scaffold(
      appBar: AppBar(title: Text(s.get('bookmarks'))),
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
}
