import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';

void main() {
  runApp(const BuddyMainApp());
}

class BuddyMainApp extends StatefulWidget {
  const BuddyMainApp({super.key});

  @override
  State<BuddyMainApp> createState() => _BuddyMainAppState();
}

class _BuddyMainAppState extends State<BuddyMainApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BUDDY Companion',
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        primaryColor: const Color(0xFF2F80FF),
        cardColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2F80FF),
          surface: Colors.white,
          onSurface: Color(0xFF0F172A),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF08111F),
        primaryColor: const Color(0xFF2F80FF),
        cardColor: const Color(0xFF162033),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2F80FF),
          surface: Color(0xFF162033),
          onSurface: Colors.white,
        ),
      ),
      home: ScreenWelcome(
        isDarkMode: _themeMode == ThemeMode.dark,
        onThemeToggle: _toggleTheme,
      ),
    );
  }
}

class ScreenWelcome extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const ScreenWelcome({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<ScreenWelcome> createState() => _ScreenWelcomeState();
}

class _ScreenWelcomeState extends State<ScreenWelcome> {
  // Web browser-kku localhost, mobile build-kku 192.168.8.192
  static const String _baseUrl = kIsWeb ? "http://localhost:5000" : "http://192.168.8.192:5000";

  Timer? _clockTimer;
  Timer? _pingTimer;
  String _currentTimeString = '';
  bool _isRobotReachable = false;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    _pingRobot();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pingRobot());
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pingTimer?.cancel();
    super.dispose();
  }

  void _updateClock() {
    if (!mounted) return;
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    setState(() {
      _currentTimeString = '$hour:$minute $period';
    });
  }

  Future<void> _pingRobot() async {
    if (!mounted) return;
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/robot_status')).timeout(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _isRobotReachable = res.statusCode == 200;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isRobotReachable = false;
        });
      }
    }
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BuddyLoginScreen(
          isDarkMode: widget.isDarkMode,
          onThemeToggle: widget.onThemeToggle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _currentTimeString.isEmpty ? '...' : _currentTimeString,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isDark ? Icons.light_mode : Icons.dark_mode,
                              color: isDark ? const Color(0xFF2F80FF) : Colors.amber.shade800,
                              size: 20,
                            ),
                            tooltip: 'Toggle Theme',
                            onPressed: widget.onThemeToggle,
                          ),
                          Icon(
                            Icons.wifi,
                            size: 18,
                            color: _isRobotReachable ? const Color(0xFF27AE60) : Colors.redAccent,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.battery_full,
                            size: 20,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        Center(
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF2F80FF).withValues(alpha: 0.15),
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? const Color(0xFF162033) : Colors.white,
                                border: Border.all(width: 3, color: const Color(0xFF2F80FF)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2F80FF).withValues(alpha: 0.3),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                              child: const Icon(
                                Icons.smart_toy_rounded,
                                size: 44,
                                color: Color(0xFF2F80FF),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Welcome to BUDDY',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRobotReachable
                              ? 'BUDDY is online and ready to connect'
                              : 'Connecting to BUDDY on local Wi-Fi...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: _isRobotReachable
                                ? const Color(0xFF27AE60)
                                : (isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B)),
                            fontWeight: _isRobotReachable ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildFeatureCard(
                          icon: Icons.shield_outlined,
                          title: 'Smart Patrol & Security',
                          description: 'Autonomous monitoring with high-fidelity perimeter alerts.',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureCard(
                          icon: Icons.face_retouching_natural_outlined,
                          title: 'AI Emotion Detection',
                          description: 'Analyze facial geometry and mood index in real-time.',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureCard(
                          icon: Icons.mic_none_outlined,
                          title: 'Voice Interaction',
                          description: 'Hands-free command link with an adaptive companion.',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2F80FF),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _navigateToLogin(context),
                          child: const Text(
                            'Get Started',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _navigateToLogin(context),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Already have BUDDY? ',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                              ),
                              const TextSpan(
                                text: 'Sign In',
                                style: TextStyle(
                                  color: Color(0xFF2F80FF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF162033) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Icon(icon, color: const Color(0xFF2F80FF), size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}