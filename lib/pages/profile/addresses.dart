import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/address.dart';
import 'package:verdant/widgets/components/subpage_scaffold.dart';

/// Edit the saved delivery address (used at checkout).
class AddressPage extends StatefulWidget {
  const AddressPage({super.key});

  @override
  State<AddressPage> createState() => _AddressPageState();
}

/// Form controllers and validation for the address.
class _AddressPageState extends State<AddressPage> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  late String _label;

  static const _labels = ['Home', 'Work', 'Other'];

  @override
  void initState() {
    super.initState();
    final a = addressBook.address;
    _label = a.label;
    _fields = {
      'fullName': TextEditingController(text: a.fullName),
      'street': TextEditingController(text: a.street),
      'city': TextEditingController(text: a.city),
      'postalCode': TextEditingController(text: a.postalCode),
      'country': TextEditingController(text: a.country),
      'phone': TextEditingController(text: a.phone),
      'email': TextEditingController(text: a.email),
    };
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _v(String key) => _fields[key]!.text.trim();

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    addressBook.address = DeliveryAddress(
      fullName: _v('fullName'),
      street: _v('street'),
      city: _v('city'),
      postalCode: _v('postalCode'),
      country: _v('country'),
      phone: _v('phone'),
      email: _v('email'),
      label: _label,
    );
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).maybePop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Delivery address saved.')),
    );
  }

  String? _required(String? v, String message) =>
      (v ?? '').trim().isEmpty ? message : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SubpageScaffold(
      title: 'Saved address',
      actionIcon: LucideIcons.mapPin,
      heading: 'Where should we deliver?',
      lede: 'Your plants will travel here. You can change it anytime.',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Field(
                label: 'Full name',
                controller: _fields['fullName']!,
                autofill: AutofillHints.name,
                validator: (v) => _required(v, 'Who will receive it?'),
              ),
              _Field(
                label: 'Street and number',
                controller: _fields['street']!,
                autofill: AutofillHints.streetAddressLine1,
                validator: (v) => _required(v, 'Add your street.'),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _Field(
                      label: 'City',
                      controller: _fields['city']!,
                      autofill: AutofillHints.addressCity,
                      validator: (v) => _required(v, 'Add your city.'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _Field(
                      label: 'Postal code',
                      controller: _fields['postalCode']!,
                      autofill: AutofillHints.postalCode,
                      validator: (v) => _required(v, 'Required.'),
                    ),
                  ),
                ],
              ),
              _Field(
                label: 'Country',
                controller: _fields['country']!,
                autofill: AutofillHints.countryName,
                validator: (v) => _required(v, 'Add your country.'),
              ),
              _Field(
                label: 'Phone',
                controller: _fields['phone']!,
                autofill: AutofillHints.telephoneNumber,
                keyboardType: TextInputType.phone,
                validator: (v) => _required(v, 'So the courier can reach you.'),
              ),
              _Field(
                label: 'Email for updates',
                controller: _fields['email']!,
                autofill: AutofillHints.email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch((v ?? '').trim())
                    ? null
                    : 'Enter a valid email address.',
              ),
              Text(
                'Label',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 9),
              SegmentedButton<String>(
                segments: [
                  for (final l in _labels)
                    ButtonSegment(value: l, label: Text(l)),
                ],
                selected: {_labels.contains(_label) ? _label : 'Other'},
                onSelectionChanged: (s) => setState(() => _label = s.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
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
                  'Save address',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Labelled text field of the address form.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.validator,
    this.autofill,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final String? autofill;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
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
            autofillHints: autofill == null ? null : [autofill!],
            textCapitalization: keyboardType == null
                ? TextCapitalization.words
                : TextCapitalization.none,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              color: scheme.onSurface,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: scheme.surface,
              isDense: true,
              contentPadding: const EdgeInsets.all(15),
              border: border(scheme.outlineVariant),
              enabledBorder: border(scheme.outlineVariant),
              focusedBorder: border(scheme.primary),
              errorBorder: border(scheme.error),
              focusedErrorBorder: border(scheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
