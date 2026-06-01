import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'screens.dart';

/// ScoreMind login / sign-up screen backed by Firebase Authentication.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ── controllers ────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _authService = AuthService();

  // ── state ──────────────────────────────────────────────────────────────────
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _errorMessage;

  // ── ScoreMind design palette ───────────────────────────────────────────────
  static const _background = Color(0xFFFFFFFF);
  static const _primary = Color(0xFFE6532E);
  static const _primaryDark = Color(0xFFD94A28);
  static const _primaryLight = Color(0xFFF6C06F);
  static const _textDark = Color(0xFF2D2D2D);
  static const _mutedText = Color(0xFF9A9A9A);
  static const _labelColor = Color(0xFF8B4D07);
  static const _fieldBorder = Color(0xFFF2BE73);
  static const _fieldFill = Color(0xFFFFFCF9);
  static const _divider = Color(0xFFF0E4D4);
  static const _errorRed = Color(0xFFE53935);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── actions ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await _authService.signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      } else {
        await _authService.signIn(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = AuthService.friendlyError(e));
    } catch (_) {
      setState(() => _errorMessage = 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Enter your email above first.');
      return;
    }

    try {
      await _authService.sendPasswordReset(email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reset link sent to $email'),
          backgroundColor: _primary,
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = AuthService.friendlyError(e));
    }
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = null;
      _formKey.currentState?.reset();
    });
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 30,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 390),
                      child: _buildForm(),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),

          const SizedBox(height: 34),

          _buildLabel(_isSignUp ? 'EMAIL' : 'STUDENT ID OR EMAIL'),
          const SizedBox(height: 7),
          _buildEmailField(),

          const SizedBox(height: 17),

          _buildLabel('PASSWORD'),
          const SizedBox(height: 7),
          _buildPasswordField(),

          if (_isSignUp) ...[
            const SizedBox(height: 17),
            _buildLabel('CONFIRM PASSWORD'),
            const SizedBox(height: 7),
            _buildConfirmField(),
          ],

          if (!_isSignUp) ...[
            const SizedBox(height: 18),
            _buildRememberForgotRow(),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorBanner(),
          ],

          const SizedBox(height: 28),

          _buildSubmitButton(),

          const SizedBox(height: 26),

          const Divider(
            height: 1,
            thickness: 1,
            color: _divider,
          ),

          const SizedBox(height: 23),

          _buildToggleButton(),
        ],
      ),
    );
  }

  // ── sub-widgets ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: [
        const _ScoreMindLogo(),
        const SizedBox(height: 16),

        const Text(
          'ScoreMind',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textDark,
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            height: 1.1,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Grade & Task Monitor for IT Students',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _mutedText,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 17),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF6E8),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: _primaryLight, width: 1.2),
          ),
          child: const Text(
            'BS Information Technology Only',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _labelColor,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildEmailField() {
    return _ScoreMindField(
      controller: _emailCtrl,
      hint: _isSignUp ? 'you@example.com' : '2024-00217',
      keyboardType: TextInputType.emailAddress,
      validator: (v) {
        final value = v?.trim() ?? '';

        if (value.isEmpty) {
          return _isSignUp
              ? 'Email is required.'
              : 'Student ID or email is required.';
        }

        if (_isSignUp) {
          final re = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
          if (!re.hasMatch(value)) return 'Enter a valid email.';
        }

        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return _ScoreMindField(
      controller: _passwordCtrl,
      hint: '••••••••',
      obscure: _obscurePassword,
      toggleObscure: () {
        setState(() => _obscurePassword = !_obscurePassword);
      },
      validator: (v) {
        if (v == null || v.isEmpty) return 'Password is required.';
        if (v.length < 6) return 'At least 6 characters required.';
        return null;
      },
    );
  }

  Widget _buildConfirmField() {
    return _ScoreMindField(
      controller: _confirmCtrl,
      hint: '••••••••',
      obscure: _obscureConfirm,
      toggleObscure: () {
        setState(() => _obscureConfirm = !_obscureConfirm);
      },
      validator: (v) {
        if (v == null || v.isEmpty) {
          return 'Please confirm your password.';
        }

        if (v != _passwordCtrl.text) {
          return 'Passwords do not match.';
        }

        return null;
      },
    );
  }

  Widget _buildRememberForgotRow() {
    return Row(
      children: [
        Transform.scale(
          scale: 0.85,
          child: Checkbox(
            value: _rememberMe,
            onChanged: (value) {
              setState(() => _rememberMe = value ?? false);
            },
            activeColor: _primary,
            checkColor: Colors.white,
            side: const BorderSide(color: _primary, width: 1.4),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),

        const SizedBox(width: 6),

        const Expanded(
          child: Text(
            'Remember me',
            style: TextStyle(
              color: _mutedText,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        TextButton(
          onPressed: _forgotPassword,
          style: TextButton.styleFrom(
            foregroundColor: _primary,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Forgot password?',
            style: TextStyle(
              color: _primary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _errorRed.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: _errorRed,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: _errorRed,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _primary,
          disabledBackgroundColor: _primary.withOpacity(0.55),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(
                _isSignUp ? 'Sign Up' : 'Log In',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
          style: const TextStyle(
            color: _mutedText,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap: _toggleMode,
          child: Text(
            _isSignUp ? 'Log in' : 'Sign up',
            style: const TextStyle(
              color: _primary,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

// ── ScoreMind styled text-field ──────────────────────────────────────────────
class _ScoreMindField extends StatelessWidget {
  const _ScoreMindField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.toggleObscure,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback? toggleObscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  static const _primary = Color(0xFFE6532E);
  static const _fieldBorder = Color(0xFFF2BE73);
  static const _fieldFill = Color(0xFFFFFCF9);
  static const _textColor = Color(0xFF777777);
  static const _hintColor = Color(0xFF8A8A8A);
  static const _errorRed = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      cursorColor: _primary,
      style: const TextStyle(
        color: _textColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: _hintColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
        suffixIcon: toggleObscure != null
            ? IconButton(
                onPressed: toggleObscure,
                splashRadius: 18,
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _hintColor,
                  size: 19,
                ),
              )
            : null,
        filled: true,
        fillColor: _fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: _fieldBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: _fieldBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: _primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: _errorRed, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: _errorRed, width: 1.4),
        ),
        errorStyle: const TextStyle(
          color: _errorRed,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── ScoreMind logo ───────────────────────────────────────────────────────────
class _ScoreMindLogo extends StatelessWidget {
  const _ScoreMindLogo();

  static const _primary = Color(0xFFE6532E);
  static const _primaryDark = Color(0xFFD94A28);
  static const _primaryLight = Color(0xFFF6C06F);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _primaryLight, width: 2),
        boxShadow: [
          BoxShadow(
            color: _primaryDark.withOpacity(0.18),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: const Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _LogoBar(height: 24),
            SizedBox(width: 7),
            _LogoBar(height: 35),
            SizedBox(width: 7),
            _LogoBar(height: 16),
          ],
        ),
      ),
    );
  }
}

class _LogoBar extends StatelessWidget {
  const _LogoBar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}