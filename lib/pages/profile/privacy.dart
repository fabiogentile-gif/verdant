import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/app_data.dart';
import 'package:verdant/data/settings.dart';
import 'package:verdant/services/notifications.dart';
import 'package:verdant/widgets/components/app_toggle.dart';
import 'package:verdant/widgets/components/subpage_scaffold.dart';

/// Notification permission and the data kept on this phone.
class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

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
        const SnackBar(
          content: Text(
            'Android blocked the request. Allow notifications for Verdant '
            'in your phone settings.',
          ),
        ),
      );
    }
  }

  Future<void> _erase() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erase everything on this phone?'),
        content: const Text(
          'Your plants, reminders, cart, orders, payment methods and settings '
          'will be removed and the demo content restored. This can’t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Erase'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await resetAppData();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Your data was erased.')));
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
      null => 'Checking…',
      true => 'Allowed by Android',
      false => 'Not allowed yet',
    };

    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, _) => SubpageScaffold(
        title: 'Privacy & permissions',
        actionIcon: LucideIcons.shieldCheck,
        heading: 'Your data, your phone.',
        lede: 'Verdant keeps everything on this device. Nothing is shared.',
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
                            'Care reminders on this phone',
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
                    label: const Text('Allow notifications'),
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
                  'What Verdant stores',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Your plants, reminders and care history\n'
                  '• Cart, favourites and demo orders\n'
                  '• Delivery address\n'
                  '• Payment methods: brand, last 4 digits and expiry only\n'
                  '• Theme and notification preferences',
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
              'Erase my data',
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
