import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const featuredIndex = 2; // Greenhouse

  static const _items = [
    _NavItemData('Home', LucideIcons.house),
    _NavItemData('Plants', LucideIcons.sprout),
    _NavItemData('Greenhouse', LucideIcons.warehouse),
    _NavItemData('Activity', LucideIcons.bell),
    _NavItemData('Profile', LucideIcons.userRound),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BottomAppBar(
      height: 64,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: scheme.shadow.withValues(alpha: 0.15),
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      clipBehavior: Clip.antiAlias,
      child: Row(
        spacing: 2,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: _NavItem(
                data: _items[i],
                selected: i == currentIndex,
                featured: i == featuredIndex,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

// Cerchio centrale
class AppCenterButton extends StatelessWidget {
  const AppCenterButton({
    super.key,
    required this.selected,
    required this.onPressed,
  });

  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FloatingActionButton(
      heroTag: null,
      onPressed: onPressed,
      elevation: 4,
      highlightElevation: 6,
      shape: const CircleBorder(),
      backgroundColor: selected ? scheme.inverseSurface : scheme.primary,
      foregroundColor: selected ? scheme.onInverseSurface : scheme.onPrimary,
      child: const Icon(LucideIcons.warehouse, size: 24),
    );
  }
}

class _NavItemData {
  const _NavItemData(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.selected,
    required this.featured,
    required this.onTap,
  });

  final _NavItemData data;
  final bool selected;
  final bool featured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = selected ? scheme.onSurface : scheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          if (featured)
            // Spazio lasciato al cerchio
            const SizedBox(height: 30)
          else
            Container(
              width: 48,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? scheme.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(data.icon, size: 21, color: color),
            ),
          Text(
            data.label,
            maxLines: 1,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
