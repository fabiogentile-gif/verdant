import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/orders.dart';
import 'package:verdant/pages/not_found.dart';
import 'package:verdant/router/router.dart';
import 'package:verdant/utils/money.dart';
import 'package:verdant/widgets/checkout/order_summary_card.dart';
import 'package:verdant/widgets/components/subpage_scaffold.dart';

final _date = DateFormat('MMM d, y', 'en_US');
final _short = DateFormat('MMM d', 'en_US');

/// "Nov 10–12" or "Nov 30 – Dec 2" for the expected delivery window.
String _arrival(Order o) {
  final (from, to) = o.arrivalWindow;
  return from.month == to.month
      ? '${_short.format(from)}–${to.day}'
      : '${_short.format(from)} – ${_short.format(to)}';
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
          title: 'My orders',
          actionIcon: LucideIcons.shoppingBag,
          onAction: () => goToTab(context, AppRoutes.greenhouse),
          heading: 'Good things, delivered.',
          lede: orders.isEmpty
              ? 'Your orders will appear here once you check out.'
              : 'Track deliveries and revisit what you’ve grown.',
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
                child: const Text(
                  'Browse the greenhouse',
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
                            'Order ${o.number}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_date.format(o.placedAt!)} · ${o.itemCount} '
                            '${o.itemCount == 1 ? 'item' : 'items'} · '
                            '${formatMoney(o.total)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            o.status() == 'Delivered'
                                ? 'Delivered'
                                : '${o.status()} · arrives ${_arrival(o)}',
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
      return const NotFoundPage(
        title: 'We can’t find this order.',
        message: 'It may have been placed on another device.',
      );
    }
    final o = order;
    final address = o.address;

    return SubpageScaffold(
      title: 'Order ${o.number}',
      actionIcon: LucideIcons.package,
      heading: o.status() == 'Delivered' ? 'Delivered.' : 'On its way soon.',
      lede:
          'Placed ${_date.format(o.placedAt!)} · ${o.shipping.label} · '
          'arrives ${_arrival(o)}.',
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
        OrderSummaryCard(data: o, title: 'What’s inside'),
        const SizedBox(height: 12),
        Text(
          'Demo order: no real payment was made and nothing will ship.',
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
