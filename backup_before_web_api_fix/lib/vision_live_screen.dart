import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'camera_web_platform.dart' as camera_web_platform;

const _api = 'http://10.138.45.237:5000';
const _bg = Color(0xFF061322);
const _panel = Color(0xFF10263B);
const _accent = Color(0xFF13A4F7);

enum BuddyVisionMode { people, objects, expressions, posture, gestures }

extension BuddyVisionLabel on BuddyVisionMode {
  String get title => switch(this) {
    BuddyVisionMode.people => 'People Recognition',
    BuddyVisionMode.objects => 'Object Detection',
    BuddyVisionMode.expressions => 'Facial Expressions',
    BuddyVisionMode.posture => 'Posture & Fall Detection',
    BuddyVisionMode.gestures => 'Hand Gestures',
  };
  IconData get icon => switch(this) {
    BuddyVisionMode.people => Icons.face_retouching_natural,
    BuddyVisionMode.objects => Icons.category_outlined,
    BuddyVisionMode.expressions => Icons.sentiment_satisfied_alt,
    BuddyVisionMode.posture => Icons.accessibility_new,
    BuddyVisionMode.gestures => Icons.pan_tool_alt_outlined,
  };
}

class BuddyLiveVisionScreen extends StatefulWidget {
  final BuddyVisionMode mode;
  const BuddyLiveVisionScreen({super.key, required this.mode});
  @override
  State<BuddyLiveVisionScreen> createState() => _BuddyLiveVisionScreenState();
}

class _BuddyLiveVisionScreenState extends State<BuddyLiveVisionScreen> {
  Timer? _poll;
  Map<String, dynamic>? _status;
  String? _error;
  String? _identifyResult;
  DateTime? _updated;
  bool _busy = false;
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'buddy-vision-${widget.mode.name}-${DateTime.now().microsecondsSinceEpoch}';
    if (kIsWeb) camera_web_platform.registerViewFactory(_viewType, '$_api/video_call');
    _fetch();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _fetch());
  }

  @override
  void dispose() { _poll?.cancel(); super.dispose(); }

  Future<void> _fetch() async {
    if (_busy) return;
    _busy = true;
    try {
      final res = await http.get(Uri.parse('$_api/api/vision/status'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      if (mounted) setState(() { _status = decoded; _error = null; _updated = DateTime.now(); });
    } catch (e) {
      if (mounted) setState(() { _error = 'Live diagnostics unavailable: $e'; });
    } finally { _busy = false; }
  }

  Future<void> _identify() async {
    setState(() => _identifyResult = 'Checking the current camera frame...');
    try {
      final res = await http.post(Uri.parse('$_api/api/objects/identify'))
          .timeout(const Duration(seconds: 25));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (mounted) setState(() => _identifyResult = '${body['text'] ?? body['error'] ?? 'No result'}');
    } catch (e) {
      if (mounted) setState(() => _identifyResult = 'Identification unavailable: $e');
    }
  }

  List<Map<String, dynamic>> get _faces => ((_status?['people'] as List?) ?? [])
      .whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  List<Map<String, dynamic>> get _objects => ((_status?['objects'] as List?) ?? [])
      .whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  Map<String, dynamic> get _diag => _status?['vision_diagnostics'] is Map
      ? Map<String, dynamic>.from(_status!['vision_diagnostics'] as Map) : {};
  bool get _poseRan => ((_diag['stages_run'] as List?) ?? []).contains('pose');

  Widget _card(String title, Widget child) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF26435B))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
      const SizedBox(height: 9), child,
    ]),
  );

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))),
      Flexible(child: Text(value, textAlign: TextAlign.end,
        style: const TextStyle(color: Color(0xFF79D8FF), fontWeight: FontWeight.w700, fontSize: 12))),
    ]),
  );

  String _asText(Object? v, [String fallback = 'Unavailable']) => v == null ? fallback : '$v';

  Widget _details() {
    switch (widget.mode) {
      case BuddyVisionMode.people:
        return _card('FACE RECOGNITION', Column(children: [
          _line('Detected faces', '${_faces.length}'),
          for (final p in _faces) ...[
            _line('Identity', _asText(p['name'], 'Unknown')),
            _line('Recognition', _asText(p['identity_state'])),
            _line('Verified', '${p['recognized'] == true}'),
          ],
          if (_faces.isEmpty) _line('Tracking', 'No faces in latest frame'),
        ]));
      case BuddyVisionMode.objects:
        return Column(children: [
          _card('LIVE OBJECTS', Column(children: [
            _line('Detected', '${_objects.length}'),
            for (final o in _objects)
              _line(_asText(o['name'] ?? o['label'], 'Unknown'),
                o['score'] is num ? '${((o['score'] as num) * 100).toStringAsFixed(0)}% detection score' : 'Detected'),
            if (_objects.isEmpty) _line('Tracking', 'No objects in latest frame'),
          ])),
          _card('LEARNED OBJECT TEST', Column(children: [
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: _identify, icon: const Icon(Icons.search), label: const Text('Identify held object'))),
            if (_identifyResult != null) Padding(padding: const EdgeInsets.only(top: 10),
              child: Text(_identifyResult!, style: const TextStyle(color: Colors.white70))),
          ])),
        ]);
      case BuddyVisionMode.expressions:
        return _card('EXPRESSION ANALYSIS', Column(children: [
          _line('Frames classified', _asText(_diag['expression_service_frames'], '0')),
          for (final p in _faces)
            _line(_asText(p['name'], 'Face'), _asText(p['expression'], 'Not classified')),
          if (_faces.isEmpty) _line('Expression', 'No face currently detected'),
          const Text('Expressions appear only when the Pi vision API returns a result.',
            style: TextStyle(color: Colors.white54, fontSize: 11)),
        ]));
      case BuddyVisionMode.posture:
        return _card('POSTURE & FALL MONITOR', Column(children: [
          _line('Pose processing', _poseRan ? 'Active in latest frame' : 'No recent pose result'),
          _line('Pose processing time', _asText((_diag['timings_ms'] as Map?)?['pose'])),
          _line('Posture', 'Not exposed by current API'),
          _line('Fall status', 'Not exposed by current API'),
          const Padding(padding: EdgeInsets.only(top: 9), child: Text(
            'The Windows fall demo can draw body joints. This Raspberry Pi endpoint does not yet expose joint coordinates or posture/fall classifications. No simulated skeleton is drawn.',
            style: TextStyle(color: Colors.amberAccent, fontSize: 11, height: 1.5))),
        ]));
      case BuddyVisionMode.gestures:
        return _card('HAND GESTURE TEST', const Text(
          'Live video is available. Hand landmarks and gesture labels require a verified hand-tracking endpoint on the Raspberry Pi. No fake landmarks or classifications are displayed.',
          style: TextStyle(color: Colors.amberAccent, height: 1.5, fontSize: 12)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    appBar: AppBar(backgroundColor: _bg, foregroundColor: Colors.white,
      title: Text(widget.mode.title), actions: [
        IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh)),
      ]),
    body: ListView(padding: const EdgeInsets.all(14), children: [
      Row(children: [
        const Icon(Icons.sensors, color: Colors.cyanAccent, size: 17),
        const SizedBox(width: 8),
        Expanded(child: Text(_status?['camera_connected'] == true ? 'PI CAMERA ONLINE' : 'WAITING FOR PI CAMERA',
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700))),
        Text(_updated == null ? 'Connecting...' : 'Updated ${_updated!.hour.toString().padLeft(2,'0')}:${_updated!.minute.toString().padLeft(2,'0')}',
          style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ]),
      const SizedBox(height: 12),
      AspectRatio(aspectRatio: 4 / 3, child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(fit: StackFit.expand, children: [
          ColoredBox(color: const Color(0xFF020913), child: kIsWeb
            ? HtmlElementView(viewType: _viewType)
            : Image.network('$_api/video_call', fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(child: Text('Camera stream unavailable',
                  style: TextStyle(color: Colors.white70))))),
          // Boxes are from live /api/vision/status and use 640x480 camera coordinates.
          if (widget.mode == BuddyVisionMode.people || widget.mode == BuddyVisionMode.objects || widget.mode == BuddyVisionMode.expressions)
            IgnorePointer(child: CustomPaint(painter: _DetectionsPainter(
              widget.mode == BuddyVisionMode.objects ? _objects : _faces,
              objectMode: widget.mode == BuddyVisionMode.objects))),
          Positioned(top: 9, left: 9, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
            child: Text(widget.mode.title.toUpperCase(), style: const TextStyle(
              color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)))),
        ]),
      )),
      if (_error != null) _card('CONNECTION', Text(_error!, style: const TextStyle(color: Colors.orangeAccent))),
      _details(),
      _card('LIVE DATA NOTICE', const Text(
        'Annotations come from recent AI status frames and may lag behind the video. Live camera is shared with the existing BUDDY vision worker. No motor commands are sent.',
        style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.5))),
    ]),
  );
}

class _DetectionsPainter extends CustomPainter {
  final List<Map<String, dynamic>> detections;
  final bool objectMode;
  const _DetectionsPainter(this.detections, {required this.objectMode});
  @override
  void paint(Canvas canvas, Size size) {
    const sourceWidth = 640.0;
    const sourceHeight = 480.0;
    final sx = size.width / sourceWidth;
    final sy = size.height / sourceHeight;
    for (final d in detections) {
      final box = d['box'];
      if (box is! List || box.length < 4 || box.take(4).any((e) => e is! num)) continue;
      final nums = box.take(4).map((e) => (e as num).toDouble()).toList();
      // Vision API currently returns bounding boxes in x1, y1, x2, y2 form.
      final rect = Rect.fromLTRB(nums[0]*sx, nums[1]*sy, nums[2]*sx, nums[3]*sy);
      final color = objectMode ? const Color(0xFFFFD467) :
          (d['recognized'] == true ? const Color(0xFF46F2A1) : const Color(0xFFFC9A68));
      canvas.drawRect(rect, Paint()..color=color..style=PaintingStyle.stroke..strokeWidth=2.5);
      final text = objectMode ? '${d['name'] ?? d['label'] ?? 'Object'}' : '${d['name'] ?? 'Unknown'}';
      final tp = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color,
        fontWeight: FontWeight.bold, fontSize: 11, backgroundColor: const Color(0xD9001020))),
        textDirection: TextDirection.ltr, maxLines: 1)..layout(maxWidth: size.width*0.7);
      tp.paint(canvas, Offset(rect.left.clamp(0.0, size.width-5).toDouble(),
        (rect.top-17).clamp(0.0, size.height-15).toDouble()));
    }
  }
  @override
  bool shouldRepaint(covariant _DetectionsPainter oldDelegate) => true;
}
