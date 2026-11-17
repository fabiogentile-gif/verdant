import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/address.dart';
import 'package:verdant/data/care_schedule.dart';
import 'package:verdant/data/orders.dart';
import 'package:verdant/data/owned_plants.dart';
import 'package:verdant/data/payment.dart';
import 'package:verdant/data/settings.dart';
import 'package:verdant/router/router.dart';
import 'package:verdant/services/notifications.dart';
import 'package:verdant/theme/theme.dart';
import 'package:verdant/widgets/components/app_toggle.dart';
import 'package:verdant/widgets/components/collection_overview.dart';
import 'package:verdant/widgets/components/page_header.dart';
import 'package:verdant/widgets/components/scrollview_list.dart';
import 'package:verdant/widgets/components/standard_app_bar.dart';

/// Profile tab: account, orders, settings and app info.
class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

/// Handles the settings actions (notification permission, time zone…).
class _ProfileState extends State<Profile> {
  final _housekeepingKey = GlobalKey();

  void _scrollToSettings() {
    final target = _housekeepingKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _setPush(bool value) async {
    appSettings.push = value;
    if (!value) return;
    final allowed = await NotificationService.requestPermission();
    if (!allowed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Android hasn’t allowed notifications for Verdant yet.',
          ),
          action: SnackBarAction(
            label: 'Details',
            onPressed: () => pushRoot(context, AppRoutes.privacy),
          ),
        ),
      );
    }
  }

  void _showTimeZone() {
    final zone = NotificationService.timeZone;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Time zone'),
        content: Text(
          zone == null
              ? 'Reminders follow your phone’s time zone.'
              : 'Reminders follow your phone’s time zone ($zone). Change it '
                    'in Android settings and Verdant will follow.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Verdant',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        LucideIcons.sprout,
        size: 36,
        color: Theme.of(context).colorScheme.primary,
      ),
      applicationLegalese:
          'A school project: a plant shop and care companion. Payments are '
          'simulated and nothing is shipped.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        plantCollection,
        careSchedule,
        appSettings,
        orderHistory,
        wallet,
        addressBook,
      ]),
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final plants = ownedPlants;
    final needsCare = plants.where(careSchedule.needsCare).length;
    final orders = orderHistory.orders.length;
    final payment = wallet.selected;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Profile',
        actionIcon: LucideIcons.settings,
        actionLabel: 'Settings',
        onActionTap: _scrollToSettings,
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
              onActionTap: () => goToTab(context, AppRoutes.plants),
              images: [for (final p in plants) p.image],
              total: plants.length,
              healthy: plants.length - needsCare,
              needsCare: needsCare,
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Your shop, your way',
              children: [
                _SettingsTile(
                  icon: LucideIcons.package,
                  title: 'My orders',
                  subtitle: orders == 0
                      ? 'Track deliveries & revisit past orders'
                      : '$orders ${orders == 1 ? 'order' : 'orders'} so far',
                  onTap: () => pushRoot(context, AppRoutes.orders),
                ),
                _SettingsTile(
                  icon: LucideIcons.mapPin,
                  title: 'Saved addresses',
                  subtitle:
                      '${addressBook.address.label} · '
                      '${addressBook.address.city}',
                  onTap: () => pushRoot(context, AppRoutes.addresses),
                ),
                _SettingsTile(
                  icon: LucideIcons.creditCard,
                  title: 'Payment methods',
                  subtitle: payment == null
                      ? 'Manage your saved payment options'
                      : 'Default: ${payment.title}',
                  onTap: () => pushRoot(context, AppRoutes.paymentMethods),
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
                      'Review schedules for your ${plants.length} '
                      '${plants.length == 1 ? 'plant' : 'plants'}',
                  onTap: () => pushRoot(context, AppRoutes.careReminders),
                ),
                _SettingsTile(
                  icon: LucideIcons.bell,
                  title: 'Push notifications',
                  subtitle: 'A gentle nudge on your phone',
                  trailing: AppToggle(
                    value: appSettings.push,
                    onChanged: _setPush,
                  ),
                ),
                _SettingsTile(
                  icon: LucideIcons.mail,
                  title: 'Email reminders',
                  subtitle: 'Saved for when email reminders arrive',
                  trailing: AppToggle(
                    value: appSettings.email,
                    onChanged: (v) => appSettings.email = v,
                  ),
                ),
                _SettingsTile(
                  icon: LucideIcons.clock3,
                  title: 'Time zone',
                  subtitle:
                      NotificationService.timeZone ?? 'Follows your phone',
                  onTap: _showTimeZone,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _Section(
              key: _housekeepingKey,
              title: 'A little housekeeping',
              children: [
                _SettingsTile(
                  icon: LucideIcons.moon,
                  title: 'Dark mode',
                  subtitle: 'Switch to a darker, easier-on-the-eyes theme',
                  trailing: AppToggle(
                    value: isDark,
                    onChanged: (v) => appSettings.themeMode = v
                        ? ThemeMode.dark
                        : ThemeMode.light,
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
                  onTap: () => pushRoot(context, AppRoutes.privacy),
                ),
                _SettingsTile(
                  icon: LucideIcons.messageCircle,
                  title: 'Help & support',
                  subtitle: 'We’re here to help you grow',
                  onTap: () => pushRoot(context, AppRoutes.help),
                ),
                _SettingsTile(
                  icon: LucideIcons.sprout,
                  title: 'About Verdant',
                  onTap: _showAbout,
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

/// Avatar, name and a short subtitle.
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
        boxShadow: AppShadows.cardSoft(scheme),
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

/// Titled group of settings tiles.
class _Section extends StatelessWidget {
  const _Section({super.key, required this.title, required this.children});

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
            boxShadow: AppShadows.cardSoft(scheme),
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

/// One settings row: icon, title, optional value and a trailing widget.
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

/// Low-emphasis outlined button.
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
