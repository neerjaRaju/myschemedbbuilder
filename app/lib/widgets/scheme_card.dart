import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/scheme.dart';
import '../screens/scheme_detail_screen.dart';

/// Compact scheme card used in rails and lists.
class SchemeCard extends StatelessWidget {
  final Scheme scheme;
  final bool showCompareToggle;

  const SchemeCard({
    super.key,
    required this.scheme,
    this.showCompareToggle = false,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final bookmarked = state.isBookmarked(scheme.id);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        title: Text(
          scheme.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (scheme.ministry.isNotEmpty)
              Text(
                scheme.ministry,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Wrap(
              spacing: 4,
              children: [
                Chip(
                  label: Text(scheme.isCentral ? 'Central' : scheme.state),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                if (scheme.category.isNotEmpty)
                  Chip(
                    label: Text(
                      scheme.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showCompareToggle)
              Checkbox(
                value: state.inCompare(scheme.id),
                onChanged: (_) => state.toggleCompare(scheme.id),
              ),
            IconButton(
              icon: Icon(
                bookmarked ? Icons.bookmark : Icons.bookmark_outline,
              ),
              onPressed: () => state.toggleBookmark(scheme.id),
            ),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SchemeDetailScreen(schemeId: scheme.id),
          ),
        ),
      ),
    );
  }
}
