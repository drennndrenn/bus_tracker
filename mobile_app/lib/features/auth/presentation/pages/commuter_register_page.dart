import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/commuter_auth_ui.dart';
import '../../data/commuter_auth_service.dart';

class CommuterRegisterPage extends StatefulWidget {
  const CommuterRegisterPage({super.key, this.onRegistered});

  final VoidCallback? onRegistered;

  @override
  State<CommuterRegisterPage> createState() => _CommuterRegisterPageState();
}

class _CommuterRegisterPageState extends State<CommuterRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await CommuterAuthService.instance.register(
        email: _email.text,
        password: _password.text,
        displayName: _name.text,
      );
      if (!mounted) return;
      if (widget.onRegistered != null) {
        widget.onRegistered!();
        return;
      }
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration failed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      title: 'Create your account',
      subtitle: 'Join commuters tracking buses across Davao del Norte.',
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTextField(
                    controller: _name,
                    label: 'Full name',
                    icon: Icons.badge_outlined,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) {
                      if (v == null || v.trim().length < 2) return 'Enter your name';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _email,
                    label: 'Email address',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || !v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _password,
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscure,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: CommuterAuthUi.brandBlue,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) return 'At least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use at least 6 characters for your password.',
                    style: TextStyle(
                      color: CommuterAuthUi.brandBlue.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AuthPrimaryButton(
                    label: 'Create account',
                    icon: Icons.check_circle_outline_rounded,
                    loading: _loading,
                    onPressed: _loading ? null : _submit,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AuthLinkRow(
              prompt: 'Already have an account?',
              actionLabel: 'Sign in',
              onPressed: _loading ? null : () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 16),
            const AuthTrustRow(),
          ],
        ),
      ),
    );
  }
}
