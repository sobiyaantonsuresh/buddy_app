import 'package:flutter/material.dart';

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
  bool _powerSavingMode = false;
  bool _autoReturnDock = true;

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

                        // Battery Indicator
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
                                      value: 0.92,
                                      strokeWidth: 10,
                                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF27AE60)),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '92%',
                                        style: TextStyle(
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        'Discharging',
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
                                '8h 45m remaining',
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
                              const Text(
                                '97% (Excellent)',
                                style: TextStyle(
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
                                    activeColor: const Color(0xFF2F80FF),
                                    onChanged: (val) => setState(() => _powerSavingMode = val),
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
                                    activeColor: const Color(0xFF2F80FF),
                                    onChanged: (val) => setState(() => _autoReturnDock = val),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}