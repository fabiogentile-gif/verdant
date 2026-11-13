import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/payment.dart';
import 'package:verdant/widgets/components/filter_chip.dart';

/// Opens the "add payment method" sheet. Resolves to the saved method,
/// or null when the sheet is dismissed.
Future<PaymentMethod?> showAddPaymentSheet(BuildContext context) {
  return showModalBottomSheet<PaymentMethod>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _AddPaymentSheet(),
  );
}

enum _Kind { card, paypal }

class _AddPaymentSheet extends StatefulWidget {
  const _AddPaymentSheet();

  @override
  State<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<_AddPaymentSheet> {
  _Kind _kind = _Kind.card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add a payment method',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFamily: 'Lora',
                fontSize: 23,
                letterSpacing: -0.5,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Demo checkout: no real payment is made.',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                AppFilterChip(
                  label: 'Card',
                  leadingIcon: LucideIcons.creditCard,
                  selected: _kind == _Kind.card,
                  onTap: () => setState(() => _kind = _Kind.card),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'PayPal',
                  leadingIcon: LucideIcons.wallet,
                  selected: _kind == _Kind.paypal,
                  onTap: () => setState(() => _kind = _Kind.paypal),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_kind == _Kind.card) const _CardForm() else const _PayPalForm(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card
// ---------------------------------------------------------------------------

class _CardForm extends StatefulWidget {
  const _CardForm();

  @override
  State<_CardForm> createState() => _CardFormState();
}

class _CardFormState extends State<_CardForm> {
  final _formKey = GlobalKey<FormState>();
  final _holder = TextEditingController();
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvc = TextEditingController();
  CardBrand _brand = CardBrand.unknown;

  @override
  void initState() {
    super.initState();
    _number.addListener(() {
      final brand = CardBrand.detect(_number.text);
      if (brand != _brand) setState(() => _brand = brand);
    });
  }

  @override
  void dispose() {
    _holder.dispose();
    _number.dispose();
    _expiry.dispose();
    _cvc.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final card = wallet.addCard(
      holder: _holder.text,
      number: _number.text,
      expiry: _expiry.text,
      cvc: _cvc.text,
    );
    Navigator.of(context).pop(card);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Field(
            label: 'Name on card',
            controller: _holder,
            hint: 'Maya Thompson',
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.creditCardName],
            validator: (v) => CardValidator.holder(v ?? ''),
          ),
          const SizedBox(height: 14),
          _Field(
            label: 'Card number',
            controller: _number,
            hint: '4242 4242 4242 4242',
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.creditCardNumber],
            inputFormatters: [_CardNumberFormatter()],
            trailing: _BrandBadge(_brand.badge),
            validator: (v) => CardValidator.number(v ?? ''),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Field(
                  label: 'Expiry',
                  controller: _expiry,
                  hint: 'MM/YY',
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.creditCardExpirationDate],
                  inputFormatters: [_ExpiryFormatter()],
                  validator: (v) => CardValidator.expiry(v ?? ''),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                  label: 'Security code',
                  controller: _cvc,
                  hint: _brand == CardBrand.amex ? '1234' : '123',
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  autofillHints: const [AutofillHints.creditCardSecurityCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (v) => CardValidator.cvc(v ?? '', _brand),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _Note(
            'Try 4242 4242 4242 4242 with any future date. '
            'Only the last 4 digits are kept.',
          ),
          const SizedBox(height: 20),
          _PrimaryButton(label: 'Save card', onPressed: _save),
        ],
      ),
    );
  }
}

/// Digits only, grouped 4-4-4-4 (4-6-5 for Amex).
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final brand = CardBrand.detect(newValue.text);
    var digits = digitsOnly(newValue.text);
    if (digits.length > brand.numberLength) {
      digits = digits.substring(0, brand.numberLength);
    }
    final groups = brand == CardBrand.amex
        ? const [4, 6, 5]
        : const [4, 4, 4, 4];
    final buffer = StringBuffer();
    var i = 0;
    for (final size in groups) {
      if (i >= digits.length) break;
      if (buffer.isNotEmpty) buffer.write(' ');
      final end = (i + size).clamp(0, digits.length);
      buffer.write(digits.substring(i, end));
      i = end;
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// `MMYY` → `MM/YY`.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = digitsOnly(newValue.text);
    if (digits.length > 4) digits = digits.substring(0, 4);
    final deleting = newValue.text.length < oldValue.text.length;
    final text = digits.length > 2 || (digits.length == 2 && !deleting)
        ? '${digits.substring(0, 2)}/${digits.substring(2)}'
        : digits;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// ---------------------------------------------------------------------------
// PayPal (fake login)
// ---------------------------------------------------------------------------

class _PayPalForm extends StatefulWidget {
  const _PayPalForm();

  @override
  State<_PayPalForm> createState() => _PayPalFormState();
}

class _PayPalFormState extends State<_PayPalForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final account = await wallet.connectPayPal(
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) return;
    Navigator.of(context).pop(account);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Field(
            label: 'PayPal email',
            controller: _email,
            hint: 'you@email.com',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            enabled: !_loading,
            validator: (v) => PayPalValidator.email(v ?? ''),
          ),
          const SizedBox(height: 14),
          _Field(
            label: 'Password',
            controller: _password,
            obscureText: true,
            enabled: !_loading,
            validator: (v) => PayPalValidator.password(v ?? ''),
          ),
          const SizedBox(height: 10),
          const _Note(
            'Simulated login: any email and password work, '
            'and the password is never stored.',
          ),
          const SizedBox(height: 20),
          _PrimaryButton(
            label: 'Log in with PayPal',
            loading: _loading,
            onPressed: _connect,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.validator,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.enabled = true,
    this.trailing,
  });

  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final bool enabled;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 9),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          autofillHints: autofillHints,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          enabled: enabled,
          autocorrect: false,
          enableSuggestions: !obscureText,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            color: scheme.onSurface,
          ),
          cursorColor: scheme.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            filled: true,
            fillColor: scheme.surface,
            isDense: true,
            contentPadding: const EdgeInsets.all(15),
            suffixIcon: trailing == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: trailing,
                  ),
            suffixIconConstraints: const BoxConstraints(minHeight: 30),
            errorStyle: TextStyle(fontSize: 11, color: scheme.error),
            border: border(scheme.outlineVariant),
            enabledBorder: border(scheme.outlineVariant),
            disabledBorder: border(scheme.outlineVariant),
            focusedBorder: border(scheme.primary),
            errorBorder: border(scheme.error),
            focusedErrorBorder: border(scheme.error),
          ),
        ),
      ],
    );
  }
}

class _BrandBadge extends StatelessWidget {
  const _BrandBadge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 42,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          LucideIcons.info,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.surfaceContainerLow,
        disabledBackgroundColor: scheme.primary.withValues(alpha: 0.6),
        minimumSize: const Size.fromHeight(52),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: loading
          ? SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.surfaceContainerLow,
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
    );
  }
}
