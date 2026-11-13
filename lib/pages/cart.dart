import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/cart.dart';
import 'package:verdant/data/product_repository.dart';
import 'package:verdant/router/router.dart';
import 'package:verdant/shell.dart';
import 'package:verdant/utils/money.dart';
import 'package:verdant/widgets/components/detail_header.dart';
import 'package:verdant/widgets/components/scrollview_list.dart';

/// "Your cart" screen (Figma: Shopping cart).
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  void _backToGreenhouse(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    AppShell.globalKey.currentState?.goTotab(AppRoutes.greenhouse);
  }

  void _checkout(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.checkout);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DetailHeader(
              title: 'Your cart',
              actionIcon: LucideIcons.shoppingBag,
              onBack: () => Navigator.of(context).maybePop(),
              onMore: () {},
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: cart,
                builder: (context, _) => cart.isEmpty
                    ? _EmptyCart(onBrowse: () => _backToGreenhouse(context))
                    : ScrollViewNoStretch(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Introduction(count: cart.itemCount),
                            const SizedBox(height: 24),
                            // Not const: these read `cart` and must rebuild.
                            _ShippingIncentive(),
                            const SizedBox(height: 24),
                            for (final item in cart.items) ...[
                              _CartItemCard(item: item),
                              const SizedBox(height: 12),
                            ],
                            const SizedBox(height: 12),
                            _DiscountCode(),
                            const SizedBox(height: 24),
                            _OrderTotals(),
                            const SizedBox(height: 24),
                            _CartActions(
                              onCheckout: () => _checkout(context),
                              onBack: () => _backToGreenhouse(context),
                            ),
                          ],
                        ),
                      ),
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
  const _Introduction({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good things, growing.',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontFamily: 'Lora',
            fontSize: 32,
            height: 1.15,
            letterSpacing: -0.7,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$count lovely ${count == 1 ? 'addition' : 'additions'} '
          'to your green space.',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            height: 1.5,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ShippingIncentive extends StatelessWidget {
  const _ShippingIncentive();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final message = cart.hasFreeDelivery
        ? 'Your delivery is on us.'
        : 'You’re ${formatCompactMoney(cart.amountToFreeDelivery)} away '
              'from free delivery.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.truck,
                size: 18,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: cart.freeDeliveryProgress,
              minHeight: 4,
              backgroundColor: scheme.surface,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Based on your ${formatCompactMoney(cart.subtotal)} '
            'merchandise subtotal.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 88,
              height: 112,
              color: scheme.surfaceContainer,
              child: item.image.isEmpty
                  ? Icon(LucideIcons.sprout, color: scheme.onSurfaceVariant)
                  : Image(
                      image: imageFor(item.image),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        LucideIcons.sprout,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _IconTap(
                      icon: LucideIcons.x,
                      size: 14,
                      semanticLabel: 'Remove ${item.name}',
                      onTap: () => cart.remove(item.productId),
                    ),
                  ],
                ),
                if (item.variant != null) ...[
                  const SizedBox(height: 9),
                  Text(
                    item.variant!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 9),
                Row(
                  children: [
                    _QuantitySelector(item: item),
                    const Spacer(),
                    Text(
                      formatMoney(item.total),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final q = item.quantity;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconTap(
            icon: LucideIcons.minus,
            size: 14,
            semanticLabel: 'Decrease quantity',
            enabled: q > 1,
            onTap: () => cart.setQuantity(item.productId, q - 1),
          ),
          const SizedBox(width: 17),
          Text(
            '$q',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(width: 17),
          _IconTap(
            icon: LucideIcons.plus,
            size: 14,
            semanticLabel: 'Increase quantity',
            enabled: q < Cart.maxQuantity,
            onTap: () => cart.setQuantity(item.productId, q + 1),
          ),
        ],
      ),
    );
  }
}

class _DiscountCode extends StatefulWidget {
  const _DiscountCode();

  @override
  State<_DiscountCode> createState() => _DiscountCodeState();
}

class _DiscountCodeState extends State<_DiscountCode> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final code = _controller.text;
    if (code.trim().isEmpty) return;
    final ok = cart.applyDiscount(code);
    setState(() => _error = ok ? null : 'That code doesn’t look right.');
    if (ok) {
      _controller.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final applied = cart.discount;

    final actionStyle = theme.textTheme.labelMedium?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: scheme.primary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _error != null ? scheme.error : scheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.ticketPercent,
                size: 18,
                color: scheme.onSurface,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: applied != null
                    ? Text(
                        applied.code,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: scheme.onSurface,
                        ),
                      )
                    : TextField(
                        controller: _controller,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _apply(),
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: scheme.onSurface,
                        ),
                        cursorColor: scheme.primary,
                        decoration: InputDecoration(
                          isDense: true,
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: 'Discount code',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              if (applied != null) ...[
                Text('Applied', style: actionStyle),
                const SizedBox(width: 10),
                _IconTap(
                  icon: LucideIcons.x,
                  size: 14,
                  semanticLabel: 'Remove discount code',
                  onTap: cart.removeDiscount,
                ),
              ] else
                GestureDetector(
                  onTap: _apply,
                  child: Text('Apply', style: actionStyle),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _error ?? 'A greener welcome: 10% off your first order.',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            height: 1.5,
            color: _error != null ? scheme.error : scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _OrderTotals extends StatelessWidget {
  const _OrderTotals();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final count = cart.itemCount;
    final discount = cart.discount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryRow(
          label: 'Subtotal · $count ${count == 1 ? 'item' : 'items'}',
          value: formatMoney(cart.subtotal),
        ),
        if (discount != null) ...[
          const SizedBox(height: 15),
          _SummaryRow(
            label: discount.label,
            value: '−${formatMoney(cart.discountAmount)}',
          ),
        ],
        const SizedBox(height: 15),
        _SummaryRow(
          label: cart.shipping.label,
          value: cart.delivery == 0 ? 'Free' : formatMoney(cart.delivery),
        ),
        const SizedBox(height: 15),
        Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Total',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            Text(
              formatMoney(cart.total),
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 21,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          'All prices in USD. Applicable taxes included.',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            height: 1.5,
            color: scheme.onSurfaceVariant,
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

class _CartActions extends StatelessWidget {
  const _CartActions({required this.onCheckout, required this.onBack});

  final VoidCallback onCheckout;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: onCheckout,
          icon: const Icon(LucideIcons.arrowRight, size: 18),
          label: const Text(
            'Continue to checkout',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.surfaceContainerLow,
            minimumSize: const Size.fromHeight(52),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.shieldCheck,
              size: 15,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 7),
            Text(
              'Secure checkout. Happy plants, guaranteed.',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: onBack,
          child: Text(
            '← Back to the greenhouse',
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSecondaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(LucideIcons.shoppingBag, size: 40, color: scheme.primary),
          const SizedBox(height: 16),
          Text(
            'Your cart is resting.',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFamily: 'Lora',
              fontSize: 26,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find a new green companion in the greenhouse.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onBrowse,
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
        ],
      ),
    );
  }
}

/// Small tappable icon with a comfortable hit area.
class _IconTap extends StatelessWidget {
  const _IconTap({
    required this.icon,
    required this.size,
    required this.semanticLabel,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final double size;
  final String semanticLabel;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Icon(
          icon,
          size: size,
          color: enabled ? scheme.onSurface : scheme.outlineVariant,
        ),
      ),
    );
  }
}

/// Confirms an add-to-cart with a snackbar that links to the cart.
void showAddedToCart(BuildContext context, String productName) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('$productName added to your cart.'),
        action: SnackBarAction(
          label: 'View cart',
          onPressed: () => Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamed(AppRoutes.cart),
        ),
      ),
    );
}
