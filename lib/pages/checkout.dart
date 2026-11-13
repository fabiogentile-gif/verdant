import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/cart.dart';
import 'package:verdant/data/payment.dart';
import 'package:verdant/data/product_repository.dart';
import 'package:verdant/router/router.dart';
import 'package:verdant/shell.dart';
import 'package:verdant/utils/money.dart';
import 'package:verdant/widgets/checkout/add_payment_sheet.dart';
import 'package:verdant/widgets/components/detail_header.dart';
import 'package:verdant/widgets/components/scrollview_list.dart';

/// "Arrives Nov 10–12" style label for a shipping option.
String _arrivalLabel(ShippingOption option, {DateTime? from}) {
  final today = from ?? DateTime.now();
  final start = today.add(Duration(days: option.minDays));
  final end = today.add(Duration(days: option.maxDays));
  final month = DateFormat('MMM', 'en_US');
  final range = start.month == end.month
      ? '${month.format(start)} ${start.day}–${end.day}'
      : '${month.format(start)} ${start.day} – ${month.format(end)} ${end.day}';
  return 'Arrives $range';
}

/// Checkout screen (Figma: Checkout). Payment is simulated.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _placing = false;

  Future<void> _addPaymentMethod() async {
    await showAddPaymentSheet(context);
  }

  Future<void> _changePaymentMethod() async {
    if (wallet.methods.isEmpty) return _addPaymentMethod();
    final addNew = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _ChoosePaymentSheet(),
    );
    if (addNew == true && mounted) await _addPaymentMethod();
  }

  Future<void> _placeOrder() async {
    final method = wallet.selected;
    if (method == null) {
      await _addPaymentMethod();
      return;
    }

    setState(() => _placing = true);
    final summary = OrderSnapshot.fromCart(method);
    final orderNumber = await processDemoPayment(
      method: method,
      amount: summary.total,
    );
    if (!mounted) return;

    cart.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            OrderConfirmationPage(orderNumber: orderNumber, summary: summary),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DetailHeader(
              title: 'Checkout',
              actionIcon: LucideIcons.lockKeyhole,
              onBack: () => Navigator.of(context).maybePop(),
              onMore: () {},
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([cart, wallet]),
                builder: (context, _) {
                  if (cart.isEmpty) {
                    return const Center(child: Text('Your cart is empty.'));
                  }
                  return ScrollViewNoStretch(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Introduction(),
                        const SizedBox(height: 26),
                        const _DeliveryAddress(),
                        const SizedBox(height: 26),
                        // Not const: these read `cart`/`wallet` and must rebuild.
                        _ShippingOptions(),
                        const SizedBox(height: 26),
                        _PaymentChoice(
                          onChange: _changePaymentMethod,
                          onAdd: _addPaymentMethod,
                        ),
                        const SizedBox(height: 26),
                        _OrderSummary(),
                        const SizedBox(height: 26),
                        _PurchaseAction(
                          total: cart.total,
                          enabled: wallet.selected != null,
                          loading: _placing,
                          onPressed: _placeOrder,
                        ),
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

// ---------------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------------

class _Introduction extends StatelessWidget {
  const _Introduction();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THE LAST LITTLE STEP',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.8,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'On their way to you.',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontFamily: 'Lora',
            fontSize: 31,
            height: 1.15,
            letterSpacing: -0.7,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Review your details and let the growing begin.',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 13,
            height: 1.5,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title, {this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: 'Lora',
              fontSize: 23,
              letterSpacing: -0.5,
              fontWeight: FontWeight.w400,
              color: scheme.onSurface,
            ),
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: theme.textTheme.labelMedium?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DeliveryAddress extends StatelessWidget {
  const _DeliveryAddress();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      fontSize: 13,
      height: 1.6,
      color: scheme.onSurfaceVariant,
    );

    // Saved address is static until user profiles exist.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(
          'Delivery address',
          actionLabel: 'Edit →',
          onAction: () {},
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.mapPin, size: 20, color: scheme.onSurface),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maya Thompson',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '124 Maple Street, Apt 3B\n'
                      'Portland, OR 97205\n'
                      'United States',
                      style: muted,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '+1 (503) 555-0148',
                      style: muted?.copyWith(fontSize: 12, height: null),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'HOME',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Icon(LucideIcons.mail, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Updates to maya.thompson@email.com',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShippingOptions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeading('A gentle journey'),
        for (final option in ShippingOption.values) ...[
          const SizedBox(height: 12),
          _ShippingTile(option: option),
        ],
      ],
    );
  }
}

class _ShippingTile extends StatelessWidget {
  const _ShippingTile({required this.option});

  final ShippingOption option;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = cart.shipping == option;
    final fee = cart.feeFor(option);
    final details = [_arrivalLabel(option), ?option.note].join(' · ');

    return _SelectableCard(
      selected: selected,
      selectedColor: scheme.primaryContainer,
      onTap: () => cart.shipping = option,
      child: Row(
        children: [
          _RadioDot(selected: selected),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            fee == 0 ? 'Free' : formatMoney(fee),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentChoice extends StatelessWidget {
  const _PaymentChoice({required this.onChange, required this.onAdd});

  final VoidCallback onChange;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final method = wallet.selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(
          'Payment',
          actionLabel: method == null ? null : 'Change →',
          onAction: onChange,
        ),
        const SizedBox(height: 12),
        if (method != null)
          _PaymentTile(method: method, selected: true, onTap: onChange)
        else
          _SelectableCard(
            selected: false,
            onTap: onAdd,
            child: Row(
              children: [
                Icon(LucideIcons.creditCard, size: 20, color: scheme.onSurface),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add a card or PayPal to place your order.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(LucideIcons.plus, size: 16, color: scheme.primary),
              ],
            ),
          ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onAdd,
          child: Text(
            method == null
                ? '+ Add a payment method'
                : '+ Add a different payment method',
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: scheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return _SelectableCard(
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          _RadioDot(selected: selected),
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
              method.badge,
              style: TextStyle(
                fontSize: method is PayPalPayment ? 8 : 10,
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
                  method.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  method.subtitle,
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
          const SizedBox(width: 12),
          Icon(LucideIcons.lockKeyhole, size: 16, color: scheme.onSurface),
        ],
      ),
    );
  }
}

class _ChoosePaymentSheet extends StatelessWidget {
  const _ChoosePaymentSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: wallet,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SectionHeading('Pay with'),
            for (final m in wallet.methods) ...[
              const SizedBox(height: 12),
              _PaymentTile(
                method: m,
                selected: m.id == wallet.selected?.id,
                onTap: () {
                  wallet.select(m.id);
                  Navigator.of(context).pop(false);
                },
              ),
            ],
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: Icon(LucideIcons.plus, size: 16, color: scheme.primary),
              label: Text(
                'Add a different payment method',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: scheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Snapshot of an order, kept for the confirmation screen after the
/// cart has been emptied.
class OrderSnapshot {
  const OrderSnapshot({
    required this.items,
    required this.subtotal,
    required this.discountLabel,
    required this.discountAmount,
    required this.shipping,
    required this.delivery,
    required this.total,
    required this.paymentTitle,
  });

  factory OrderSnapshot.fromCart([PaymentMethod? method]) => OrderSnapshot(
    items: cart.items,
    subtotal: cart.subtotal,
    discountLabel: cart.discount?.shortLabel,
    discountAmount: cart.discountAmount,
    shipping: cart.shipping,
    delivery: cart.delivery,
    total: cart.total,
    paymentTitle: method?.title,
  );

  final List<CartItem> items;
  final double subtotal;
  final String? discountLabel;
  final double discountAmount;
  final ShippingOption shipping;
  final double delivery;
  final double total;
  final String? paymentTitle;
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({this.data, this.title = 'Your green delivery'});

  /// Defaults to the live cart.
  final OrderSnapshot? data;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final d = data ?? OrderSnapshot.fromCart();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeading(title),
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

class _PurchaseAction extends StatelessWidget {
  const _PurchaseAction({
    required this.total,
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  final double total;
  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: enabled && !loading ? onPressed : null,
          icon: loading
              ? SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.surfaceContainerLow,
                  ),
                )
              : const Icon(LucideIcons.arrowRight, size: 18),
          label: Text(
            loading
                ? 'Processing payment…'
                : 'Place order · ${formatMoney(total)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.surfaceContainerLow,
            disabledBackgroundColor: scheme.primary.withValues(alpha: 0.5),
            disabledForegroundColor: scheme.surfaceContainerLow,
            minimumSize: const Size.fromHeight(52),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'By placing your order, you agree to our Terms & Returns. '
          'Your plants are covered by our 30-day happiness promise.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            height: 1.6,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared controls
// ---------------------------------------------------------------------------

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.selected,
    required this.onTap,
    required this.child,
    this.selectedColor,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? (selectedColor ?? scheme.surface) : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(17), child: child),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: scheme.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 6 : 1.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confirmation
// ---------------------------------------------------------------------------

/// Shown after a (simulated) successful payment.
class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({
    super.key,
    required this.orderNumber,
    required this.summary,
  });

  final String orderNumber;
  final OrderSnapshot summary;

  void _done(BuildContext context, String tab) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    AppShell.globalKey.currentState?.goTotab(tab);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _done(context, AppRoutes.homepage);
      },
      child: Scaffold(
        body: SafeArea(
          child: ScrollViewNoStretch(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.circleCheck,
                      size: 30,
                      color: scheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'ORDER $orderNumber',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.8,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Thank you. Growing soon.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontFamily: 'Lora',
                    fontSize: 31,
                    height: 1.15,
                    letterSpacing: -0.7,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_arrivalLabel(summary.shipping)} · '
                  'we’ll email maya.thompson@email.com along the way.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    height: 1.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 26),
                _OrderSummary(data: summary, title: 'Your order'),
                const SizedBox(height: 26),
                FilledButton(
                  onPressed: () => _done(context, AppRoutes.homepage),
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
                    'Back to home',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => _done(context, AppRoutes.greenhouse),
                  child: Text(
                    'Keep exploring the greenhouse',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSecondaryContainer,
                    ),
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
