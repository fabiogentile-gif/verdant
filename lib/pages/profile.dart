import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/owned_plants.dart';
import 'package:verdant/search_field.dart';
import 'package:verdant/theme/theme_controller.dart';
import 'package:verdant/widgets/components/collection_overview.dart';
import 'package:verdant/widgets/components/page_header.dart';
import 'package:verdant/widgets/components/plant_card.dart';
import 'package:verdant/widgets/components/scrollview_list.dart';

// + gli stessi import della pagina Piante da cui arriva StandardAppBar

class Profile extends StatefulWidget {
  const Profile({super.key, this.onOpenPlants});

  final VoidCallback? onOpenPlants;

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool _push = true;
  bool _email = false;

  @override
  Widget build(BuildContext context) {
    final needsCare = ownedPlants
        .where((p) => p.status == PlantStatus.needsCare)
        .length;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: StandardAppBar(
        title: 'Profile',
        actionIcon: LucideIcons.settings,
        onActionTap: () {},
      ),
      body: ScrollViewNoStretch(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader.eyebrowText(
              'YOUR VERDANT WORLD',
              title: 'Rooted in you.',
              subtitle: 'A little space for you and your growing world.',
            ),
            const SizedBox(height: 24),
            const _IdentityCard(
              name: 'Maya',
              subtitle: 'Plant parent · Portland, OR',
            ),
            const SizedBox(height: 24),
            CollectionOverview(
              title: 'Your little jungle',
              actionLabel: 'My plants →',
              onActionTap: widget.onOpenPlants,
              images: [for (final p in ownedPlants) p.image],
              total: ownedPlants.length,
              healthy: ownedPlants.length - needsCare,
              needsCare: needsCare,
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Your shop, your way',
              children: [
                _SettingsTile(
                  icon: LucideIcons.package,
                  title: 'My orders',
                  subtitle: 'Track deliveries & revisit past orders',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: LucideIcons.mapPin,
                  title: 'Saved addresses',
                  subtitle: 'Your delivery details, all in one place',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: LucideIcons.creditCard,
                  title: 'Payment methods',
                  subtitle: 'Manage your saved payment options',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Your care rhythm',
              children: [
                _SettingsTile(
                  icon: LucideIcons.calendarDays,
                  title: 'Care reminders',
                  subtitle:
                      'Review schedules for your ${ownedPlants.length} plants',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: LucideIcons.bell,
                  title: 'Push notifications',
                  subtitle: 'A gentle nudge on your phone',
                  trailing: _Toggle(
                    value: _push,
                    onChanged: (v) => setState(() => _push = v),
                  ),
                ),
                _SettingsTile(
                  icon: LucideIcons.mail,
                  title: 'Email reminders',
                  subtitle: 'Keep your inbox a little quieter',
                  trailing: _Toggle(
                    value: _email,
                    onChanged: (v) => setState(() => _email = v),
                  ),
                ),
                _SettingsTile(
                  icon: LucideIcons.clock3,
                  title: 'Time zone',
                  subtitle: 'Portland · Pacific Time',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'A little housekeeping',
              children: [
                _SettingsTile(
                  icon: LucideIcons.moon,
                  title: 'Dark mode',
                  subtitle: 'Switch to a darker, easier-on-the-eyes theme',
                  trailing: _Toggle(
                    value: isDark,
                    onChanged: (v) => themeMode.value = v ? ThemeMode.dark : ThemeMode.light,
                  ),
                ),
                _SettingsTile(
                  icon: LucideIcons.userRound,
                  title: 'Account & security',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: LucideIcons.shieldCheck,
                  title: 'Privacy & permissions',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: LucideIcons.messageCircle,
                  title: 'Help & support',
                  subtitle: 'We’re here to help you grow',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: LucideIcons.sprout,
                  title: 'About Verdant',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SoftButton(label: 'Sign out', onPressed: () {}),
            const SizedBox(height: 18),
            Text(
              'Good things grow with a little care.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.name, required this.subtitle});

  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  name[0].toUpperCase(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w400,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Icon(LucideIcons.sprout, size: 25, color: scheme.primary),
            ],
          ),
          const SizedBox(height: 18),
          _SoftButton(label: 'Edit profile', onPressed: () {}),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 23,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.5,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: scheme.outlineVariant,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: scheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        height: 1.45,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing ??
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(3),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: value ? scheme.primary : scheme.outlineVariant,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _SoftButton extends StatelessWidget {
  const _SoftButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        minimumSize: const Size.fromHeight(50),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
