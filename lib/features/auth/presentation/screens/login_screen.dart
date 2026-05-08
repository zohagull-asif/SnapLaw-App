import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/snaplaw_widgets.dart';
import '../../data/models/user_model.dart';
import '../providers/auth_provider.dart';

// ─────────────────────────────────────────────
// Particle data (fixed seed so layout is stable)
// ─────────────────────────────────────────────
class _Particle {
  final double x;      // 0-1 horizontal position
  final double speed;  // relative speed
  final double delay;  // phase offset 0-1
  final double size;   // radius in logical px
  final double baseOpacity;
  const _Particle({
    required this.x,
    required this.speed,
    required this.delay,
    required this.size,
    required this.baseOpacity,
  });
}

final _kParticles = () {
  final rng = Random(42);
  return List.generate(20, (_) => _Particle(
    x: rng.nextDouble(),
    speed: 0.6 + rng.nextDouble() * 0.8,
    delay: rng.nextDouble(),
    size: 2.0 + rng.nextDouble() * 3.5,
    baseOpacity: 0.25 + rng.nextDouble() * 0.35,
  ));
}();

// ─────────────────────────────────────────────
// Background painter: gradient + orbs + particles
// ─────────────────────────────────────────────
class _BackgroundPainter extends CustomPainter {
  final double bgT;    // 0-1, loops
  final double partT;  // 0-1, loops

  _BackgroundPainter({required this.bgT, required this.partT});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Animated gradient
    final shift = sin(bgT * 2 * pi) * 0.06;
    final grad = LinearGradient(
      begin: Alignment(-0.4 + shift, -1.0),
      end: Alignment(0.4 - shift, 1.0),
      colors: const [
        Color(0xFF0A0E27),
        Color(0xFF0F1535),
        Color(0xFF0F1535),
        Color(0xFF0F1535),
      ],
      stops: const [0.0, 0.32, 0.65, 1.0],
    );
    canvas.drawRect(Offset.zero & size, Paint()..shader = grad.createShader(Offset.zero & size));

    // Gold orbs
    _drawOrb(canvas, Offset(w * 0.85, h * 0.12), 100, bgT, 0.0);
    _drawOrb(canvas, Offset(w * 0.10, h * 0.78), 70, bgT, 0.33);
    _drawOrb(canvas, Offset(w * 0.06, h * 0.44), 40, bgT, 0.66);

    // Rising particles — gold tint
    for (final p in _kParticles) {
      final phase = (partT * p.speed + p.delay) % 1.0;
      final opacity = sin(phase * pi) * p.baseOpacity;
      if (opacity <= 0) continue;
      final px = w * p.x;
      final py = h * (1.0 - phase);
      final paint = Paint()
        ..color = const Color(0xFFF4A324).withOpacity(opacity * 0.5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), p.size, paint);
    }
  }

  void _drawOrb(Canvas canvas, Offset center, double radius, double t, double phaseOffset) {
    final bobY = sin((t + phaseOffset) * 2 * pi) * 10.0;
    final c = center.translate(0, bobY);
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48)
      ..color = const Color(0xFFF4A324).withOpacity(0.08);
    canvas.drawCircle(c, radius, paint);
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) =>
      old.bgT != bgT || old.partT != partT;
}

// ─────────────────────────────────────────────
// Justice scales watermark painter
// ─────────────────────────────────────────────
class _ScalesPainter extends CustomPainter {
  final double animValue;
  _ScalesPainter({required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final scaleSize = h * 0.75;
    final centerX = w * 0.5;
    final centerY = h * 0.5;

    final goldPaint = Paint()
      ..color = const Color(0xFFF4A324).withOpacity(0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final goldFillPaint = Paint()
      ..color = const Color(0xFFF4A324).withOpacity(0.07)
      ..style = PaintingStyle.fill;

    final tiltAngle = sin(animValue * 2 * pi) * 0.08;

    final poleTop = Offset(centerX, centerY - scaleSize * 0.42);
    final poleBottom = Offset(centerX, centerY + scaleSize * 0.42);
    canvas.drawLine(poleTop, poleBottom, goldPaint..strokeWidth = 3);

    final basePath = Path()
      ..moveTo(centerX - scaleSize * 0.15, poleBottom.dy)
      ..lineTo(centerX + scaleSize * 0.15, poleBottom.dy)
      ..lineTo(centerX + scaleSize * 0.22, poleBottom.dy + scaleSize * 0.06)
      ..lineTo(centerX - scaleSize * 0.22, poleBottom.dy + scaleSize * 0.06)
      ..close();
    canvas.drawPath(basePath, goldFillPaint);
    canvas.drawPath(basePath, goldPaint..strokeWidth = 2);

    canvas.drawCircle(poleTop, scaleSize * 0.035, goldFillPaint);
    canvas.drawCircle(poleTop, scaleSize * 0.035, goldPaint..strokeWidth = 2);

    final beamY = centerY - scaleSize * 0.28;
    final beamHalf = scaleSize * 0.38;
    final pivotX = centerX;
    final pivotY = beamY;
    final leftEndX = pivotX - beamHalf;
    final leftEndY = pivotY - tiltAngle * beamHalf;
    final rightEndX = pivotX + beamHalf;
    final rightEndY = pivotY + tiltAngle * beamHalf;

    canvas.drawLine(
      Offset(leftEndX, leftEndY),
      Offset(rightEndX, rightEndY),
      goldPaint..strokeWidth = 3,
    );

    final leftChainTop = Offset(leftEndX, leftEndY);
    final leftPanY = leftEndY + scaleSize * 0.28;
    final leftPanCenter = Offset(leftEndX, leftPanY);
    final leftChainSpread = scaleSize * 0.10;
    canvas.drawLine(leftChainTop, Offset(leftEndX - leftChainSpread, leftPanY), goldPaint..strokeWidth = 1.5);
    canvas.drawLine(leftChainTop, Offset(leftEndX, leftPanY), goldPaint..strokeWidth = 1.5);
    canvas.drawLine(leftChainTop, Offset(leftEndX + leftChainSpread, leftPanY), goldPaint..strokeWidth = 1.5);
    final leftPanRect = Rect.fromCenter(center: leftPanCenter, width: scaleSize * 0.28, height: scaleSize * 0.07);
    canvas.drawOval(leftPanRect, goldFillPaint);
    canvas.drawOval(leftPanRect, goldPaint..strokeWidth = 2);

    final rightChainTop = Offset(rightEndX, rightEndY);
    final rightPanY = rightEndY + scaleSize * 0.28;
    final rightPanCenter = Offset(rightEndX, rightPanY);
    final rightChainSpread = scaleSize * 0.10;
    canvas.drawLine(rightChainTop, Offset(rightEndX - rightChainSpread, rightPanY), goldPaint..strokeWidth = 1.5);
    canvas.drawLine(rightChainTop, Offset(rightEndX, rightPanY), goldPaint..strokeWidth = 1.5);
    canvas.drawLine(rightChainTop, Offset(rightEndX + rightChainSpread, rightPanY), goldPaint..strokeWidth = 1.5);
    final rightPanRect = Rect.fromCenter(center: rightPanCenter, width: scaleSize * 0.28, height: scaleSize * 0.07);
    canvas.drawOval(rightPanRect, goldFillPaint);
    canvas.drawOval(rightPanRect, goldPaint..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_ScalesPainter old) => old.animValue != animValue;
}

// ─────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────
class LoginScreen extends ConsumerStatefulWidget {
  final String? requiredRole;
  const LoginScreen({super.key, this.requiredRole});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  // ── Form (unchanged) ──────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // ── Animation controllers ─────────────────
  late final AnimationController _bgCtrl;    // 8s, repeat
  late final AnimationController _partCtrl;  // 5s, repeat
  late final AnimationController _entryCtrl; // 3000ms, one-shot

  // Entry sub-animations (Interval based)
  late final Animation<double> _cardIn;
  late final Animation<double> _logoIn;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
    _partCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..repeat();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))
      ..forward();

    _cardIn = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.50, 0.77, curve: Curves.easeOutBack),
    );
    _logoIn = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.73, 0.93, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _partCtrl.dispose();
    _entryCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Auth logic (unchanged) ─────────────────
  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(authProvider.notifier).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  Future<void> _navigateBasedOnRole(UserModel user) async {
    // Enforce portal role restriction
    if (widget.requiredRole != null) {
      final expected = const {
        'client': UserRole.client,
        'lawyer': UserRole.lawyer,
        'admin': UserRole.admin,
      }[widget.requiredRole];
      if (expected != null && user.role != expected) {
        await ref.read(authProvider.notifier).signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'This account is not a ${widget.requiredRole}. Please use the correct portal.'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ));
        return;
      }
    }

    switch (user.role) {
      case UserRole.client:
        context.go('/client');
        break;
      case UserRole.lawyer:
        // Check if lawyer has been approved by admin
        try {
          final result = await Supabase.instance.client.from('lawyer_profiles')
              .select('is_verified')
              .eq('user_id', user.id)
              .maybeSingle();
          if (!mounted) return;
          if (result != null && result['is_verified'] == true) {
            context.go('/lawyer');
          } else {
            context.go('/lawyer/pending');
          }
        } catch (_) {
          if (mounted) context.go('/lawyer/pending');
        }
        break;
      case UserRole.admin:
        context.go('/admin');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Auth state listener (unchanged)
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      } else if (next.status == AuthStatus.authenticated && next.user != null &&
          previous?.status != AuthStatus.authenticated) {
        _navigateBasedOnRole(next.user!);
      }
    });

    final screenSize = MediaQuery.of(context).size;
    final isWide = screenSize.width > 680;

    return Scaffold(
      backgroundColor: const Color(0xFF020818),
      body: AppBackground(
        overlayOpacity: 0.60,
        child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [

          // ── Glassmorphism card ───────────────
          AnimatedBuilder(
            animation: _cardIn,
            builder: (_, __) {
              final slideX = (1.0 - _cardIn.value) * 80.0;
              if (isWide) {
                return Center(
                  child: Transform.translate(
                    offset: Offset(slideX, 0),
                    child: Opacity(
                      opacity: _cardIn.value.clamp(0.0, 1.0),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0012)
                          ..rotateX(-0.06),
                        child: Container(
                          width: 420,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.07),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.3],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.85),
                                blurRadius: 140,
                                spreadRadius: 20,
                                offset: const Offset(0, 80),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.55),
                                blurRadius: 60,
                                spreadRadius: 5,
                                offset: const Offset(0, 35),
                              ),
                              BoxShadow(
                                color: const Color(0xFFF4A324).withOpacity(0.22),
                                blurRadius: 100,
                                spreadRadius: 5,
                                offset: const Offset(0, 0),
                              ),
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withOpacity(0.15),
                                blurRadius: 80,
                                offset: const Offset(-30, 30),
                              ),
                            ],
                          ),
                          child: _buildCard(context),
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                return Positioned(
                  left: 16,
                  right: 16,
                  top: 60,
                  bottom: 16,
                  child: Transform.translate(
                    offset: Offset(slideX, 0),
                    child: Opacity(
                      opacity: _cardIn.value.clamp(0.0, 1.0),
                      child: _buildCard(context),
                    ),
                  ),
                );
              }
            },
          ),

          // ── Animated logo ─────────────────
          AnimatedBuilder(
            animation: _logoIn,
            builder: (_, __) {
              return Positioned(
                top: 28,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _logoIn.value.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, (1 - _logoIn.value) * 14),
                    child: _buildLogo(),
                  ),
                ),
              );
            },
          ),

          // ── Back button ───────────────────
          Positioned(
            top: 36,
            left: 12,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
                onPressed: () => context.go('/portal-select'),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.balance, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'SNAP',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 2,
                    ),
                  ),
                  TextSpan(
                    text: 'LAW',
                    style: TextStyle(
                      color: Color(0xFFF4A324),
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF4A324).withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF4A324).withOpacity(0.30)),
          ),
          child: const Text(
            'PAKISTAN LEGAL PLATFORM',
            style: TextStyle(
              color: Color(0xFFF4A324),
              fontSize: 9,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    final authState = ref.watch(authProvider);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F1535),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF4A324).withOpacity(0.30), width: 1.5),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Text(
                    widget.requiredRole == 'lawyer'
                        ? 'Lawyer Login'
                        : widget.requiredRole == 'admin'
                            ? 'Admin Login'
                            : 'Welcome Back',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.appTagline,
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                  ),
                  const SizedBox(height: 28),

                  // Email
                  _FieldLabel('Email'),
                  const SizedBox(height: 6),
                  _glassInput(
                    controller: _emailController,
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.email_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) return AppStrings.emailRequired;
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return AppStrings.invalidEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Password
                  _FieldLabel('Password'),
                  const SizedBox(height: 6),
                  _glassInput(
                    controller: _passwordController,
                    hint: '••••••••',
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.lock_outlined,
                    onFieldSubmitted: (_) => _handleLogin(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.white60,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return AppStrings.passwordRequired;
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFF4A324),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      ),
                      child: const Text(AppStrings.forgotPassword),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Sign-in button
                  _SignInButton(
                    isLoading: authState.status == AuthStatus.loading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  Row(children: [
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.2), height: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.2), height: 1)),
                  ]),
                  const SizedBox(height: 18),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.dontHaveAccount,
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFF4A324),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        child: const Text(AppStrings.signUp),
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

  Widget _glassInput({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      cursorColor: const Color(0xFFF4A324),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.white.withOpacity(0.6), size: 20)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF0F1535),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFFF4A324).withOpacity(0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFFF4A324).withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF4A324), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFFB3B3), fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      validator: validator,
    );
  }
}

// ─────────────────────────────────────────────
// Small helpers
// ─────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.85),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SignInButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _SignInButton({required this.isLoading, required this.onPressed});

  @override
  State<_SignInButton> createState() => _SignInButtonState();
}

class _SignInButtonState extends State<_SignInButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.isLoading) widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF4A324), Color(0xFFF59E0B), Color(0xFFF4A324)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF4A324).withOpacity(0.45),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    AppStrings.signIn,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
