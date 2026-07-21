import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/scheme.dart';
import '../screens/scheme_detail_screen.dart';
import '../theme/app_theme.dart';

/// Pastel accent palette cycled across cards (from the app design tokens).
const List<(Color, Color)> _accents = AppTheme.cardAccents;

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

/// Section header with a colored round icon, bold title and a
/// "view all →" action, followed by a horizontally scrolling card rail.
class SchemeRail extends StatelessWidget {
  final String title;
  final List<Scheme> schemes;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onViewAll;

  const SchemeRail({
    super.key,
    required this.title,
    required this.schemes,
    this.icon = Icons.star,
    this.iconColor = AppTheme.accentTeal,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (schemes.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final s = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: iconColor,
                child: Icon(icon, size: 17, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s.get('viewAll')),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, size: 15),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 175,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: schemes.length,
            itemBuilder: (context, index) => _RailCard(
              scheme: schemes[index],
              accent: _accents[index % _accents.length],
            ),
          ),
        ),
      ],
    );
  }
}

class _RailCard extends StatelessWidget {
  final Scheme scheme;
  final (Color, Color) accent;

  const _RailCard({required this.scheme, required this.accent});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final (background, foreground) = accent;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 230,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: isDark
              ? Theme.of(context).colorScheme.surfaceContainerHigh
              : background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: foreground.withValues(alpha: 0.15)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SchemeDetailScreen(schemeId: scheme.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: foreground.withValues(alpha: 0.12),
                      child: Icon(_iconFor(scheme), color: foreground),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right,
                        color: foreground.withValues(alpha: 0.7)),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Text(
                    scheme.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: foreground.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    scheme.isCentral ? s.get('centralGov') : scheme.state,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
