import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StandardAppBar({
    super.key,
    required this.title,
    this.actionIcon,
    this.onActionTap,
    this.backgroundColor = Colors.transparent,
  }) : _isHome = false,
       hasUnread = false;

  const StandardAppBar.home({
    super.key,
    this.onActionTap,
    this.hasUnread = false,
  }) : title = "verdant",
       actionIcon = LucideIcons.bell,
       backgroundColor = null,
       _isHome = true;

  final String title;
  final IconData? actionIcon;
  final VoidCallback? onActionTap;
  final Color? backgroundColor;
  final bool hasUnread;
  final bool _isHome;

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
      title: _isHome ? _buildBrand(colors) : _buildTitle(theme, colors),
      actions: [
        if (actionIcon != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 20),
            child: _isHome ? _buildBell(colors) : _buildAction(colors),
          ),
      ],
    );
  }

  Widget _buildTitle(ThemeData theme, ColorScheme colors) {
    return Column(
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
    );
  }

  Widget _buildAction(ColorScheme colors) {
    return Material(
      color: backgroundColor,
      shape: CircleBorder(side: BorderSide(color: colors.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onActionTap,
        child: SizedBox.square(
          dimension: 40,
          child: Icon(actionIcon, size: 20, color: colors.onSurface),
        ),
      ),
    );
  }

  Widget _buildBrand(ColorScheme colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.sprout, size: 24, color: colors.onSurface),
        const SizedBox(width: 7),
        Text(
          title,
          maxLines: 1,
          style: TextStyle(
            fontFamily: 'Lora',
            fontSize: 26,
            fontWeight: FontWeight.w400,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          ".",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 21,
            fontWeight: FontWeight.w400,
            color: colors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildBell(ColorScheme colors) {
    return Material(
      color: colors.surface,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onActionTap,
        child: SizedBox.square(
          dimension: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(actionIcon, size: 20, color: colors.onSurface),
              // if (hasUnread)
              //   Positioned(
              //     left: 26,
              //     top: 8,
              //     child: Container(
              //       width: 5,
              //       height: 5,
              //       decoration: BoxDecoration(
              //         color: colors.primary,
              //         shape: BoxShape.circle,
              //       ),
              //     ),
              //   ),
            ],
          ),
        ),
      ),
    );
  }
}
