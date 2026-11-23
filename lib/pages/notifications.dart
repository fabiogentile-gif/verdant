import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/care_schedule.dart';
import 'package:verdant/data/orders.dart';
import 'package:verdant/data/settings.dart';
import 'package:verdant/router/router.dart';
import 'package:verdant/theme/theme.dart';
import 'package:verdant/widgets/components/detail_header.dart';
import 'package:verdant/widgets/components/scrollview_list.dart';
import 'package:verdant/l10n/i18n.dart';

/// One entry of the in-app inbox.
class AppNotification {
  const AppNotification({
    required this.icon,
    required this.title,
    required this.body,
    required this.at,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String body;
  final DateTime at;
  final String route;
}

/// Care due today (or overdue) and orders from the last two weeks.
List<AppNotification> currentNotifications({DateTime? now}) {
  final at = now ?? DateTime.now();
  return [
    for (final task in careSchedule.dueTasks(now: at))
      if (!task.due.isAfter(at))
        AppNotification(
          icon: task.plan.kind.icon,
          title: task.title,
          body:
              task.plan.note ??
              '${task.plant.room} · ${formatDue(task.due, now: at)}',
          at: task.due,
          route: AppRoutes.plantPath(task.plant.id),
        ),
    for (final order in orderHistory.orders)
      if (order.placedAt != null && at.difference(order.placedAt!).inDays < 14)
        AppNotification(
          icon: LucideIcons.package,
          title: trArgs('Order {0} · {1}', [
            order.number,
            order.status(now: at).tr,
          ]),
          body: trArgs('{0} {1} on the way to {2}.', [
            order.itemCount,
            order.itemCount == 1 ? 'item'.tr : 'items'.tr,
            order.address?.city ?? 'you',
          ]),
          at: order.placedAt!,
          route: AppRoutes.orderPath(order.number!),
        ),
  ]..sort((a, b) => b.at.compareTo(a.at));
}

/// True when something arrived after the inbox was last opened.
bool hasUnreadNotifications({DateTime? now}) {
  final seen = appSettings.notificationsSeenAt;
  final items = currentNotifications(now: now);
  if (seen == null) return items.isNotEmpty;
  return items.any((n) => n.at.isAfter(seen));
}

/// In-app inbox: care due today and recent orders.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

/// Remembers when the inbox was last opened, to highlight new entries.
class _NotificationsPageState extends State<NotificationsPage> {
  static DateFormat get _time => appDate('MMM d · h:mm a');
  late final DateTime? _seenBefore = appSettings.notificationsSeenAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => appSettings.markNotificationsSeen(),
    );
  }

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
              title: 'Notifications'.tr,
              actionIcon: LucideIcons.settings2,
              onBack: () => Navigator.of(context).maybePop(),
              onMore: () => pushRoot(context, AppRoutes.privacy),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([careSchedule, orderHistory]),
                builder: (context, _) {
                  final items = currentNotifications();
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.bellOff,
                            size: 36,
                            color: scheme.primary,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'All quiet in the greenhouse.'.tr,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 23,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Care reminders and order updates will show up here.'
                                .tr,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ScrollViewNoStretch(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final n in items) ...[
                          _NotificationTile(
                            notification: n,
                            unread:
                                _seenBefore == null ||
                                n.at.isAfter(_seenBefore),
                            timeLabel: _time.format(n.at),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One entry of the inbox.
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.unread,
    required this.timeLabel,
  });

  final AppNotification notification;
  final bool unread;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
          onTap: () => pushRoot(context, notification.route),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notification.icon,
                    size: 18,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          if (unread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: scheme.tertiary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          height: 1.45,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
