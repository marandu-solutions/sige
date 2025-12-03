import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:module_auth/src/auth_service.dart';

// O widget do logo, mantido no mesmo arquivo para simplicidade.
class MaranduLogo extends StatelessWidget {
  final double size;
  const MaranduLogo({super.key, this.size = 120.0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = LinearGradient(
      colors: [theme.colorScheme.primary, const Color(0xFF673AB7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final String svgString = '''
    <svg width="$size" height="$size" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="logoGradient" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" style="stop-color:${_colorToHex(gradient.colors[0])};stop-opacity:1" />
          <stop offset="100%" style="stop-color:${_colorToHex(gradient.colors[1])};stop-opacity:1" />
        </linearGradient>
      </defs>
      <circle cx="50" cy="50" r="45" stroke="url(#logoGradient)" stroke-width="8" fill="none"/>
      <path d="M 25 70 L 25 30 L 50 55 L 75 30 L 75 70" stroke="url(#logoGradient)" stroke-width="12" fill="none" stroke-linejoin="round" stroke-linecap="round"/>
    </svg>
    ''';

    return SvgPicture.string(svgString, width: size, height: size);
  }

  String _colorToHex(Color color) =>
      '#${color.value.toRadixString(16).substring(2)}';
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();

    final success = await authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/homepage');
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email ou senha inválidos. Tente novamente.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.watch<AuthService>();
    final isLoading = authService.status == AuthStatus.authenticating;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const MaranduLogo(size: 100),
                const SizedBox(height: 24),
                Text("Bem-vindo de volta!",
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text("Faça login para continuar",
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 32),
                _buildLoginForm(theme, isLoading),
                const SizedBox(height: 24),
                _buildSignUpLink(context, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(ThemeData theme, bool isLoading) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: inputDecoration.copyWith(
              labelText: 'Email',
              prefixIcon: const Icon(LucideIcons.mail),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) => (value == null || !value.contains('@'))
                ? 'Digite um email válido'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: inputDecoration.copyWith(
              labelText: 'Senha',
              prefixIcon: const Icon(LucideIcons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                    _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            validator: (value) => (value == null || value.length < 6)
                ? 'A senha deve ter pelo menos 6 caracteres'
                : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: isLoading ? Container() : const Icon(LucideIcons.logIn),
              onPressed: isLoading ? null : _handleLogin,
              label: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text("Entrar"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpLink(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Não tem uma conta?", style: theme.textTheme.bodyMedium),
        TextButton(
          onPressed: () {/* Navegação para cadastro será implementada */},
          child: const Text("Cadastre-se"),
        ),
      ],
    );
  }
}
