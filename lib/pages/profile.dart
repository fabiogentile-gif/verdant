import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/address.dart';
import 'package:verdant/data/auth.dart';
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
import 'package:verdant/l10n/i18n.dart';

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
          content: Text(
            'Android hasn’t allowed notifications for Verdant yet.'.tr,
          ),
          action: SnackBarAction(
            label: 'Details'.tr,
            onPressed: () => pushRoot(context, AppRoutes.privacy),
          ),
        ),
      );
    }
  }

  String get _languageLabel => switch (appSettings.language) {
    AppLanguage.system => 'Follows your phone'.tr,
    AppLanguage.en => 'English',
    AppLanguage.it => 'Italiano',
  };

  Future<void> _pickLanguage() async {
    final picked = await showModalBottomSheet<AppLanguage>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        Widget option(AppLanguage value, String label) => ListTile(
          title: Text(label),
          trailing: appSettings.language == value
              ? Icon(LucideIcons.check, size: 18, color: scheme.primary)
              : null,
          onTap: () => Navigator.of(context).pop(value),
        );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                option(AppLanguage.system, 'Use phone language'.tr),
                option(AppLanguage.it, 'Italiano'),
                option(AppLanguage.en, 'English'),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) appSettings.language = picked;
  }

  void _showTimeZone() {
    final zone = NotificationService.timeZone;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Time zone'.tr),
        content: Text(
          zone == null
              ? 'Reminders follow your phone’s time zone.'.tr
              : trArgs(
                  'Reminders follow your phone’s time zone ({0}). Change it in Android settings and Verdant will follow.',
                  [zone],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Got it'.tr),
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
      applicationLegalese: 'A school project: a plant shop and care companion. Payments are simulated and nothing is shipped.'
          .tr,
    );
  }

  Future<void> _confirmSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign out of Verdant?'.tr),
        content: Text(
          'Your plants and orders stay safe in your account. Reminders stop on this phone until you sign in again.'
              .tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Stay'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Sign out'.tr),
          ),
        ],
      ),
    );
    if (ok == true) await authStore.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        authStore,
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
    final user = authStore.user;
    final address = addressBook.address;

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Profile'.tr,
        actionIcon: LucideIcons.settings,
        actionLabel: 'Settings'.tr,
        onActionTap: _scrollToSettings,
      ),
      body: ScrollViewNoStretch(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader.eyebrowText(
              'YOUR VERDANT WORLD'.tr,
              title: 'Rooted in you.'.tr,
              subtitle: 'A little space for you and your growing world.'.tr,
            ),
            const SizedBox(height: 24),
            _IdentityCard(
              name: user?.name ?? 'Verdant',
              subtitle: user == null || user.location.isEmpty
                  ? 'Plant parent'.tr
                  : trArgs('Plant parent · {0}', [user.location]),
              onEdit: () => pushRoot(context, AppRoutes.account),
            ),
            const SizedBox(height: 24),
            CollectionOverview(
              title: 'Your little jungle'.tr,
              actionLabel: 'My plants →'.tr,
              onActionTap: () => goToTab(context, AppRoutes.plants),
              images: [for (final p in plants) p.image],
              total: plants.length,
              healthy: plants.length - needsCare,
              needsCare: needsCare,
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Your shop, your way'.tr,
              children: [
                _SettingsTile(
                  icon: LucideIcons.package,
                  title: 'My orders'.tr,
                  subtitle: orders == 0
                      ? 'Track deliveries & revisit past orders'.tr
                      : trArgs('{0} {1} so far', [
                          orders,
                          orders == 1 ? 'order'.tr : 'orders'.tr,
                        ]),
                  onTap: () => pushRoot(context, AppRoutes.orders),
                ),
                _SettingsTile(
                  icon: LucideIcons.mapPin,
                  title: 'Saved addresses'.tr,
                  subtitle: address.isComplete
                      ? '${address.label.tr} · ${address.city}'
                      : 'Add where your plants should arrive'.tr,
                  onTap: () => pushRoot(context, AppRoutes.addresses),
                ),
                _SettingsTile(
                  icon: LucideIcons.creditCard,
                  title: 'Payment methods'.tr,
                  subtitle: payment == null
                      ? 'Manage your saved payment options'.tr
                      : trArgs('Default: {0}', [payment.title]),
                  onTap: () => pushRoot(context, AppRoutes.paymentMethods),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Your care rhythm'.tr,
              children: [
                _SettingsTile(
                  icon: LucideIcons.calendarDays,
                  title: 'Care reminders'.tr,
                  subtitle: trArgs('Review schedules for your {0} {1}', [
                    plants.length,
                    plants.length == 1 ? 'plant'.tr : 'plants'.tr,
                  ]),
                  onTap: () => pushRoot(context, AppRoutes.careReminders),
                ),
                _SettingsTile(
                  icon: LucideIcons.bell,
                  title: 'Push notifications'.tr,
                  subtitle: 'A gentle nudge on your phone'.tr,
                  trailing: AppToggle(
                    value: appSettings.push,
                    onChanged: _setPush,
                  ),
                ),
                _SettingsTile(
                  icon: LucideIcons.mail,
                  title: 'Email reminders'.tr,
                  subtitle: 'For reminders with email turned on'.tr,
                  trailing: AppToggle(
                    value: appSettings.email,
                    onChanged: (v) => appSettings.email = v,
                  ),
                ),
                _SettingsTile(
                  icon: LucideIcons.clock3,
                  title: 'Time zone'.tr,
                  subtitle:
                      NotificationService.timeZone ?? 'Follows your phone'.tr,
                  onTap: _showTimeZone,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _Section(
              key: _housekeepingKey,
              title: 'A little housekeeping'.tr,
              children: [
                _SettingsTile(
                  icon: LucideIcons.moon,
                  title: 'Dark mode'.tr,
                  subtitle: 'Switch to a darker, easier-on-the-eyes theme'.tr,
                  trailing: AppToggle(
                    value: isDark,
                    onChanged: (v) => appSettings.themeMode = v
                        ? ThemeMode.dark
                        : ThemeMode.light,
                  ),
                ),
                _SettingsTile(
                  icon: LucideIcons.languages,
                  title: 'Language'.tr,
                  subtitle: _languageLabel,
                  onTap: _pickLanguage,
                ),
                _SettingsTile(
                  icon: LucideIcons.userRound,
                  title: 'Account & security'.tr,
                  subtitle: user?.email,
                  onTap: () => pushRoot(context, AppRoutes.account),
                ),
                _SettingsTile(
                  icon: LucideIcons.shieldCheck,
                  title: 'Privacy & permissions'.tr,
                  onTap: () => pushRoot(context, AppRoutes.privacy),
                ),
                _SettingsTile(
                  icon: LucideIcons.messageCircle,
                  title: 'Help & support'.tr,
                  subtitle: 'We’re here to help you grow'.tr,
                  onTap: () => pushRoot(context, AppRoutes.help),
                ),
                _SettingsTile(
                  icon: LucideIcons.sprout,
                  title: 'About Verdant'.tr,
                  onTap: _showAbout,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SoftButton(label: 'Sign out'.tr, onPressed: _confirmSignOut),
            const SizedBox(height: 18),
            Text(
              'Good things grow with a little care.'.tr,
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
  const _IdentityCard({
    required this.name,
    required this.subtitle,
    required this.onEdit,
  });

  final String name;
  final String subtitle;
  final VoidCallback onEdit;

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
          _SoftButton(label: 'Edit profile'.tr, onPressed: onEdit),
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
