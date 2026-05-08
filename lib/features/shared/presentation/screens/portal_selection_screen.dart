import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/widgets/snaplaw_widgets.dart';
import '../../../../services/supabase_service.dart';

class PortalSelectionScreen extends StatefulWidget {
  const PortalSelectionScreen({super.key});
  @override
  State<PortalSelectionScreen> createState() => _PortalSelectionScreenState();
}

class _PortalSelectionScreenState extends State<PortalSelectionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _logoIn, _tagIn;
  late final Animation<double> _card1In, _card2In, _card3In, _card4In;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1600))..forward();

    _logoIn  = CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0.00, 0.35, curve: Curves.easeOut));
    _tagIn   = CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0.15, 0.45, curve: Curves.easeOut));
    _card1In = CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0.22, 0.55, curve: Curves.easeOutBack));
    _card2In = CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOutBack));
    _card3In = CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0.48, 0.78, curve: Curves.easeOutBack));
    _card4In = CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0.60, 0.90, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Widget _fade(Animation<double> anim, Widget child, {bool slideDown = false}) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - anim.value) * (slideDown ? 30.0 : -12.0)),
          child: child,
        ),
      ),
    );
  }

  // ── Admin dialog ────────────────────────────────────────────────────────────
  void _showAdminDialog(BuildContext ctx) {
    final ctrl = TextEditingController();
    bool obscure = true;
    String? err;

    showDialog(
      context: ctx,
      barrierDismissible: true,
      builder: (_) => StatefulBuilder(
        builder: (dCtx, setDS) => AlertDialog(
          backgroundColor: const Color(0xFF0D1240),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: const Color(0xFFF4A324).withOpacity(0.40)),
          ),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4A324).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings,
                  color: Color(0xFFF4A324), size: 22),
            ),
            const SizedBox(width: 12),
            Text('Admin Access',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter admin credentials to continue',
                  style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                obscureText: obscure,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Admin Password',
                  labelStyle: GoogleFonts.poppins(color: Colors.white60, fontSize: 13),
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.white60),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white60),
                    onPressed: () => setDS(() => obscure = !obscure),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: const Color(0xFFF4A324).withOpacity(0.30)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFF4A324)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF08102A),
                ),
              ),
              if (err != null) ...[
                const SizedBox(height: 8),
                Text(err!,
                    style: GoogleFonts.poppins(
                        color: Colors.red, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF4A324),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (ctrl.text == 'SnapLawAdmin@2026') {
                  Navigator.pop(dCtx);
                  ctx.go('/login');
                } else {
                  setDS(() => err = 'Incorrect password. Try again.');
                }
              },
              child: Text('Continue',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final compact = screenH < 680;

    return Scaffold(
      backgroundColor: const Color(0xFF020818),
      body: AppBackground(
        overlayOpacity: 0.50,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: compact ? 10 : 20),

                // ── Logo / header ─────────────────────────────────────────
                _fade(_logoIn, _buildHeader(compact)),
                SizedBox(height: compact ? 8 : 14),

                // ── "CHOOSE YOUR PORTAL" pill ─────────────────────────────
                _fade(_tagIn, _buildChooserLabel()),
                SizedBox(height: compact ? 10 : 18),

                // ── 2×2 portal card grid ─────────────────────────────────
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: compact ? 360 : 430,
                        maxWidth: 580,
                      ),
                      child: Column(children: [
                        Expanded(child: Row(children: [
                          Expanded(child: _fade(_card1In, _PortalCard(
                            lottiePath: 'assets/animations/client.json',
                            fallbackIcon: Icons.person_outline,
                            accentColor: const Color(0xFF3B82F6),
                            title: 'Client',
                            subtitle: 'Find lawyers, manage your cases and get legal help',
                            onTap: () {
                              final role = SupabaseService.currentUser
                                  ?.userMetadata?['role'];
                              if (SupabaseService.isAuthenticated &&
                                  role == 'client') {
                                context.go('/client');
                              } else {
                                context.go('/login?role=client');
                              }
                            },
                          ), slideDown: true)),
                          const SizedBox(width: 10),
                          Expanded(child: _fade(_card2In, _PortalCard(
                            lottiePath: 'assets/animations/lawyer.json',
                            fallbackIcon: Icons.manage_accounts,
                            accentColor: const Color(0xFF7B61FF),
                            title: 'Lawyer',
                            subtitle: 'Manage clients, cases and grow your practice',
                            onTap: () {
                              final role = SupabaseService.currentUser
                                  ?.userMetadata?['role'];
                              if (SupabaseService.isAuthenticated &&
                                  role == 'lawyer') {
                                context.go('/lawyer');
                              } else {
                                context.go('/login?role=lawyer');
                              }
                            },
                          ), slideDown: true)),
                        ])),
                        const SizedBox(height: 10),
                        Expanded(child: Row(children: [
                          Expanded(child: _fade(_card3In, _PortalCard(
                            lottiePath: 'assets/animations/citizen.json',
                            fallbackIcon: Icons.people_outline,
                            accentColor: const Color(0xFF00C896),
                            title: 'Citizen',
                            subtitle: 'Learn your rights and access free legal guidance',
                            badge: 'No Login Required',
                            badgeColor: const Color(0xFF00C896),
                            onTap: () => context.push('/citizen'),
                          ), slideDown: true)),
                          const SizedBox(width: 10),
                          Expanded(child: _fade(_card4In, _PortalCard(
                            lottiePath: 'assets/animations/admin.json',
                            fallbackIcon: Icons.admin_panel_settings_outlined,
                            accentColor: const Color(0xFFFF4757),
                            title: 'Admin',
                            subtitle: 'Oversee platform, verify lawyers and manage users',
                            badge: 'Restricted',
                            badgeColor: const Color(0xFFFF4757),
                            onTap: () => _showAdminDialog(context),
                          ), slideDown: true)),
                        ])),
                      ]),
                    ),
                  ),
                ),

                SizedBox(height: compact ? 4 : 8),
                Text('Pakistan Legal Platform',
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF4A5580),
                        fontSize: 10,
                        letterSpacing: 1.2)),
                SizedBox(height: compact ? 8 : 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool compact) {
    return Column(children: [
      Container(
        width: compact ? 58 : 68,
        height: compact ? 58 : 68,
        decoration: BoxDecoration(
          gradient: const RadialGradient(
              colors: [Color(0xFF1C2870), Color(0xFF0D1130)]),
          shape: BoxShape.circle,
          border: Border.all(
              color: const Color(0xFFF4A324).withOpacity(0.65), width: 2),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFF4A324).withOpacity(0.40),
                blurRadius: 28,
                spreadRadius: 4),
            BoxShadow(
                color: const Color(0xFFF4A324).withOpacity(0.18),
                blurRadius: 50,
                spreadRadius: 10),
          ],
        ),
        child: Icon(Icons.balance,
            size: compact ? 30 : 34, color: const Color(0xFFF4A324)),
      ),
      SizedBox(height: compact ? 8 : 10),
      RichText(
        text: TextSpan(children: [
          TextSpan(
              text: 'Snap',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 24 : 30,
                  letterSpacing: 0.5)),
          TextSpan(
              text: 'Law',
              style: GoogleFonts.poppins(
                  color: const Color(0xFFF4A324),
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 24 : 30,
                  letterSpacing: 0.5)),
        ]),
      ),
      SizedBox(height: compact ? 3 : 5),
      Text('Justice Made Simple',
          style: GoogleFonts.poppins(
              color: const Color(0xFF8892B0),
              fontSize: compact ? 11 : 12,
              letterSpacing: 1.8)),
    ]);
  }

  Widget _buildChooserLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4A324).withOpacity(0.09),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: const Color(0xFFF4A324).withOpacity(0.40), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFF4A324).withOpacity(0.12),
              blurRadius: 12),
        ],
      ),
      child: Text('CHOOSE YOUR PORTAL',
          style: GoogleFonts.poppins(
              color: const Color(0xFFF4A324),
              fontSize: 10,
              letterSpacing: 2.8,
              fontWeight: FontWeight.w700)),
    );
  }
}

// ─── Portal Card ─────────────────────────────────────────────────────────────
class _PortalCard extends StatefulWidget {
  final String lottiePath;
  final IconData fallbackIcon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _PortalCard({
    required this.lottiePath,
    required this.fallbackIcon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  State<_PortalCard> createState() => _PortalCardState();
}

class _PortalCardState extends State<_PortalCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  bool _hovered = false;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : (_hovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) {
              final glow = 0.07 + _pulse.value * 0.06;
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF0B1033),
                  border: Border.all(
                    color: accent.withOpacity(_hovered ? 0.40 : 0.14),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(_hovered ? glow + 0.08 : glow * 0.35),
                      blurRadius: _pressed ? 30 : 18,
                      offset: const Offset(0, 4),
                    ),
                    const BoxShadow(
                      color: Color(0x44000000),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Lottie / Icon — top section
                      Expanded(
                        child: Center(
                          child: Lottie.asset(
                            widget.lottiePath,
                            fit: BoxFit.contain,
                            repeat: true,
                            errorBuilder: (_, __, ___) => Icon(
                              widget.fallbackIcon,
                              color: accent,
                              size: 52,
                            ),
                          ),
                        ),
                      ),
                      // Badge pill (below animation)
                      if (widget.badge != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: (widget.badgeColor ?? accent).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (widget.badgeColor ?? accent).withOpacity(0.50),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            widget.badge!,
                            style: GoogleFonts.poppins(
                              color: widget.badgeColor ?? accent,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Title in accent color
                      Text(
                        widget.title,
                        style: GoogleFonts.poppins(
                          color: accent,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Subtitle
                      Text(
                        widget.subtitle,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 10,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      // Arrow
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: accent.withOpacity(0.65),
                        size: 13,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

