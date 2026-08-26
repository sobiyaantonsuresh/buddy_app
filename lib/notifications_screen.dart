import 'package:flutter/material.dart';
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

  final List<Map<String, dynamic>> _notificationItems = [
    {
      'id': '1',
      'title': 'CRITICAL: Unregistered Person',
      'desc': 'Unknown target detected at Front Yard perimeter.',
      'time': '2m ago',
      'isUnread': true,
      'category': 'Security',
      'hasAction': true,
      'actionText': 'View Stream',
      'actionType': 'camera',
    },
    {
      'id': '2',
      'title': 'WARNING: Battery Low (15%)',
      'desc': 'Robot returning to charging dock shortly.',
      'time': '12m ago',
      'isUnread': true,
      'category': 'System',
      'hasAction': true,
      'actionText': 'Dismiss',
      'actionType': 'dismiss',
    },
    {
      'id': '3',
      'title': 'INFO: Patrol Route Updated',
      'desc': 'Route Alpha synced successfully via cloud.',
      'time': '1h ago',
      'isUnread': false,
      'category': 'System',
      'hasAction': false,
    },
    {
      'id': '4',
      'title': 'ARRIVED: Sobiya arrived home',
      'desc': 'Owner recognized successfully with high mood index.',
      'time': '2h ago',
      'isUnread': false,
      'category': 'Info',
      'hasAction': false,
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (var item in _notificationItems) {
        item['isUnread'] = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read.')),
    );
  }

  void _handleAction(String actionType, int index) {
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
                        // Header with Mark All Read
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

                        // Filter Chips
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

                        // Notification Items List
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
                                    color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
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
                                              backgroundColor: isCritical ? const Color(0xFFEB5757) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                                              foregroundColor: isCritical ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                              minimumSize: Size.zero,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
            color: isSelected ? const Color(0xFF2F80FF) : (isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0)),
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