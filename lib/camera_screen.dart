import 'dart:async';
import 'dart:convert';
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'home_screen.dart';
import 'control_screen.dart';
import 'activity_screen.dart';
import 'settings_screen.dart';

class ScreenCamera extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const ScreenCamera({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<ScreenCamera> createState() => _ScreenCameraState();
}

class _ScreenCameraState extends State<ScreenCamera> {
  static const String _baseUrl =
      kIsWeb ? "http://localhost:5000" : "http://192.168.8.192:5000";

  int _currentNavIndex = 2;
  Timer? _clockTimer;
  String _currentTimeString = '';

  bool _isTorchOn = false;
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  String _selectedCategory = 'All';
  late String _viewType;

  // Dynamic media items list fetched from the robot server
  List<Map<String, dynamic>> _mediaItems = [];

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());

    // Fetch previously saved records from server on startup
    _fetchPersistedMedia();

    _viewType = 'video-feed-${DateTime.now().millisecondsSinceEpoch}';
    if (kIsWeb) {
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) {
          final img = html.ImageElement()
            ..src = '$_baseUrl/video_call'
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.objectFit = 'cover'
            ..style.border = 'none';
          return img;
        },
      );
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _recordTimer?.cancel();
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

  // Load saved captures from server
  Future<void> _fetchPersistedMedia() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/camera/media_list'));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _mediaItems = data.map((item) {
              final isPhoto = item['type'] == 'photo';
              return {
                'name': item['name'],
                'title': item['title'],
                'time': item['time'],
                'type': item['type'],
                'icon': isPhoto
                    ? Icons.camera_alt_outlined
                    : Icons.videocam_outlined,
                'color': isPhoto
                    ? const Color(0xFF27AE60)
                    : const Color(0xFFEB5757),
                'mediaUrl': "$_baseUrl${item['url']}",
              };
            }).toList();
          });
        }
      }
    } catch (_) {}
  }

  // Delete media file from captures/ folder
  Future<void> _deleteMedia(String filename) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/camera/delete_media'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'filename': filename}),
      );
      if (res.statusCode == 200) {
        _fetchPersistedMedia();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Media item deleted successfully"),
              backgroundColor: Color(0xFFEB5757),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _toggleTorch() async {
    setState(() => _isTorchOn = !_isTorchOn);
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/camera/torch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'state': _isTorchOn}),
      );
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isTorchOn ? "Torch light ON" : "Torch light OFF"),
          duration: const Duration(seconds: 1),
          backgroundColor: const Color(0xFF2F80FF),
        ),
      );
    }
  }

  Future<void> _takeSnapshot() async {
    try {
      final res = await http.post(Uri.parse('$_baseUrl/api/camera/snapshot'));
      if (res.statusCode == 200) {
        await _fetchPersistedMedia();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("📸 Snapshot saved to captures/"),
              backgroundColor: Color(0xFF27AE60),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _toggleRecording() async {
    if (!_isRecording) {
      try {
        await http.post(Uri.parse('$_baseUrl/api/camera/record/start'));
      } catch (_) {}

      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
      });

      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) setState(() => _recordSeconds++);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🔴 Video recording started..."),
            backgroundColor: Color(0xFFEB5757),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } else {
      _recordTimer?.cancel();
      try {
        await http.post(Uri.parse('$_baseUrl/api/camera/record/stop'));
        await _fetchPersistedMedia();
      } catch (_) {}

      setState(() => _isRecording = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⏹️ Recording saved (${_recordSeconds}s)"),
            backgroundColor: const Color(0xFF27AE60),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _resetCamera() async {
    try {
      await http.post(Uri.parse('$_baseUrl/api/camera/reset'));
    } catch (_) {}

    setState(() {
      _viewType = 'video-feed-${DateTime.now().millisecondsSinceEpoch}';
      if (kIsWeb) {
        ui_web.platformViewRegistry.registerViewFactory(
          _viewType,
          (int viewId) => html.ImageElement()
            ..src =
                '$_baseUrl/video_call?t=${DateTime.now().millisecondsSinceEpoch}'
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.objectFit = 'cover',
        );
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🔄 Camera feed refreshed"),
          backgroundColor: Color(0xFF2F80FF),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _openMediaPreview(Map<String, dynamic> item) {
    final String? mediaUrl = item['mediaUrl'];
    final bool isPhoto = item['type'] == 'photo';
    final String? fileName = item['name'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(item['icon'] as IconData,
                    color: item['color'] as Color, size: 22),
                const SizedBox(width: 8),
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (fileName != null)
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 20),
                tooltip: "Delete File",
                onPressed: () {
                  Navigator.pop(ctx);
                  _deleteMedia(fileName);
                },
              ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Captured at: ${item['time']}",
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1B2A44)),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: mediaUrl != null
                  ? (isPhoto
                      ? Image.network(
                          mediaUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Text("Unable to preview image",
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 12)),
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Color(0xFF27AE60), size: 40),
                              const SizedBox(height: 8),
                              Text(
                                "File: ${mediaUrl.split('/').last}",
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Stored securely in captures/",
                                style: TextStyle(
                                    color: Colors.greenAccent, fontSize: 10),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                ),
                                onPressed: () {
                                  html.window.open(mediaUrl, '_blank');
                                },
                                icon: const Icon(Icons.download,
                                    size: 14, color: Colors.white),
                                label: const Text(
                                  "Download / View Video",
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.white),
                                ),
                              )
                            ],
                          ),
                        ))
                  : const Center(
                      child: Text("No Preview Available",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
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
      setState(() => _currentNavIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _mediaItems.where((item) {
      if (_selectedCategory == 'All') return true;
      if (_selectedCategory == 'Photos') return item['type'] == 'photo';
      if (_selectedCategory == 'Videos') return item['type'] == 'video';
      if (_selectedCategory == 'Alerts') return item['type'] == 'alert';
      return true;
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new,
                                size: 14, color: Colors.white70),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.maybePop(context),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _currentTimeString.isEmpty
                                ? '12:09 PM'
                                : _currentTimeString,
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
                          const Icon(Icons.wifi,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          const Icon(Icons.battery_full,
                              color: Colors.white70, size: 18),
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
                        // Live Stream Card
                        Container(
                          height: 230,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF080F1E),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF1B2A44)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              kIsWeb
                                  ? HtmlElementView(viewType: _viewType)
                                  : Image.network(
                                      '$_baseUrl/video_call',
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                    ),
                              Positioned(
                                top: 12,
                                left: 12,
                                right: 12,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.videocam,
                                            size: 14, color: Colors.white70),
                                        SizedBox(width: 4),
                                        Text(
                                          "CAM_FRONT_01",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        if (_isRecording) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEB5757),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              "REC ${_recordSeconds}s",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.5),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.circle,
                                                  size: 6,
                                                  color: Color(0xFF22C55E)),
                                              SizedBox(width: 4),
                                              Text(
                                                "LIVE FEED",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    GestureDetector(
                                      onTap: _toggleTorch,
                                      child: CircleAvatar(
                                        radius: 17,
                                        backgroundColor: _isTorchOn
                                            ? const Color(0xFF2563EB)
                                            : Colors.black.withOpacity(0.6),
                                        child: Icon(
                                          _isTorchOn
                                              ? Icons.flash_on
                                              : Icons.flash_off_outlined,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _takeSnapshot,
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundColor:
                                            Colors.black.withOpacity(0.6),
                                        child: const Icon(
                                          Icons.camera_alt_outlined,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _toggleRecording,
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: const Color(0xFFEB5757),
                                        child: Icon(
                                          _isRecording
                                              ? Icons.stop
                                              : Icons.fiber_manual_record,
                                          color: Colors.white,
                                          size: _isRecording ? 18 : 22,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _resetCamera,
                                      child: CircleAvatar(
                                        radius: 17,
                                        backgroundColor:
                                            Colors.black.withOpacity(0.6),
                                        child: const Icon(
                                          Icons.refresh,
                                          color: Colors.white,
                                          size: 17,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "CAPTURED MEDIA GALLERY",
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildCategoryChip('All'),
                              const SizedBox(width: 8),
                              _buildCategoryChip('Photos'),
                              const SizedBox(width: 8),
                              _buildCategoryChip('Videos'),
                              const SizedBox(width: 8),
                              _buildCategoryChip('Alerts'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Media Cards Display
                        if (_mediaItems.isEmpty)
                          Container(
                            height: 100,
                            alignment: Alignment.center,
                            child: const Text(
                              "No captures yet. Take a snapshot or start recording!",
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 11),
                            ),
                          )
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: filteredList.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: GestureDetector(
                                    onTap: () => _openMediaPreview(item),
                                    child: Container(
                                      width: 105,
                                      height: 110,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F1A2E),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                            color: const Color(0xFF1B2A44)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(
                                            item['icon'] as IconData,
                                            color: item['color'] as Color,
                                            size: 20,
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['title'] as String,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item['time'] as String,
                                                style: const TextStyle(
                                                  color: Colors.white38,
                                                  fontSize: 9,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
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
                      _buildBottomNavItem(
                        icon: Icons.home_outlined,
                        label: "Home",
                        isSelected: _currentNavIndex == 0,
                        onTap: () => _onBottomNavTapped(0),
                      ),
                      _buildBottomNavItem(
                        icon: Icons.sports_esports_outlined,
                        label: "Control",
                        isSelected: _currentNavIndex == 1,
                        onTap: () => _onBottomNavTapped(1),
                      ),
                      _buildBottomNavItem(
                        icon: Icons.videocam,
                        label: "Camera",
                        isSelected: _currentNavIndex == 2,
                        onTap: () => setState(() => _currentNavIndex = 2),
                      ),
                      _buildBottomNavItem(
                        icon: Icons.show_chart,
                        label: "Activity",
                        isSelected: _currentNavIndex == 3,
                        onTap: () => _onBottomNavTapped(3),
                      ),
                      _buildBottomNavItem(
                        icon: Icons.settings_outlined,
                        label: "Settings",
                        isSelected: _currentNavIndex == 4,
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
          color:
              isSelected ? const Color(0xFF2563EB) : const Color(0xFF0F1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFF1B2A44),
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
          Icon(icon,
              size: 20,
              color: isSelected ? const Color(0xFF2563EB) : Colors.white38),
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