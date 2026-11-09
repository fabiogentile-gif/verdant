import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CategoryFilter {
  const CategoryFilter(this.label, {this.icon});

  final String label;
  final IconData? icon;
}

const popularCategories = [
  CategoryFilter('Indoor', icon: LucideIcons.leaf),
  CategoryFilter('Outdoor', icon: LucideIcons.sun),
  CategoryFilter('Pots & more'),
];

class PopularCategories extends StatelessWidget {
  const PopularCategories({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.categories = popularCategories,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<CategoryFilter> categories;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Find your kind of green',
          style: TextStyle(
            fontFamily: 'Lora',
            fontSize: 23,
            letterSpacing: -0.5,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < categories.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _FilterChip(
                  category: categories[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelected(i),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final CategoryFilter category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final background = selected ? scheme.primary : scheme.surface;
    final border = selected ? scheme.primary : scheme.outlineVariant;
    final foreground = selected ? scheme.onPrimary : scheme.onSurfaceVariant;

    return Material(
      color: background,
      shape: StadiumBorder(side: BorderSide(color: border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (category.icon != null) ...[
                Icon(category.icon, size: 14, color: foreground),
                const SizedBox(width: 6),
              ],
              Text(
                category.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}