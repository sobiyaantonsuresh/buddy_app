import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UnknownAlertService {
  static const String baseUrl = kIsWeb
      ? 'http://localhost:5000' : 'http://192.168.8.192:5000';
  static bool _isDialogOpen = false;

  static void startListening(BuildContext context) { /* UI invokes dialog explicitly. */ }
  static void stopListening() { _isDialogOpen = false; }

  static Uint8List? safeDecodeBase64(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final clean = raw.split(',').last.replaceAll(RegExp(r'\s'), '');
      return base64Decode(clean);
    } catch (_) { return null; }
  }

  static void showEnrollDialog(BuildContext context, String base64Image,
      String timestamp, {VoidCallback? onSuccess}) {
    if (_isDialogOpen) return;
    _isDialogOpen = true;
    String name = '';
    bool consent = false;
    bool loading = false;
    String? error;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, refresh) => AlertDialog(
          title: const Text('Verify & Enroll Person'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Detected: $timestamp'),
              const SizedBox(height: 8),
              const Text('Registration uses the live camera. Only the consenting '
                  'person should be in view.'),
              TextField(
                enabled: !loading,
                onChanged: (value) => name = value.trim(),
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              CheckboxListTile(
                value: consent,
                onChanged: loading ? null : (value) => refresh(() {
                  consent = value == true;
                }),
                title: const Text('The person has agreed to BUDDY storing '
                    'their facial templates.'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (error != null) Text(error!,
                style: const TextStyle(color: Colors.red)),
            ]),
          ),
          actions: [
            TextButton(onPressed: loading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Dismiss')),
            ElevatedButton(
              onPressed: loading ? null : () async {
                if (name.length < 2 || !consent) {
                  refresh(() => error = 'Enter a name and confirm subject consent.');
                  return;
                }
                refresh(() { loading = true; error = null; });
                try {
                  await sendEnrollment(name, base64Image, subjectConsent: consent);
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$name registered successfully.')),
                    );
                    onSuccess?.call();
                  }
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  refresh(() {
                    loading = false;
                    error = e.toString().replaceFirst('Exception: ', '');
                  });
                }
              },
              child: Text(loading ? 'Registering...' : 'Confirm & Add'),
            ),
          ],
        ),
      ),
    ).whenComplete(() => _isDialogOpen = false);
  }

  static Future<void> sendEnrollment(String name, String base64Image,
      {bool subjectConsent = false}) async {
    if (!subjectConsent) throw Exception('Subject consent is required');
    final res = await http.post(
      Uri.parse('$baseUrl/api/enroll_unknown_person'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'subject_consent': true}),
    ).timeout(const Duration(seconds: 45));
    dynamic json;
    try { json = jsonDecode(res.body); } catch (_) {}
    if ((res.statusCode != 200 && res.statusCode != 201) ||
        json is! Map || json['success'] != true || json['person_id'] == null) {
      throw Exception(json is Map && json['error'] != null
          ? json['error'] : 'Enrollment failed (HTTP ${res.statusCode})');
    }
  }

  static Future<void> clearAlertOnBackend() async {
    final res = await http.post(Uri.parse('$baseUrl/api/clear_unknown_alert'))
      .timeout(const Duration(seconds: 5));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Unable to clear alert (HTTP ${res.statusCode})');
    }
  }
}
