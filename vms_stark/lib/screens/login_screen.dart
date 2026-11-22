import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../auth/auth_service.dart';
import '../data/data_exception.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_mark.dart';
import '../widgets/error_banner.dart';

/// Signs in through [AuthService]; the backend checks the credentials.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  bool _signingIn = false;
  late String? _error = widget.auth.sessionExpired
      ? 'Your session has expired. Please sign in again.'
      : null;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose(); // the password lives only in this field, never stored
    super.dispose();
  }

  Future<void> _login() async {
    if (_signingIn || !_formKey.currentState!.validate()) return;
    setState(() {
      _signingIn = true;
      _error = null;
    });
    try {
      await widget.auth.signIn(_email.text.trim(), _password.text);
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.vehicles);
    } on InvalidCredentialsException catch (e) {
      _password.clear();
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = userMessage(e));
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Brand panel only on wide screens; tablets get the form alone.
    final showBrandPanel = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showBrandPanel) const Expanded(child: _BrandPanel()),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _buildForm(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text('Sign in', style: text.headlineMedium),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Welcome back. Enter your details to continue.',
                style: text.bodyMedium?.copyWith(color: AppTheme.slate)),
            const SizedBox(height: AppSpacing.xl),
            if (_error != null) ...[
              ErrorBanner(message: _error!),
              const SizedBox(height: AppSpacing.md),
            ],
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (v) {
                final email = v?.trim() ?? '';
                if (email.isEmpty) return 'Email is required';
                if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(email)) {
                  return 'Enter a valid email, e.g. name@starkgroup.com';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _password,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _hidePassword ? 'Show password' : 'Hide password',
                  icon: Icon(_hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                ),
              ),
              obscureText: _hidePassword,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _login(),
              validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _signingIn ? null : _login, // disabled while signing in: no double submit
              child: Text(_signingIn ? 'Signing in…' : 'Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      color: AppTheme.navy,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandMark(),
          const Spacer(),
          Text('Vehicle Management System',
              style: text.displaySmall?.copyWith(color: Colors.white)),
          const SizedBox(height: AppSpacing.md),
          Text('Register, track and manage every vehicle across the group in one place.',
              style: text.titleMedium?.copyWith(color: AppTheme.sidebarText)),
          const Spacer(),
        ],
      ),
    );
  }
}
