import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/api_client.dart';
import 'package:verdant/data/auth.dart';
import 'package:verdant/shell.dart';
import 'package:verdant/widgets/auth/auth_field.dart';
import 'package:verdant/l10n/i18n.dart';

/// Shows the app when signed in, the sign-in page otherwise.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    authStore.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    authStore.removeListener(_onAuthChanged);
    super.dispose();
  }

  /// Signed out (even from a pushed page): close everything above the gate.
  void _onAuthChanged() {
    if (!authStore.isSignedIn && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authStore,
      builder: (context, _) => authStore.isSignedIn
          ? AppShell(key: AppShell.globalKey)
          : const AuthPage(),
    );
  }
}

/// Sign in and create an account, on one page.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _registering = false;
  bool _loading = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _clearErrors() {
    if (_error == null && _fieldErrors.isEmpty) return;
    setState(() {
      _error = null;
      _fieldErrors = const {};
    });
  }

  void _toggleMode() {
    _formKey.currentState?.reset();
    setState(() {
      _registering = !_registering;
      _error = null;
      _fieldErrors = const {};
    });
  }

  Future<void> _submit() async {
    _clearErrors();
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      if (_registering) {
        await authStore.register(
          name: _name.text,
          email: _email.text,
          password: _password.text,
        );
      } else {
        await authStore.signIn(email: _email.text, password: _password.text);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _fieldErrors = e.fields;
        _error = e.fields.isEmpty ? e.message : null;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.sprout,
                            size: 22,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'verdant.',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontFamily: 'Lora',
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                      Text(
                        _registering ? 'Start growing.'.tr : 'Welcome back.'.tr,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 34,
                          height: 1.15,
                          letterSpacing: -0.7,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _registering
                            ? 'Create an account to keep your plants and orders safe.'
                                  .tr
                            : 'Your plants have been waiting for you.'.tr,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          height: 1.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (_registering)
                        AuthField(
                          label: 'Your name'.tr,
                          controller: _name,
                          validator: AuthValidators.name,
                          errorText: _fieldErrors['name'],
                          autofillHints: const [AutofillHints.name],
                          textCapitalization: TextCapitalization.words,
                          onChanged: (_) => _clearErrors(),
                        ),
                      AuthField(
                        label: 'Email'.tr,
                        controller: _email,
                        validator: AuthValidators.email,
                        errorText: _fieldErrors['email'],
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        onChanged: (_) => _clearErrors(),
                      ),
                      AuthField(
                        label: 'Password'.tr,
                        controller: _password,
                        isPassword: true,
                        validator: _registering
                            ? AuthValidators.newPassword
                            : AuthValidators.password,
                        errorText: _fieldErrors['password'],
                        autofillHints: [
                          _registering
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => _clearErrors(),
                        onSubmitted: (_) => _submit(),
                      ),
                      if (_error != null) ...[
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                              height: 1.4,
                              color: scheme.error,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      const SizedBox(height: 6),
                      AuthButton(
                        label: _registering
                            ? 'Create account'.tr
                            : 'Sign in'.tr,
                        loading: _loading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _loading ? null : _toggleMode,
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: scheme.onSecondaryContainer,
                        ),
                        child: Text(
                          _registering
                              ? 'Already have an account? Sign in'.tr
                              : 'New to Verdant? Create an account'.tr,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
