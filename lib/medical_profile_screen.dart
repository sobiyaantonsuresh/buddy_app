import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only DEMO data. Do not use for actual emergency decisions.
class BuddyMedicalProfileScreen extends StatefulWidget {
  final String memberName;
  final bool isDarkMode;

  const BuddyMedicalProfileScreen({
    super.key,
    required this.memberName,
    required this.isDarkMode,
  });

  @override
  State<BuddyMedicalProfileScreen> createState() =>
      _BuddyMedicalProfileScreenState();
}

class _BuddyMedicalProfileScreenState extends State<BuddyMedicalProfileScreen> {
  static const fields = <String, String>{
    'Blood group': 'Not recorded',
    'Allergies': 'Not recorded',
    'Medical conditions': 'Not recorded',
    'Current medications': 'Not recorded',
    'Medication reminders': 'Not scheduled',
    'Emergency contact': 'Not recorded',
    'Additional notes': 'Demo profile — no clinical records',
  };

  late final Map<String, TextEditingController> _controllers = {
    for (final entry in fields.entries)
      entry.key: TextEditingController(text: entry.value),
  };

  bool _loading = true;
  bool _saving = false;

  String _key(String field) =>
      'buddy_demo_medical_v1_${Uri.encodeComponent(widget.memberName.trim().toLowerCase())}_${Uri.encodeComponent(field)}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final field in fields.keys) {
        _controllers[field]!.text =
            prefs.getString(_key(field)) ?? fields[field]!;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Local cache unavailable: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in _controllers.entries) {
        final ok = await prefs.setString(
          _key(entry.key),
          entry.value.text.trim(),
        );
        if (!ok) throw StateError('Could not cache ${entry.key}');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to this device’s local cache')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save locally: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final bg = dark ? const Color(0xFF0B132B) : const Color(0xFFF5F0E5);
    final surface = dark ? const Color(0xFF162033) : Colors.white;
    final text = dark ? Colors.white : const Color(0xFF173630);
    final accent = dark ? const Color(0xFF2F80FF) : const Color(0xFF173F37);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Medical Profile'),
        backgroundColor: surface,
        foregroundColor: text,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.memberName,
                  style: TextStyle(
                    color: text,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE9BE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'DEMO ONLY — not verified medical information. '
                    'Stored in this browser/device cache only. '
                    'Not suitable for emergencies or medical decisions.',
                    style: TextStyle(color: Color(0xFF694500)),
                  ),
                ),
                const SizedBox(height: 16),
                for (final entry in _controllers.entries) ...[
                  TextField(
                    controller: entry.value,
                    minLines: 1,
                    maxLines: entry.key == 'Additional notes' ? 3 : 2,
                    style: TextStyle(color: text),
                    decoration: InputDecoration(
                      labelText: entry.key,
                      labelStyle: TextStyle(color: text.withValues(alpha: .75)),
                      filled: true,
                      fillColor: surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving...' : 'Save on this device'),
                ),
              ],
            ),
    );
  }
}
