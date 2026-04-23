import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin     = true;
  bool _isLoading   = false;
  bool _obscurePass = true;

  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const HomeScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _submit() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      _showSnack('Please fill in all fields', Colors.orange);
      return;
    }
    if (!_isLogin && _nameCtrl.text.trim().isEmpty) {
      _showSnack('Please enter your name', Colors.orange);
      return;
    }
    setState(() => _isLoading = true);
    // Simulate a short delay then go home
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isLoading = false);
      _goHome();
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -100, right: -100,
            child: _decorBlob(280, AppTheme.midGreen.withValues(alpha: 0.18)),
          ),
          Positioned(
            bottom: -80, left: -80,
            child: _decorBlob(240, AppTheme.oceanBlue.withValues(alpha: 0.15)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isLogin ? 'Welcome\nBack' : 'Create\nAccount',
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin
                        ? 'Sign in to analyze satellite imagery'
                        : 'Join and start classifying land cover',
                    style: GoogleFonts.outfit(
                        fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  _buildTabRow(),
                  const SizedBox(height: 28),
                  AnimatedCrossFade(
                    firstChild: _buildLoginFields(),
                    secondChild: _buildRegisterFields(),
                    crossFadeState: _isLogin
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 300),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : Text(
                              _isLogin ? 'Sign In' : 'Create Account',
                              style: GoogleFonts.outfit(
                                  fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: GestureDetector(
                      onTap: () => setState(() => _isLogin = !_isLogin),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.outfit(
                              color: AppTheme.textSecondary, fontSize: 14),
                          children: [
                            TextSpan(
                              text: _isLogin
                                  ? "Don't have an account?  "
                                  : "Already have an account?  ",
                            ),
                            TextSpan(
                              text: _isLogin ? 'Register' : 'Sign In',
                              style: const TextStyle(
                                color: AppTheme.midGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorBlob(double size, Color color) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }

  Widget _buildTabRow() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(children: [
        _tabItem('Sign In', _isLogin, () => setState(() => _isLogin = true)),
        _tabItem('Register', !_isLogin, () => setState(() => _isLogin = false)),
      ]),
    );
  }

  Widget _tabItem(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? AppTheme.midGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.outfit(
                  color: active ? Colors.white : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                )),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginFields() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _inputField(
          controller: _emailCtrl,
          label: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress),
      const SizedBox(height: 16),
      _inputField(
          controller: _passCtrl,
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          isPassword: true),
    ]);
  }

  Widget _buildRegisterFields() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _inputField(
          controller: _nameCtrl,
          label: 'Full Name',
          icon: Icons.person_outline_rounded),
      const SizedBox(height: 16),
      _inputField(
          controller: _emailCtrl,
          label: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress),
      const SizedBox(height: 16),
      _inputField(
          controller: _passCtrl,
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          isPassword: true),
    ]);
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePass : false,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePass
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () =>
                    setState(() => _obscurePass = !_obscurePass),
              )
            : null,
      ),
    );
  }
}
