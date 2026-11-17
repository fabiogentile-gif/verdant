import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/theme/theme.dart';
import 'package:verdant/widgets/components/detail_header.dart';
import 'package:verdant/widgets/components/scrollview_list.dart';

/// Layout for pushed pages: [DetailHeader], an optional intro and a
/// scrolling body with the standard 20px gutter.
class SubpageScaffold extends StatelessWidget {
  const SubpageScaffold({
    super.key,
    required this.title,
    required this.children,
    this.heading,
    this.lede,
    this.actionIcon,
    this.onAction,
  });

  final String title;

  /// Optional Lora title and lede at the top of the content.
  final String? heading;
  final String? lede;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DetailHeader(
              title: title,
              actionIcon: actionIcon ?? LucideIcons.sprout,
              onBack: () => Navigator.of(context).maybePop(),
              onMore: onAction ?? () {},
            ),
            Expanded(
              child: ScrollViewNoStretch(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (heading != null) ...[
                      Text(
                        heading!,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 31,
                          height: 1.15,
                          letterSpacing: -0.7,
                          color: scheme.onSurface,
                        ),
                      ),
                      if (lede != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          lede!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            height: 1.5,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                    ...children,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Petal-white rounded card with the soft shadow.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardSoft(scheme),
      ),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
