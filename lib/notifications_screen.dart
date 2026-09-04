import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'camera_screen.dart';

class ScreenNotifications extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const ScreenNotifications({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<ScreenNotifications> createState() => _ScreenNotificationsState();
}

class _ScreenNotificationsState extends State<ScreenNotifications> {
  String _selectedCategory = 'All';

  static const String _baseUrl = "http://10.242.169.228:5000";
  Timer? _clockTimer;
  Timer? _pollingTimer;
  String _currentTimeString = '';

  List<Map<String, dynamic>> _notificationItems = [
    {
      'id': '1',
      'title': 'CRITICAL: Unregistered Person',
      'desc': 'Unknown target detected at Front Yard perimeter.',
      'time': 'Just now',
      'isUnread': true,
      'category': 'Security',
      'hasAction': true,
      'actionText': 'View Stream',
      'actionType': 'camera',
    },
    {
      'id': '2',
      'title': 'INFO: Patrol Route Active',
      'desc': 'Perimeter Alpha monitoring running normally.',
      'time': '15m ago',
      'isUnread': false,
      'category': 'System',
      'hasAction': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    _fetchLiveNotifications();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchLiveNotifications());
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

  Future<void> _fetchLiveNotifications() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/api/notifications'))
          .timeout(const Duration(seconds: 2));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List && mounted) {
          final List<Map<String, dynamic>> fetched = [];
          for (var item in decoded) {
            fetched.add({
              'id': item['id']?.toString() ?? UniqueKey().toString(),
              'title': item['title'] ?? 'System Event',
              'desc': item['desc'] ?? '',
              'time': item['time'] ?? 'Recent',
              'isUnread': item['isUnread'] ?? true,
              'category': item['category'] ?? 'Security',
              'hasAction': item['hasAction'] ?? false,
              'actionText': item['actionText'] ?? 'View Stream',
              'actionType': item['actionType'] ?? 'camera',
            });
          }
          setState(() => _notificationItems = fetched);
        }
      }
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      for (var item in _notificationItems) {
        item['isUnread'] = false;
      }
    });

    try {
      await http.post(Uri.parse('$_baseUrl/api/clear_unknown_alert'));
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read.'),
          backgroundColor: Color(0xFF27AE60),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _handleAction(String actionType, int index) async {
    if (actionType == 'camera') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScreenCamera(
            isDarkMode: widget.isDarkMode,
            onThemeToggle: widget.onThemeToggle,
          ),
        ),
      );
    } else if (actionType == 'dismiss') {
      setState(() {
        _notificationItems.removeAt(index);
      });

      try {
        await http.post(Uri.parse('$_baseUrl/api/clear_unknown_alert'));
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    final filteredItems = _notificationItems.where((item) {
      if (_selectedCategory == 'All') return true;
      return item['category'] == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
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
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchLiveNotifications,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Notifications',
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              GestureDetector(
                                onTap: _markAllAsRead,
                                child: const Text(
                                  'Mark All Read',
                                  style: TextStyle(
                                    color: Color(0xFF2F80FF),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Recent robotic events and alert logs',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip('All', isDark),
                                const SizedBox(width: 8),
                                _buildFilterChip('Security', isDark),
                                const SizedBox(width: 8),
                                _buildFilterChip('System', isDark),
                                const SizedBox(width: 8),
                                _buildFilterChip('Info', isDark),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (filteredItems.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  'No notifications found.',
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
                              itemCount: filteredItems.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                final isCritical = item['title'].toString().contains('CRITICAL');

                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF162033) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isCritical
                                          ? const Color(0xFFEB5757).withValues(alpha: 0.5)
                                          : (isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['title'] as String,
                                                  style: TextStyle(
                                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  item['desc'] as String,
                                                  style: TextStyle(
                                                    color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Row(
                                            children: [
                                              Text(
                                                item['time'] as String,
                                                style: TextStyle(
                                                  color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF94A3B8),
                                                  fontSize: 11,
                                                ),
                                              ),
                                              if (item['isUnread'] == true) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF2F80FF),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (item['hasAction'] == true) ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isCritical
                                                    ? const Color(0xFFEB5757)
                                                    : const Color(0xFF2F80FF),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                                minimumSize: Size.zero,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                              ),
                                              onPressed: () => _handleAction(item['actionType'] as String, index),
                                              child: Text(
                                                item['actionText'] as String,
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2F80FF) : (isDark ? const Color(0xFF162033) : Colors.white),
          borderRadius: BorderRadius.circular(20),
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
}