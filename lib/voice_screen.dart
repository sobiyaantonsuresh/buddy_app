import 'package:flutter/material.dart';
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

class _ScreenVoiceState extends State<ScreenVoice> {
  int _selectedNavIndex = 0; // Active state
  bool _isListening = true;
  String _userCommand = '"Buddy, scan for any unregistered guests in the yard."';
  String _buddyResponse = '"Starting yard scan now. Will alert you if unknown movement is found."';

  void _handleQuickCommand(String command) {
    setState(() {
      _userCommand = '"Buddy, $command."';
      if (command == 'Come here') {
        _buddyResponse = '"Navigating towards your coordinates now."';
      } else if (command == 'Sit') {
        _buddyResponse = '"Holding stationary posture at current waypoint."';
      } else if (command == 'Patrol') {
        _buddyResponse = '"Starting perimeter security sweep."';
      } else if (command == 'Follow me') {
        _buddyResponse = '"Target lock acquired. Following escort routine."';
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                // Top Status Bar with Back Button & Theme Toggle
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
                              size: 18,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            tooltip: 'Back',
                            onPressed: () => Navigator.maybePop(context),
                          ),
                          Text(
                            '9:41',
                            style: TextStyle(
                              fontSize: 14,
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
                              size: 20,
                            ),
                            tooltip: 'Toggle Theme',
                            onPressed: widget.onThemeToggle,
                          ),
                          Icon(Icons.wifi, size: 18, color: isDark ? Colors.white70 : Colors.black54),
                          const SizedBox(width: 8),
                          Icon(Icons.battery_full, size: 20, color: isDark ? Colors.white70 : Colors.black54),
                        ],
                      ),
                    ],
                  ),
                ),

                // Header Title & Active Status
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AI Voice Assistant',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF27AE60),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Active Voice link',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Scrollable Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // Voice Pulse Visualizer
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF2F80FF).withValues(alpha: 0.15),
                                ),
                              ),
                              Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? const Color(0xFF162033) : Colors.white,
                                  border: Border.all(
                                    width: 2.5,
                                    color: const Color(0xFF2F80FF),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2F80FF).withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                                child: const Icon(
                                  Icons.graphic_eq_rounded,
                                  color: Color(0xFF2F80FF),
                                  size: 42,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text(
                          _isListening ? 'Listening...' : 'Tap Mic to Speak',
                          style: const TextStyle(
                            color: Color(0xFF2F80FF),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Animated Voice Waveform Bars
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildWaveBar(16),
                            _buildWaveBar(26),
                            _buildWaveBar(36),
                            _buildWaveBar(20),
                            _buildWaveBar(14),
                            _buildWaveBar(30),
                            _buildWaveBar(18),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Chat Messages (User Bubble)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 300),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Buddy AI Response Bubble
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 300),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Quick Commands Chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildCommandChip('Come here', isDark),
                            _buildCommandChip('Sit', isDark),
                            _buildCommandChip('Patrol', isDark),
                            _buildCommandChip('Follow me', isDark),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Center Mic Button
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isListening = !_isListening;
                            });
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isListening ? const Color(0xFF2F80FF) : Colors.grey.shade700,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2F80FF).withValues(alpha: 0.4),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Icon(
                              _isListening ? Icons.mic : Icons.mic_off,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Bottom Navigation Bar
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF162033) : Colors.white,
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
      width: 4,
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
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: () => _handleQuickCommand(label),
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
            size: 22,
            color: const Color(0xFF8F9BB3),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8F9BB3),
            ),
          ),
        ],
      ),
    );
  }
}