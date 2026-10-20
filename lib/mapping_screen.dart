import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ScreenMapping extends StatefulWidget {
  const ScreenMapping({super.key});

  @override
  State<ScreenMapping> createState() => _ScreenMappingState();
}

class _ScreenMappingState extends State<ScreenMapping> {
  static const baseUrl = 'http://10.138.45.237:5000';

  Timer? _timer;
  Map<String, dynamic>? _data;
  String? _error;
  bool _scanning = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/mapping/status'))
          .timeout(const Duration(seconds: 4));

      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() => _error = 'Sensor data unavailable');
        return;
      }

      final decoded = jsonDecode(response.body);
      setState(() {
        _data = Map<String, dynamic>.from(decoded);
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Cannot connect to BUDDY');
    }
  }

  void _startScan() {
    _timer?.cancel();
    setState(() => _scanning = true);
    _refresh();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refresh(),
    );
  }

  void _stopScan() {
    _timer?.cancel();
    setState(() => _scanning = false);
  }

  double? _distance(String key) {
    final valid = _data?['valid'];
    if (valid is Map && valid[key] != true) return null;
    final value = _data?[key];
    if (value is! num || !value.toDouble().isFinite) return null;
    return value.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF081829);

    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text('BUDDY  |  Scan Area'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '2D ULTRASONIC PROXIMITY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Live directional measurements · Robot remains stationary',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Container(
              height: 330,
              decoration: BoxDecoration(
                color: const Color(0xFF0C243A),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.blueGrey.shade700),
              ),
              child: CustomPaint(
                painter: _RadarPainter({
                  'front': _distance('front'),
                  'rear': _distance('rear'),
                  'left': _distance('left'),
                  'right': _distance('right'),
                }),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 16),
            if (_data?['degraded'] == true)
              const Card(
                color: Color(0xFF513A16),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Sensor warning: at least one physical ultrasonic '
                    'measurement is unavailable.',
                    style: TextStyle(color: Colors.amberAccent),
                  ),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.orangeAccent),
                ),
              ),
            for (final direction in [
              'front', 'rear', 'left', 'right'
            ])
              Card(
                color: const Color(0xFF102C45),
                child: ListTile(
                  title: Text(
                    direction.toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: Text(
                    _distance(direction) == null
                        ? 'Unavailable'
                        : '${_distance(direction)!.toStringAsFixed(2)} m',
                    style: const TextStyle(
                      color: Colors.lightBlueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _scanning ? _stopScan : _startScan,
              icon: Icon(_scanning ? Icons.stop : Icons.radar),
              label: Text(
                _scanning ? 'Stop Scanning' : 'Scan Area',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _scanning ? Colors.redAccent : const Color(0xFF008EFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Approximate proximity visualization. '
              'Not a complete room map or SLAM reconstruction.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final Map<String, double?> distances;

  _RadarPainter(this.distances);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.40;

    final gridPaint = Paint()
      ..color = Colors.blueGrey.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke;

    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * i / 4, gridPaint);
    }

    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      gridPaint,
    );

    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      gridPaint,
    );

    canvas.drawCircle(
      center,
      13,
      Paint()..color = Colors.lightBlueAccent,
    );

    final directions = {
      'front': const Offset(0, -1),
      'rear': const Offset(0, 1),
      'left': const Offset(-1, 0),
      'right': const Offset(1, 0),
    };

    for (final entry in directions.entries) {
      final distance = distances[entry.key];
      if (distance == null) continue;

      final proportion = (distance / 4.0).clamp(0.0, 1.0);
      final offset = Offset(
        center.dx + entry.value.dx * radius * proportion,
        center.dy + entry.value.dy * radius * proportion,
      );

      final color = distance < 0.5
          ? Colors.redAccent
          : distance < 1.0
              ? Colors.amberAccent
              : Colors.greenAccent;

      canvas.drawCircle(offset, 8, Paint()..color = color);
      canvas.drawCircle(
        offset,
        12,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => true;
}
