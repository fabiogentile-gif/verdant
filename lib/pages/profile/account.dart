import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/api_client.dart';
import 'package:verdant/data/auth.dart';
import 'package:verdant/widgets/auth/auth_field.dart';
import 'package:verdant/widgets/components/subpage_scaffold.dart';
import 'package:verdant/l10n/i18n.dart';

/// Edit the profile, change the password or delete the account.
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _profileKey = GlobalKey<FormState>();
  final _passwordKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: authStore.user?.name);
  late final _location = TextEditingController(text: authStore.user?.location);
  final _current = TextEditingController();
  final _next = TextEditingController();

  bool _savingProfile = false;
  bool _savingPassword = false;
  String? _currentError;

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  void _say(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _saveProfile() async {
    if (!_profileKey.currentState!.validate()) return;
    setState(() => _savingProfile = true);
    try {
      await authStore.updateProfile(name: _name.text, location: _location.text);
      if (mounted) _say('Profile saved.'.tr);
    } on ApiException catch (e) {
      if (mounted) _say(e.message);
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _savePassword() async {
    setState(() => _currentError = null);
    if (!_passwordKey.currentState!.validate()) return;
    setState(() => _savingPassword = true);
    try {
      await authStore.changePassword(current: _current.text, next: _next.text);
      _current.clear();
      _next.clear();
      if (mounted) _say('Password changed. Other devices were signed out.'.tr);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.fields['currentPassword'] != null) {
        setState(() => _currentError = e.fields['currentPassword']);
      } else {
        _say(e.fields['newPassword'] ?? e.message);
      }
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _deleteAccount() async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _DeleteDialog(),
    );
    if (password == null || password.isEmpty || !mounted) return;
    try {
      await authStore.deleteAccount(password);
    } on ApiException catch (e) {
      if (mounted) _say(e.fields['currentPassword'] ?? e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sectionStyle = theme.textTheme.headlineSmall?.copyWith(
      fontSize: 23,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.5,
      color: scheme.onSurface,
    );

    return SubpageScaffold(
      title: 'Account & security'.tr,
      actionIcon: LucideIcons.userRound,
      heading: 'A little about you.'.tr,
      lede: trArgs('Signed in as {0}', [authStore.user?.email ?? '']),
      children: [
        Form(
          key: _profileKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthField(
                label: 'Your name'.tr,
                controller: _name,
                validator: AuthValidators.name,
                autofillHints: const [AutofillHints.name],
                textCapitalization: TextCapitalization.words,
              ),
              AuthField(
                label: 'Where you grow (optional)'.tr,
                controller: _location,
                autofillHints: const [AutofillHints.addressCity],
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
              ),
              AuthButton(
                label: 'Save profile'.tr,
                loading: _savingProfile,
                onPressed: _saveProfile,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text('Change password'.tr, style: sectionStyle),
        const SizedBox(height: 14),
        Form(
          key: _passwordKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthField(
                label: 'Current password'.tr,
                controller: _current,
                isPassword: true,
                validator: AuthValidators.password,
                errorText: _currentError,
                autofillHints: const [AutofillHints.password],
              ),
              AuthField(
                label: 'New password'.tr,
                controller: _next,
                isPassword: true,
                validator: AuthValidators.newPassword,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
              ),
              AuthButton(
                label: 'Update password'.tr,
                loading: _savingPassword,
                onPressed: _savePassword,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: _deleteAccount,
          icon: Icon(LucideIcons.trash2, size: 18, color: scheme.error),
          label: Text(
            'Delete my account'.tr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: scheme.error,
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            side: BorderSide(color: scheme.outlineVariant),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

/// Asks for the password before deleting the account.
class _DeleteDialog extends StatefulWidget {
  const _DeleteDialog();

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Delete your account?'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your plants, reminders, orders and saved details will be removed for good. Enter your password to confirm.'
                .tr,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(labelText: 'Password'.tr),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Keep my account'.tr),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_password.text),
          child: Text(
            'Delete'.tr,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }
}
