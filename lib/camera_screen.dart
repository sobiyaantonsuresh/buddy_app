import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'control_screen.dart';
import 'activity_screen.dart';
import 'settings_screen.dart';

class ScreenCamera extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const ScreenCamera({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<ScreenCamera> createState() => _ScreenCameraState();
}

class _ScreenCameraState extends State<ScreenCamera> {
  int _selectedNavIndex = 2; // Camera tab
  String _selectedFilter = 'All';
  bool _isRecording = true;

  final List<Map<String, dynamic>> _mediaList = [
    {'time': '09:22 AM', 'type': 'photo', 'label': 'Front Cam', 'icon': Icons.camera_alt},
    {'time': '08:45 AM', 'type': 'video', 'label': 'Yard Clip', 'icon': Icons.videocam},
    {'time': '08:00 AM', 'type': 'alert', 'label': 'Alert Motion', 'icon': Icons.warning_amber},
  ];

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Live Camera Viewport (Native Canvas View)
                        Container(
                          width: double.infinity,
                          height: 280,
                          color: const Color(0xFF0A1128),
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.videocam_rounded, size: 48, color: Colors.white.withValues(alpha: 0.3)),
                                    const SizedBox(height: 6),
                                    Text(
                                      'BUDDY LIVE RTSP STREAM',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.6),
                                        fontSize: 12,
                                        letterSpacing: 1,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Camera Header Overlay
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xCC162033),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'CAM_FRONT_01',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _isRecording ? const Color(0xCCEB5757) : Colors.black54,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _isRecording ? 'REC 04:12' : 'STANDBY',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Quick Controls Overlay
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: const Color(0xCC162033),
                                          child: IconButton(
                                            icon: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 20),
                                            onPressed: () {},
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: const Color(0xCC162033),
                                              child: IconButton(
                                                icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                                                onPressed: () {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Snapshot saved to Gallery!')),
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            CircleAvatar(
                                              radius: 22,
                                              backgroundColor: const Color(0xCCEB5757),
                                              child: IconButton(
                                                icon: Icon(_isRecording ? Icons.stop_rounded : Icons.fiber_manual_record, color: Colors.white, size: 22),
                                                onPressed: () {
                                                  setState(() => _isRecording = !_isRecording);
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: const Color(0xCC162033),
                                          child: IconButton(
                                            icon: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 22),
                                            onPressed: () {},
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Media Gallery Section
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CAPTURED MEDIA GALLERY',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Gallery Filter Chips
                              Row(
                                children: [
                                  _buildFilterChip('All', isDark),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('Photos', isDark),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('Videos', isDark),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('Alerts', isDark),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Gallery Grid
                              Row(
                                children: _mediaList.map((media) {
                                  return Expanded(
                                    child: Container(
                                      height: 85,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF162033) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(media['icon'] as IconData, size: 20, color: const Color(0xFF2F80FF)),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                media['label'] as String,
                                                style: TextStyle(
                                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                media['time'] as String,
                                                style: const TextStyle(
                                                  color: Color(0xFF8F9BB3),
                                                  fontSize: 8,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildFilterChip(String label, bool isDark) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2F80FF)
              : (isDark ? const Color(0xFF162033) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2F80FF)
                : (isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF0F172A)),
            fontSize: 12,
            fontWeight: FontWeight.w700,
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