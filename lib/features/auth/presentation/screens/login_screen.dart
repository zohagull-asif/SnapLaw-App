import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
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
    final shift = sin(bgT * 2 * pi) * 0.18;
    final grad = LinearGradient(
      begin: Alignment(-0.4 + shift, -1.0),
      end: Alignment(0.4 - shift, 1.0),
      colors: const [
        Color(0xFF6C63FF),
        Color(0xFF8B7CF6),
        Color(0xFFA78BFA),
        Color(0xFF7C3AED),
      ],
      stops: const [0.0, 0.32, 0.65, 1.0],
    );
    canvas.drawRect(Offset.zero & size, Paint()..shader = grad.createShader(Offset.zero & size));

    // Floating orbs
    _drawOrb(canvas, Offset(w * 0.85, h * 0.12), 100, bgT, 0.0);
    _drawOrb(canvas, Offset(w * 0.10, h * 0.78), 70, bgT, 0.33);
    _drawOrb(canvas, Offset(w * 0.06, h * 0.44), 40, bgT, 0.66);

    // Rising particles
    for (final p in _kParticles) {
      final phase = (partT * p.speed + p.delay) % 1.0;
      final opacity = sin(phase * pi) * p.baseOpacity;
      if (opacity <= 0) continue;
      final px = w * p.x;
      final py = h * (1.0 - phase);
      final paint = Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), p.size, paint);
    }
  }

  void _drawOrb(Canvas canvas, Offset center, double radius, double t, double phaseOffset) {
    final bobY = sin((t + phaseOffset) * 2 * pi) * 10.0;
    final c = center.translate(0, bobY);
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48)
      ..color = Colors.white.withOpacity(0.18);
    canvas.drawCircle(c, radius, paint);
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) =>
      old.bgT != bgT || old.partT != partT;
}

// ─────────────────────────────────────────────
// Character painter: walking figure
// ─────────────────────────────────────────────
class _CharPainter extends CustomPainter {
  final double cycle;  // -1 to 1, walk cycle
  final bool isIdle;

  _CharPainter({required this.cycle, required this.isIdle});

  // Design space: 140 × 240
  static const double _dw = 140;
  static const double _dh = 240;
  static const double _cx = 70; // horizontal center

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _dw, size.height / _dh);

    // Ground shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(_cx, 232), width: 60, height: 12),
      shadowPaint,
    );

    final bobY = isIdle ? cycle.abs() * -2.5 : 0.0;
    final bodyOffY = isIdle ? cycle.abs() * -1.5 : 0.0;

    // ── Legs ──────────────────────────────────
    final legAngleL = isIdle ? 0.0 : cycle * 8 * pi / 180;
    final legAngleR = isIdle ? 0.0 : -cycle * 8 * pi / 180;
    final legPx = _cx;
    final legPy = 175.0 + bodyOffY;

    _limb(canvas, legPx - 9, legPy, legAngleL, (c) {
      final p = Paint()..color = const Color(0xFF3B82F6); // blue pants
      c.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-7, 0, 14, 50), const Radius.circular(6)),p);
    });
    _limb(canvas, legPx + 9, legPy, legAngleR, (c) {
      final p = Paint()..color = const Color(0xFF3B82F6);
      c.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-7, 0, 14, 50), const Radius.circular(6)),p);
    });

    // ── Shoes ──────────────────────────────────
    _limb(canvas, legPx - 9, legPy, legAngleL, (c) {
      final p = Paint()..color = Colors.white;
      c.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-9, 44, 18, 10), const Radius.circular(5)),p);
    });
    _limb(canvas, legPx + 9, legPy, legAngleR, (c) {
      final p = Paint()..color = Colors.white;
      c.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-9, 44, 18, 10), const Radius.circular(5)),p);
    });

    // ── Belt ──────────────────────────────────
    final beltY = 170.0 + bodyOffY;
    final beltPaint = Paint()..color = const Color(0xFF92400E);
    canvas.drawRect(Rect.fromLTWH(_cx - 22, beltY, 44, 8), beltPaint);
    // buckle
    final bucklePaint = Paint()..color = const Color(0xFFD97706);
    canvas.drawRect(Rect.fromLTWH(_cx - 7, beltY + 1, 14, 6), bucklePaint);

    // ── Torso ─────────────────────────────────
    final torsoAngle = isIdle ? 0.0 : cycle * 2 * pi / 180;
    _limb(canvas, _cx, 135.0 + bodyOffY, torsoAngle, (c) {
      final p = Paint()..color = const Color(0xFFF97316); // orange shirt
      c.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-22, 0, 44, 40), const Radius.circular(6)),p);
    });

    // ── Arms ──────────────────────────────────
    final armAngleL = isIdle ? 20 * pi / 180 : cycle * 30 * pi / 180;
    final armAngleR = isIdle ? -60 * pi / 180 : -cycle * 30 * pi / 180;
    final armPy = 138.0 + bodyOffY;

    _limb(canvas, _cx - 22, armPy, armAngleL, (c) {
      final p = Paint()..color = const Color(0xFFF97316);
      c.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-6, 0, 12, 36), const Radius.circular(5)),p);
      // hand
      final hp = Paint()..color = const Color(0xFF92400E);
      c.drawCircle(const Offset(0, 39), 7, hp);
    });
    _limb(canvas, _cx + 22, armPy, armAngleR, (c) {
      final p = Paint()..color = const Color(0xFFF97316);
      c.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-6, 0, 12, 36), const Radius.circular(5)),p);
      // hand
      final hp = Paint()..color = const Color(0xFF92400E);
      c.drawCircle(const Offset(0, 39), 7, hp);
    });

    // ── Head ──────────────────────────────────
    final headY = 95.0 + bodyOffY + bobY;

    // Neck
    final neckPaint = Paint()..color = const Color(0xFF92400E);
    canvas.drawRect(Rect.fromLTWH(_cx - 7, headY + 24, 14, 14), neckPaint);

    // Head base (brown skin)
    final headPaint = Paint()..color = const Color(0xFF92400E);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(_cx, headY + 14), width: 42, height: 44),
      headPaint,
    );

    // Afro
    final afroPaint = Paint()..color = const Color(0xFF1C0A00);
    canvas.drawCircle(Offset(_cx, headY + 4), 26, afroPaint);
    canvas.drawCircle(Offset(_cx - 14, headY + 8), 16, afroPaint);
    canvas.drawCircle(Offset(_cx + 14, headY + 8), 16, afroPaint);

    // Eyes
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(_cx - 8, headY + 13), 5, eyePaint);
    canvas.drawCircle(Offset(_cx + 8, headY + 13), 5, eyePaint);
    final pupilPaint = Paint()..color = const Color(0xFF1C0A00);
    canvas.drawCircle(Offset(_cx - 7, headY + 14), 3, pupilPaint);
    canvas.drawCircle(Offset(_cx + 9, headY + 14), 3, pupilPaint);

    // Smile
    final smilePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final smilePath = Path()
      ..moveTo(_cx - 7, headY + 22)
      ..quadraticBezierTo(_cx, headY + 27, _cx + 7, headY + 22);
    canvas.drawPath(smilePath, smilePaint);

    // Earring (small gold dot on left ear)
    final earringPaint = Paint()..color = const Color(0xFFD97706);
    canvas.drawCircle(Offset(_cx - 20, headY + 18), 3, earringPaint);
  }

  /// Rotate around pivot (px, py); drawFn receives canvas with origin at (px, py).
  void _limb(Canvas canvas, double px, double py, double angle, void Function(Canvas) drawFn) {
    canvas.save();
    canvas.translate(px, py);
    canvas.rotate(angle);
    drawFn(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CharPainter old) =>
      old.cycle != cycle || old.isIdle != isIdle;
}

// ─────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

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
  late final AnimationController _walkCtrl;  // 450ms, alternate repeat
  late final AnimationController _entryCtrl; // 3000ms, one-shot
  late final AnimationController _idleCtrl;  // 2000ms, repeat

  // Entry sub-animations (Interval based)
  late final Animation<double> _charIn;
  late final Animation<double> _cardIn;
  late final Animation<double> _logoIn;

  bool _isIdle = false;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
    _partCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..repeat();
    _walkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450))
      ..repeat(reverse: true);
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))
      ..forward();
    _idleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);

    _charIn = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.07, 0.53, curve: Curves.easeOut),
    );
    _cardIn = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.50, 0.77, curve: Curves.easeOutBack),
    );
    _logoIn = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.73, 0.93, curve: Curves.easeOut),
    );

    _entryCtrl.addListener(() {
      if (!_isIdle && _entryCtrl.value >= 0.53) {
        setState(() => _isIdle = true);
        _walkCtrl.stop();
      }
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _partCtrl.dispose();
    _walkCtrl.dispose();
    _entryCtrl.dispose();
    _idleCtrl.dispose();
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

  void _navigateBasedOnRole(UserModel user) {
    switch (user.role) {
      case UserRole.client:
        context.go('/client');
        break;
      case UserRole.lawyer:
        context.go('/lawyer');
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
      } else if (next.status == AuthStatus.authenticated && next.user != null) {
        _navigateBasedOnRole(next.user!);
      }
    });

    final screenSize = MediaQuery.of(context).size;
    final isWide = screenSize.width > 680;

    return Scaffold(
      backgroundColor: const Color(0xFF7C3AED),
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          // ── Animated background ──────────────
          AnimatedBuilder(
            animation: Listenable.merge([_bgCtrl, _partCtrl]),
            builder: (_, __) => CustomPaint(
              painter: _BackgroundPainter(
                bgT: _bgCtrl.value,
                partT: _partCtrl.value,
              ),
              child: const SizedBox.expand(),
            ),
          ),

          // ── Walking character (wide only) ────
          if (isWide)
            AnimatedBuilder(
              animation: Listenable.merge([_charIn, _walkCtrl, _idleCtrl]),
              builder: (_, __) {
                final charProgress = _charIn.value;
                final charX = -120.0 + (screenSize.width * 0.22 + 120) * charProgress;
                final cycle = _isIdle
                    ? _idleCtrl.value * 2 - 1
                    : _walkCtrl.value * 2 - 1;
                return Positioned(
                  left: charX,
                  bottom: 0,
                  child: SizedBox(
                    width: 120,
                    height: 200,
                    child: CustomPaint(
                      painter: _CharPainter(cycle: cycle, isIdle: _isIdle),
                    ),
                  ),
                );
              },
            ),

          // ── Glassmorphism card ───────────────
          AnimatedBuilder(
            animation: _cardIn,
            builder: (_, __) {
              final slideX = (1.0 - _cardIn.value) * 80.0;
              if (isWide) {
                return Positioned(
                  right: 48,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(slideX, 0),
                      child: Opacity(
                        opacity: _cardIn.value.clamp(0.0, 1.0),
                        child: SizedBox(
                          width: 420,
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
                      color: Color(0xFFD97706),
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
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: const Text(
            'PAKISTAN LEGAL PLATFORM',
            style: TextStyle(
              color: Colors.white70,
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
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.30), width: 1.5),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
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
                        foregroundColor: const Color(0xFFD97706),
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
                          foregroundColor: const Color(0xFFD97706),
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
      cursorColor: const Color(0xFFD97706),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.white.withOpacity(0.6), size: 20)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.20)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.20)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.5),
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
              colors: [Color(0xFFD97706), Color(0xFFF59E0B), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD97706).withOpacity(0.45),
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
