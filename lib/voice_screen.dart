import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';
import 'control_screen.dart';
import 'camera_screen.dart';
import 'activity_screen.dart';

class ScreenVoice extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const ScreenVoice({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<ScreenVoice> createState() => _ScreenVoiceState();
}

class _ScreenVoiceState extends State<ScreenVoice> with SingleTickerProviderStateMixin {
  int _selectedNavIndex = 0;
  bool _isListening = false;
  bool _isProcessing = false;
  String _userCommand = '"Buddy, scan surroundings for visitors."';
  String _buddyResponse = '"Starting 360 camera sweep. Tracking perimeter."';

  static const String _baseUrl = kIsWeb ? "http://localhost:5000" : "http://192.168.8.192:5000";
  Timer? _clockTimer;
  String _currentTimeString = '';

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _updateClock() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    if (mounted) {
      setState(() {
        _currentTimeString = '$hour:$minute $period';
      });
    }
  }

  Future<void> _handleCommand(String command) async {
    setState(() {
      _userCommand = '"Buddy, $command."';
      _isProcessing = true;
      _buddyResponse = '"Processing command..."';
    });

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/control/voice_command'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'command': command}),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _buddyResponse = '"${data['response'] ?? 'Command executed successfully.'}"';
          });
        }
      } else {
        _fallbackResponse(command);
      }
    } catch (_) {
      _fallbackResponse(command);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // 4-Wheel Robot-kku thaguthiyaana direct responses mattum:
  void _fallbackResponse(String command) {
    if (!mounted) return;
    setState(() {
      if (command == 'Come here' || command == 'Move forward') {
        _buddyResponse = '"Motors active. Rolling towards you now."';
      } else if (command == 'Stop') {
        _buddyResponse = '"Brakes applied. Robot stationary."';
      } else if (command == 'Patrol area') {
        _buddyResponse = '"Patrol route started. Monitoring room."';
      } else if (command == 'Scan surroundings') {
        _buddyResponse = '"Panning camera sensor to scan environment."';
      } else {
        _buddyResponse = '"Command received. Executing action."';
      }
    });
  }

  void _onBottomNavTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScreenHome(
            isDarkMode: widget.isDarkMode,
            onThemeToggle: widget.onThemeToggle,
          ),
        ),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScreenControl(
            isDarkMode: widget.isDarkMode,
            onThemeToggle: widget.onThemeToggle,
          ),
        ),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScreenCamera(
            isDarkMode: widget.isDarkMode,
            onThemeToggle: widget.onThemeToggle,
          ),
        ),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScreenActivity(
            isDarkMode: widget.isDarkMode,
            onThemeToggle: widget.onThemeToggle,
          ),
        ),
      );
    } else {
      setState(() => _selectedNavIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF060B16) : const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Column(
              children: [
                // Top Status Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios_new,
                              size: 16,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            tooltip: 'Back',
                            onPressed: () => Navigator.maybePop(context),
                          ),
                          Text(
                            _currentTimeString.isEmpty ? '...' : _currentTimeString,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isDark ? Icons.light_mode : Icons.dark_mode,
                              color: isDark ? const Color(0xFF2F80FF) : Colors.amber.shade800,
                              size: 18,
                            ),
                            onPressed: widget.onThemeToggle,
                          ),
                          Icon(Icons.wifi, size: 16, color: isDark ? Colors.white70 : Colors.black54),
                          const SizedBox(width: 8),
                          Icon(Icons.battery_full, size: 18, color: isDark ? Colors.white70 : Colors.black54),
                        ],
                      ),
                    ],
                  ),
                ),

                // Header Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AI Voice Assistant',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF27AE60),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Online Link',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Area
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),

                        // Voice Pulse Animation
                        Center(
                          child: AnimatedBuilder(
                            animation: _animController,
                            builder: (context, child) {
                              final scale = _isListening ? 1.0 + (_animController.value * 0.12) : 1.0;
                              return Transform.scale(
                                scale: scale,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF2F80FF).withOpacity(_isListening ? 0.25 : 0.1),
                                      ),
                                    ),
                                    Container(
                                      width: 86,
                                      height: 86,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDark ? const Color(0xFF162033) : Colors.white,
                                        border: Border.all(
                                          width: 2.5,
                                          color: const Color(0xFF2F80FF),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF2F80FF).withOpacity(0.35),
                                            blurRadius: 14,
                                            spreadRadius: 2,
                                          )
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.graphic_eq_rounded,
                                        color: Color(0xFF2F80FF),
                                        size: 38,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),

                        Text(
                          _isProcessing
                              ? 'Executing Command...'
                              : (_isListening ? 'Listening on Robot Mic...' : 'Tap Mic or Select Wheel Action'),
                          style: const TextStyle(
                            color: Color(0xFF2F80FF),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Waveform
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildWaveBar(14),
                            _buildWaveBar(24),
                            _buildWaveBar(32),
                            _buildWaveBar(18),
                            _buildWaveBar(12),
                            _buildWaveBar(28),
                            _buildWaveBar(16),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Chat bubbles
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 280),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2F80FF),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(14),
                                topRight: Radius.circular(14),
                                bottomLeft: Radius.circular(14),
                              ),
                            ),
                            child: Text(
                              _userCommand,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 280),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF162033) : Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(14),
                                topRight: Radius.circular(14),
                                bottomRight: Radius.circular(14),
                              ),
                              border: Border.all(
                                color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              _buddyResponse,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Wheeled Robot Actions Mattum (No Sit/Stand)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildCommandChip('Come here', isDark),
                            _buildCommandChip('Patrol area', isDark),
                            _buildCommandChip('Scan surroundings', isDark),
                            _buildCommandChip('Stop', isDark),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Center Mic Toggle Button
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isListening = !_isListening;
                            });
                            if (_isListening) {
                              _handleCommand('Scan surroundings');
                            }
                          },
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isListening ? const Color(0xFF2F80FF) : Colors.grey.shade700,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2F80FF).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),

                // Bottom Navigation Dock
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF060B16) : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(Icons.home_rounded, 'Home', 0),
                      _buildNavItem(Icons.tune_rounded, 'Control', 1),
                      _buildNavItem(Icons.videocam_outlined, 'Camera', 2),
                      _buildNavItem(Icons.timeline_rounded, 'Activity', 3),
                      _buildNavItem(Icons.settings_outlined, 'Settings', 4),
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

  Widget _buildWaveBar(double height) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2.5),
      width: 3.5,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF2F80FF),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildCommandChip(String label, bool isDark) {
    return ActionChip(
      backgroundColor: isDark ? const Color(0xFF162033) : Colors.white,
      side: BorderSide(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
      ),
      label: Text(
        '"$label"',
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: _isProcessing ? null : () => _handleCommand(label),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    return GestureDetector(
      onTap: () => _onBottomNavTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF8F9BB3),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8F9BB3),
            ),
          ),
        ],
      ),
    );
  }
}