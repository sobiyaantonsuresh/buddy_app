import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'camera_web_platform.dart' as camera_web_platform;

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
  // Chrome and Flask run on the same computer. Change the mobile address
  // only if you later test from an actual phone on the same trusted LAN.
  static const String _baseUrl =
      kIsWeb ? 'http://localhost:5000' : 'http://192.168.8.192:5000';

  static const String _householdViewType = 'buddy-household-shared-camera';

  List<Map<String, dynamic>> _members = [];
  bool _loading = false;
  String? _loadError;

  Color get _background => widget.isDarkMode
      ? const Color(0xFF0B132B) : const Color(0xFFF5F0E5);
  Color get _surface => widget.isDarkMode
      ? const Color(0xFF162033) : const Color(0xFFFFFDF8);
  Color get _inputSurface => widget.isDarkMode
      ? const Color(0xFF0F172A) : Colors.white;
  Color get _foreground => widget.isDarkMode
      ? Colors.white : const Color(0xFF173630);
  Color get _muted => widget.isDarkMode
      ? Colors.white60 : const Color(0xFF5A7069);
  Color get _accent => widget.isDarkMode
      ? const Color(0xFF2F80FF) : const Color(0xFF173F37);
  Color get _outline => widget.isDarkMode
      ? const Color(0xFF293549) : const Color(0xFFD3E2D8);

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      camera_web_platform.registerViewFactory(
        _householdViewType, '$_baseUrl/video_call',
      );
    }
    _fetchHouseholdMembers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final image = widget.initialImageBase64;
      if (image != null && image.isNotEmpty) _openEnrollDialog(image);
    });
  }

  Future<void> _fetchHouseholdMembers() async {
    if (!mounted) return;
    setState(() { _loading = true; _loadError = null; });
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/household_members'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        throw Exception(_apiMessage(res, 'Unable to load household members'));
      }
      final decoded = jsonDecode(res.body);
      if (decoded is! List) throw const FormatException('Unexpected household response');
      final updated = decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      if (mounted) setState(() => _members = updated);
    } catch (e) {
      if (mounted) setState(() => _loadError = _cleanError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _cleanError(Object error) {
    final raw = error.toString();
    return raw.startsWith('Exception: ') ? raw.substring(11) : raw;
  }

  String _apiMessage(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        for (final key in ['error', 'message', 'detail']) {
          final value = body[key];
          if (value is String && value.trim().isNotEmpty) return value.trim();
        }
      }
    } catch (_) {}
    return '$fallback (HTTP ${response.statusCode})';
  }

  Uint8List? _decodeSafeBase64(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      String clean = raw.trim();
      if (clean.contains(',')) clean = clean.split(',').last;
      clean = clean.replaceAll(RegExp(r'\s'), '');
      return base64Decode(clean);
    } catch (_) { return null; }
  }

  Future<Map<String, dynamic>> _registerPerson(String name) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/enroll_unknown_person'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'subject_consent': true}),
    ).timeout(const Duration(seconds: 45)); // Multi-frame embedding takes time.
    dynamic body;
    try { body = jsonDecode(res.body); } catch (_) {}
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(_apiMessage(res, 'Face registration failed'));
    }
    if (body is! Map || body['success'] != true || body['person_id'] == null) {
      throw const FormatException('Backend did not confirm registration');
    }
    return Map<String, dynamic>.from(body);
  }

  void _showMessage(String message, {required bool success}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: success ? const Color(0xFF278657) : const Color(0xFFB8433F),
    ));
  }

  void _openEnrollDialog([String? autoImageBase64]) {
    String enteredName = '';
    String selectedRole = 'Member (Full Recognition)';
    // Snapshot is a preview only; backend enrolls from its existing camera.
    final imageBytes = _decodeSafeBase64(autoImageBase64 ?? widget.initialImageBase64);
    bool subjectConsented = false;
    bool saving = false;
    String? error;
    final bg = _surface, textColor = _foreground, muted = _muted;
    final fieldColor = _inputSurface, accent = _accent, border = _outline;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, updateSheet) => SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text('Enroll New Companion',
                    style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold))),
                  IconButton(
                    icon: Icon(Icons.close, color: muted),
                    onPressed: saving ? null : () => Navigator.pop(sheetContext),
                  ),
                ]),
                const SizedBox(height: 12),
                Container(
                  height: 150, width: double.infinity,
                  decoration: BoxDecoration(color: fieldColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border)),
                  clipBehavior: Clip.antiAlias,
                  child: imageBytes != null
                    ? Image.memory(imageBytes, fit: BoxFit.cover)
                    : kIsWeb
                        ? const HtmlElementView(viewType: _householdViewType)
                        : Image.network(
                            '$_baseUrl/video_call',
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            errorBuilder: (_, error, stackTrace) => Center(
                              child: Text('Camera preview unavailable. Check Flask.',
                                  style: TextStyle(color: muted, fontSize: 12)),
                            ),
                          ),
                ),
                const SizedBox(height: 12),
                Text('Live preview from the shared BUDDY camera. Only the new member should face the camera. Keep their face visible and slowly turn their head for several seconds.',
                  style: TextStyle(color: muted, fontSize: 12)),
                const SizedBox(height: 14),
                TextFormField(
                  onChanged: (value) => enteredName = value,
                  enabled: !saving,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Full Name', labelStyle: TextStyle(color: muted),
                    prefixIcon: Icon(Icons.person, color: accent),
                    filled: true, fillColor: fieldColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  dropdownColor: bg,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Household Permission Role',
                    labelStyle: TextStyle(color: muted),
                    prefixIcon: Icon(Icons.security, color: accent),
                    filled: true, fillColor: fieldColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Member (Full Recognition)', child: Text('Member (Full Recognition)')),
                    DropdownMenuItem(value: 'Guest (Temporary Access)', child: Text('Guest (Temporary Access)')),
                  ],
                  onChanged: saving ? null : (val) {
                    if (val != null) updateSheet(() => selectedRole = val);
                  },
                ),
                const SizedBox(height: 6),
                Text('Role selection is for display only; this API does not yet save permission roles.',
                    style: TextStyle(color: muted, fontSize: 11)),
                const SizedBox(height: 10),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: accent,
                  value: subjectConsented,
                  onChanged: saving ? null : (val) => updateSheet(() => subjectConsented = val ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text('The person being enrolled has agreed',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text('I have asked this person directly, and they agree to BUDDY storing their facial templates for recognition.',
                    style: TextStyle(color: muted, fontSize: 12)),
                ),
                if (error != null) Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(error!, style: const TextStyle(color: Color(0xFFDC594B), fontSize: 13)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: saving ? null : () async {
                      final name = enteredName.trim();
                      if (name.length < 2) {
                        updateSheet(() => error = 'Enter a name of at least two characters.');
                        return;
                      }
                      if (!subjectConsented) {
                        updateSheet(() => error = 'Please obtain and confirm the person’s consent first.');
                        return;
                      }
                      updateSheet(() { saving = true; error = null; });
                      bool completed = false;
                      try {
                        final result = await _registerPerson(name);
                        if (!sheetContext.mounted) return;
                        completed = true;
                        Navigator.pop(sheetContext);
                        _showMessage('${result['name'] ?? name} registered successfully (${result['templates'] ?? '?'} templates).',
                          success: true);
                        await _fetchHouseholdMembers();
                      } catch (e) {
                        if (sheetContext.mounted) updateSheet(() => error = _cleanError(e));
                      } finally {
                        if (!completed && sheetContext.mounted) {
                          updateSheet(() => saving = false);
                        }
                      }
                    },
                    child: saving
                      ? const SizedBox(height: 22, width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('SAVE & REGISTER FACE',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _foreground, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Household Profile',
          style: TextStyle(color: _foreground, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          Text('Manage recognized family and permissions',
            style: TextStyle(color: _muted, fontSize: 13)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Text('HOUSEHOLD MEMBERS', style: TextStyle(
              color: _muted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8))),
            IconButton(onPressed: _loading ? null : _fetchHouseholdMembers,
              tooltip: 'Refresh household members',
              icon: Icon(Icons.refresh, color: _accent)),
          ]),
          const SizedBox(height: 10),
          if (_loadError != null) Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Could not refresh members: $_loadError',
              style: const TextStyle(color: Color(0xFFDC594B), fontSize: 12)),
          ),
          Expanded(child: _loading && _members.isEmpty
            ? Center(child: CircularProgressIndicator(color: _accent))
            : _members.isEmpty
              ? Center(child: Text(
                  _loadError == null ? 'No household members registered yet.' : 'Please check the BUDDY API and tap refresh.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, fontSize: 13)))
              : ListView.separated(
                  itemCount: _members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    final isRecognized = member['status'] == 'RECOGNIZED';
                    final memberBytes = _decodeSafeBase64(member['image'] as String?);
                    final label = (member['name'] ?? 'Unknown').toString();
                    return GestureDetector(
                      onTap: isRecognized ? null : () => _openEnrollDialog(member['image'] as String?),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _surface, borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isRecognized ? _outline : Colors.orangeAccent),
                        ),
                        child: Row(children: [
                          if (memberBytes != null)
                            ClipOval(child: Image.memory(memberBytes, width: 40, height: 40, fit: BoxFit.cover))
                          else
                            CircleAvatar(radius: 20,
                              backgroundColor: _accent.withValues(alpha: 0.12),
                              child: Icon(isRecognized ? Icons.person_outline : Icons.person_search_rounded,
                                color: isRecognized ? _accent : Colors.orangeAccent)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(label, style: TextStyle(color: _foreground,
                              fontWeight: FontWeight.w600, fontSize: 14)),
                            Text((member['role'] ?? '').toString(),
                              style: TextStyle(color: _muted, fontSize: 12)),
                            if (member['templates'] != null)
                              Text('${member['templates']} face templates',
                                style: TextStyle(color: _muted, fontSize: 11)),
                          ])),
                          const SizedBox(width: 8),
                          Text((member['status'] ?? '').toString(),
                            style: TextStyle(color: isRecognized
                              ? const Color(0xFF278657) : Colors.orangeAccent,
                              fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Icon(Icons.circle, size: 6,
                            color: isRecognized ? const Color(0xFF278657) : Colors.orangeAccent),
                        ]),
                      ),
                    );
                  },
                )),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SizedBox(width: double.infinity, height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _accent, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () => _openEnrollDialog(),
                child: Text('Add New Member +', style: TextStyle(
                  color: _accent, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
