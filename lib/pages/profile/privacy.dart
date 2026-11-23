import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/api_client.dart';
import 'package:verdant/data/app_data.dart';
import 'package:verdant/data/settings.dart';
import 'package:verdant/services/notifications.dart';
import 'package:verdant/widgets/components/app_toggle.dart';
import 'package:verdant/widgets/components/subpage_scaffold.dart';
import 'package:verdant/l10n/i18n.dart';

/// Notification permission and the data kept on this phone.
class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

/// Checks the notification permission and handles "Erase my data".
class _PrivacyPageState extends State<PrivacyPage> {
  bool? _allowed;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final allowed = await NotificationService.areEnabled();
    if (mounted) setState(() => _allowed = allowed);
  }

  Future<void> _request() async {
    await NotificationService.requestPermission();
    await _check();
    if (mounted && _allowed == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Android blocked the request. Allow notifications for Verdant in your phone settings.'
                .tr,
          ),
        ),
      );
    }
  }

  Future<void> _erase() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Erase your Verdant data?'.tr),
        content: Text(
          'Your plants, reminders, cart, orders, payment methods and settings will be removed from your account and this phone, and the starter plants restored. You stay signed in. This can’t be undone.'
              .tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Erase'.tr),
          ),
        ],
      ),
    );
    if (ok != true) return;
    String message = 'Your data was erased.'.tr;
    try {
      await resetAppData();
    } on ApiException catch (e) {
      message = trArgs('Nothing was erased. {0}', [e.message]);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    TextStyle? body(Color c) => theme.textTheme.bodySmall?.copyWith(
      fontSize: 12,
      height: 1.5,
      color: c,
    );

    final permission = switch (_allowed) {
      null => 'Checking…'.tr,
      true => 'Allowed by Android'.tr,
      false => 'Not allowed yet'.tr,
    };

    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, _) => SubpageScaffold(
        title: 'Privacy & permissions'.tr,
        actionIcon: LucideIcons.shieldCheck,
        heading: 'Your data, your call.'.tr,
        lede: 'Verdant saves your data to your account so it follows you. It is never shared.'
            .tr,
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.bell, size: 20, color: scheme.onSurface),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Care reminders on this phone'.tr,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            permission,
                            style: body(scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    AppToggle(
                      value: appSettings.push,
                      onChanged: (v) async {
                        appSettings.push = v;
                        if (v) await _request();
                      },
                    ),
                  ],
                ),
                if (_allowed == false && appSettings.push) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _request,
                    icon: const Icon(LucideIcons.bellRing, size: 16),
                    label: Text('Allow notifications'.tr),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What Verdant stores'.tr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Your name and email (your password is stored only as a secure hash)\n• Your plants, reminders and care history\n• Cart, favourites and demo orders\n• Delivery address\n• Payment methods: brand, last 4 digits and expiry only\n• Theme and notification preferences'
                      .tr,
                  style: body(scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _erase,
            icon: Icon(LucideIcons.trash2, size: 18, color: scheme.error),
            label: Text(
              'Erase my data'.tr,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.error,
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: BorderSide(color: scheme.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
