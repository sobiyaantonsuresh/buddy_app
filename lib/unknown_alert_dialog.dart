import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UnknownAlertService {
  static const String baseUrl = kIsWeb ? "http://localhost:5000" : "http://192.168.8.192:5000";
  static bool _isDialogOpen = false;

  static void startListening(BuildContext context) {
    _isDialogOpen = false;
  }

  static void stopListening() {
    _isDialogOpen = false;
  }

  static Uint8List? safeDecodeBase64(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      String clean = raw.trim();
      if (clean.contains(',')) {
        clean = clean.split(',').last;
      }
      clean = clean.replaceAll('\n', '').replaceAll('\r', '').replaceAll(' ', '');
      return base64Decode(clean);
    } catch (_) {
      return null;
    }
  }

  static void showEnrollDialog(BuildContext context, String base64Image, String timestamp, {VoidCallback? onSuccess}) {
    if (_isDialogOpen) return;
    _isDialogOpen = true;

    final TextEditingController nameController = TextEditingController();
    final Uint8List? imageBytes = safeDecodeBase64(base64Image);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.person_add_rounded, color: Color(0xFF2F80FF), size: 26),
              SizedBox(width: 8),
              Text(
                "Verify & Enroll Person",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Detected at: $timestamp",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 180,
                    width: 320,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    child: imageBytes != null
                        ? Image.memory(
                            imageBytes,
                            width: 320,
                            height: 180,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.broken_image, color: Colors.white54, size: 40),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      hintText: "Enter name to enroll",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                _isDialogOpen = false;
                Navigator.of(ctx).pop();
                await clearAlertOnBackend();
                if (onSuccess != null) onSuccess();
              },
              child: const Text("Dismiss", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F80FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final enteredName = nameController.text.trim();
                if (enteredName.isNotEmpty) {
                  await sendEnrollment(enteredName, base64Image);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$enteredName enrolled successfully!'),
                        backgroundColor: const Color(0xFF27AE60),
                      ),
                    );
                  }
                  if (onSuccess != null) onSuccess();
                }
                _isDialogOpen = false;
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text("Confirm & Add"),
            ),
          ],
        );
      },
    ).then((_) {
      _isDialogOpen = false;
    });
  }

  static Future<void> sendEnrollment(String name, String base64Image) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/enroll_unknown_person'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "image": base64Image,
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  static Future<void> clearAlertOnBackend() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/clear_unknown_alert'),
      ).timeout(const Duration(seconds: 2));
    } catch (_) {}
  }
}