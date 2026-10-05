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
import 'voice_screen.dart'; // Ee import vazhi ScreenVoice link cheyyunnu

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

  static const String _baseUrl = kIsWeb ? "http://localhost:5000" : "http://192.168.8.192:5000";

  Timer? _clockTimer;
  Timer? _telemetryTimer;
  String _currentTimeString = '';

  bool _isOnline = true;
  int _batteryPercent = 92;
  String _currentState = "Patrolling";
  String _lastFace = "sobiya";
  String _lastEmotion = "Neutral";
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
      final res = await http.get(Uri.parse('$_baseUrl/api/robot_status')).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _isOnline = data['status'] == 'online';
            _batteryPercent = data['battery'] ?? 92;
            _currentState = data['state'] ?? 'Patrolling';
            _lastFace = data['last_face'] ?? 'sobiya';
            _lastEmotion = data['last_emotion'] ?? 'Neutral';
            _hasUnknownAlert = data['has_unknown'] ?? false;
          });
        }
      }
    } catch (_) {}
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

  // Mic button click cheyyumbol ScreenVoice open aakunna method
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
      backgroundColor: const Color(0xFF060B16),
      // Mic button click cheythaal ScreenVoice-lekku navigate aakunnu
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 45),
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF2563EB),
          elevation: 6,
          mini: true,
          onPressed: _openVoiceScreen,
          child: const Icon(Icons.mic, color: Colors.white, size: 20),
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
                          const Icon(Icons.arrow_back, color: Colors.white70, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _currentTimeString.isEmpty ? '11:02 PM' : _currentTimeString,
                            style: const TextStyle(
                              color: Colors.white,
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
                                const Icon(Icons.notifications_none, color: Colors.white70, size: 18),
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
                            child: const Icon(Icons.wb_sunny_outlined, color: Colors.lightBlueAccent, size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.wifi, color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          const Icon(Icons.battery_full, color: Colors.white70, size: 18),
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
                            color: const Color(0xFF0F1A2E),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF1B2A44)),
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
                                      color: const Color(0xFF1E3A8A).withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.smart_toy_outlined, color: Color(0xFF38BDF8), size: 22),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "BUDDY",
                                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.circle, size: 6, color: _isOnline ? const Color(0xFF22C55E) : Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            _isOnline ? "Online" : "Offline",
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
                                      color: const Color(0xFF0B1323),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.battery_charging_full, size: 12, color: Color(0xFF22C55E)),
                                        const SizedBox(width: 3),
                                        Text("$_batteryPercent%", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0B1323),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text("4G", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                            color: const Color(0xFF0F1A2E),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF1B2A44)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.radar, color: Color(0xFF38BDF8), size: 15),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Current State: $_currentState",
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const Row(
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
                                color: const Color(0xFF450A0A).withOpacity(0.4),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.circle, size: 6, color: Color(0xFFEF4444)),
                                      SizedBox(width: 6),
                                      Text(
                                        "Person Detected | Approaching",
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
                                    child: const Text("ALERT", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Text(
                          "DETECTION ANALYSIS",
                          style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ScreenHousehold(isDarkMode: isDark, onThemeToggle: widget.onThemeToggle))),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F1A2E),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF1B2A44)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Color(0xFF2563EB),
                                      child: Icon(Icons.person, color: Colors.white, size: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_lastFace, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                        const Text("Registered Companion", style: TextStyle(color: Colors.white38, fontSize: 9)),
                                      ],
                                    ),
                                  ],
                                ),
                                Text("Mood: $_lastEmotion •", style: const TextStyle(color: Color(0xFF22C55E), fontSize: 10, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "QUICK COMMANDS",
                          style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F1A2E),
                                  foregroundColor: Colors.white70,
                                  side: const BorderSide(color: Color(0xFF1B2A44)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                onPressed: () => _sendCommand("RETURN_BASE"),
                                icon: const Icon(Icons.home_outlined, size: 15, color: Color(0xFF38BDF8)),
                                label: const Text("Return Base", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F1A2E),
                                  foregroundColor: Colors.white70,
                                  side: const BorderSide(color: Color(0xFF1B2A44)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                onPressed: () => _sendCommand("SPEAK"),
                                icon: const Icon(Icons.volume_up_outlined, size: 15, color: Color(0xFF38BDF8)),
                                label: const Text("Speak", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
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
                  decoration: const BoxDecoration(
                    color: Color(0xFF060B16),
                    border: Border(top: BorderSide(color: Color(0xFF131D31))),
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: isSelected ? const Color(0xFF2563EB) : Colors.white38),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: isSelected ? const Color(0xFF2563EB) : Colors.white38,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}