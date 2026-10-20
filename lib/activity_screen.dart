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
import 'settings_screen.dart';

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
  int _selectedNavIndex = 3; // Activity Tab Index
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const String _baseUrl = "http://10.138.45.237:5000";
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

  Future<void> _fetchLiveActivities() async {
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
    } catch (_) {}
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
      Navigator.push(context, MaterialPageRoute(builder: (context) => ScreenSecurity(isDarkMode: widget.isDarkMode, onThemeToggle: widget.onThemeToggle)));
    } else if (id == 'alert') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ScreenCamera(isDarkMode: widget.isDarkMode, onThemeToggle: widget.onThemeToggle)));
    } else if (id == 'emotion') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ScreenEmotion(isDarkMode: widget.isDarkMode, onThemeToggle: widget.onThemeToggle)));
    } else if (id == 'status') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ScreenStatus(isDarkMode: widget.isDarkMode, onThemeToggle: widget.onThemeToggle)));
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
    } else if (index == 3) {
      setState(() => _selectedNavIndex = 3);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredActivities = _activities.where((act) {
      final matchesCategory = _selectedCategory == 'All' || act['category'] == _selectedCategory;
      final matchesSearch = act['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          act['desc'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF060B16),
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
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.white70),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.maybePop(context),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _currentTimeString.isEmpty ? '12:09 PM' : _currentTimeString,
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
                            onTap: widget.onThemeToggle,
                            child: const Icon(
                              Icons.wb_sunny_outlined,
                              color: Colors.lightBlueAccent,
                              size: 16,
                            ),
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
                  child: RefreshIndicator(
                    onRefresh: _fetchLiveActivities,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          const Text(
                            'ACTIVITY LOG',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Activity History & Telemetry',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F1A2E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF1B2A44)),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => setState(() => _searchQuery = value),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: 'Search historical events...',
                                hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                                prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.white38),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildCategoryChip('All'),
                                const SizedBox(width: 8),
                                _buildCategoryChip('Detections'),
                                const SizedBox(width: 8),
                                _buildCategoryChip('Patrols'),
                                const SizedBox(width: 8),
                                _buildCategoryChip('Alerts'),
                                const SizedBox(width: 8),
                                _buildCategoryChip('System'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (filteredActivities.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  'No matching activity logs found.',
                                  style: TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredActivities.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item = filteredActivities[index];
                                return GestureDetector(
                                  onTap: () => _handleActivityTap(item['id'] as String),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F1A2E),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF1B2A44)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF060B16),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(width: 1.2, color: item['color'] as Color),
                                          ),
                                          child: Icon(item['icon'] as IconData, size: 18, color: item['color'] as Color),
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
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    item['time'] as String,
                                                    style: const TextStyle(color: Colors.white38, fontSize: 9),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                item['desc'] as String,
                                                style: const TextStyle(color: Colors.white60, fontSize: 10),
                                                overflow: TextOverflow.ellipsis,
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
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF060B16),
                    border: Border(top: BorderSide(color: Color(0xFF131D31))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBottomNavItem(
                        icon: Icons.home_outlined,
                        label: "Home",
                        isSelected: _selectedNavIndex == 0,
                        onTap: () => _onBottomNavTapped(0),
                      ),
                      _buildBottomNavItem(
                        icon: Icons.sports_esports_outlined,
                        label: "Control",
                        isSelected: _selectedNavIndex == 1,
                        onTap: () => _onBottomNavTapped(1),
                      ),
                      _buildBottomNavItem(
                        icon: Icons.videocam_outlined,
                        label: "Camera",
                        isSelected: _selectedNavIndex == 2,
                        onTap: () => _onBottomNavTapped(2),
                      ),
                      _buildBottomNavItem(
                        icon: Icons.show_chart,
                        label: "Activity",
                        isSelected: _selectedNavIndex == 3,
                        onTap: () => _onBottomNavTapped(3),
                      ),
                      _buildBottomNavItem(
                        icon: Icons.settings_outlined,
                        label: "Settings",
                        isSelected: _selectedNavIndex == 4,
                        onTap: () => _onBottomNavTapped(4),
                      ),
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

  Widget _buildCategoryChip(String title) {
    final isSelected = _selectedCategory == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF0F1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1B2A44),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.bold,
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