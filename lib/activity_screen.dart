import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';
import 'control_screen.dart';
import 'camera_screen.dart';
import 'emotion_screen.dart';
import 'security_screen.dart';
import 'status_screen.dart';

class ScreenActivity extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const ScreenActivity({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<ScreenActivity> createState() => _ScreenActivityState();
}

class _ScreenActivityState extends State<ScreenActivity> {
  int _selectedNavIndex = 3; // Activity Tab
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Correct Laptop Wi-Fi IP and Flask Backend Port
  static const String _baseUrl = "http://192.168.8.192:5000";
  Timer? _clockTimer;
  Timer? _pollingTimer;
  String _currentTimeString = '';

  List<Map<String, dynamic>> _activities = [
    {
      'id': 'patrol',
      'title': 'Patrol Started — Route Alpha',
      'desc': 'Autonomous security route active',
      'time': '09:30 AM',
      'category': 'Patrols',
      'icon': Icons.security_rounded,
      'color': const Color(0xFF2F80FF),
    },
    {
      'id': 'alert',
      'title': 'Unregistered Face Detected',
      'desc': 'Front lawn perimeter alert issued',
      'time': '09:22 AM',
      'category': 'Alerts',
      'icon': Icons.warning_amber_rounded,
      'color': const Color(0xFFEB5757),
    },
    {
      'id': 'emotion',
      'title': 'Sobiya Detected — Mood: Happy',
      'desc': 'Target recognized successfully',
      'time': '08:45 AM',
      'category': 'Detections',
      'icon': Icons.face_retouching_natural_rounded,
      'color': const Color(0xFF27AE60),
    },
    {
      'id': 'status',
      'title': 'BUDDY Online — Battery 98%',
      'desc': 'System reboot complete',
      'time': '08:00 AM',
      'category': 'System',
      'icon': Icons.power_settings_new_rounded,
      'color': const Color(0xFF2F80FF),
    },
    {
      'id': 'status',
      'title': 'Charging Complete',
      'desc': 'Docking station release',
      'time': '07:30 AM',
      'category': 'System',
      'icon': Icons.battery_charging_full_rounded,
      'color': const Color(0xFF27AE60),
    },
  ];

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    _fetchLiveActivities();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchLiveActivities());
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pollingTimer?.cancel();
    _searchController.dispose();
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

  Future<void> _fetchLiveActivities() {
    return _fetchLogsFromApi();
  }

  Future<void> _fetchLogsFromApi() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/notifications'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          final List<Map<String, dynamic>> parsedList = [];
          for (var item in decoded) {
            final category = item['category'] ?? 'System';

            String navId = 'status';
            if (category == 'Patrols') {
              navId = 'patrol';
            } else if (category == 'Alerts') {
              navId = 'alert';
            } else if (category == 'Detections') {
              navId = 'emotion';
            }

            parsedList.add({
              'id': navId,
              'title': item['title'] ?? 'System Event',
              'desc': item['desc'] ?? '',
              'time': item['time'] ?? _currentTimeString,
              'category': category,
              'icon': _getCategoryIcon(category),
              'color': _getCategoryColor(category),
            });
          }
          if (mounted && parsedList.isNotEmpty) {
            setState(() {
              _activities = parsedList;
            });
          }
        }
      }
    } catch (_) {
      // Keeps fallback logs active if server is temporarily unreachable
    }
  }

  IconData _getCategoryIcon(dynamic category) {
    switch (category) {
      case 'Patrols':
        return Icons.security_rounded;
      case 'Alerts':
        return Icons.warning_amber_rounded;
      case 'Detections':
        return Icons.face_retouching_natural_rounded;
      default:
        return Icons.power_settings_new_rounded;
    }
  }

  Color _getCategoryColor(dynamic category) {
    switch (category) {
      case 'Alerts':
        return const Color(0xFFEB5757);
      case 'Detections':
        return const Color(0xFF27AE60);
      default:
        return const Color(0xFF2F80FF);
    }
  }

  void _handleActivityTap(String id) {
    if (id == 'patrol') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScreenSecurity(
            isDarkMode: widget.isDarkMode,
            onThemeToggle: widget.onThemeToggle,
          ),
        ),
      );
    } else if (id == 'alert') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScreenCamera(
            isDarkMode: widget.isDarkMode,
            onThemeToggle: widget.onThemeToggle,
          ),
        ),
      );
    } else if (id == 'emotion') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScreenEmotion(
            isDarkMode: widget.isDarkMode,
            onThemeToggle: widget.onThemeToggle,
          ),
        ),
      );
    } else if (id == 'status') {
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
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScreenStatus(
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

    final filteredActivities = _activities.where((act) {
      final matchesCategory = _selectedCategory == 'All' || act['category'] == _selectedCategory;
      final matchesSearch = act['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          act['desc'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

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
                    onRefresh: _fetchLiveActivities,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Activity Log',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Comprehensive robotic telemetry & quick logs',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Search Field
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF162033) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => setState(() => _searchQuery = value),
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Search historical events...',
                                hintStyle: TextStyle(
                                  color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF94A3B8),
                                  fontSize: 13,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                  color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Filter Chips
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildFilterChip('All', isDark),
                              _buildFilterChip('Detections', isDark),
                              _buildFilterChip('Patrols', isDark),
                              _buildFilterChip('Alerts', isDark),
                              _buildFilterChip('System', isDark),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Activity List Items
                          if (filteredActivities.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  'No matching activity logs found.',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredActivities.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item = filteredActivities[index];
                                return GestureDetector(
                                  onTap: () => _handleActivityTap(item['id'] as String),
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
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF08111F) : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(width: 1.2, color: item['color'] as Color),
                                          ),
                                          child: Icon(item['icon'] as IconData, size: 20, color: item['color'] as Color),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item['title'] as String,
                                                      style: TextStyle(
                                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    item['time'] as String,
                                                    style: TextStyle(
                                                      color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF94A3B8),
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item['desc'] as String,
                                                      style: TextStyle(
                                                        color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                                                        fontSize: 11,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.arrow_forward_ios_rounded,
                                                    size: 11,
                                                    color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF94A3B8),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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

  Widget _buildFilterChip(String label, bool isDark) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
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