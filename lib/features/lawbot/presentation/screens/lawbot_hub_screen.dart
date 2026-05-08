import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/snaplaw_widgets.dart';
import '../../../../theme/snaplaw_theme.dart';

class LawBotHubScreen extends StatelessWidget {
  const LawBotHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020818),
      appBar: AppBar(
        backgroundColor: SnapLawColors.bgDark,
        elevation: 0,
        title: const Text('LawBot Assistant',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: AppBackground(
        overlayOpacity: 0.55,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: Column(children: [
                    Container(
                      width: 84, height: 84,
                      decoration: BoxDecoration(
                        gradient: SnapLawGradients.primary,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [BoxShadow(
                          color: SnapLawColors.primary.withOpacity(0.45),
                          blurRadius: 20, offset: const Offset(0, 6),
                        )],
                      ),
                      child: const Icon(Icons.smart_toy, size: 42, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text('LawBot Assistant',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('How can I help you today?',
                      style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.60))),
                  ]),
                ),
              ),
              const SizedBox(height: 32),

              // Tool Cards
              FadeSlideIn(delay: const Duration(milliseconds: 150),
                child: _ToolCard(
                  icon: Icons.smart_toy,
                  title: 'LawBot Chat',
                  subtitle: 'Ask any question about Pakistani law — powered by Gemini AI',
                  color: SnapLawColors.primary,
                  onTap: () => context.push('/lawbot/qa'),
                )),
              const SizedBox(height: 14),
              FadeSlideIn(delay: const Duration(milliseconds: 250),
                child: _ToolCard(
                  icon: Icons.article_outlined,
                  title: 'Simplify Contract',
                  subtitle: 'Convert complex legal jargon into plain, simple language',
                  color: SnapLawColors.citizenGreen,
                  onTap: () => context.push('/lawbot/simplify'),
                )),
              const SizedBox(height: 14),
              FadeSlideIn(delay: const Duration(milliseconds: 350),
                child: _ToolCard(
                  icon: Icons.shield_outlined,
                  title: 'Abuse Detection',
                  subtitle: 'Detect abuse, hate speech, threats & harassment with Pakistani law references',
                  color: SnapLawColors.warning,
                  onTap: () => context.push('/lawbot/bias'),
                )),
              const SizedBox(height: 14),
              FadeSlideIn(delay: const Duration(milliseconds: 450),
                child: _ToolCard(
                  icon: Icons.shield,
                  title: 'SafeSpace — Abuse Guidance',
                  subtitle: 'Get help with harassment, violence, or abuse situations',
                  color: const Color(0xFFEC4899),
                  onTap: () => context.push('/lawbot/safespace'),
                )),

              const SizedBox(height: 28),

              // Disclaimer
              FadeSlideIn(
                delay: const Duration(milliseconds: 550),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  borderColor: SnapLawColors.info.withOpacity(0.30),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.info_outline, size: 18, color: SnapLawColors.info),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'LawBot provides general legal information based on Pakistani law. '
                        'For specific legal advice, always consult a licensed attorney.',
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.65), height: 1.4),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: GlassCard(
            padding: const EdgeInsets.all(18),
            borderColor: widget.color.withOpacity(0.30),
            child: Row(children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: widget.color.withOpacity(0.30)),
                ),
                child: Icon(widget.icon, size: 26, color: widget.color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.title, style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(widget.subtitle, style: TextStyle(
                    fontSize: 12, color: Colors.white.withOpacity(0.55), height: 1.3)),
                ]),
              ),
              Icon(Icons.chevron_right, color: widget.color.withOpacity(0.70)),
            ]),
          ),
        ),
      ),
    );
  }
}
