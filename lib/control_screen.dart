import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'camera_screen.dart';
import 'activity_screen.dart';
import 'settings_screen.dart';

class ScreenControl extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const ScreenControl({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<ScreenControl> createState() => _ScreenControlState();
}

class _ScreenControlState extends State<ScreenControl> {
  int _selectedNavIndex = 1; // Control Tab
  String _activePosture = 'Stand';
  double _speedValue = 1.0;

  void _onBottomNavTapped(int index) {
    if (index == _selectedNavIndex) return;

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
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScreenSettings(
            isDarkMode: widget.isDarkMode,
            onThemeToggle: widget.onThemeToggle,
          ),
        ),
      );
    } else {
      setState(() => _selectedNavIndex = index);
    }
  }

  void _sendCommand(String direction) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Robot Moving: $direction'),
        duration: const Duration(milliseconds: 600),
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

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Robot Control',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manual directional pilot & kinematic commands',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Directional Joystick Pad
                        Center(
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF162033) : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                )
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Forward
                                Positioned(
                                  top: 10,
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_drop_up_rounded, size: 48, color: Color(0xFF2F80FF)),
                                    onPressed: () => _sendCommand('FORWARD'),
                                  ),
                                ),
                                // Backward
                                Positioned(
                                  bottom: 10,
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_drop_down_rounded, size: 48, color: Color(0xFF2F80FF)),
                                    onPressed: () => _sendCommand('BACKWARD'),
                                  ),
                                ),
                                // Left
                                Positioned(
                                  left: 10,
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_left_rounded, size: 48, color: Color(0xFF2F80FF)),
                                    onPressed: () => _sendCommand('LEFT'),
                                  ),
                                ),
                                // Right
                                Positioned(
                                  right: 10,
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_right_rounded, size: 48, color: Color(0xFF2F80FF)),
                                    onPressed: () => _sendCommand('RIGHT'),
                                  ),
                                ),
                                // Center Stop Button
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEB5757).withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFEB5757), width: 1.5),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.stop_rounded, color: Color(0xFFEB5757), size: 30),
                                    onPressed: () => _sendCommand('HALT'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Posture Selection
                        Text(
                          'ROBOTIC POSTURE',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildPostureBtn('Stand', isDark),
                            const SizedBox(width: 8),
                            _buildPostureBtn('Sit', isDark),
                            const SizedBox(width: 8),
                            _buildPostureBtn('Crouch', isDark),
                            const SizedBox(width: 8),
                            _buildPostureBtn('Shake', isDark),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Speed Control Slider
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF162033) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Throttle Speed',
                                    style: TextStyle(
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${_speedValue.toStringAsFixed(1)} m/s',
                                    style: const TextStyle(
                                      color: Color(0xFF2F80FF),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: _speedValue,
                                min: 0.2,
                                max: 2.5,
                                activeColor: const Color(0xFF2F80FF),
                                onChanged: (v) => setState(() => _speedValue = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
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

  Widget _buildPostureBtn(String label, bool isDark) {
    final isSelected = _activePosture == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activePosture = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2F80FF) : (isDark ? const Color(0xFF162033) : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF2F80FF) : (isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0)),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF0F172A)),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () => _onBottomNavTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: isSelected ? const Color(0xFF2F80FF) : const Color(0xFF8F9BB3),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? const Color(0xFF2F80FF) : const Color(0xFF8F9BB3),
            ),
          ),
        ],
      ),
    );
  }
}