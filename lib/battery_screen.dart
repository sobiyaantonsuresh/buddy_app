import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ScreenBattery extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const ScreenBattery({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<ScreenBattery> createState() => _ScreenBatteryState();
}

class _ScreenBatteryState extends State<ScreenBattery> {
  static const String _baseUrl = "http://10.242.169.228:5000";

  bool _powerSavingMode = false;
  bool _autoReturnDock = true;

  double _batteryPercentage = 92.0;
  String _batteryState = 'Discharging';
  String _timeRemaining = '8h 45m remaining';
  String _healthStatus = '97% (Excellent)';

  Timer? _clockTimer;
  Timer? _pollingTimer;
  String _currentTimeString = '';

  final List<Map<String, dynamic>> _drainData = [
    {'day': 'M', 'height': 30.0},
    {'day': 'T', 'height': 22.0},
    {'day': 'W', 'height': 45.0},
    {'day': 'T', 'height': 15.0},
    {'day': 'F', 'height': 40.0},
    {'day': 'S', 'height': 28.0},
    {'day': 'S', 'height': 46.0},
  ];

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    _fetchLiveBattery();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchLiveBattery());
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

  Future<void> _fetchLiveBattery() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/battery_status'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _batteryPercentage = (data['percentage'] as num?)?.toDouble() ?? _batteryPercentage;
            _batteryState = data['state'] ?? _batteryState;
            _timeRemaining = data['remaining'] ?? _timeRemaining;
            _healthStatus = data['health'] ?? _healthStatus;
            if (data['power_saving'] != null) {
              _powerSavingMode = data['power_saving'] as bool;
            }
            if (data['auto_return'] != null) {
              _autoReturnDock = data['auto_return'] as bool;
            }
          });
        }
      }
    } catch (_) {
      // Retains current battery metrics when network drops
    }
  }

  Future<void> _updatePowerSetting(String key, bool value) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/power_settings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({key: value}),
      );
    } catch (_) {
      // Retains offline toggling
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final progressValue = (_batteryPercentage / 100.0).clamp(0.0, 1.0);

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

                // Main Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchLiveBattery,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Battery & Power',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Autonomous power diagnostics and docking',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Live Battery Indicator
                          Center(
                            child: Column(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 120,
                                      height: 120,
                                      child: CircularProgressIndicator(
                                        value: progressValue,
                                        strokeWidth: 10,
                                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          _batteryPercentage > 20 ? const Color(0xFF27AE60) : const Color(0xFFEB5757),
                                        ),
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${_batteryPercentage.toInt()}%',
                                          style: TextStyle(
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          _batteryState,
                                          style: TextStyle(
                                            color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _timeRemaining,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // State of Health Card
                          Container(
                            padding: const EdgeInsets.all(14),
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
                                Text(
                                  'Battery State of Health',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  _healthStatus,
                                  style: const TextStyle(
                                    color: Color(0xFF27AE60),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 7 Days Drain Graph
                          Text(
                            'LAST 7 DAYS POWER DRAIN',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF162033) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: SizedBox(
                              height: 70,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: _drainData.map((d) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        width: 18,
                                        height: d['height'] as double,
                                        decoration: BoxDecoration(
                                          color: d['day'] == 'S' ? const Color(0xFF27AE60) : const Color(0xFF2F80FF),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        d['day'] as String,
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Power Settings
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
                                      'Power Saving Mode',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        fontSize: 14,
                                      ),
                                    ),
                                    Switch(
                                      value: _powerSavingMode,
                                      activeThumbColor: const Color(0xFF2F80FF),
                                      onChanged: (val) {
                                        setState(() => _powerSavingMode = val);
                                        _updatePowerSetting('power_saving', val);
                                      },
                                    ),
                                  ],
                                ),
                                Divider(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0), height: 1),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Auto-Return to Dock at 20%',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        fontSize: 14,
                                      ),
                                    ),
                                    Switch(
                                      value: _autoReturnDock,
                                      activeThumbColor: const Color(0xFF2F80FF),
                                      onChanged: (val) {
                                        setState(() => _autoReturnDock = val);
                                        _updatePowerSetting('auto_return', val);
                                      },
                                    ),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}