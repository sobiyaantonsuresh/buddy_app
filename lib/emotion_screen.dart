import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'control_screen.dart';
import 'camera_screen.dart';
import 'activity_screen.dart';

class ScreenEmotion extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const ScreenEmotion({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<ScreenEmotion> createState() => _ScreenEmotionState();
}

class _ScreenEmotionState extends State<ScreenEmotion> {
  int _selectedNavIndex = 3; // Activity / Analytics Area
  String _currentEmotion = 'Happy';
  int _confidence = 94;

  final Map<String, Color> _emotionColors = {
    'Happy': const Color(0xFF27AE60),
    'Calm': const Color(0xFF2F80FF),
    'Sad': const Color(0xFFF2994A),
    'Stressed': const Color(0xFFEB5757),
  };

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
    final activeColor = _emotionColors[_currentEmotion] ?? const Color(0xFF27AE60);

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

                // Main Scrollable Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          'Emotion Detection',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Biometric behavioral & facial geometry analysis',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Identified Target & Biometric Face Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF162033) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: activeColor.withValues(alpha: 0.2),
                                    child: Icon(Icons.person, size: 16, color: activeColor),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Identified Target: Sobiya',
                                    style: TextStyle(
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Biometric Circle Face Avatar
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF08111F) : const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                  border: Border.all(width: 2.5, color: activeColor),
                                  boxShadow: [
                                    BoxShadow(
                                      color: activeColor.withValues(alpha: 0.25),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: activeColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 28),
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: activeColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Icon(
                                      _currentEmotion == 'Happy'
                                          ? Icons.sentiment_very_satisfied_rounded
                                          : _currentEmotion == 'Calm'
                                              ? Icons.sentiment_satisfied_rounded
                                              : _currentEmotion == 'Sad'
                                                  ? Icons.sentiment_dissatisfied_rounded
                                                  : Icons.sentiment_very_dissatisfied_rounded,
                                      color: activeColor,
                                      size: 32,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              Text(
                                _currentEmotion,
                                style: TextStyle(
                                  color: activeColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Confidence Index: $_confidence%',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Emotion Quick State Switches
                        Row(
                          children: [
                            _buildEmotionSwitch('Happy', 94, isDark),
                            const SizedBox(width: 6),
                            _buildEmotionSwitch('Calm', 88, isDark),
                            const SizedBox(width: 6),
                            _buildEmotionSwitch('Sad', 76, isDark),
                            const SizedBox(width: 6),
                            _buildEmotionSwitch('Stressed', 82, isDark),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Mood Analysis (Last 24 Hours)
                        Text(
                          'MOOD ANALYSIS (LAST 24H)',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF162033) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Timeline Chart Simulation
                              SizedBox(
                                height: 75,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _buildTimelineBar(40, const Color(0xFF2F80FF)),
                                    _buildTimelineBar(55, const Color(0xFF27AE60)),
                                    _buildTimelineBar(68, const Color(0xFF27AE60)),
                                    _buildTimelineBar(45, const Color(0xFFF2994A)),
                                    _buildTimelineBar(70, const Color(0xFF27AE60)),
                                    _buildTimelineBar(60, const Color(0xFF27AE60)),
                                    _buildTimelineBar(35, const Color(0xFFEB5757)),
                                    _buildTimelineBar(65, const Color(0xFF27AE60)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Divider(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0), height: 1),
                              const SizedBox(height: 8),

                              // Time Label Axes
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildTimeAxisText('12 AM', isDark),
                                  _buildTimeAxisText('06 AM', isDark),
                                  _buildTimeAxisText('12 PM', isDark),
                                  _buildTimeAxisText('06 PM', isDark),
                                ],
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

  Widget _buildEmotionSwitch(String emotion, int conf, bool isDark) {
    final isSelected = _currentEmotion == emotion;
    final color = _emotionColors[emotion] ?? const Color(0xFF2F80FF);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentEmotion = emotion;
            _confidence = conf;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : (isDark ? const Color(0xFF162033) : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : (isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0)),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            emotion,
            style: TextStyle(
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF0F172A)),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineBar(double height, Color color) {
    return Container(
      width: 18,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildTimeAxisText(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF94A3B8),
        fontSize: 11,
        fontWeight: FontWeight.w500,
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