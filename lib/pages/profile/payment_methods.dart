import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/payment.dart';
import 'package:verdant/widgets/checkout/add_payment_sheet.dart';
import 'package:verdant/widgets/components/subpage_scaffold.dart';

/// Saved (demo) payment methods: choose the default, remove, add.
class PaymentMethodsPage extends StatelessWidget {
  const PaymentMethodsPage({super.key});

  Future<void> _remove(BuildContext context, PaymentMethod m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${m.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) wallet.remove(m.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: wallet,
      builder: (context, _) {
        final methods = wallet.methods;
        final selectedId = wallet.selected?.id;
        return SubpageScaffold(
          title: 'Payment methods',
          actionIcon: LucideIcons.plus,
          onAction: () => showAddPaymentSheet(context),
          heading: 'Pay your way.',
          lede:
              'Demo checkout: cards are checked but never charged, and only '
              'the last 4 digits are kept.',
          children: [
            if (methods.isEmpty)
              Text(
                'No payment methods yet.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            for (final m in methods) ...[
              SoftCard(
                onTap: () => wallet.select(m.id),
                padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                child: Row(
                  children: [
                    Icon(
                      m.id == selectedId
                          ? LucideIcons.circleCheck
                          : LucideIcons.circle,
                      size: 20,
                      color: m.id == selectedId
                          ? scheme.primary
                          : scheme.outlineVariant,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 42,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Text(
                        m.badge,
                        style: TextStyle(
                          fontSize: m is PayPalPayment ? 8 : 10,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m.id == selectedId
                                ? '${m.subtitle} · Default'
                                : m.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: () => _remove(context, m),
                      icon: Icon(
                        LucideIcons.trash2,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => showAddPaymentSheet(context),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text(
                'Add a payment method',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onSecondaryContainer,
                minimumSize: const Size.fromHeight(50),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
