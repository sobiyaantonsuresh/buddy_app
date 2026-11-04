import 'package:flutter/material.dart';
import 'vision_live_screen.dart';

class ScreenVisionDiagnostics extends StatelessWidget {
  const ScreenVisionDiagnostics({super.key});
  static const _bg = Color(0xFF061322);
  static const _panel = Color(0xFF10263B);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    appBar: AppBar(backgroundColor: _bg, foregroundColor: Colors.white,
      title: const Text('BUDDY  |  AI Vision Lab')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('LIVE VISION TESTING', style: TextStyle(
        color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
      const SizedBox(height: 6),
      const Text('Select a mode to open the live Raspberry Pi camera and its AI results.',
        style: TextStyle(color: Colors.white60, height: 1.4)),
      const SizedBox(height: 20),
      for (final mode in BuddyVisionMode.values)
        Padding(padding: const EdgeInsets.only(bottom: 11), child: Material(
          color: _panel, borderRadius: BorderRadius.circular(16), child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => BuddyLiveVisionScreen(mode: mode))),
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 15),
              child: Row(children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(
                  color: const Color(0xFF0C4365), borderRadius: BorderRadius.circular(12)),
                  child: Icon(mode.icon, color: const Color(0xFF64D5FF))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(mode.title, style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(_subtitle(mode), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ])),
                const Icon(Icons.chevron_right, color: Colors.white54),
              ])),
          ))),
      const SizedBox(height: 16),
      const Text('LIVE: face/object boxes when the API reports them. Pose and gesture overlays require additional verified Pi endpoints.',
        style: TextStyle(color: Colors.amberAccent, fontSize: 12, height: 1.5)),
    ]),
  );

  static String _subtitle(BuddyVisionMode m) => switch(m) {
    BuddyVisionMode.people => 'Live face boxes and recognized names',
    BuddyVisionMode.objects => 'Live detection boxes + Identify Object',
    BuddyVisionMode.expressions => 'Face video and expression result availability',
    BuddyVisionMode.posture => 'Live video + pose pipeline readiness',
    BuddyVisionMode.gestures => 'Live video + gesture model connection status',
  };
}
