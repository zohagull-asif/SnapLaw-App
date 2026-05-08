import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/snaplaw_theme.dart';

// ═══════════════════════════════════════════════════════
// APP BACKGROUND — 3D image with dark overlay
// ═══════════════════════════════════════════════════════

class AppBackground extends StatelessWidget {
  final Widget child;
  final double overlayOpacity;
  final Color? overlayColor;

  const AppBackground({
    super.key,
    required this.child,
    this.overlayOpacity = 0.58,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/law_bg.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF020818), Color(0xFF050D2A), Color(0xFF030A1E)],
              ),
            ),
          ),
        ),
        Container(
          color: (overlayColor ?? const Color(0xFF020818))
              .withOpacity(overlayOpacity),
        ),
        child,
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// ANIMATED BACKGROUND
// ═══════════════════════════════════════════════════════

class _Particle {
  final double x, speed, delay, size, baseOpacity;
  const _Particle({required this.x, required this.speed, required this.delay,
    required this.size, required this.baseOpacity});
}

class _BgPainter extends CustomPainter {
  final double bgT, partT;
  final String portalType;
  final List<_Particle> particles;

  _BgPainter({required this.bgT, required this.partT,
    required this.portalType, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;

    // Portal-specific gradient — dark navy palette
    LinearGradient grad;
    List<Offset> orbPositions;
    switch (portalType) {
      case 'client':
        final s = sin(bgT * 2 * pi) * 0.08;
        grad = LinearGradient(
          begin: Alignment(-0.4 + s, -1), end: Alignment(0.4 - s, 1),
          colors: const [Color(0xFF0A0E27), Color(0xFF0D1E35), Color(0xFF1A3A5C), Color(0xFF1E3A5C)],
          stops: const [0, 0.32, 0.65, 1],
        );
        orbPositions = [Offset(w * 0.85, h * 0.10), Offset(w * 0.08, h * 0.75), Offset(w * 0.55, h * 0.88)];
        break;
      case 'lawyer':
        final s = sin(bgT * 2 * pi) * 0.08;
        grad = LinearGradient(
          begin: Alignment(-0.3 + s, -1), end: Alignment(0.3 - s, 1),
          colors: const [Color(0xFF0A0E27), Color(0xFF0D0D1E), Color(0xFF1A1A3E), Color(0xFF1A1A3E)],
          stops: const [0, 0.3, 0.65, 1],
        );
        orbPositions = [Offset(w * 0.9, h * 0.08), Offset(w * 0.05, h * 0.65), Offset(w * 0.45, h * 0.92)];
        break;
      case 'citizen':
        final s = sin(bgT * 2 * pi) * 0.07;
        grad = LinearGradient(
          begin: Alignment(-0.3 + s, -1), end: Alignment(0.3 - s, 1),
          colors: const [Color(0xFF0A0E27), Color(0xFF0A1A0F), Color(0xFF0A2818), Color(0xFF0A2818)],
          stops: const [0, 0.32, 0.65, 1],
        );
        orbPositions = [Offset(w * 0.88, h * 0.12), Offset(w * 0.10, h * 0.70), Offset(w * 0.50, h * 0.90)];
        break;
      default:
        final s = sin(bgT * 2 * pi) * 0.08;
        grad = LinearGradient(
          begin: Alignment(-0.4 + s, -1), end: Alignment(0.4 - s, 1),
          colors: const [Color(0xFF0A0E27), Color(0xFF0F1535), Color(0xFF0F1535), Color(0xFF0F1535)],
          stops: const [0, 0.3, 0.65, 1],
        );
        orbPositions = [Offset(w * 0.85, h * 0.10), Offset(w * 0.08, h * 0.75), Offset(w * 0.50, h * 0.90)];
    }

    canvas.drawRect(Offset.zero & size, Paint()..shader = grad.createShader(Offset.zero & size));

    // Gold orbs
    final orbSizes = [110.0, 75.0, 55.0];
    final orbPhases = [0.0, 0.35, 0.68];
    for (int i = 0; i < orbPositions.length; i++) {
      final bob = Offset(0, sin((bgT + orbPhases[i]) * 2 * pi) * 9);
      canvas.drawCircle(orbPositions[i] + bob, orbSizes[i], Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48)
        ..color = const Color(0xFFF4A324).withOpacity(0.08));
    }

    // Particles — subtle gold tint
    for (final p in particles) {
      final phase = (partT * p.speed + p.delay) % 1.0;
      final opacity = sin(phase * pi) * p.baseOpacity;
      if (opacity <= 0) continue;
      canvas.drawCircle(Offset(w * p.x, h * (1.0 - phase)), p.size,
          Paint()..color = const Color(0xFFF4A324).withOpacity(opacity * 0.6));
    }
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.bgT != bgT || old.partT != partT;
}

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final String portalType; // 'client' | 'lawyer' | 'citizen' | 'default'
  final int particleCount;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.portalType = 'default',
    this.particleCount = 15,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _partCtrl;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat();
    _partCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

    final rng = Random(widget.portalType.hashCode);
    _particles = List.generate(widget.particleCount, (_) => _Particle(
      x: rng.nextDouble(),
      speed: 0.5 + rng.nextDouble() * 0.8,
      delay: rng.nextDouble(),
      size: 1.5 + rng.nextDouble() * 3.0,
      baseOpacity: 0.15 + rng.nextDouble() * 0.25,
    ));
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _partCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_bgCtrl, _partCtrl]),
            builder: (_, __) => CustomPaint(
              painter: _BgPainter(
                bgT: _bgCtrl.value, partT: _partCtrl.value,
                portalType: widget.portalType, particles: _particles,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// GLASS CARD
// ═══════════════════════════════════════════════════════

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double opacity;
  final Color? borderColor;
  final Color? tintColor;
  final double blur;
  final List<BoxShadow>? shadows;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.opacity = 0.12,
    this.borderColor,
    this.tintColor,
    this.blur = 16,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tintColor?.withOpacity(opacity) ?? const Color(0xFF0F1535).withOpacity(0.85),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? const Color(0xFFF4A324).withOpacity(0.18),
              width: 1.2,
            ),
            boxShadow: shadows ?? [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// GOLD GRADIENT BUTTON
// ═══════════════════════════════════════════════════════

class GoldButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final IconData? icon;

  const GoldButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.height = 48,
    this.icon,
  });

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onPressed?.call(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: SnapLawGradients.gold,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(
              color: const Color(0xFFF4A324).withOpacity(0.40),
              blurRadius: 12, offset: const Offset(0, 4),
            )],
          ),
          child: Center(child: widget.isLoading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(widget.text, style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold,
                  fontSize: 14, letterSpacing: 0.5)),
              ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// STAT CARD
// ═══════════════════════════════════════════════════════

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? subtitle;
  final IconData? trendIcon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.subtitle,
    this.trendIcon,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [accentColor.withOpacity(0.30), accentColor.withOpacity(0.15)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withOpacity(0.35)),
                  boxShadow: [BoxShadow(
                    color: accentColor.withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              if (trendIcon != null)
                Icon(trendIcon, color: SnapLawColors.success, size: 16),
            ],
          ),
          const SizedBox(height: 14),
          Text(value, style: const TextStyle(
            fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 3),
          Text(title, style: TextStyle(
            fontSize: 13, color: Colors.white.withOpacity(0.75),
            fontWeight: FontWeight.w500)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: TextStyle(
              fontSize: 11, color: Colors.white.withOpacity(0.50))),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// GLASS SIDEBAR MENU ITEM
// ═══════════════════════════════════════════════════════

class SidebarMenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;

  const SidebarMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.accentColor = const Color(0xFFF4A324),
  });

  @override
  State<SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<SidebarMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected || _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.accentColor.withOpacity(0.22)
                : (_hovered ? Colors.white.withOpacity(0.06) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: widget.isSelected
                ? Border.all(color: widget.accentColor.withOpacity(0.55), width: 1.5)
                : (_hovered ? Border.all(color: Colors.white.withOpacity(0.10)) : null),
            boxShadow: widget.isSelected ? [
              BoxShadow(
                color: widget.accentColor.withOpacity(0.15),
                blurRadius: 8, offset: const Offset(0, 2)),
            ] : null,
          ),
          child: Row(children: [
            Icon(widget.icon,
              color: widget.isSelected ? widget.accentColor : Colors.white.withOpacity(active ? 0.80 : 0.55),
              size: 19),
            const SizedBox(width: 11),
            Text(widget.title, style: TextStyle(
              color: widget.isSelected ? Colors.white : Colors.white.withOpacity(active ? 0.85 : 0.60),
              fontSize: 13.5,
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
            )),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// GLASS TOP BAR
// ═══════════════════════════════════════════════════════

class GlassTopBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final double height;

  const GlassTopBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.height = 64,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1130).withOpacity(0.95),
            border: Border(
              bottom: BorderSide(color: const Color(0xFFF4A324).withOpacity(0.20), width: 1),
            ),
          ),
          child: Row(children: [
            if (leading != null) leading!,
            if (leading == null) const SizedBox(width: 16),
            Flexible(child: Text(title, style: const TextStyle(
              color: Colors.white, fontSize: 19,
              fontWeight: FontWeight.bold, letterSpacing: 0.3),
              overflow: TextOverflow.ellipsis)),
            const Spacer(),
            if (actions != null) ...actions!,
            if (actions == null) const SizedBox(width: 16),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// GLASS SIDEBAR CONTAINER
// ═══════════════════════════════════════════════════════

class GlassSidebar extends StatelessWidget {
  final Widget child;
  final double width;

  const GlassSidebar({super.key, required this.child, this.width = 258});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF0D1130), Color(0xFF0A0E27)],
            ),
            border: Border(
              right: BorderSide(color: const Color(0xFFF4A324).withOpacity(0.18), width: 1),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// ANIMATED ENTRANCE WRAPPER (fade + slide)
// ═══════════════════════════════════════════════════════

class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.beginOffset = const Offset(0, 0.06),
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: widget.beginOffset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ═══════════════════════════════════════════════════════
// SCALES WATERMARK
// ═══════════════════════════════════════════════════════

class ScalesWatermark extends StatefulWidget {
  final Widget child;
  const ScalesWatermark({super.key, required this.child});

  @override
  State<ScalesWatermark> createState() => _ScalesWatermarkState();
}

class _ScalesWatermarkState extends State<ScalesWatermark>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              painter: _ScalesWatermarkPainter(animValue: _ctrl.value),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScalesWatermarkPainter extends CustomPainter {
  final double animValue;
  _ScalesWatermarkPainter({required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final scaleSize = h * 0.68;
    final centerX = w * 0.5;
    final centerY = h * 0.5;
    final tiltAngle = sin(animValue * 2 * 3.14159) * 0.07;

    final goldStroke = Paint()
      ..color = const Color(0xFFF4A324).withOpacity(0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final goldFill = Paint()
      ..color = const Color(0xFFF4A324).withOpacity(0.065)
      ..style = PaintingStyle.fill;

    final poleTop = Offset(centerX, centerY - scaleSize * 0.40);
    final poleBottom = Offset(centerX, centerY + scaleSize * 0.40);
    canvas.drawLine(poleTop, poleBottom, goldStroke..strokeWidth = 3);

    final basePath = Path()
      ..moveTo(centerX - scaleSize * 0.14, poleBottom.dy)
      ..lineTo(centerX + scaleSize * 0.14, poleBottom.dy)
      ..lineTo(centerX + scaleSize * 0.20, poleBottom.dy + scaleSize * 0.055)
      ..lineTo(centerX - scaleSize * 0.20, poleBottom.dy + scaleSize * 0.055)
      ..close();
    canvas.drawPath(basePath, goldFill);
    canvas.drawPath(basePath, goldStroke..strokeWidth = 1.5);

    canvas.drawCircle(poleTop, scaleSize * 0.030, goldFill);
    canvas.drawCircle(poleTop, scaleSize * 0.030, goldStroke..strokeWidth = 1.5);

    final beamY = centerY - scaleSize * 0.26;
    final beamHalf = scaleSize * 0.36;
    final leftEndX = centerX - beamHalf;
    final leftEndY = beamY - tiltAngle * beamHalf;
    final rightEndX = centerX + beamHalf;
    final rightEndY = beamY + tiltAngle * beamHalf;
    canvas.drawLine(
      Offset(leftEndX, leftEndY),
      Offset(rightEndX, rightEndY),
      goldStroke..strokeWidth = 2.5,
    );

    final chainSpread = scaleSize * 0.09;

    final leftPanY = leftEndY + scaleSize * 0.26;
    for (final dx in [-chainSpread, 0.0, chainSpread]) {
      canvas.drawLine(Offset(leftEndX, leftEndY), Offset(leftEndX + dx, leftPanY), goldStroke..strokeWidth = 1.2);
    }
    canvas.drawOval(Rect.fromCenter(center: Offset(leftEndX, leftPanY), width: scaleSize * 0.26, height: scaleSize * 0.065), goldFill);
    canvas.drawOval(Rect.fromCenter(center: Offset(leftEndX, leftPanY), width: scaleSize * 0.26, height: scaleSize * 0.065), goldStroke..strokeWidth = 1.5);

    final rightPanY = rightEndY + scaleSize * 0.26;
    for (final dx in [-chainSpread, 0.0, chainSpread]) {
      canvas.drawLine(Offset(rightEndX, rightEndY), Offset(rightEndX + dx, rightPanY), goldStroke..strokeWidth = 1.2);
    }
    canvas.drawOval(Rect.fromCenter(center: Offset(rightEndX, rightPanY), width: scaleSize * 0.26, height: scaleSize * 0.065), goldFill);
    canvas.drawOval(Rect.fromCenter(center: Offset(rightEndX, rightPanY), width: scaleSize * 0.26, height: scaleSize * 0.065), goldStroke..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_ScalesWatermarkPainter old) => old.animValue != animValue;
}
