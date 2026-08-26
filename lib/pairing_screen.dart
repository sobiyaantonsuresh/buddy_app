import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class ScreenPairing extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const ScreenPairing({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<ScreenPairing> createState() => _ScreenPairingState();
}

class _ScreenPairingState extends State<ScreenPairing> {
  bool _isBluetoothEnabled = true;
  bool _isWifiDirectEnabled = true;
  bool _isConnecting = false;
  String _connectionStatus = 'Searching for BUDDY...';

  void _connectToRobot(String robotName) async {
    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Connecting to $robotName...';
    });

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() {
      _isConnecting = false;
      _connectionStatus = 'Connected to $robotName!';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully linked with $robotName!'),
        backgroundColor: const Color(0xFF27AE60),
      ),
    );

    // Navigate to Home screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ScreenHome(
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
                              Icons.settings_outlined,
                              color: isDark ? Colors.white70 : Colors.black87,
                              size: 20,
                            ),
                            tooltip: 'Settings Hub',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ScreenSettings(
                                    isDarkMode: widget.isDarkMode,
                                    onThemeToggle: widget.onThemeToggle,
                                  ),
                                ),
                              );
                            },
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
                        // Header
                        Text(
                          'Connect to BUDDY',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Establish a secure local network link via Bluetooth/Wi-Fi',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Radar Search Visualizer
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 170,
                                    height: 170,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF2F80FF).withValues(alpha: 0.2), width: 1.5),
                                    ),
                                  ),
                                  Container(
                                    width: 125,
                                    height: 125,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF2F80FF).withValues(alpha: 0.4), width: 1.5),
                                    ),
                                  ),
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF2F80FF).withValues(alpha: 0.15),
                                      border: Border.all(color: const Color(0xFF2F80FF), width: 2),
                                    ),
                                    child: const Icon(Icons.radar_rounded, color: Color(0xFF2F80FF), size: 36),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2F80FF),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _connectionStatus,
                                    style: TextStyle(
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Available Robots Section
                        Text(
                          'AVAILABLE ROBOTS',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Robot Discovery Card
                        Container(
                          width: double.infinity,
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
                              Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2F80FF).withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF2F80FF), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'BUDDY-X1 (Edge-AI)',
                                        style: TextStyle(
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'Signal: Excellent (-42 dBm)',
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                                          fontSize: 11,
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
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                onPressed: _isConnecting ? null : () => _connectToRobot('BUDDY-X1'),
                                child: _isConnecting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Connect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Wireless Toggles
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
                                  Row(
                                    children: [
                                      const Icon(Icons.bluetooth_rounded, color: Color(0xFF2F80FF), size: 20),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Local Bluetooth',
                                        style: TextStyle(
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: _isBluetoothEnabled,
                                    activeColor: const Color(0xFF2F80FF),
                                    onChanged: (val) => setState(() => _isBluetoothEnabled = val),
                                  ),
                                ],
                              ),
                              Divider(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0), height: 1),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.wifi_tethering_rounded, color: Color(0xFF2F80FF), size: 20),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Wi-Fi Direct',
                                        style: TextStyle(
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: _isWifiDirectEnabled,
                                    activeColor: const Color(0xFF2F80FF),
                                    onChanged: (val) => setState(() => _isWifiDirectEnabled = val),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        Center(
                          child: Text(
                            'Make sure BUDDY is powered on and within 10m range',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                              fontSize: 12,
                            ),
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