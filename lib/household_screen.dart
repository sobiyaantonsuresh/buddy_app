import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ScreenHousehold extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const ScreenHousehold({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<ScreenHousehold> createState() => _ScreenHouseholdState();
}

class _ScreenHouseholdState extends State<ScreenHousehold> {
  final ImagePicker _picker = ImagePicker();
  static const String _baseUrl = "http://10.242.169.228:5000";

  Timer? _clockTimer;
  Timer? _pollingTimer;
  String _currentTimeString = '';
  bool _isUploading = false;

  List<Map<String, dynamic>> _members = [
    {
      'name': 'Sobiya',
      'role': 'Owner',
      'status': 'RECOGNIZED',
      'color': const Color(0xFF27AE60),
      'imageBytes': null,
    },
    {
      'name': 'Rayan',
      'role': 'Member',
      'status': 'RECOGNIZED',
      'color': const Color(0xFF27AE60),
      'imageBytes': null,
    },
    {
      'name': 'Zara',
      'role': 'Guest',
      'status': 'UNREGISTERED',
      'color': const Color(0xFFF2994A),
      'imageBytes': null,
    },
  ];

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    _fetchHouseholdMembers();
    _pollingTimer = Timer.periodic(const Duration(seconds: 6), (_) => _fetchHouseholdMembers());
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

  Future<void> _fetchHouseholdMembers() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/get_household_members')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List && decoded.isNotEmpty) {
          final List<Map<String, dynamic>> fetched = [];
          for (var item in decoded) {
            Uint8List? bytes;
            if (item['image_base64'] != null && item['image_base64'].toString().isNotEmpty) {
              try {
                bytes = base64Decode(item['image_base64']);
              } catch (_) {}
            }
            fetched.add({
              'name': item['name'] ?? 'Unknown',
              'role': item['role'] ?? 'Member',
              'status': item['status'] ?? 'RECOGNIZED',
              'color': item['status'] == 'RECOGNIZED' ? const Color(0xFF27AE60) : const Color(0xFFF2994A),
              'imageBytes': bytes,
            });
          }
          if (mounted) {
            setState(() => _members = fetched);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _registerFaceOnBackend(String name, String role, Uint8List? imageBytes) async {
    try {
      String? base64Img;
      if (imageBytes != null) {
        base64Img = base64Encode(imageBytes);
      }

      await http.post(
        Uri.parse('$_baseUrl/api/register_face'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'role': role,
          'image': base64Img,
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  void _showAddMemberDialog() {
    final nameController = TextEditingController();
    String selectedRole = 'Member';
    Uint8List? capturedImageBytes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDarkMode ? const Color(0xFF162033) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Enroll New Companion',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: widget.isDarkMode ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Image Preview / Scanner Viewport
                Container(
                  width: double.infinity,
                  height: 190,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1128),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: capturedImageBytes != null ? const Color(0xFF27AE60) : const Color(0xFF2F80FF),
                      width: 1.5,
                    ),
                  ),
                  child: capturedImageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(capturedImageBytes!, fit: BoxFit.cover, width: double.infinity),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.face_retouching_natural_rounded,
                              size: 48,
                              color: Colors.white54,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Take a photo or choose from gallery',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 12),

                // Dual Image Pick Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F80FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          try {
                            final XFile? photo = await _picker.pickImage(
                              source: ImageSource.camera,
                              maxWidth: 600,
                              maxHeight: 600,
                              imageQuality: 85,
                            );
                            if (photo != null) {
                              final bytes = await photo.readAsBytes();
                              setModalState(() {
                                capturedImageBytes = bytes;
                              });
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Camera error: $e')),
                            );
                          }
                        },
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text('Open Camera', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          foregroundColor: widget.isDarkMode ? Colors.white : const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: widget.isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          try {
                            final XFile? image = await _picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 600,
                              maxHeight: 600,
                              imageQuality: 85,
                            );
                            if (image != null) {
                              final bytes = await image.readAsBytes();
                              setModalState(() {
                                capturedImageBytes = bytes;
                              });
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gallery error: $e')),
                            );
                          }
                        },
                        icon: const Icon(Icons.photo_library_rounded, size: 18, color: Color(0xFF2F80FF)),
                        label: const Text('From Gallery', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name Input Field
                TextField(
                  controller: nameController,
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g., Anton Suresh',
                    prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF2F80FF)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // Role Dropdown Selection
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  dropdownColor: widget.isDarkMode ? const Color(0xFF162033) : Colors.white,
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Household Permission Role',
                    prefixIcon: const Icon(Icons.security_rounded, color: Color(0xFF2F80FF)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Member', child: Text('Member (Full Recognition)')),
                    DropdownMenuItem(value: 'Guest', child: Text('Guest (Temporary Access)')),
                    DropdownMenuItem(value: 'Admin', child: Text('Admin (System Access)')),
                  ],
                  onChanged: (val) => setModalState(() => selectedRole = val ?? 'Member'),
                ),
                const SizedBox(height: 20),

                // Save Member Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F80FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: _isUploading
                        ? null
                        : () async {
                            final enteredName = nameController.text.trim();
                            if (enteredName.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a member name.')),
                              );
                              return;
                            }

                            setModalState(() => _isUploading = true);

                            // Send to Python Flask & AI database
                            await _registerFaceOnBackend(enteredName, selectedRole, capturedImageBytes);

                            if (mounted) {
                              setState(() {
                                _members.add({
                                  'name': enteredName,
                                  'role': selectedRole,
                                  'status': capturedImageBytes != null ? 'RECOGNIZED' : 'UNREGISTERED',
                                  'color': capturedImageBytes != null ? const Color(0xFF27AE60) : const Color(0xFFF2994A),
                                  'imageBytes': capturedImageBytes,
                                });
                              });
                            }

                            setModalState(() => _isUploading = false);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$enteredName registered into Face Database!'),
                                  backgroundColor: const Color(0xFF27AE60),
                                ),
                              );
                            }
                          },
                    child: _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('SAVE & REGISTER FACE', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
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

                // Main Content Area
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchHouseholdMembers,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Household Profile',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage recognized family and permissions',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Owner Profile Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF162033) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: const Color(0xFF2F80FF).withValues(alpha: 0.2),
                                  child: const Icon(Icons.person, color: Color(0xFF2F80FF), size: 30),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Sobiya',
                                          style: TextStyle(
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2F80FF),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'OWNER',
                                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Connected since Jan 2026',
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Members List Section
                          Text(
                            'HOUSEHOLD MEMBERS',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 10),

                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _members.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final m = _members[index];
                              final Uint8List? imgBytes = m['imageBytes'] as Uint8List?;

                              return Container(
                                padding: const EdgeInsets.all(12),
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
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                          backgroundImage: imgBytes != null ? MemoryImage(imgBytes) : null,
                                          child: imgBytes == null
                                              ? Icon(Icons.person_outline, size: 20, color: isDark ? Colors.white70 : Colors.black87)
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              m['name'] as String,
                                              style: TextStyle(
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              m['role'] as String,
                                              style: TextStyle(
                                                color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          m['status'] as String,
                                          style: TextStyle(
                                            color: m['color'] as Color,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(color: m['color'] as Color, shape: BoxShape.circle),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // Add Member Trigger Button
                          GestureDetector(
                            onTap: _showAddMemberDialog,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF2F80FF), width: 1.5),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Add New Member +',
                                style: TextStyle(color: Color(0xFF2F80FF), fontSize: 14, fontWeight: FontWeight.w700),
                              ),
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