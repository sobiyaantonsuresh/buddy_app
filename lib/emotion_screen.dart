import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';
import 'control_screen.dart';
import 'camera_screen.dart';
import 'activity_screen.dart';
import 'settings_screen.dart';

class ScreenEmotion extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  final String targetName;

  const ScreenEmotion({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
    this.targetName = 'ashandth',
  });

  @override
  State<ScreenEmotion> createState() => _ScreenEmotionState();
}

class _ScreenEmotionState extends State<ScreenEmotion> {
  int _selectedNavIndex = 3;
  late String _targetName;
  String _currentEmotion = 'Unknown';
  List<String> _householdNames = [];
  String? _profileError;

  int _confidence = 0;
  bool _isMusicRequested = false;
  bool _isMusicPlayingNow = false; // Backend polling moolam update aagum
  List<dynamic> _reports24h = [];
  bool _isLoading = true;

  // Fall Detection State Variables
  bool _isFallEmergency = false;

  // Music Therapy Trackers
  String _lastPlayedTime = 'None';
  String _musicTarget = 'None';

  static const String _baseUrl = kIsWeb ? "http://10.138.45.237:5000" : "http://10.138.45.237:5000";
  Timer? _clockTimer;
  Timer? _pollingTimer;
  String _currentTimeString = '';

  // 7 Emotions Color Mapping
  final Map<String, Color> _emotionColors = {
    'Happy': const Color(0xFF27AE60),    // Green ðŸ˜Š
    'Sad': const Color(0xFF2F80FF),      // Blue ðŸ˜¢
    'Angry': const Color(0xFFEB5757),    // Red ðŸ˜ 
    'Fear': const Color(0xFF9B51E0),     // Purple ðŸ˜¨
    'Surprise': const Color(0xFFF2C94C), // Yellow ðŸ˜²
    'Disgust': const Color(0xFF219653),  // Dark Green ðŸ¤¢
    'Neutral': const Color(0xFF8F9BB3),  // Grey/Blue ðŸ˜
  };

  @override
  void initState() {
    super.initState();
    _targetName = widget.targetName.trim().isEmpty ? 'Ashandth' : widget.targetName.trim();
    _loadHouseholdMembers();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    _fetchEmotionReport24h();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchEmotionReport24h());
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

  Future<void> _loadHouseholdMembers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/household_members'),
      ).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) throw Exception('Household API unavailable');
      final decoded = jsonDecode(response.body);
      if (decoded is! List) throw Exception('Invalid household response');
      final names = decoded.map((entry) => entry is Map ? entry['name']?.toString().trim() : null)
          .whereType<String>().where((name) => name.isNotEmpty).toSet().toList();
      if (!mounted) return;
      setState(() {
        _householdNames = names;
        _profileError = null;
        if (names.isNotEmpty && !names.any((name) => name.toLowerCase() == _targetName.toLowerCase())) {
          _targetName = names.first;
          _reports24h = [];
          _currentEmotion = 'Unknown';
          _confidence = 0;
          _isLoading = true;
        } else {
          for (final name in names) {
            if (name.toLowerCase() == _targetName.toLowerCase()) _targetName = name;
          }
        }
      });
      await _fetchEmotionReport24h();
    } catch (error) {
      if (!mounted) return;
      setState(() => _profileError = 'Household list unavailable');
    }
  }

  void _selectHouseholdMember(String? name) {
    if (name == null || name == _targetName) return;
    setState(() {
      _targetName = name;
      _reports24h = [];
      _currentEmotion = 'Unknown';
      _confidence = 0;
      _isFallEmergency = false;
      _isMusicPlayingNow = false;
      _lastPlayedTime = 'None';
      _musicTarget = name;
      _isLoading = true;
    });
    _fetchEmotionReport24h();
  }

  Future<void> _fetchEmotionReport24h() async {
    try {
      final requestedTarget = _targetName;
      final cleanTarget = Uri.encodeComponent(requestedTarget.trim().toLowerCase());
      final response = await http
          .get(Uri.parse('$_baseUrl/api/emotion_report/$cleanTarget'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> reports = data['reports'] ?? [];
        
        final recentReports = reports.length > 10 ? reports.sublist(reports.length - 10) : reports;
        final bool fallDetected = data['fall_detected'] ?? false;
        
        // Backend-ilirunthu music status & tracking get panrom
        final bool serverMusicPlaying = data['music_playing'] ?? false;
        final String serverLastTime = data['last_played_time'] ?? 'None';
        final String serverTarget = data['music_target'] ?? _targetName;

        if (mounted && _targetName == requestedTarget) {
          setState(() {
            _reports24h = recentReports;
            _isFallEmergency = fallDetected;
            _isMusicPlayingNow = serverMusicPlaying;
            _lastPlayedTime = serverLastTime;
            _musicTarget = serverTarget;

            if (reports.isNotEmpty) {
              final latest = reports.last;
              _currentEmotion = _capitalize(latest['emotion'] ?? 'neutral');
              _confidence = ((latest['confidence'] ?? 0.0) * 100).round();
            } else {
              _currentEmotion = 'Unknown';
              _confidence = 0;
            }
            _isLoading = false;
          });
        }
      } else {
        if (mounted && _targetName == requestedTarget) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return Icons.sentiment_very_satisfied_rounded;
      case 'sad':
        return Icons.sentiment_dissatisfied_rounded;
      case 'angry':
        return Icons.sentiment_very_dissatisfied_rounded;
      case 'fear':
        return Icons.warning_rounded;
      case 'surprise':
        return Icons.sentiment_neutral_rounded;
      case 'disgust':
        return Icons.sick_rounded;
      case 'neutral':
      default:
        return Icons.sentiment_satisfied_rounded;
    }
  }

  Future<void> _requestMusicTherapy() async {
    setState(() => _isMusicRequested = true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/control/action'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'PLAY_MUSIC',
          'mood': _currentEmotion,
          'target': _targetName,
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'];

        if (mounted) {
          if (status == 'playing') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('âš ï¸ Music is already playing right now! Please wait.'),
                backgroundColor: Colors.orange,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ðŸŽ¶ Signal sent to BUDDY for music therapy!'),
                backgroundColor: Color(0xFF27AE60),
              ),
            );
          }
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('âŒ Error connecting to BUDDY server.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isMusicRequested = false);
      }
    }
  }

  Future<void> _acknowledgeEmergency() async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/emergency/acknowledge'),
        headers: {'Content-Type': 'application/json'},
      );
      setState(() {
        _isFallEmergency = false;
      });
    } catch (_) {}
  }

  void _onBottomNavTapped(int index) {
    if (index == _selectedNavIndex) return;

    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ScreenHome(isDarkMode: widget.isDarkMode, onThemeToggle: widget.onThemeToggle)));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ScreenControl(isDarkMode: widget.isDarkMode, onThemeToggle: widget.onThemeToggle)));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ScreenCamera(isDarkMode: widget.isDarkMode, onThemeToggle: widget.onThemeToggle)));
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ScreenActivity(isDarkMode: widget.isDarkMode, onThemeToggle: widget.onThemeToggle)));
    } else if (index == 4) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ScreenSettings(isDarkMode: widget.isDarkMode, onThemeToggle: widget.onThemeToggle)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final activeColor = _emotionColors[_currentEmotion] ?? const Color(0xFF2F80FF);
    final bool isSadOrStressed = _currentEmotion == 'Sad' || _currentEmotion == 'Angry' || _currentEmotion == 'Fear' || _currentEmotion == 'Disgust';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF060B16) : Colors.white,
      body: SafeArea(
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
                        icon: Icon(Icons.arrow_back_ios_new, size: 18, color: isDark ? Colors.white : Colors.black87),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      Text(
                        _currentTimeString.isEmpty ? '...' : _currentTimeString,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: isDark ? const Color(0xFF2F80FF) : Colors.amber.shade800, size: 20),
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

            // Main Content Area
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchEmotionReport24h,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emotion Report & Therapy',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Recent Telemetry for ${_targetName.toUpperCase()}',
                        style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),

                      // Household member picker - only registered names from live Flask API.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF10192D) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('HOUSEHOLD MEMBER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : const Color(0xFF64748B))),
                            const SizedBox(height: 5),
                            if (_householdNames.isNotEmpty)
                              DropdownButton<String>(
                                isExpanded: true,
                                value: _householdNames.contains(_targetName) ? _targetName : _householdNames.first,
                                underline: const SizedBox.shrink(),
                                items: _householdNames.map((name) => DropdownMenuItem<String>(
                                  value: name,
                                  child: Text(name, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF173630))),
                                )).toList(),
                                onChanged: _selectHouseholdMember,
                              )
                            else
                              Text(_profileError ?? 'Loading registered household members...',
                                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ðŸš¨ STANDALONE MUSIC STATUS CARD (Always visible, independent of emotion)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF10192D) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isMusicPlayingNow ? Colors.green : const Color(0xFF2F80FF),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isMusicPlayingNow ? Icons.music_note_rounded : Icons.history_rounded,
                              color: _isMusicPlayingNow ? Colors.green : const Color(0xFF2F80FF),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isMusicPlayingNow ? 'ðŸŽ¶ MUSIC THERAPY: PLAYING' : 'ðŸŽµ MUSIC THERAPY STATUS',
                                    style: TextStyle(
                                      color: _isMusicPlayingNow ? Colors.green : const Color(0xFF2F80FF),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isMusicPlayingNow
                                        ? 'Song is currently playing for ${_musicTarget.toUpperCase()}...'
                                        : (_lastPlayedTime != 'None'
                                            ? 'Last Played for: ${_musicTarget.toUpperCase()} at $_lastPlayedTime'
                                            : 'Music status is not available from this server.'),
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : Colors.black87,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ðŸš¨ FALL DETECTION EMERGENCY BANNER
                      if (_isFallEmergency)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_rounded, color: Colors.red, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'EMERGENCY: FALL DETECTED!',
                                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Person fallen or unresponsive. Buddy is attempting contact.',
                                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 11),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(140, 32),
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: _acknowledgeEmergency,
                                      icon: const Icon(Icons.check_circle_rounded, size: 16),
                                      label: const Text('Acknowledge / Stop'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Care Assistant Banner (For negative emotions)
                      if (isSadOrStressed && !_isFallEmergency)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2994A).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF2994A), width: 1.2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.favorite_rounded, color: Color(0xFFF2994A), size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Care Assistant Notice',
                                      style: TextStyle(color: Color(0xFFF2994A), fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _isMusicPlayingNow
                                          ? 'Music therapy is currently playing for ${_targetName.toUpperCase()}...'
                                          : 'A $_currentEmotion facial expression was estimated for ${_targetName.toUpperCase()}. You can offer music if they want it.',
                                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 11),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isMusicPlayingNow ? Colors.grey : const Color(0xFFF2994A),
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(140, 32),
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: _isMusicPlayingNow ? null : _requestMusicTherapy,
                                      icon: Icon(_isMusicPlayingNow ? Icons.hourglass_top_rounded : Icons.music_note_rounded, size: 16),
                                      label: Text(_isMusicPlayingNow ? 'Music Playing...' : 'Ask BUDDY for Music'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // HUD Hero Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF10192D) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: activeColor.withOpacity(0.5), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.face_retouching_natural_rounded, size: 18, color: activeColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Profile: ${_targetName.toUpperCase()}',
                                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: activeColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _currentEmotion == 'Unknown' ? 'NO MODEL SCORE' : '$_confidence% MODEL SCORE',
                                    style: TextStyle(color: activeColor, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: activeColor,
                              child: Icon(_getEmotionIcon(_currentEmotion), color: Colors.white, size: 36),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _currentEmotion.toUpperCase(),
                              style: TextStyle(color: activeColor, fontSize: 20, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Recent Mood Timeline Section
                      Text(
                        'RECENT MOOD TIMELINE',
                        style: TextStyle(color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF10192D) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0)),
                        ),
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _reports24h.isEmpty
                                ? Column(
                                    children: [
                                      const Icon(Icons.analytics_outlined, size: 36, color: Colors.white54),
                                      const SizedBox(height: 8),
                                      Text('No telemetry history for ${_targetName.toUpperCase()}.', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                    ],
                                  )
                                : SizedBox(
                                    height: 80,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: _reports24h.map((log) {
                                        final emo = log['emotion']?.toString() ?? 'Neutral';
                                        final barColor = _emotionColors[_capitalize(emo)] ?? const Color(0xFF2F80FF);
                                        return Column(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Container(
                                              width: 14,
                                              height: 45,
                                              decoration: BoxDecoration(
                                                color: barColor,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              log['timestamp'] != null ? log['timestamp'].toString().substring(11, 16) : '',
                                              style: TextStyle(color: isDark ? const Color(0xFF8F9BB3) : Colors.black54, fontSize: 8),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                      ),
                      const SizedBox(height: 12),
                      Text('EXPRESSION COLOR GUIDE',
                        style: TextStyle(color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                          fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 14,
                        runSpacing: 10,
                        children: _emotionColors.entries.map((entry) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 12, height: 12,
                              decoration: BoxDecoration(color: entry.value,
                                borderRadius: BorderRadius.circular(3))),
                            const SizedBox(width: 5),
                            Text(entry.key, style: TextStyle(fontSize: 11,
                              color: isDark ? Colors.white70 : const Color(0xFF475569))),
                          ],
                        )).toList(),
                      ),
                      const SizedBox(height: 8),
                      Text('Colors represent estimated facial expressions, not confirmed feelings.',
                        style: TextStyle(fontSize: 10,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B))),
                      const SizedBox(height: 24),
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
                  _buildNavItem(Icons.sports_esports_outlined, 'Control', 1),
                  _buildNavItem(Icons.videocam_outlined, 'Camera', 2),
                  _buildNavItem(Icons.timeline_rounded, 'Activity', 3),
                  _buildNavItem(Icons.settings_outlined, 'Settings', 4),
                ],
              ),
            ),
          ],
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
