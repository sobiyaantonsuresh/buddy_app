import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UnknownAlertService {
  static const String baseUrl = "http://10.242.169.228:5000";
  static Timer? _timer;
  static bool _isDialogOpen = false;

  static void startListening(BuildContext context) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isDialogOpen) return;

      try {
        final response = await http.get(
          Uri.parse('$baseUrl/api/get_unknown_alert'),
        ).timeout(const Duration(seconds: 2));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['status'] == 'alert' && data['image'] != null) {
            _isDialogOpen = true;
            if (context.mounted) {
              _showEnrollDialog(
                context,
                data['image'],
                data['time'] ?? 'Just now',
              );
            }
          }
        }
      } catch (e) {
        // Handle network drops silently
      }
    });
  }

  static void stopListening() {
    _timer?.cancel();
    _isDialogOpen = false;
  }

  static void _showEnrollDialog(BuildContext context, String base64Image, String timestamp) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text("Unknown Face Alert", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Detected at: $timestamp",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    base64Decode(base64Image),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: Colors.grey.shade900,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image, color: Colors.white54, size: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Person's Name",
                    hintText: "Enter name to enroll",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.person_add),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                _isDialogOpen = false;
                Navigator.of(ctx).pop();
                await _clearAlertOnBackend();
              },
              child: const Text("Dismiss", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final enteredName = nameController.text.trim();
                if (enteredName.isNotEmpty) {
                  await _sendEnrollment(enteredName, base64Image);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$enteredName successfully registered!'),
                        backgroundColor: const Color(0xFF27AE60),
                      ),
                    );
                  }
                }
                _isDialogOpen = false;
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text("Add Person"),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _sendEnrollment(String name, String base64Image) async {
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

  static Future<void> _clearAlertOnBackend() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/clear_unknown_alert'),
      ).timeout(const Duration(seconds: 2));
    } catch (_) {}
  }
}