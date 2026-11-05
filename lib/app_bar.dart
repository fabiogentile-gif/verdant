import 'package:flutter/material.dart';

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StandardAppBar({
    super.key,
    required this.title,
    this.actionIcon,
    this.onActionTap,
  });

  final String title;
  final IconData? actionIcon;
  final VoidCallback? onActionTap;

  static const _height = 68.0;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      toolbarHeight: _height,
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
      actions: [
        if (actionIcon != null)
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 20),
          child: Material(
            color: Colors.transparent,
            shape: CircleBorder(side: BorderSide(color: colors.outlineVariant)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onActionTap,
              child: SizedBox.square(
                dimension: 40,
                child: Icon(actionIcon, size: 20, color: colors.onSurface),
              ),
            ),
          ),
        ),
      ],
    );
  }
}