import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../l10n/strings.dart';
import '../models/scheme.dart';
import '../screens/scheme_detail_screen.dart';
import '../theme/app_theme.dart';

/// Elevated scheme card used in lists and search/eligibility results.
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
    final theme = Theme.of(context);
    final s = S.of(context);
    final bookmarked = state.isBookmarked(scheme.id);
    final inCompare = state.inCompare(scheme.id);

    // Deterministic accent per scheme so the same card is always one colour.
    final accent = AppTheme
        .cardAccents[scheme.id.hashCode.abs() % AppTheme.cardAccents.length];
    final (tint, foreground) = accent;
    final isDark = theme.brightness == Brightness.dark;
    final surface =
        isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow(theme.brightness),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SchemeDetailScreen(schemeId: scheme.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isDark ? foreground.withValues(alpha: 0.22) : tint,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(_iconFor(scheme), color: foreground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scheme.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.2,
                      ),
                    ),
                    if (scheme.ministry.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        scheme.ministry,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Pill(
                          text: scheme.isCentral
                              ? s.get('centralGov')
                              : scheme.state,
                          color: foreground,
                        ),
                        if (scheme.category.isNotEmpty)
                          _Pill(
                            text: scheme.category,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      bookmarked ? Icons.bookmark : Icons.bookmark_outline,
                      color: bookmarked ? theme.colorScheme.primary : null,
                    ),
                    onPressed: () => state.toggleBookmark(scheme.id),
                  ),
                  if (showCompareToggle)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        inCompare ? Icons.check_box : Icons.add_box_outlined,
                        color: inCompare ? theme.colorScheme.primary : null,
                      ),
                      onPressed: () => state.toggleCompare(scheme.id),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

IconData _iconFor(Scheme scheme) {
  final blob = scheme.searchBlob;
  if (blob.contains('farmer') || blob.contains('agricultur')) {
    return Icons.agriculture;
  }
  if (blob.contains('pension') || blob.contains('old age')) {
    return Icons.savings;
  }
  if (blob.contains('housing') || blob.contains('awas')) {
    return Icons.home_work;
  }
  if (blob.contains('health') || blob.contains('insurance')) {
    return Icons.health_and_safety;
  }
  if (blob.contains('education') ||
      blob.contains('scholarship') ||
      blob.contains('student')) {
    return Icons.school;
  }
  if (blob.contains('business') || blob.contains('industr')) {
    return Icons.factory;
  }
  if (blob.contains('women') || blob.contains('girl')) {
    return Icons.woman;
  }
  if (blob.contains('disabilit') || blob.contains('divyang')) {
    return Icons.accessible;
  }
  return Icons.groups;
}
