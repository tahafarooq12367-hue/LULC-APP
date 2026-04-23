import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'upload_screen.dart';
import 'previous_work_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildDashboard(),
          const UploadScreen(),
          const PreviousWorkScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ── Bottom Navigation ─────────────────────────────
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentTab,
      onTap: (index) {
        setState(() {
          _currentTab = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.upload),
          label: "Upload",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: "History",
        ),
      ],
    );
  }

  // ── Dashboard ─────────────────────────────
  Widget _buildDashboard() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "LULC Classifier",
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // 🔥 BIG CARD
          _bigCard(
            title: "Upload Image",
            subtitle: "Classify satellite or aerial imagery",
            icon: Icons.cloud_upload,
            onTap: () {
              setState(() {
                _currentTab = 1;
              });
            },
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _smallCard(
                  title: "Previous Work",
                  icon: Icons.history,
                  color: AppTheme.oceanBlue,
                  onTap: () {
                    setState(() {
                      _currentTab = 2;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _smallCard(
                  title: "About",
                  icon: Icons.info,
                  color: AppTheme.earthBrown,
                  onTap: _showAbout,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Big Card ─────────────────────────────
  Widget _bigCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.midGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style: const TextStyle(color: Colors.white70)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ── Small Card ─────────────────────────────
  Widget _smallCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(title),
          ],
        ),
      ),
    );
  }

  // ── About Bottom Sheet ─────────────────────────────
  void _showAbout() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: const Text(
            "LULC AI Classifier\n\nBuilt with Flutter + AI",
          ),
        );
      },
    );
  }
}