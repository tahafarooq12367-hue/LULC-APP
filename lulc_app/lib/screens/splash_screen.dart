
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late final AnimationController _bgCtrl =
  AnimationController(vsync: this, duration: const Duration(seconds: 10))
    ..repeat();

  late final AnimationController _logoCtrl =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  late final AnimationController _contentCtrl =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  late final AnimationController _pulseCtrl =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat(reverse: true);

  // Logo animations
  late final Animation<double> _logoScale =
  CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut)
      .drive(Tween(begin: 0.0, end: 1.0));
  late final Animation<double> _logoFade =
  CurvedAnimation(parent: _logoCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn))
      .drive(Tween(begin: 0.0, end: 1.0));

  // Text animations
  late final Animation<double> _titleFade =
  CurvedAnimation(parent: _contentCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn))
      .drive(Tween(begin: 0.0, end: 1.0));
  late final Animation<Offset> _titleSlide =
  CurvedAnimation(parent: _contentCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic))
      .drive(Tween(begin: const Offset(0, 0.5), end: Offset.zero));
  late final Animation<double> _subtitleFade =
  CurvedAnimation(parent: _contentCtrl,
      curve: const Interval(0.3, 0.7, curve: Curves.easeIn))
      .drive(Tween(begin: 0.0, end: 1.0));

  // Button animations
  late final Animation<double> _btnFade =
  CurvedAnimation(parent: _contentCtrl,
      curve: const Interval(0.6, 1.0, curve: Curves.easeIn))
      .drive(Tween(begin: 0.0, end: 1.0));
  late final Animation<Offset> _btnSlide =
  CurvedAnimation(parent: _contentCtrl,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic))
      .drive(Tween(begin: const Offset(0, 1.0), end: Offset.zero));

  // Pulse for logo glow
  late final Animation<double> _pulse =
  CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut)
      .drive(Tween(begin: 0.93, end: 1.07));

  @override
  void initState() {
    super.initState();
    // Staggered animation start
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _logoCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _contentCtrl.forward();
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    _contentCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _goToAuth() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const AuthScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Animated satellite grid background ──────────────────────────
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: SatelliteGridPainter(_bgCtrl.value),
            ),
          ),

          // ── Gradient overlay ─────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.darkSurface.withOpacity(0.3),
                  AppTheme.darkSurface.withOpacity(0.8),
                  AppTheme.darkSurface,
                ],
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo with pulse
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) => Transform.scale(
                        scale: _pulse.value,
                        child: _buildLogo(),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 42),

                // App name
                SlideTransition(
                  position: _titleSlide,
                  child: FadeTransition(
                    opacity: _titleFade,
                    child: Text(
                      'LULC AI Classifier',
                      style: GoogleFonts.outfit(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Subtitle
                FadeTransition(
                  opacity: _subtitleFade,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 52),
                    child: Text(
                      'Deep Learning Based Land Use\nLand Cover Detection',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.7,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Get Started button
                SlideTransition(
                  position: _btnSlide,
                  child: FadeTransition(
                    opacity: _btnFade,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: _goToAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.midGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Get Started',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.arrow_forward_rounded, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 52),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [AppTheme.midGreen, AppTheme.deepForest],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.midGreen.withOpacity(0.45),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(70, 70),
          painter: EarthLogoPainter(),
        ),
      ),
    );
  }
}

// ── Earth Logo Painter ────────────────────────────────────────────────────────
class EarthLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;

    // Ocean
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = AppTheme.oceanBlue);

    // Land masses
    final land = Paint()..color = AppTheme.forestGreen;
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 7, cy - 5), width: 22, height: 27),
        land);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 12, cy + 8), width: 17, height: 13),
        land);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 3, cy + 17), width: 22, height: 9),
        Paint()..color = AppTheme.sandTan);

    // Atmosphere ring
    canvas.drawCircle(
        Offset(cx, cy), r,
        Paint()
          ..color = AppTheme.lightSky.withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Satellite Grid Background Painter ────────────────────────────────────────
class SatelliteGridPainter extends CustomPainter {
  final double progress;
  SatelliteGridPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // Grid lines
    final gridPaint = Paint()
      ..color = AppTheme.midGreen.withOpacity(0.055)
      ..strokeWidth = 1.0;
    const spacing = 40.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Scanning line effect
    final scanY = (progress * size.height * 1.5) % (size.height + 80) - 40;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          AppTheme.midGreen.withOpacity(0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, scanY, size.width, 80));
    canvas.drawRect(Rect.fromLTWH(0, scanY, size.width, 80), scanPaint);

    // Corner brackets
    final bracketPaint = Paint()
      ..color = AppTheme.skyBlue.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const l = 28.0;
    const p = 22.0;

    void drawBracket(double ox, double oy, double sx, double sy) {
      canvas.drawPath(
        Path()
          ..moveTo(ox, oy + sy * l)
          ..lineTo(ox, oy)
          ..lineTo(ox + sx * l, oy),
        bracketPaint,
      );
    }

    drawBracket(p, p, 1, 1);
    drawBracket(size.width - p, p, -1, 1);
    drawBracket(p, size.height - p, 1, -1);
    drawBracket(size.width - p, size.height - p, -1, -1);
  }

  @override
  bool shouldRepaint(SatelliteGridPainter old) => old.progress != progress;
}
