import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';
import 'control_screen.dart';
import 'camera_screen.dart';
import 'activity_screen.dart';
import 'battery_screen.dart';
import 'household_screen.dart';
import 'pairing_screen.dart';

class ScreenSettings extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const ScreenSettings({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<ScreenSettings> createState() => _ScreenSettingsState();
}

class _ScreenSettingsState extends State<ScreenSettings> {
  int _selectedNavIndex = 4;
  bool _emotionDetection = true;
  bool _faceRecognition = true;
  double _maxSpeed = 1.2;
  String _robotName = 'BUDDY';

  static const String _baseUrl = "http://10.242.169.228:5000";
  Timer? _clockTimer;
  String _currentTimeString = '';

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    _fetchSettings();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
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

  Future<void> _fetchSettings() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/settings/get')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _emotionDetection = data['emotion_detection'] ?? _emotionDetection;
            _faceRecognition = data['face_recognition'] ?? _faceRecognition;
            _maxSpeed = (data['max_speed'] as num?)?.toDouble() ?? _maxSpeed;
            _robotName = data['robot_name'] ?? _robotName;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/settings/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({key: value}),
      );
    } catch (_) {}
  }

  Future<void> _performFactoryReset() async {
    try {
      await http.post(Uri.parse('$_baseUrl/api/settings/factory_reset'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Factory Reset signal transmitted to BUDDY.'),
            backgroundColor: Color(0xFF27AE60),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings reset locally.')),
        );
      }
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF162033) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEB5757), size: 28),
            SizedBox(width: 8),
            Text('Factory Reset', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to reset BUDDY configurations and clear cached face profiles?',
          style: TextStyle(
            color: widget.isDarkMode ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF8F9BB3), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEB5757),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _performFactoryReset();
            },
            child: const Text('RESET NOW', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

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
                            _currentTimeString.isEmpty ? '...' : _currentTimeString,
                            style: TextStyle(
                              fontSize: 13,
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
                  child: RefreshIndicator(
                    onRefresh: _fetchSettings,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'System controls and custom configurations',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Quick Hubs
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickLinkCard(
                                  icon: Icons.bluetooth_searching_rounded,
                                  title: 'Pairing Hub',
                                  subtitle: 'Bluetooth / Wi-Fi',
                                  isDark: isDark,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ScreenPairing(
                                          isDarkMode: widget.isDarkMode,
                                          onThemeToggle: widget.onThemeToggle,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildQuickLinkCard(
                                  icon: Icons.battery_charging_full_rounded,
                                  title: 'Battery & Power',
                                  subtitle: 'Docking & Drain',
                                  isDark: isDark,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ScreenBattery(
                                          isDarkMode: widget.isDarkMode,
                                          onThemeToggle: widget.onThemeToggle,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          _buildQuickLinkCard(
                            icon: Icons.people_alt_rounded,
                            title: 'Household Profile',
                            subtitle: 'Manage recognized family members & guests',
                            isDark: isDark,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ScreenHousehold(
                                    isDarkMode: widget.isDarkMode,
                                    onThemeToggle: widget.onThemeToggle,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),

                          // ROBOT CONFIGURATION
                          Text(
                            'ROBOT CONFIGURATION',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 10),
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
                                      'Robot Name: $_robotName',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Icon(Icons.smart_toy_rounded, size: 16, color: Color(0xFF2F80FF)),
                                  ],
                                ),
                                Divider(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0), height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Max Movement Speed',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${_maxSpeed.toStringAsFixed(1)} m/s',
                                      style: const TextStyle(
                                        color: Color(0xFF2F80FF),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: _maxSpeed,
                                  min: 0.5,
                                  max: 2.5,
                                  activeColor: const Color(0xFF2F80FF),
                                  onChanged: (val) {
                                    setState(() => _maxSpeed = val);
                                  },
                                  onChangeEnd: (val) {
                                    _updateSetting('max_speed', val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // AI & BIOMETRIC ANALYSIS
                          Text(
                            'AI & BIOMETRIC ANALYSIS',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF162033) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Emotion Detection',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Switch(
                                      value: _emotionDetection,
                                      activeThumbColor: const Color(0xFF2F80FF),
                                      onChanged: (val) {
                                        setState(() => _emotionDetection = val);
                                        _updateSetting('emotion_detection', val);
                                      },
                                    ),
                                  ],
                                ),
                                Divider(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0), height: 1),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Face Recognition',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Switch(
                                      value: _faceRecognition,
                                      activeThumbColor: const Color(0xFF2F80FF),
                                      onChanged: (val) {
                                        setState(() => _faceRecognition = val);
                                        _updateSetting('face_recognition', val);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // DEVICE MAINTENANCE
                          Text(
                            'DEVICE MAINTENANCE',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 10),
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
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Firmware Update',
                                      style: TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Up to date (v3.2.1)',
                                      style: TextStyle(
                                        color: Color(0xFF27AE60),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0), height: 20),
                                GestureDetector(
                                  onTap: _showResetDialog,
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Factory Reset',
                                        style: TextStyle(
                                          color: Color(0xFFEB5757),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFEB5757)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
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

  Widget _buildQuickLinkCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF162033) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2F80FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF2F80FF), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: isDark ? Colors.white54 : Colors.black45),
          ],
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