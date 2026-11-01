import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/demo_users.dart';
import '../../domain/providers.dart';
import '../theme/portal_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signIn(
            email: _email.text.trim(),
            password: _password.text,
          );
    } catch (e) {
      setState(() => _error = 'ההתחברות נכשלה. בדקו אימייל וסיסמה.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _demo(ManheletDemoUser user) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signInAsDemo(user);
    } catch (e) {
      setState(
        () => _error =
            'התחברות הדגמה נכשלה. ודאו שסונכרנו סיסמאות הדגמה (tool/sync_demo_passwords.dart).',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'פורטל המנהלת',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: PortalColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'התחברות לסביבת ההדגמה',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: PortalColors.muted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'אימייל'),
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    decoration: const InputDecoration(labelText: 'סיסמה'),
                    obscureText: true,
                    textDirection: TextDirection.ltr,
                    onSubmitted: (_) => _busy ? null : _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: PortalColors.danger)),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('כניסה'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'משתמשי הדגמה (התחברות אמיתית ל-Auth)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final u in kManheletDemoUsers)
                        ActionChip(
                          label: Text(u.labelHe),
                          onPressed: _busy ? null : () => _demo(u),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
