import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/snaplaw_widgets.dart';
import '../../data/models/user_model.dart';
import '../providers/auth_provider.dart';

// ─── Main screen ─────────────────────────────────────────────────────────────
class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _resendTimer;
  int _resendCountdown = 60;
  bool _canResend = false;
  bool _isLoading = false;

  late final AnimationController _entryCtrl;
  late final Animation<double> _cardIn;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _cardIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack);
    _startResendTimer();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final n in _focusNodes) n.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() { _resendCountdown = 60; _canResend = false; });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        setState(() => _canResend = true);
        t.cancel();
      }
    });
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) _focusNodes[index + 1].requestFocus();
    if (_otpCode.length == 6) _verifyOtp();
  }

  void _onKeyPressed(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _otpControllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCode;
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter the complete 6-digit code'),
        backgroundColor: AppColors.error));
      return;
    }
    setState(() => _isLoading = true);
    final success = await ref.read(authProvider.notifier).verifyOtp(otp);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Email verified successfully!'), backgroundColor: AppColors.success));
    } else {
      for (final c in _otpControllers) c.clear();
      _focusNodes[0].requestFocus();
      final err = ref.read(authProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err ?? 'Invalid OTP. Please try again.'),
        backgroundColor: AppColors.error));
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    final success = await ref.read(authProvider.notifier).resendOtp();
    if (!mounted) return;
    if (success) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('OTP resent successfully!'), backgroundColor: AppColors.success));
    } else {
      final err = ref.read(authProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err ?? 'Failed to resend OTP'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final email = authState.pendingEmail ?? '';

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.status == AuthStatus.authenticated) {
        final role = next.user?.role;
        if (role == UserRole.client) context.go('/client');
        else if (role == UserRole.lawyer) context.go('/lawyer');
        else if (role == UserRole.admin) context.go('/admin');
        else context.go('/role-selection');
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
            builder: (_, __) => Center(
              child: Transform.translate(
                offset: Offset(0, (1 - _cardIn.value) * 50.0),
                child: Opacity(
                  opacity: _cardIn.value.clamp(0.0, 1.0),
                  child: SizedBox(
                    width: isWide ? 440 : screenSize.width - 32,
                    child: _buildCard(email, authState),
                  ),
                ),
              ),
            ),
          ),

          // Back button
          Positioned(
            top: 36, left: 12,
            child: SafeArea(child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
              onPressed: () {
                ref.read(authProvider.notifier).clearError();
                context.go('/register');
              },
            )),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildCard(String email, AuthState authState) {
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
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
                  child: const Icon(Icons.email_outlined, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 22),

                const Text('Verify Your Email',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                const SizedBox(height: 8),
                Text('We\'ve sent a 6-digit code to',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.60), fontSize: 13)),
                const SizedBox(height: 4),
                Text(email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFF4A324), fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 32),

                // OTP boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) => Container(
                    width: 46, height: 54,
                    margin: EdgeInsets.only(right: i < 5 ? 8 : 0),
                    child: RawKeyboardListener(
                      focusNode: FocusNode(),
                      onKey: (e) => _onKeyPressed(i, e),
                      child: TextField(
                        controller: _otpControllers[i],
                        focusNode: _focusNodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        cursorColor: const Color(0xFFF4A324),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0xFF0A0E27).withOpacity(0.70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: const Color(0xFFF4A324).withOpacity(0.30))),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: const Color(0xFFF4A324).withOpacity(0.30))),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFF4A324), width: 2)),
                          contentPadding: EdgeInsets.zero,
                        ),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (v) => _onOtpChanged(i, v),
                      ),
                    ),
                  )),
                ),
                const SizedBox(height: 30),

                // Verify button
                _GoldButton(
                  label: 'Verify Email',
                  isLoading: _isLoading || authState.status == AuthStatus.loading,
                  onTap: _verifyOtp,
                ),
                const SizedBox(height: 20),

                // Resend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Didn\'t receive the code? ',
                      style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13)),
                    if (_canResend)
                      GestureDetector(
                        onTap: _resendOtp,
                        child: const Text('Resend',
                          style: TextStyle(color: Color(0xFFF4A324),
                              fontSize: 13, fontWeight: FontWeight.w600)))
                    else
                      Text('Resend in ${_resendCountdown}s',
                        style: TextStyle(color: Colors.white.withOpacity(0.40), fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 16),

                // Spam note
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.20)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF3B82F6), size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        'Check your spam folder if you don\'t see the email.',
                        style: TextStyle(color: const Color(0xFF3B82F6).withOpacity(0.80), fontSize: 12),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
          height: 52, width: double.infinity,
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
