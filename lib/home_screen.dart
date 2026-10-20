import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'camera_screen.dart';
import 'control_screen.dart';
import 'activity_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'household_screen.dart';
import 'voice_screen.dart';
import 'emotion_screen.dart';

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
  int _currentNavIndex = 0;

  static const String _baseUrl = kIsWeb ? "http://10.138.45.237:5000" : "http://10.138.45.237:5000";

  Timer? _clockTimer;
  Timer? _telemetryTimer;
  String _currentTimeString = '';

  bool _isOnline = false;
  int? _batteryPercent;
  String _currentState = "Checking camera";
  String _lastFace = "No person detected";
  String _lastEmotion = "Unavailable";
  bool _hasUnknownAlert = false;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    _fetchRobotStatus();
    _telemetryTimer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchRobotStatus());
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _telemetryTimer?.cancel();
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

  Future<void> _fetchRobotStatus() async {
    if (!mounted) return;
    try {
      // Actual recognition and expressions come from the shared vision camera,
      // not /api/robot_status demo placeholders.
      final res = await http.get(
        Uri.parse('$_baseUrl/api/vision/status'),
      ).timeout(const Duration(seconds: 3));
      if (res.statusCode != 200) throw StateError('Vision API unavailable');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final cameraOnline = data['camera_connected'] == true && data['vision_ready'] == true;
      final people = data['people'] is List ? data['people'] as List : const [];
      final recognized = people.where((entry) => entry is Map &&
          entry['recognized'] == true &&
          (entry['name']?.toString().trim().isNotEmpty ?? false)).toList();
      final selected = recognized.isNotEmpty ? recognized.first as Map : null;
      final events = data['events'] is List ? data['events'] as List : const [];
      final unknownPresent = people.any((entry) => entry is Map &&
          entry['recognized'] != true);
      final unknownEvent = events.any((entry) => entry is Map &&
          (entry['kind'] == 'unknown_person' ||
           entry['kind'] == 'unknown_person_alert'));
      if (!mounted) return;
      setState(() {
        _isOnline = cameraOnline;
        _currentState = cameraOnline ? 'Vision online' : 'Camera unavailable';
        _lastFace = cameraOnline && selected != null
            ? selected['name'].toString() : 'No person detected';
        final expression = selected?['expression']?.toString();
        _lastEmotion = expression != null && expression.isNotEmpty
            ? expression[0].toUpperCase() + expression.substring(1)
            : 'Unavailable';
        _hasUnknownAlert = cameraOnline && (unknownPresent || unknownEvent);
        // No verified battery endpoint in the active Flask vision API.
        _batteryPercent = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isOnline = false;
        _currentState = 'Camera unavailable';
        _lastFace = 'No person detected';
        _lastEmotion = 'Unavailable';
        _hasUnknownAlert = false;
        _batteryPercent = null;
      });
    }
  }

  Future<void> _sendCommand(String action) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/control/action'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': action}),
      ).timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScreenNotifications(
          isDarkMode: widget.isDarkMode,
          onThemeToggle: widget.onThemeToggle,
        ),
      ),
    ).then((_) => _fetchRobotStatus());
  }

  void _openVoiceScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScreenVoice(
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
      backgroundColor: isDark
    ? const Color(0xFF060B16)
    : const Color(0xFFF5F0E5),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 45),
        child: FloatingActionButton(
          backgroundColor: isDark ? const Color(0xFF2563EB) : const Color(0xFFED7666),
          elevation: 6,
          mini: true,
          onPressed: _openVoiceScreen,
          child: Icon(Icons.mic, color: isDark ? Colors.white : const Color(0xFF173630), size: 20),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_back, color: isDark ? Colors.white70 : const Color(0xFF65766F), size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _currentTimeString.isEmpty ? '11:02 PM' : _currentTimeString,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF173630),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _openNotifications,
                            child: Stack(
                              children: [
                                Icon(Icons.notifications_none, color: isDark ? Colors.white70 : const Color(0xFF65766F), size: 18),
                                if (_hasUnknownAlert)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEB5757),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: widget.onThemeToggle,
                            child: Icon(Icons.wb_sunny_outlined, color: Colors.lightBlueAccent, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.wifi, color: isDark ? Colors.white70 : const Color(0xFF65766F), size: 16),
                          const SizedBox(width: 6),
                          Icon(Icons.battery_full, color: isDark ? Colors.white70 : const Color(0xFF65766F), size: 18),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F1A2E) : const Color(0xFFFFFDF8),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? const Color(0xFF1B2A44) : const Color(0xFFC9D3C9)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.smart_toy_outlined, color: Color(0xFF38BDF8), size: 22),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "BUDDY",
                                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF173630), fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.circle, size: 6, color: _isOnline ? const Color(0xFF22C55E) : Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            _isOnline ? "Camera online" : "Camera offline",
                                            style: const TextStyle(color: Color(0xFF22C55E), fontSize: 10, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0B1323) : const Color(0xFFDCEFE5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.battery_charging_full, size: 12, color: Color(0xFF22C55E)),
                                        const SizedBox(width: 3),
                                        Text(_batteryPercent == null ? "N/A" : "$_batteryPercent%", style: TextStyle(color: isDark ? Colors.white : const Color(0xFF173630), fontSize: 10, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0B1323) : const Color(0xFFDCEFE5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text("Local", style: TextStyle(color: isDark ? Colors.white : const Color(0xFF173630), fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F1A2E) : const Color(0xFFFFFDF8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? const Color(0xFF1B2A44) : const Color(0xFFC9D3C9)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.radar, color: Color(0xFF38BDF8), size: 15),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Current State: $_currentState",
                                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF173630), fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.circle, size: 5, color: Color(0xFF38BDF8)),
                                  SizedBox(width: 4),
                                  Icon(Icons.chevron_right, size: 16, color: Colors.white54),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_hasUnknownAlert) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _openNotifications,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF450A0A).withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.circle, size: 6, color: Color(0xFFEF4444)),
                                      SizedBox(width: 6),
                                      Text(
                                        "Unknown person in camera",
                                        style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text("ALERT", style: TextStyle(color: isDark ? Colors.white : const Color(0xFF173630), fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          "DETECTION ANALYSIS",
                          style: TextStyle(color: isDark ? Colors.white38 : const Color(0xFF65766F), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 8),

                        // DETECTION ANALYSIS CARD:
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F1A2E) : const Color(0xFFFFFDF8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? const Color(0xFF1B2A44) : const Color(0xFFC9D3C9)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Sobiya click -> Household Screen
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ScreenHousehold(
                                        isDarkMode: isDark,
                                        onThemeToggle: widget.onThemeToggle,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Color(0xFF2563EB),
                                        child: Icon(Icons.person, color: isDark ? Colors.white : const Color(0xFF173630), size: 16),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_lastFace, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF173630), fontSize: 12, fontWeight: FontWeight.bold)),
                                          Text(_lastFace == "No person detected" ? "Waiting for recognition" : "Recognized Companion", style: TextStyle(color: isDark ? Colors.white38 : const Color(0xFF65766F), fontSize: 9)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Mood click -> Emotion Screen with dynamic _lastFace & _lastEmotion
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ScreenEmotion(
                                      isDarkMode: isDark,
                                      onThemeToggle: widget.onThemeToggle,
                                      targetName: _lastFace == "No person detected" ? "Ashandth" : _lastFace, // Open a real household profile
                                    ),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFDCEFE5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "Expression: $_lastEmotion",
                                    style: const TextStyle(color: Color(0xFF22C55E), fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        Text(
                          "QUICK COMMANDS",
                          style: TextStyle(color: isDark ? Colors.white38 : const Color(0xFF65766F), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? const Color(0xFF0F1A2E) : const Color(0xFFDCEFE5),
                                  foregroundColor: isDark ? Colors.white70 : const Color(0xFF173630),
                                  side: BorderSide(color: isDark ? const Color(0xFF1B2A44) : const Color(0xFF173630)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                onPressed: () => _sendCommand("RETURN_BASE"),
                                icon: Icon(Icons.home_outlined, size: 15, color: Color(0xFF38BDF8)),
                                label: Text("Return Base", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? const Color(0xFF0F1A2E) : const Color(0xFFDCEFE5),
                                  foregroundColor: isDark ? Colors.white70 : const Color(0xFF173630),
                                  side: BorderSide(color: isDark ? const Color(0xFF1B2A44) : const Color(0xFF173630)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                onPressed: () => _sendCommand("SPEAK"),
                                icon: Icon(Icons.volume_up_outlined, size: 15, color: Color(0xFF38BDF8)),
                                label: Text("Speak", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF060B16) : const Color(0xFFFFFDF8),
                    border: Border(
                      top: BorderSide(
                        color: isDark ? const Color(0xFF131D31) : const Color(0xFFC9D3C9),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBottomNavItem(icon: Icons.home, label: "Home", isSelected: _currentNavIndex == 0, onTap: () => setState(() => _currentNavIndex = 0)),
                      _buildBottomNavItem(icon: Icons.sports_esports_outlined, label: "Control", isSelected: _currentNavIndex == 1, onTap: () {
                        setState(() => _currentNavIndex = 1);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ScreenControl(isDarkMode: isDark, onThemeToggle: widget.onThemeToggle)));
                      }),
                      _buildBottomNavItem(icon: Icons.videocam_outlined, label: "Camera", isSelected: _currentNavIndex == 2, onTap: () {
                        setState(() => _currentNavIndex = 2);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ScreenCamera(isDarkMode: isDark, onThemeToggle: widget.onThemeToggle)));
                      }),
                      _buildBottomNavItem(icon: Icons.show_chart, label: "Activity", isSelected: _currentNavIndex == 3, onTap: () {
                        setState(() => _currentNavIndex = 3);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ScreenActivity(isDarkMode: isDark, onThemeToggle: widget.onThemeToggle)));
                      }),
                      _buildBottomNavItem(icon: Icons.settings_outlined, label: "Settings", isSelected: _currentNavIndex == 4, onTap: () {
                        setState(() => _currentNavIndex = 4);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ScreenSettings(isDarkMode: isDark, onThemeToggle: widget.onThemeToggle)));
                      }),
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

  
  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = widget.isDarkMode;

    final Color itemColor = isDark
        ? (isSelected
            ? const Color(0xFF2563EB)
            : Colors.white38)
        : (isSelected
            ? const Color(0xFF173F37)
            : const Color(0xFF65766F));

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: !isDark && isSelected
              ? const Color(0xFFDCEFE5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 21,
              color: itemColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: itemColor,
                fontWeight: isSelected
                    ? FontWeight.w800
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


