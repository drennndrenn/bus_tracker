import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/commuter_auth_ui.dart';
import '../../data/commuter_auth_service.dart';
import 'commuter_register_page.dart';

class CommuterLoginPage extends StatefulWidget {
  const CommuterLoginPage({super.key, this.onAuthenticated});

  final VoidCallback? onAuthenticated;

  @override
  State<CommuterLoginPage> createState() => _CommuterLoginPageState();
}

class _CommuterLoginPageState extends State<CommuterLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await CommuterAuthService.instance.signIn(
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      if (widget.onAuthenticated != null) {
        widget.onAuthenticated!();
        return;
      }
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Sign in failed')),
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
      title: 'Welcome back',
      subtitle: 'Sign in to unlock Pro plans, payments, and synced alerts.',
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
                  const SizedBox(height: 24),
                  AuthPrimaryButton(
                    label: 'Sign in',
                    icon: Icons.arrow_forward_rounded,
                    loading: _loading,
                    onPressed: _loading ? null : _submit,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AuthLinkRow(
              prompt: 'New here?',
              actionLabel: 'Create account',
              onPressed: _loading
                  ? null
                  : () async {
                      if (widget.onAuthenticated != null) {
                        await Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => CommuterRegisterPage(
                              onRegistered: widget.onAuthenticated,
                            ),
                          ),
                        );
                        return;
                      }
                      final navigator = Navigator.of(context);
                      final registered = await navigator.push<bool>(
                        MaterialPageRoute<bool>(
                          builder: (_) => const CommuterRegisterPage(),
                        ),
                      );
                      if (!mounted) return;
                      if (registered == true) {
                        navigator.pop(true);
                      }
                    },
            ),
            const SizedBox(height: 16),
            const AuthTrustRow(),
          ],
        ),
      ),
    );
  }
}
