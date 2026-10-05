import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ScreenHousehold extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  final String? initialImageBase64;

  const ScreenHousehold({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
    this.initialImageBase64,
  });

  @override
  State<ScreenHousehold> createState() => _ScreenHouseholdState();
}

class _ScreenHouseholdState extends State<ScreenHousehold> {
  static const String _baseUrl = kIsWeb ? "http://localhost:5000" : "http://192.168.8.192:5000";

  List<Map<String, dynamic>> _members = [
    {"name": "Sobiya", "role": "Owner", "status": "RECOGNIZED"},
    {"name": "Rayan", "role": "Member", "status": "RECOGNIZED"},
    {"name": "Zara", "role": "Guest", "status": "UNREGISTERED"},
  ];

  @override
  void initState() {
    super.initState();
    _fetchHouseholdMembers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.initialImageBase64 != null && widget.initialImageBase64!.isNotEmpty) {
        _openEnrollDialog(widget.initialImageBase64);
      }
    });
  }

  Future<void> _fetchHouseholdMembers() async {
    if (!mounted) return;
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/api/household_members'))
          .timeout(const Duration(seconds: 2));

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        if (mounted) {
          final updated = data.map((e) => Map<String, dynamic>.from(e)).toList();
          if (jsonEncode(_members) != jsonEncode(updated)) {
            setState(() {
              _members = updated;
            });
          }
        }
      }
    } catch (_) {}
  }

  Uint8List? _decodeSafeBase64(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      String clean = raw.trim();
      if (clean.contains(',')) clean = clean.split(',').last;
      clean = clean.replaceAll('\n', '').replaceAll('\r', '').replaceAll(' ', '');
      return base64Decode(clean);
    } catch (_) {
      return null;
    }
  }

  void _openEnrollDialog([String? autoImageBase64]) {
    final nameController = TextEditingController();
    String selectedRole = "Member (Full Recognition)";
    final String? currentImage = autoImageBase64 ?? widget.initialImageBase64;
    final Uint8List? imageBytes = _decodeSafeBase64(currentImage);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF162033),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Enroll New Companion",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2F80FF), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              imageBytes,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.face_retouching_natural_rounded, color: Color(0xFF2F80FF), size: 48),
                              SizedBox(height: 8),
                              Text("Snapshot will appear upon detection", style: TextStyle(color: Colors.white54, fontSize: 13)),
                            ],
                          ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Full Name",
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.person, color: Color(0xFF2F80FF)),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Household Permission Role",
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.security, color: Color(0xFF2F80FF)),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: const [
                      DropdownMenuItem(value: "Member (Full Recognition)", child: Text("Member (Full Recognition)")),
                      DropdownMenuItem(value: "Guest (Temporary Access)", child: Text("Guest (Temporary Access)")),
                    ],
                    onChanged: (val) => setModalState(() => selectedRole = val!),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F80FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final enteredName = nameController.text.trim();
                        if (enteredName.isNotEmpty) {
                          Navigator.pop(ctx);
                          await _registerPerson(enteredName, currentImage ?? "");
                          _fetchHouseholdMembers();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("$enteredName registered successfully!"),
                                backgroundColor: const Color(0xFF27AE60),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text("SAVE & REGISTER FACE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _registerPerson(String name, String imageBase64) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/enroll_unknown_person'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"name": name, "image": imageBase64}),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Household Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text("Manage recognized family and permissions", style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF162033),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1F2937)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFF2F80FF),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text("Sobiya", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF2F80FF), borderRadius: BorderRadius.circular(4)),
                            child: const Text("OWNER", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text("Connected since Jan 2026", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "HOUSEHOLD MEMBERS",
              style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView.separated(
                itemCount: _members.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final member = _members[index];
                  final isRecognized = member['status'] == 'RECOGNIZED';
                  final String? memberImg = member['image'];
                  final Uint8List? memberBytes = _decodeSafeBase64(memberImg);

                  return GestureDetector(
                    onTap: () {
                      if (!isRecognized) {
                        _openEnrollDialog(memberImg);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF162033),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isRecognized ? const Color(0xFF1F2937) : Colors.orangeAccent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              memberBytes != null
                                  ? ClipOval(
                                      child: Image.memory(
                                        memberBytes,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : CircleAvatar(
                                      radius: 20,
                                      backgroundColor: isRecognized
                                          ? const Color(0xFF2F80FF).withValues(alpha: 0.2)
                                          : Colors.orangeAccent.withValues(alpha: 0.2),
                                      child: Icon(
                                        isRecognized ? Icons.person_outline : Icons.person_search_rounded,
                                        color: isRecognized ? const Color(0xFF2F80FF) : Colors.orangeAccent,
                                      ),
                                    ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member['name'] ?? '',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  Text(
                                    member['role'] ?? '',
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                member['status'] ?? '',
                                style: TextStyle(
                                  color: isRecognized ? const Color(0xFF27AE60) : Colors.orangeAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.circle,
                                size: 6,
                                color: isRecognized ? const Color(0xFF27AE60) : Colors.orangeAccent,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2F80FF), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _openEnrollDialog(),
                  child: const Text("Add New Member +", style: TextStyle(color: Color(0xFF2F80FF), fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}