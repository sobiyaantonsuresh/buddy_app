import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Read-only tester for currently available BUDDY Flask endpoints.
/// Does not send motor commands or enroll faces.
class ScreenVisionDiagnostics extends StatefulWidget {
  const ScreenVisionDiagnostics({super.key});

  @override
  State<ScreenVisionDiagnostics> createState() => _ScreenVisionDiagnosticsState();
}

class _ScreenVisionDiagnosticsState extends State<ScreenVisionDiagnostics> {
  static const api = 'http://10.138.45.237:5000';
  static const sections = <String>['Overview', 'People', 'Objects', 'Expressions', 'Pose', 'Gestures'];
  String section = 'Overview';
  Map<String, dynamic>? vision;
  List<dynamic>? taught;
  String? error;
  bool loading = false;
  bool automatic = false;
  Timer? ticker;
  DateTime? lastUpdated;
  String? identification;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    if (loading) return;
    setState(() => loading = true);
    try {
      final response = await http.get(Uri.parse('$api/api/vision/status')).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) throw Exception('Vision API HTTP ${response.statusCode}');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      List<dynamic>? objects;
      try {
        final r = await http.get(Uri.parse('$api/api/objects')).timeout(const Duration(seconds: 4));
        if (r.statusCode == 200) objects = jsonDecode(r.body) as List<dynamic>;
      } catch (_) { /* Learning list is optional. */ }
      if (mounted) setState(() { vision = data; taught = objects; error = null; lastUpdated = DateTime.now(); });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void setAuto(bool enabled) {
    ticker?.cancel();
    setState(() => automatic = enabled);
    if (enabled) ticker = Timer.periodic(const Duration(seconds: 3), (_) => refresh());
  }

  Future<void> identify() async {
    setState(() => identification = 'Identifying current camera frame…');
    try {
      final response = await http.post(Uri.parse('$api/api/objects/identify')).timeout(const Duration(seconds: 20));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (mounted) setState(() => identification = (data['text'] ?? data['error'] ?? response.body).toString());
    } catch (e) {
      if (mounted) setState(() => identification = 'Identification unavailable: $e');
    }
  }

  Widget panel(String title, Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFF10283F), border: Border.all(color: const Color(0xFF244563)), borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 10), child,
    ]),
  );
  Widget line(String label, Object? value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: Colors.white70))),
      Flexible(child: Text('${value ?? "Unavailable"}', textAlign: TextAlign.end, style: const TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.w600)))]),
  );
  Widget note(String text) => Text(text, style: const TextStyle(color: Colors.white70, height: 1.5));
  List<dynamic> get people => vision?['people'] is List ? vision!['people'] as List : [];
  List<dynamic> get objects => vision?['objects'] is List ? vision!['objects'] as List : [];
  Map<String, dynamic> get diagnostics => vision?['vision_diagnostics'] is Map ? Map<String, dynamic>.from(vision!['vision_diagnostics'] as Map) : {};

  Widget content() {
    if (vision == null) return note(error ?? 'Waiting for the first vision update…');
    switch (section) {
      case 'People':
        return panel('Face detection & recognition', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          line('Faces detected', people.length),
          if (people.isEmpty) note('No face in the latest processed frame.'),
          for (final p in people)
            if (p is Map) ...[
              const Divider(color: Colors.white24),
              line('Person', p['name'] ?? 'Unknown'),
              line('Identity state', p['identity_state']),
              line('Recognized', p['recognized']),
              line('Facial expression', p['expression'] ?? 'Not available'),
            ],
        ]));
      case 'Objects':
        return Column(children: [
          panel('Current object detections', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            line('Detected objects', objects.length),
            for (final o in objects) if (o is Map) line((o['name'] ?? o['label'] ?? 'Unknown').toString(), 'Score: ${o['score'] ?? 'N/A'}'),
            if (objects.isEmpty) note('No object in the latest processed frame.'),
          ])),
          panel('Previously taught objects', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final o in taught ?? []) if (o is Map) line('${o['name']}', '${o['samples']} samples'),
            if (taught == null) note('Object list unavailable.'),
            const SizedBox(height: 10),
            FilledButton.icon(onPressed: identify, icon: const Icon(Icons.search), label: const Text('Identify object in frame')),
            if (identification != null) Padding(padding: const EdgeInsets.only(top: 12), child: note(identification!)),
          ])),
        ]);
      case 'Expressions':
        return panel('Facial expression testing', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          line('Expression service frames', diagnostics['expression_service_frames'] ?? 0),
          for (final p in people) if (p is Map) line('${p['name'] ?? 'Unknown'}', p['expression'] ?? 'No expression result'),
          note('The expression stage may execute without producing a classification. Results are shown only when the API reports them.'),
        ]));
      case 'Pose':
        return panel('Body pose / posture processing', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          line('Pose stage ran', (diagnostics['stages_run'] is List && (diagnostics['stages_run'] as List).contains('pose')) ? 'Yes' : 'Not in latest frame'),
          line('Pose timing (ms)', (diagnostics['timings_ms'] is Map) ? (diagnostics['timings_ms'] as Map)['pose'] : null),
          note('Standing, sitting and body keypoints are not currently exposed by /api/vision/status. This screen cannot truthfully classify them until a dedicated endpoint is added.'),
        ]));
      case 'Gestures':
        return panel('Hand gesture recognition', note('Not connected yet. No verified hand-gesture classification endpoint is available in the currently inspected Flask API. This is a placeholder for the future gesture model — no invented detections.'));
      default:
        return Column(children: [
          panel('BUDDY live system', Column(children: [
            line('Camera', vision!['camera_connected'] == true ? 'Connected' : 'Offline'),
            line('Vision', vision!['vision_ready'] == true ? 'Ready' : 'Not ready'),
            line('Faces visible', people.length),
            line('Objects visible', objects.length),
            line('Learned objects', taught?.length ?? 'Unavailable'),
            line('Last update', lastUpdated?.toLocal().toString().split('.').first),
          ])),
          panel('Last processing stages', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            note((diagnostics['stages_run'] as List?)?.join('  •  ') ?? 'No diagnostics available'),
            if (diagnostics['timings_ms'] is Map)
              for (final e in (diagnostics['timings_ms'] as Map).entries) line('${e.key} (ms)', e.value is num ? (e.value as num).toStringAsFixed(1) : e.value),
          ])),
        ]);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF071728),
    appBar: AppBar(backgroundColor: const Color(0xFF071728), foregroundColor: Colors.white,
      title: const Text('BUDDY • AI Testing')),
    body: SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        Expanded(child: note('Live Raspberry Pi vision diagnostics')),
        const Text('Auto', style: TextStyle(color: Colors.white70)),
        Switch(value: automatic, onChanged: setAuto),
        IconButton(onPressed: loading ? null : refresh, color: Colors.lightBlueAccent, icon: const Icon(Icons.refresh)),
      ])),
      SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
        for (final s in sections)
          Padding(padding: const EdgeInsets.only(right: 7), child: ChoiceChip(label: Text(s), selected: section == s,
            onSelected: (_) => setState(() => section = s),
            selectedColor: const Color(0xFF137EE8), labelStyle: TextStyle(color: section == s ? Colors.white : Colors.black87))),
      ])),
      if (error != null) Padding(padding: const EdgeInsets.all(10), child: Text('Connection issue: $error', style: const TextStyle(color: Colors.orangeAccent))),
      Expanded(child: ListView(padding: const EdgeInsets.all(14), children: [content()])),
    ])),
  );
}
