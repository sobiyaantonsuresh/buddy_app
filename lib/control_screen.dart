import 'dart:math' as math;
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
  int _selectedNavIndex = 1;
  String _activePosture = 'Stand';
  final double _speedValue = 1.2;
  bool _followMode = false;
  bool _headlightOn = true;
  bool _nightVision = false;

  // PUBG-Style Dynamic 360 Joystick Variables
  Offset _joystickKnob = Offset.zero;
  final double _joystickRadius = 55.0;
  String _currentDirection = 'STANDBY';

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

  void _updateJoystick(Offset localPosition, Size centerSize) {
    final center = Offset(centerSize.width / 2, centerSize.height / 2);
    final delta = localPosition - center;
    final distance = delta.distance;
    final angle = delta.direction;

    Offset clampedOffset;
    if (distance <= _joystickRadius) {
      clampedOffset = delta;
    } else {
      clampedOffset = Offset(
        math.cos(angle) * _joystickRadius,
        math.sin(angle) * _joystickRadius,
      );
    }

    String direction = 'DRIVING';
    final degrees = (angle * 180 / math.pi);

    if (degrees >= -45 && degrees <= 45) {
      direction = 'STRAFE RIGHT ▶';
    } else if (degrees > 45 && degrees < 135) {
      direction = 'REVERSE ▼';
    } else if (degrees >= 135 || degrees <= -135) {
      direction = '◀ STRAFE LEFT';
    } else if (degrees > -135 && degrees < -45) {
      direction = 'FORWARD ▲';
    }

    setState(() {
      _joystickKnob = clampedOffset;
      _currentDirection = direction;
    });
  }

  void _resetJoystick() {
    setState(() {
      _joystickKnob = Offset.zero;
      _currentDirection = 'STANDBY';
    });
  }

  void _triggerAction(String action) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('BUDDY Command: $action'),
        duration: const Duration(milliseconds: 600),
        backgroundColor: const Color(0xFF2F80FF),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: isLandscape
                ? _buildLandscapeGamingCockpit(isDark)
                : _buildPortraitCockpit(isDark),
          ),
        );
      },
    );
  }

  // 1. LANDSCAPE MODE (Full PUBG-Style Dual Thumb Cockpit)
  Widget _buildLandscapeGamingCockpit(bool isDark) {
    return Stack(
      children: [
        // Fullscreen Live FPV Feed
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: _nightVision ? const Color(0xFF051C08) : const Color(0xFF0A1128),
            image: const DecorationImage(
              image: NetworkImage("https://placehold.co/800x450/0a1128/ffffff.png?text=BUDDY+FPV+LANDSCAPE+STREAM"),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Center Crosshair HUD
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 1),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.cyanAccent, shape: BoxShape.circle)),
                Positioned(top: 0, child: Container(width: 1, height: 10, color: Colors.cyanAccent.withValues(alpha: 0.5))),
                Positioned(bottom: 0, child: Container(width: 1, height: 10, color: Colors.cyanAccent.withValues(alpha: 0.5))),
                Positioned(left: 0, child: Container(width: 10, height: 1, color: Colors.cyanAccent.withValues(alpha: 0.5))),
                Positioned(right: 0, child: Container(width: 10, height: 1, color: Colors.cyanAccent.withValues(alpha: 0.5))),
              ],
            ),
          ),
        ),

        // Top HUD Bar (Telemetry)
        Positioned(
          top: 10,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'STATUS: $_currentDirection | SPEED: ${_speedValue.toStringAsFixed(1)} m/s',
                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(_headlightOn ? Icons.lightbulb : Icons.lightbulb_outline,
                        color: _headlightOn ? Colors.amber : Colors.white70, size: 18),
                    onPressed: () => setState(() => _headlightOn = !_headlightOn),
                  ),
                  IconButton(
                    icon: Icon(Icons.nightlight_round, color: _nightVision ? const Color(0xFF27AE60) : Colors.white70, size: 18),
                    onPressed: () => setState(() => _nightVision = !_nightVision),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Left Thumb: 360 Analog Joystick
        Positioned(
          bottom: 20,
          left: 30,
          child: _buildAnalogJoystick(),
        ),

        // Right Thumb: Quick Combat / Dog Action Buttons
        Positioned(
          bottom: 20,
          right: 30,
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildOverlayCircleBtn(Icons.pets, 'Paw', () => _triggerAction('Give Paw')),
                  const SizedBox(height: 8),
                  _buildOverlayCircleBtn(Icons.volume_up, 'Bark', () => _triggerAction('Bark')),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildOverlayCircleBtn(Icons.replay_rounded, 'Roll', () => _triggerAction('Roll 360')),
                  const SizedBox(height: 8),
                  _buildOverlayCircleBtn(
                    Icons.person_pin_circle_rounded,
                    'Follow',
                    () {
                      setState(() => _followMode = !_followMode);
                      _triggerAction(_followMode ? 'Follow Mode ON' : 'Follow Mode OFF');
                    },
                    isActive: _followMode,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. PORTRAIT MODE (Vertical Phone Screen)
  Widget _buildPortraitCockpit(bool isDark) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          children: [
            // Top Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: isDark ? const Color(0xFF08111F) : const Color(0xFF162033),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FPV PILOT COCKPIT',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                          Text('Rotate phone for Landscape Gaming Mode', style: TextStyle(color: Colors.white60, fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(_headlightOn ? Icons.lightbulb : Icons.lightbulb_outline,
                            color: _headlightOn ? Colors.amber : Colors.white60, size: 20),
                        onPressed: () => setState(() => _headlightOn = !_headlightOn),
                      ),
                      IconButton(
                        icon: Icon(Icons.nightlight_round, color: _nightVision ? const Color(0xFF27AE60) : Colors.white60, size: 20),
                        onPressed: () => setState(() => _nightVision = !_nightVision),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Live Camera Viewport
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: _nightVision ? const Color(0xFF051C08) : const Color(0xFF0A1128),
                      image: const DecorationImage(
                        image: NetworkImage("https://placehold.co/600x600/0a1128/ffffff.png?text=BUDDY+FPV+LIVE+VIEWPORT"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Center Crosshairs
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 1),
                      ),
                    ),
                  ),

                  // Status Indicator
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'STATUS: $_currentDirection',
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),

                  // Posture Switches
                  Positioned(
                    bottom: 170,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        _buildPosturePill('Stand'),
                        const SizedBox(width: 6),
                        _buildPosturePill('Sit'),
                        const SizedBox(width: 6),
                        _buildPosturePill('Crouch'),
                        const SizedBox(width: 6),
                        _buildPosturePill('Shake'),
                      ],
                    ),
                  ),

                  // Analog Joystick
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Center(child: _buildAnalogJoystick()),
                  ),
                ],
              ),
            ),

            // Bottom Navigation
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
                  _buildNavItem(Icons.home_rounded, 'Home', 0, isDark),
                  _buildNavItem(Icons.tune_rounded, 'Control', 1, isDark),
                  _buildNavItem(Icons.videocam_outlined, 'Camera', 2, isDark),
                  _buildNavItem(Icons.timeline_rounded, 'Activity', 3, isDark),
                  _buildNavItem(Icons.settings_outlined, 'Settings', 4, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // PUBG 360 Analog Controller Widget
  Widget _buildAnalogJoystick() {
    return GestureDetector(
      onPanStart: (details) => _updateJoystick(details.localPosition, const Size(140, 140)),
      onPanUpdate: (details) => _updateJoystick(details.localPosition, const Size(140, 140)),
      onPanEnd: (_) => _resetJoystick(),
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.55),
          border: Border.all(
            color: const Color(0xFF2F80FF).withValues(alpha: 0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2F80FF).withValues(alpha: 0.2),
              blurRadius: 14,
            )
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12, width: 1),
              ),
            ),
            const Positioned(top: 4, child: Icon(Icons.keyboard_arrow_up, size: 16, color: Colors.white60)),
            const Positioned(bottom: 4, child: Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white60)),
            const Positioned(left: 4, child: Icon(Icons.keyboard_arrow_left, size: 16, color: Colors.white60)),
            const Positioned(right: 4, child: Icon(Icons.keyboard_arrow_right, size: 16, color: Colors.white60)),

            // The Analog Draggable Thumb Knob
            Transform.translate(
              offset: _joystickKnob,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFF5BA0FF), Color(0xFF2F80FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2F80FF).withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.drag_indicator_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayCircleBtn(IconData icon, String label, VoidCallback onTap, {bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF27AE60) : Colors.black.withValues(alpha: 0.65),
          shape: BoxShape.circle,
          border: Border.all(color: isActive ? Colors.white : Colors.white24, width: 1.2),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildPosturePill(String posture) {
    final isSelected = _activePosture == posture;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _activePosture = posture);
          _triggerAction('Posture: $posture');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2F80FF) : Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSelected ? const Color(0xFF2F80FF) : Colors.white24),
          ),
          alignment: Alignment.center,
          child: Text(
            posture,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isDark) {
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
            color: isSelected ? const Color(0xFF2F80FF) : (isDark ? const Color(0xFF8F9BB3) : Colors.black54),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? const Color(0xFF2F80FF) : (isDark ? const Color(0xFF8F9BB3) : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}