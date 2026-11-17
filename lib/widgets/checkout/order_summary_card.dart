import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/cart.dart';
import 'package:verdant/data/orders.dart';
import 'package:verdant/data/product_repository.dart';
import 'package:verdant/theme/theme.dart';
import 'package:verdant/utils/money.dart';

/// Items and totals of an order (the live cart by default).
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({
    super.key,
    this.data,
    this.title = 'Your green delivery',
  });

  /// Defaults to the live cart.
  final Order? data;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final d = data ?? Order.fromCart();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: AppShadows.cardSoft(scheme),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 23,
              letterSpacing: -0.5,
              fontWeight: FontWeight.w400,
              color: scheme.onSurface,
            ),
          ),
          for (final item in d.items) ...[
            const SizedBox(height: 16),
            _OrderItemRow(item: item),
          ],
          const SizedBox(height: 16),
          Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
          const SizedBox(height: 16),
          _SummaryRow(label: 'Subtotal', value: formatMoney(d.subtotal)),
          if (d.discountLabel != null) ...[
            const SizedBox(height: 16),
            _SummaryRow(
              label: d.discountLabel!,
              value: '−${formatMoney(d.discountAmount)}',
            ),
          ],
          const SizedBox(height: 16),
          _SummaryRow(
            label: d.shipping.label,
            value: d.delivery == 0 ? 'Free' : formatMoney(d.delivery),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total · USD',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              Text(
                formatMoney(d.total),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            d.paymentTitle == null
                ? 'Applicable taxes included.'
                : 'Paid with ${d.paymentTitle}. Applicable taxes included.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final placeholder = Icon(
      LucideIcons.sprout,
      size: 18,
      color: scheme.onSurfaceVariant,
    );

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 48,
            height: 48,
            color: scheme.surfaceContainer,
            child: item.image.isEmpty
                ? placeholder
                : Image(
                    image: imageFor(item.image),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => placeholder,
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Qty ${item.quantity}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          formatMoney(item.total),
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            color: scheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}
