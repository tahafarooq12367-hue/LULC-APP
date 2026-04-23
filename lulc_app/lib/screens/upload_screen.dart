import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../models/result_model.dart';
import 'processing_screen.dart';
import 'result_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with SingleTickerProviderStateMixin {
  File?             _selectedImage;
  final ImagePicker _picker = ImagePicker();

  late final AnimationController _borderCtrl =
  AnimationController(vsync: this,
      duration: const Duration(milliseconds: 1600))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _borderCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not access image: $e',
            style: GoogleFonts.outfit()),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please select an image first',
            style: GoogleFonts.outfit()),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    final result = await Navigator.push<ResultModel>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) =>
            ProcessingScreen(imageFile: _selectedImage!),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );

    if (result != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(children: [
        // ── Header ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 4),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upload Image',
                        style: GoogleFonts.outfit(
                            fontSize: 24, fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary)),
                    Text('Select satellite or aerial imagery to analyze',
                        style: GoogleFonts.outfit(
                            fontSize: 13, color: AppTheme.textSecondary)),
                  ]),
            ),
            if (_selectedImage != null)
              TextButton.icon(
                onPressed: () => setState(() => _selectedImage = null),
                icon: const Icon(Icons.close_rounded,
                    color: Colors.redAccent, size: 16),
                label: Text('Clear', style: GoogleFonts.outfit(
                    color: Colors.redAccent, fontSize: 13)),
              ),
          ]),
        ),

        const SizedBox(height: 20),

        // ── Image Preview / Drop Zone ───────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _selectedImage != null
                ? _buildImagePreview()
                : _buildDropZone(),
          ),
        ),

        const SizedBox(height: 20),

        // ── Source Selection Buttons ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Expanded(child: _sourceButton(
              label: 'Gallery',
              icon: Icons.photo_library_outlined,
              onTap: () => _pickImage(ImageSource.gallery),
            )),
            const SizedBox(width: 14),
            Expanded(child: _sourceButton(
              label: 'Camera',
              icon: Icons.camera_alt_outlined,
              onTap: () => _pickImage(ImageSource.camera),
            )),
          ]),
        ),

        const SizedBox(height: 14),

        // ── Analyze Button ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity, height: 58,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: ElevatedButton(
                onPressed: _selectedImage != null ? _analyzeImage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedImage != null
                      ? AppTheme.midGreen
                      : AppTheme.cardBorder,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.analytics_rounded, size: 22),
                    const SizedBox(width: 10),
                    Text('Analyze Image',
                        style: GoogleFonts.outfit(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(fit: StackFit.expand, children: [
        Image.file(_selectedImage!, fit: BoxFit.cover),
        // Color overlay tint
        Container(color: AppTheme.midGreen.withOpacity(0.08)),
        // Bottom info bar
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.72),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.lightGreen, size: 18),
              const SizedBox(width: 8),
              Text('Image ready for analysis',
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildDropZone() {
    return AnimatedBuilder(
      animation: _borderCtrl,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppTheme.midGreen.withOpacity(
              0.2 + 0.3 * (_borderCtrl.value < 0.5
                  ? _borderCtrl.value * 2
                  : (1 - _borderCtrl.value) * 2),
            ),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 86, height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.midGreen.withOpacity(0.1),
              ),
              child: const Icon(Icons.satellite_alt_rounded,
                  color: AppTheme.midGreen, size: 42),
            ),
            const SizedBox(height: 22),
            Text('Select Satellite Image',
                style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary, fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Use Gallery or Camera below',
                style: GoogleFonts.outfit(
                    color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            Text('Supported: JPG, PNG, TIFF  |  Max: 10MB',
                style: GoogleFonts.outfit(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _sourceButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: AppTheme.skyBlue, size: 22),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.outfit(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600, fontSize: 15)),
        ]),
      ),
    );
  }
}
