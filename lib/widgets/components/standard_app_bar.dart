import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Top app bar of the main tabs: a title (or the Verdant wordmark on the
/// homepage) and one circular action on the right.
class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StandardAppBar({
    super.key,
    required this.title,
    this.actionIcon,
    this.onActionTap,
    this.actionLabel,
    this.badgeCount = 0,
    this.backgroundColor = Colors.transparent,
  }) : _isHome = false,
       hasUnread = false;

  const StandardAppBar.home({
    super.key,
    this.onActionTap,
    this.hasUnread = false,
  }) : title = 'verdant',
       actionIcon = LucideIcons.bell,
       actionLabel = 'Notifications',
       badgeCount = 0,
       backgroundColor = null,
       _isHome = true;

  final String title;
  final IconData? actionIcon;
  final VoidCallback? onActionTap;

  /// Accessibility label of the action button.
  final String? actionLabel;

  /// Small count on the action (e.g. items in the cart). Hidden when 0.
  final int badgeCount;
  final Color? backgroundColor;

  /// Shows a dot on the bell (homepage only).
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
            child: Semantics(
              button: true,
              label: actionLabel,
              child: _isHome ? _buildBell(colors) : _buildAction(colors),
            ),
          ),
      ],
    );
  }

  Widget _buildTitle(ThemeData theme, ColorScheme colors) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.onSurface,
      ),
    );
  }

  Widget _buildAction(ColorScheme colors) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: backgroundColor,
          shape: CircleBorder(side: BorderSide(color: colors.outlineVariant)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onActionTap,
            child: SizedBox.square(
              dimension: 48,
              child: Icon(actionIcon, size: 20, color: colors.onSurface),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: IgnorePointer(
              child: Container(
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: colors.surfaceContainerLow,
                    width: 2,
                  ),
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colors.onPrimary,
                  ),
                ),
              ),
            ),
          ),
      ],
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
          '.',
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
          dimension: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(actionIcon, size: 20, color: colors.onSurface),
              if (hasUnread)
                Positioned(
                  left: 27,
                  top: 13,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: colors.tertiary,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.surface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
