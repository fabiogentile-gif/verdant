import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Top bar for pushed detail pages: back arrow, title and a circular action.
class DetailHeader extends StatelessWidget {
  const DetailHeader({
    super.key,
    required this.title,
    required this.onBack,
    required this.onMore,
    this.actionIcon = LucideIcons.ellipsis,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onMore;
  final IconData actionIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Icon(
              LucideIcons.arrowLeft,
              size: 20,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
          GestureDetector(
            onTap: onMore,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Icon(actionIcon, size: 20, color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
