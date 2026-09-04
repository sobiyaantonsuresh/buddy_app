import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'control_screen.dart';
import 'camera_screen.dart';
import 'activity_screen.dart';
import 'emotion_screen.dart';
import 'security_screen.dart';
import 'status_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'voice_screen.dart';
import 'login_screen.dart';
import 'household_screen.dart';
import 'unknown_alert_dialog.dart';

class ScreenHome extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const ScreenHome({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<ScreenHome> createState() => _ScreenHomeState();
}

class _ScreenHomeState extends State<ScreenHome> {
  int _selectedNavIndex = 0;

  static const String _baseUrl = "http://10.242.169.228:5000";
  Timer? _clockTimer;
  Timer? _pollingTimer;
  String _currentTimeString = '';

  // Live Telemetry & Detection variables
  bool _isOnline = true;
  String _robotState = 'Patrolling';
  int _batteryPercent = 92;
  String _detectedPerson = 'Sobiya';
  String _detectedMood = 'Happy';

  // Unknown face alert buffer
  bool _hasUnknownAlert = false;
  String? _latestAlertImage;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());

    // Polling live robot telemetry
    _fetchLiveStatus();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchLiveStatus());

    // Start listening for unknown face alert popups
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UnknownAlertService.startListening(context);
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pollingTimer?.cancel();
    UnknownAlertService.stopListening();
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

  Future<void> _fetchLiveStatus() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/robot_status')).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _isOnline = true;
            _batteryPercent = (data['battery'] as num?)?.toInt() ?? _batteryPercent;
            _robotState = data['state'] ?? _robotState;
            _detectedPerson = data['last_face'] ?? _detectedPerson;
            _detectedMood = data['last_emotion'] ?? _detectedMood;
          });
        }
      }

      // Check for unknown person alert and retrieve base64 crop
      final alertRes = await http.get(Uri.parse('$_baseUrl/api/get_unknown_alert')).timeout(const Duration(seconds: 2));
      if (alertRes.statusCode == 200) {
        final alertData = jsonDecode(alertRes.body);
        if (mounted) {
          setState(() {
            if (alertData['status'] == 'alert' && alertData['image'] != null) {
              _hasUnknownAlert = true;
              _latestAlertImage = alertData['image'].toString();
            } else {
              _hasUnknownAlert = false;
            }
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isOnline = false);
      }
    }
  }

  Future<void> _sendRobotCommand(String command) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Command Sent: $command'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF2F80FF),
      ),
    );

    try {
      await http.post(
        Uri.parse('$_baseUrl/api/control/action'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': command}),
      );
    } catch (_) {}
  }

  void _onBottomNavTapped(int index) {
    if (index == 0) {
      setState(() => _selectedNavIndex = 0);
      return;
    }

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScreenControl(
            isDarkMode: widget.isDarkMode,
            onThemeToggle: widget.onThemeToggle,
          ),
        ),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScreenCamera(
            isDarkMode: widget.isDarkMode,
            onThemeToggle: widget.onThemeToggle,
          ),
        ),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScreenActivity(
            isDarkMode: widget.isDarkMode,
            onThemeToggle: widget.onThemeToggle,
          ),
        ),
      );
    } else if (index == 4) {
      _goToSettingsScreen();
    }
  }

  void _goToSettingsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScreenSettings(
          isDarkMode: widget.isDarkMode,
          onThemeToggle: widget.onThemeToggle,
        ),
      ),
    );
  }

  void _goToHouseholdScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScreenHousehold(
          isDarkMode: widget.isDarkMode,
          onThemeToggle: widget.onThemeToggle,
          initialImageBase64: _latestAlertImage,
        ),
      ),
    );
  }

  void _goToStatusScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScreenStatus(
          isDarkMode: widget.isDarkMode,
          onThemeToggle: widget.onThemeToggle,
        ),
      ),
    );
  }

  void _goToSecurityScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScreenSecurity(
          isDarkMode: widget.isDarkMode,
          onThemeToggle: widget.onThemeToggle,
        ),
      ),
    );
  }

  void _goToNotificationsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScreenNotifications(
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2F80FF),
        elevation: 6,
        tooltip: 'Voice Assistant',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScreenVoice(
                isDarkMode: widget.isDarkMode,
                onThemeToggle: widget.onThemeToggle,
              ),
            ),
          );
        },
        child: const Icon(Icons.mic, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                // Top Status Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.logout_rounded,
                              size: 18,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            tooltip: 'Logout',
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BuddyLoginScreen(
                                    isDarkMode: widget.isDarkMode,
                                    onThemeToggle: widget.onThemeToggle,
                                  ),
                                ),
                              );
                            },
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
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.notifications_outlined,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  size: 20,
                                ),
                                tooltip: 'Notifications',
                                onPressed: _goToNotificationsScreen,
                              ),
                              if (_hasUnknownAlert)
                                Positioned(
                                  right: 10,
                                  top: 10,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEB5757),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              isDark ? Icons.light_mode : Icons.dark_mode,
                              color: isDark ? const Color(0xFF2F80FF) : Colors.amber.shade800,
                              size: 20,
                            ),
                            tooltip: 'Toggle Theme',
                            onPressed: widget.onThemeToggle,
                          ),
                          Icon(Icons.wifi, size: 18, color: _isOnline ? const Color(0xFF27AE60) : Colors.redAccent),
                          const SizedBox(width: 8),
                          Icon(
                            _batteryPercent > 20 ? Icons.battery_full : Icons.battery_alert_rounded,
                            size: 20,
                            color: _batteryPercent > 20 ? (isDark ? Colors.white70 : Colors.black54) : Colors.redAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Scrollable Area
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchLiveStatus,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF162033) : Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF2F80FF), size: 24),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'BUDDY',
                                        style: TextStyle(
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.circle,
                                            color: _isOnline ? const Color(0xFF27AE60) : Colors.redAccent,
                                            size: 8,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _isOnline ? 'Online' : 'Offline',
                                            style: TextStyle(
                                              color: _isOnline ? const Color(0xFF27AE60) : Colors.redAccent,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: _goToStatusScreen,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF162033) : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.battery_charging_full,
                                            size: 14,
                                            color: _batteryPercent > 20 ? const Color(0xFF27AE60) : Colors.redAccent,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$_batteryPercent%',
                                            style: TextStyle(
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF162033) : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: const Text(
                                        '4G',
                                        style: TextStyle(
                                          color: Color(0xFF2F80FF),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          GestureDetector(
                            onTap: _goToSecurityScreen,
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.radar_rounded, size: 18, color: Color(0xFF2F80FF)),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Current State: ',
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        _robotState,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Row(
                                    children: [
                                      Icon(Icons.circle, color: Color(0xFF2F80FF), size: 8),
                                      SizedBox(width: 6),
                                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF8F9BB3)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (_hasUnknownAlert) ...[
                            GestureDetector(
                              onTap: _goToSecurityScreen,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF162033) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFEB5757).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.circle, color: Color(0xFFEB5757), size: 8),
                                        SizedBox(width: 8),
                                        Text(
                                          'Person Detected | Approaching',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEB5757),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'ALERT',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          Text(
                            'DETECTION ANALYSIS',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 10),

                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ScreenEmotion(
                                    isDarkMode: widget.isDarkMode,
                                    onThemeToggle: widget.onThemeToggle,
                                  ),
                                ),
                              );
                            },
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: const Color(0xFF2F80FF).withValues(alpha: 0.2),
                                        child: const Icon(Icons.person, color: Color(0xFF2F80FF)),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _detectedPerson,
                                            style: TextStyle(
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'Registered Companion',
                                            style: TextStyle(
                                              color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Mood: $_detectedMood',
                                        style: const TextStyle(
                                          color: Color(0xFF27AE60),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.circle, color: Color(0xFF27AE60), size: 6),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF8F9BB3)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Unknown Person Alert Card
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF162033) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: const Color(0xFFEB5757).withValues(alpha: 0.2),
                                      child: const Icon(Icons.person_search_rounded, color: Color(0xFFEB5757)),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Unregistered Detection',
                                          style: TextStyle(
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const Text(
                                          'Unknown Person',
                                          style: TextStyle(
                                            color: Color(0xFFEB5757),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2F80FF),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    minimumSize: Size.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 0,
                                  ),
                                  onPressed: _goToHouseholdScreen,
                                  child: const Text('Add Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'QUICK COMMANDS',
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
                              Expanded(
                                child: _buildCommandCard(
                                  icon: Icons.home_repair_service_rounded,
                                  title: 'Return Base',
                                  isDark: isDark,
                                  onTap: () => _sendRobotCommand('Return Base'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildCommandCard(
                                  icon: Icons.volume_up_rounded,
                                  title: 'Speak',
                                  isDark: isDark,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ScreenVoice(
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
                          const SizedBox(height: 20),
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

  Widget _buildCommandCard({
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF162033) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF2F80FF)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
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