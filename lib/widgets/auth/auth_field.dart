import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/l10n/i18n.dart';

/// Labelled text field of the account forms, with an optional show/hide
/// control for passwords and an error coming from the server.
class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.errorText,
    this.keyboardType,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.next,
    this.isPassword = false,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final String? errorText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final bool isPassword;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _visible = false;

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
            widget.label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 9),
          TextFormField(
            controller: widget.controller,
            validator: widget.validator,
            keyboardType: widget.keyboardType,
            autofillHints: widget.autofillHints,
            textCapitalization: widget.textCapitalization,
            textInputAction: widget.textInputAction,
            obscureText: widget.isPassword && !_visible,
            autocorrect: !widget.isPassword,
            enableSuggestions: !widget.isPassword,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: scheme.onSurface,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: scheme.surface,
              isDense: true,
              errorText: widget.errorText,
              errorMaxLines: 2,
              contentPadding: const EdgeInsets.all(15),
              border: border(scheme.outlineVariant),
              enabledBorder: border(scheme.outlineVariant),
              focusedBorder: border(scheme.primary),
              errorBorder: border(scheme.error),
              focusedErrorBorder: border(scheme.error),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      tooltip: _visible
                          ? 'Hide password'.tr
                          : 'Show password'.tr,
                      onPressed: () => setState(() => _visible = !_visible),
                      icon: Icon(
                        _visible ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Main action of the account forms, with a loading state.
class AuthButton extends StatelessWidget {
  const AuthButton({
    super.key,
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
        disabledBackgroundColor: scheme.primary.withValues(alpha: 0.5),
        disabledForegroundColor: scheme.surfaceContainerLow,
        minimumSize: const Size.fromHeight(52),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: loading
          ? SizedBox.square(
              dimension: 18,
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
