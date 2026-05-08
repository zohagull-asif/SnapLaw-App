import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/snaplaw_widgets.dart';
import '../providers/auth_provider.dart';

// ─── Main screen ─────────────────────────────────────────────────────────────
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;
  bool _checking = false;

  late final AnimationController _entryCtrl;
  late final Animation<double> _cardIn;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _cardIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _checking = true);
    await ref.read(authProvider.notifier).resetPassword(_emailController.text.trim());
    if (!mounted) return;
    setState(() { _checking = false; _emailSent = true; });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.errorMessage!), backgroundColor: AppColors.error));
        ref.read(authProvider.notifier).clearError();
      }
    });

    final screenSize = MediaQuery.of(context).size;
    final isWide = screenSize.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFF020818),
      body: AppBackground(
        overlayOpacity: 0.62,
        child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          // Card
          AnimatedBuilder(
            animation: _cardIn,
            builder: (_, __) {
              final slideY = (1.0 - _cardIn.value) * 50.0;
              return Center(
                child: Transform.translate(
                  offset: Offset(0, slideY),
                  child: Opacity(
                    opacity: _cardIn.value.clamp(0.0, 1.0),
                    child: SizedBox(
                      width: isWide ? 420 : screenSize.width - 32,
                      child: _emailSent ? _buildSuccessCard() : _buildFormCard(),
                    ),
                  ),
                ),
              );
            },
          ),

          // Back button
          Positioned(
            top: 36, left: 12,
            child: SafeArea(child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
              onPressed: () => context.pop(),
            )),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildFormCard() {
    final authState = ref.watch(authProvider);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F1535).withOpacity(0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF4A324).withOpacity(0.30), width: 1.5),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.35), blurRadius: 32, offset: const Offset(0, 8))],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Center(child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF4A324), Color(0xFFE08E10)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                        color: const Color(0xFFF4A324).withOpacity(0.35),
                        blurRadius: 20, offset: const Offset(0, 6))],
                    ),
                    child: const Icon(Icons.lock_reset, color: Colors.white, size: 36),
                  )),
                  const SizedBox(height: 24),

                  const Text('Reset Password',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your email and we\'ll send you a reset link.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.60), fontSize: 13),
                  ),
                  const SizedBox(height: 32),

                  // Email label
                  Text('Email Address',
                    style: TextStyle(color: Colors.white.withOpacity(0.85),
                        fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  _glassInput(
                    controller: _emailController,
                    hint: 'you@example.com',
                    icon: Icons.email_outlined,
                    type: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return AppStrings.emailRequired;
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v))
                        return AppStrings.invalidEmail;
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Submit button
                  _GoldButton(
                    label: AppStrings.sendResetLink,
                    isLoading: authState.status == AuthStatus.loading || _checking,
                    onTap: _handleResetPassword,
                  ),
                  const SizedBox(height: 18),

                  // Back to login
                  Center(child: TextButton(
                    onPressed: () => context.pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFF4A324),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Back to Login'),
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F1535).withOpacity(0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF00C896).withOpacity(0.35), width: 1.5),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.35), blurRadius: 32, offset: const Offset(0, 8))],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C896), Color(0xFF00A070)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(
                      color: const Color(0xFF00C896).withOpacity(0.35),
                      blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  child: const Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 40),
                )),
                const SizedBox(height: 24),
                const Text('Check Your Email',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                const SizedBox(height: 10),
                Text(
                  'We\'ve sent a reset link to\n${_emailController.text}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  'Check your inbox (and spam folder) and follow the instructions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.50), fontSize: 12),
                ),
                const SizedBox(height: 36),
                _GoldButton(label: 'Back to Login', onTap: () => context.go('/login')),
                const SizedBox(height: 14),
                Center(child: TextButton(
                  onPressed: () => setState(() => _emailSent = false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white54,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text("Didn't receive the email? Try again"),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleResetPassword(),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      cursorColor: const Color(0xFFF4A324),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.55), size: 20),
        filled: true,
        fillColor: const Color(0xFF0A0E27).withOpacity(0.60),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFFF4A324).withOpacity(0.25))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFFF4A324).withOpacity(0.25))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF4A324), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.5)),
        errorStyle: const TextStyle(color: Color(0xFFFFB3B3), fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

// ─── Gold gradient button ─────────────────────────────────────────────────────
class _GoldButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;
  const _GoldButton({required this.label, this.isLoading = false, this.onTap});

  @override
  State<_GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<_GoldButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap?.call(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB74D), Color(0xFFF4A324), Color(0xFFE08E10)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
              color: const Color(0xFFF4A324).withOpacity(0.45),
              blurRadius: 16, offset: const Offset(0, 5))],
          ),
          child: Center(
            child: widget.isLoading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : Text(widget.label, style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold,
                  fontSize: 15, letterSpacing: 0.5)),
          ),
        ),
      ),
    );
  }
}
