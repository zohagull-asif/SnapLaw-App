import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/password_validator.dart';
import '../../../../core/widgets/password_strength_indicator.dart';
import '../../../../core/widgets/snaplaw_widgets.dart';
import '../../data/models/user_model.dart';
import '../providers/auth_provider.dart';

// ─────────────────────────────────────────────
// Register Screen
// ─────────────────────────────────────────────
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {

  // ── Form controllers (unchanged) ─────────────
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserRole _selectedRole = UserRole.client;

  // ── Animation controllers ─────────────────
  late final AnimationController _entryCtrl;
  late final Animation<double> _logoIn;
  late final Animation<double> _cardIn;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();

    _logoIn = CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0.0, 0.50, curve: Curves.easeOut));
    _cardIn = CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0.18, 0.90, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _nameController.dispose(); _emailController.dispose();
    _phoneController.dispose(); _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Auth logic (unchanged) ─────────────────
  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(authProvider.notifier).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
            role: _selectedRole,
          );
    }
  }

  void _navigateBasedOnRole(UserModel user) {
    switch (user.role) {
      case UserRole.client:  context.go('/client'); break;
      case UserRole.lawyer:  context.go('/lawyer'); break;
      case UserRole.admin:   context.go('/admin');  break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.errorMessage!),
          backgroundColor: AppColors.error,
        ));
        ref.read(authProvider.notifier).clearError();
      } else if (next.status == AuthStatus.pendingVerification) {
        context.go('/verify-otp');
      } else if (next.status == AuthStatus.authenticated && next.user != null) {
        _navigateBasedOnRole(next.user!);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF020818),
      body: AppBackground(
        overlayOpacity: 0.62,
        child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [

          // Logo
          AnimatedBuilder(
            animation: _logoIn,
            builder: (_, __) => Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Opacity(
                    opacity: _logoIn.value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, (1 - _logoIn.value) * -16),
                      child: _buildLogoRow(),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Glass card slides up
          AnimatedBuilder(
            animation: _cardIn,
            builder: (_, __) {
              final slideY = (1.0 - _cardIn.value) * 60.0;
              return Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 72,
                  bottom: MediaQuery.of(context).padding.bottom + 12,
                  left: 16, right: 16,
                ),
                child: Transform.translate(
                  offset: Offset(0, slideY),
                  child: Opacity(
                    opacity: _cardIn.value.clamp(0.0, 1.0),
                    child: _buildCard(authState),
                  ),
                ),
              );
            },
          ),

          // Back button
          Positioned(
            top: 0, left: 0,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
                onPressed: () => context.pop(),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildLogoRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.balance, color: Colors.white, size: 20),
        const SizedBox(width: 7),
        RichText(
          text: const TextSpan(children: [
            TextSpan(text: 'SNAP', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900,
              fontSize: 20, letterSpacing: 2)),
            TextSpan(text: 'LAW', style: TextStyle(
              color: Color(0xFFF4A324), fontWeight: FontWeight.w900,
              fontSize: 20, letterSpacing: 2)),
          ]),
        ),
      ],
    );
  }

  Widget _buildCard(AuthState authState) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F1535),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF4A324).withOpacity(0.28), width: 1.5),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  const Text('Create Account',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 22)),
                  const SizedBox(height: 3),
                  Text('Join SnapLaw to get legal assistance',
                    style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13)),
                  const SizedBox(height: 22),

                  // Role selection
                  _SectionLabel('Select Your Role'),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _GlassRoleCard(
                      icon: Icons.person_outline,
                      title: 'Client',
                      isSelected: _selectedRole == UserRole.client,
                      onTap: () => setState(() => _selectedRole = UserRole.client),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _GlassRoleCard(
                      icon: Icons.gavel,
                      title: 'Lawyer',
                      isSelected: _selectedRole == UserRole.lawyer,
                      onTap: () => setState(() => _selectedRole = UserRole.lawyer),
                    )),
                  ]),
                  const SizedBox(height: 20),

                  // Full Name
                  _SectionLabel('Full Name'),
                  const SizedBox(height: 6),
                  _glassInput(
                    controller: _nameController,
                    hint: 'Your full name',
                    prefixIcon: Icons.person_outline,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.isEmpty) ? AppStrings.nameRequired : null,
                  ),
                  const SizedBox(height: 14),

                  // Email
                  _SectionLabel('Email'),
                  const SizedBox(height: 6),
                  _glassInput(
                    controller: _emailController,
                    hint: 'you@example.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.isEmpty) return AppStrings.emailRequired;
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v))
                        return AppStrings.invalidEmail;
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Phone
                  _SectionLabel('Phone Number'),
                  const SizedBox(height: 6),
                  _glassInput(
                    controller: _phoneController,
                    hint: '+92 3XX XXXXXXX',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Phone number is required';
                      final clean = value.replaceAll(RegExp(r'[\s\-]'), '');
                      if (clean.startsWith('+92')) {
                        if (!RegExp(r'^\+923[0-9]{9}$').hasMatch(clean))
                          return 'Invalid Pakistan number. Format: +92 3XX XXXXXXX';
                      } else if (clean.startsWith('92')) {
                        if (!RegExp(r'^923[0-9]{9}$').hasMatch(clean))
                          return 'Invalid Pakistan number. Format: 92 3XX XXXXXXX';
                      } else if (clean.startsWith('0')) {
                        if (!RegExp(r'^03[0-9]{9}$').hasMatch(clean))
                          return 'Invalid Pakistan number. Format: 03XX XXXXXXX';
                      } else {
                        return 'Invalid format. Use +92 3XX XXXXXXX or 03XX XXXXXXX';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Password
                  _SectionLabel('Password'),
                  const SizedBox(height: 6),
                  _glassInput(
                    controller: _passwordController,
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outlined,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.white60, size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) => PasswordValidator.validate(v ?? ''),
                  ),

                  // Strength indicator
                  if (_passwordController.text.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _GlassPasswordStrength(password: _passwordController.text),
                  ],
                  const SizedBox(height: 14),

                  // Confirm Password
                  _SectionLabel('Confirm Password'),
                  const SizedBox(height: 6),
                  _glassInput(
                    controller: _confirmPasswordController,
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outlined,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleRegister(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.white60, size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    validator: (v) => PasswordValidator.validateConfirmPassword(
                      _passwordController.text, v ?? ''),
                  ),
                  const SizedBox(height: 26),

                  // Register button
                  _RegisterButton(
                    isLoading: authState.status == AuthStatus.loading,
                    onPressed: _handleRegister,
                  ),
                  const SizedBox(height: 20),

                  // Login link
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(AppStrings.alreadyHaveAccount,
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                    TextButton(
                      onPressed: () => context.pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFF4A324),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      child: const Text(AppStrings.signIn),
                    ),
                  ]),
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
    IconData? prefixIcon,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      cursorColor: const Color(0xFFF4A324),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF8892B0), fontSize: 13),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: const Color(0xFF8892B0), size: 20)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF141B45),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
      validator: validator,
    );
  }
}

// ─────────────────────────────────────────────
// Password strength wrapped in glass style
// ─────────────────────────────────────────────
class _GlassPasswordStrength extends StatelessWidget {
  final String password;
  const _GlassPasswordStrength({required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = PasswordValidator.getStrength(password);
    final label = PasswordValidator.getStrengthLabel(strength);
    final color = _strengthColor(strength);
    final requirements = PasswordValidator.getRequirements(password);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Strength bar
          Row(children: List.generate(4, (i) => Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
              decoration: BoxDecoration(
                color: i < strength ? color : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ))),
          const SizedBox(height: 6),
          Text('Strength: $label',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          // Requirements
          ...requirements.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(children: [
              Icon(e.value ? Icons.check_circle : Icons.cancel,
                size: 13, color: e.value ? const Color(0xFF00C896) : Colors.white38),
              const SizedBox(width: 6),
              Text(e.key,
                style: TextStyle(
                  color: e.value ? Colors.white70 : Colors.white38,
                  fontSize: 11)),
            ]),
          )),
        ],
      ),
    );
  }

  Color _strengthColor(int s) {
    if (s <= 1) return const Color(0xFFFF6B6B);
    if (s == 2) return const Color(0xFFFACC15);
    if (s == 3) return const Color(0xFF60A5FA);
    return const Color(0xFF00C896);
  }
}

// ─────────────────────────────────────────────
// Glass role card
// ─────────────────────────────────────────────
class _GlassRoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _GlassRoleCard({
    required this.icon, required this.title,
    required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF4A324).withOpacity(0.25)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFF4A324) : Colors.white.withOpacity(0.18),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFFF4A324).withOpacity(0.25),
                  blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(children: [
          Icon(icon, size: 28,
            color: isSelected ? const Color(0xFFF4A324) : Colors.white.withOpacity(0.7)),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFFF4A324) : Colors.white.withOpacity(0.8),
          )),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
    style: TextStyle(color: Colors.white.withOpacity(0.82),
        fontSize: 12, fontWeight: FontWeight.w600));
}

// ─────────────────────────────────────────────
// Register button (gold gradient with press scale)
// ─────────────────────────────────────────────
class _RegisterButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _RegisterButton({required this.isLoading, required this.onPressed});

  @override
  State<_RegisterButton> createState() => _RegisterButtonState();
}

class _RegisterButtonState extends State<_RegisterButton> {
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
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF4A324), Color(0xFFF59E0B), Color(0xFFF4A324)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
              color: const Color(0xFFF4A324).withOpacity(0.40),
              blurRadius: 14, offset: const Offset(0, 5),
            )],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                : const Text('Create Account',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
          ),
        ),
      ),
    );
  }
}
