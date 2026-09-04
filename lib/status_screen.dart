import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';
import 'control_screen.dart';
import 'camera_screen.dart';
import 'activity_screen.dart';
import 'settings_screen.dart';

class ScreenStatus extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const ScreenStatus({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<ScreenStatus> createState() => _ScreenStatusState();
}

class _ScreenStatusState extends State<ScreenStatus> {
  int _selectedNavIndex = 3;

  static const String _baseUrl = "http://192.168.8.192:5000";
  Timer? _clockTimer;
  Timer? _pollingTimer;
  String _currentTimeString = '';

  // Live telemetry metrics
  double _batteryPercent = 92.0;
  String _connectionType = 'Strong (Wi-Fi)';
  String _behaviorMode = 'Patrolling';
  String _coreTemp = '38°C (Normal)';
  String _storageUsage = '64GB / 128GB';
  double _cpuLoad = 0.24;
  double _memoryLoad = 0.58;
  String _lastChecked = 'Today 08:00 AM';

  // Sensor status map
  Map<String, bool> _sensors = {
    'Camera Module': true,
    'LiDAR / Ultrasonic': true,
    'Microphone Array': true,
    'IMU Accelerometer': true,
  };

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    _fetchDiagnostics();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) => _fetchDiagnostics());
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pollingTimer?.cancel();
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

  Future<void> _fetchDiagnostics() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/device_diagnostics')).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _batteryPercent = (data['battery'] as num?)?.toDouble() ?? _batteryPercent;
            _connectionType = data['connection'] ?? _connectionType;
            _behaviorMode = data['behavior'] ?? _behaviorMode;
            _coreTemp = data['temp'] ?? _coreTemp;
            _storageUsage = data['storage'] ?? _storageUsage;
            _cpuLoad = (data['cpu_load'] as num?)?.toDouble() ?? _cpuLoad;
            _memoryLoad = (data['memory_load'] as num?)?.toDouble() ?? _memoryLoad;
            _lastChecked = data['last_checked'] ?? _currentTimeString;

            if (data['sensors'] != null && data['sensors'] is Map) {
              final Map<String, dynamic> rawSensors = data['sensors'];
              rawSensors.forEach((key, val) {
                if (_sensors.containsKey(key)) {
                  _sensors[key] = val == true;
                }
              });
            }
          });
        }
      }
    } catch (_) {}
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
                    onRefresh: _fetchDiagnostics,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Device Status',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'System telemetry and diagnostic reports',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Circular Battery Charge Indicator
                          Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 110,
                                  height: 110,
                                  child: CircularProgressIndicator(
                                    value: (_batteryPercent / 100.0).clamp(0.0, 1.0),
                                    strokeWidth: 8,
                                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _batteryPercent > 20 ? const Color(0xFF27AE60) : const Color(0xFFEB5757),
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${_batteryPercent.toInt()}%',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      _batteryPercent > 20 ? 'CHARGED' : 'LOW BATTERY',
                                      style: TextStyle(
                                        color: _batteryPercent > 20 ? const Color(0xFF27AE60) : const Color(0xFFEB5757),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Telemetry Tiles
                          Row(
                            children: [
                              Expanded(
                                child: _buildTelemetryTile(
                                  label: 'Connection',
                                  value: _connectionType,
                                  valueColor: const Color(0xFF27AE60),
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildTelemetryTile(
                                  label: 'Behavior Mode',
                                  value: _behaviorMode,
                                  valueColor: const Color(0xFF2F80FF),
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTelemetryTile(
                                  label: 'Core Temp',
                                  value: _coreTemp,
                                  valueColor: isDark ? Colors.white : const Color(0xFF0F172A),
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildTelemetryTile(
                                  label: 'Internal Storage',
                                  value: _storageUsage,
                                  valueColor: isDark ? Colors.white : const Color(0xFF0F172A),
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // System Health Section
                          Text(
                            'SYSTEM HEALTH',
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
                                _buildHealthMetric(
                                  label: 'CPU Performance',
                                  percentageText: '${(_cpuLoad * 100).toInt()}%',
                                  progressValue: _cpuLoad.clamp(0.0, 1.0),
                                  progressColor: _cpuLoad > 0.8 ? const Color(0xFFEB5757) : const Color(0xFF27AE60),
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 14),
                                _buildHealthMetric(
                                  label: 'Memory Load',
                                  percentageText: '${(_memoryLoad * 100).toInt()}%',
                                  progressValue: _memoryLoad.clamp(0.0, 1.0),
                                  progressColor: _memoryLoad > 0.85 ? const Color(0xFFEB5757) : const Color(0xFF2F80FF),
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Sensor Diagnostics Section
                          Text(
                            'SENSOR DIAGNOSTICS',
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
                                _buildSensorRow('Camera Module', _sensors['Camera Module'] ?? true, isDark),
                                const Divider(height: 18),
                                _buildSensorRow('LiDAR / Ultrasonic', _sensors['LiDAR / Ultrasonic'] ?? true, isDark),
                                const Divider(height: 18),
                                _buildSensorRow('Microphone Array', _sensors['Microphone Array'] ?? true, isDark),
                                const Divider(height: 18),
                                _buildSensorRow('IMU Accelerometer', _sensors['IMU Accelerometer'] ?? true, isDark),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Firmware Footer Info
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Firmware: v3.2.1',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF94A3B8),
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                'Last Checked: $_lastChecked',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF94A3B8),
                                  fontSize: 11,
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

  Widget _buildTelemetryTile({
    required String label,
    required String value,
    required Color valueColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          Text(
            label,
            style: TextStyle(
              color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetric({
    required String label,
    required String percentageText,
    required double progressValue,
    required Color progressColor,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 12,
              ),
            ),
            Text(
              percentageText,
              style: TextStyle(
                color: progressColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progressValue,
            minHeight: 6,
            backgroundColor: isDark ? const Color(0xFF08111F) : const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }

  Widget _buildSensorRow(String sensorName, bool isActive, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          sensorName,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 13,
          ),
        ),
        Row(
          children: [
            Text(
              isActive ? 'ACTIVE' : 'OFFLINE',
              style: TextStyle(
                color: isActive ? const Color(0xFF27AE60) : const Color(0xFFEB5757),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 14,
              color: isActive ? const Color(0xFF27AE60) : const Color(0xFFEB5757),
            ),
          ],
        ),
      ],
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