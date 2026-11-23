import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/orders.dart';
import 'package:verdant/pages/not_found.dart';
import 'package:verdant/router/router.dart';
import 'package:verdant/utils/money.dart';
import 'package:verdant/widgets/checkout/order_summary_card.dart';
import 'package:verdant/widgets/components/subpage_scaffold.dart';
import 'package:verdant/l10n/i18n.dart';

DateFormat get _date => appDate('MMM d, y');

/// "Nov 10–12" or "Nov 30 – Dec 2" for the expected delivery window.
String _arrival(Order o) {
  final (from, to) = o.arrivalWindow;
  return formatDateRange(from, to);
}

/// List of the orders placed on this device.
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: orderHistory,
      builder: (context, _) {
        final orders = orderHistory.orders;
        return SubpageScaffold(
          title: 'My orders'.tr,
          actionIcon: LucideIcons.shoppingBag,
          onAction: () => goToTab(context, AppRoutes.greenhouse),
          heading: 'Good things, delivered.'.tr,
          lede: orders.isEmpty
              ? 'Your orders will appear here once you check out.'.tr
              : 'Track deliveries and revisit what you’ve grown.'.tr,
          children: [
            if (orders.isEmpty)
              FilledButton(
                onPressed: () => goToTab(context, AppRoutes.greenhouse),
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.surfaceContainerLow,
                  minimumSize: const Size.fromHeight(52),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Browse the greenhouse'.tr,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            for (final o in orders) ...[
              SoftCard(
                onTap: () => pushRoot(context, AppRoutes.orderPath(o.number!)),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.package,
                        size: 20,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trArgs('Order {0}', [o.number]),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_date.format(o.placedAt!)} · ${o.itemCount} '
                            '${o.itemCount == 1 ? 'item'.tr : 'items'.tr} · '
                            '${formatMoney(o.total)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            {
                                  'Delivered'.tr,
                                  'Cancelled'.tr,
                                }.contains(o.status())
                                ? o.status().tr
                                : trArgs('{0} · arrives {1}', [
                                    o.status().tr,
                                    _arrival(o),
                                  ]),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

/// Items, totals, address and payment of one order.
class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key, required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Order? order;
    for (final o in orderHistory.orders) {
      if (o.number == number) order = o;
    }
    if (order == null) {
      return NotFoundPage(
        title: 'We can’t find this order.'.tr,
        message: 'It may have been placed on another device.'.tr,
      );
    }
    final o = order;
    final address = o.address;

    return SubpageScaffold(
      title: trArgs('Order {0}', [o.number]),
      actionIcon: LucideIcons.package,
      heading: switch (o.status()) {
        'Delivered' => 'Delivered.'.tr,
        'Cancelled' => 'Cancelled.'.tr,
        'On its way' => 'On its way.'.tr,
        _ => 'On its way soon.'.tr,
      },
      lede: o.status() == 'Cancelled'
          ? trArgs('Placed {0} · {1}.', [
              _date.format(o.placedAt!),
              o.shipping.label,
            ])
          : trArgs('Placed {0} · {1} · arrives {2}.', [
              _date.format(o.placedAt!),
              o.shipping.label,
              _arrival(o),
            ]),
      children: [
        if (address != null) ...[
          SoftCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.mapPin, size: 20, color: scheme.onSurface),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${address.fullName}\n${address.lines}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      height: 1.6,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        OrderSummaryCard(data: o, title: 'What’s inside'.tr),
        const SizedBox(height: 12),
        Text(
          'Demo order: no real payment was made and nothing will ship.'.tr,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
