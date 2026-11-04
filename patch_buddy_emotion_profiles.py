"""Conservatively add household profile selection to buddy_app/lib/emotion_screen.dart.
Run from buddy_app. Creates backup. Does not edit backend or database.
"""
from pathlib import Path
import re, shutil, sys
p=Path('lib/emotion_screen.dart')
if not p.exists(): sys.exit('ERROR: Run from buddy_app folder.')
s=p.read_text(encoding='utf-8')
if '_loadHouseholdMembers()' in s: sys.exit('Already patched; no changes made.')
markers=["this.targetName = 'sobiya',", "  String _currentEmotion = 'Neutral';", "  void initState() {", "    _targetName = widget.targetName;", "  Future<void> _fetchEmotionReport24h() async {", "        final List<dynamic> reports = data['reports'] ?? [];", "      if (response.statusCode == 200) {", "    } catch (_) {", "  // 7 Emotions Color Mapping"]
for m in markers:
 if s.count(m)!=1: sys.exit('ERROR: Unexpected source structure: '+m)
s=s.replace("this.targetName = 'sobiya',", "this.targetName = 'ashandth',",1)
s=s.replace("  String _currentEmotion = 'Neutral';", "  String _currentEmotion = 'Unknown';\n  List<String> _householdNames = [];\n  String? _profileError;\n",1)
s=s.replace("  int _confidence = 85;", "  int _confidence = 0;",1)
s=s.replace("    _targetName = widget.targetName;", "    _targetName = widget.targetName.trim().isEmpty ? 'Ashandth' : widget.targetName.trim();\n    _loadHouseholdMembers();",1)
# Insert helper before fetch function
helper='''  Future<void> _loadHouseholdMembers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/household_members'),
      ).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) throw Exception('Household API unavailable');
      final decoded = jsonDecode(response.body);
      if (decoded is! List) throw Exception('Invalid household response');
      final names = decoded.map((entry) => entry is Map ? entry['name']?.toString().trim() : null)
          .whereType<String>().where((name) => name.isNotEmpty).toSet().toList();
      if (!mounted) return;
      setState(() {
        _householdNames = names;
        _profileError = null;
        if (names.isNotEmpty && !names.any((name) => name.toLowerCase() == _targetName.toLowerCase())) {
          _targetName = names.first;
          _reports24h = [];
          _currentEmotion = 'Unknown';
          _confidence = 0;
          _isLoading = true;
        } else {
          for (final name in names) {
            if (name.toLowerCase() == _targetName.toLowerCase()) _targetName = name;
          }
        }
      });
      await _fetchEmotionReport24h();
    } catch (error) {
      if (!mounted) return;
      setState(() => _profileError = 'Household list unavailable');
    }
  }

  void _selectHouseholdMember(String? name) {
    if (name == null || name == _targetName) return;
    setState(() {
      _targetName = name;
      _reports24h = [];
      _currentEmotion = 'Unknown';
      _confidence = 0;
      _isFallEmergency = false;
      _isMusicPlayingNow = false;
      _lastPlayedTime = 'None';
      _musicTarget = name;
      _isLoading = true;
    });
    _fetchEmotionReport24h();
  }

'''
s=s.replace('  Future<void> _fetchEmotionReport24h() async {',helper+'  Future<void> _fetchEmotionReport24h() async {',1)
# protect races, and allow no history without fabricated 85%
s=s.replace('      final cleanTarget = _targetName.trim().toLowerCase();', "      final requestedTarget = _targetName;\n      final cleanTarget = Uri.encodeComponent(requestedTarget.trim().toLowerCase());",1)
s=s.replace('        if (mounted) {\n          setState(() {\n            _reports24h = recentReports;', '        if (mounted && _targetName == requestedTarget) {\n          setState(() {\n            _reports24h = recentReports;',1)
s=s.replace("              _confidence = ((latest['confidence'] ?? 0.85) * 100).toInt();", "              _confidence = ((latest['confidence'] ?? 0.0) * 100).round();\n            } else {\n              _currentEmotion = 'Unknown';\n              _confidence = 0;",1)
# locate catch in fetch only, avoid replacing elsewhere
start=s.index('  Future<void> _fetchEmotionReport24h() async {')
end=s.index('  String _capitalize(String s)',start)
part=s[start:end]
part=part.replace('    } catch (_) {\n      if (mounted) setState(() => _isLoading = false);', '    } catch (_) {\n      if (mounted) setState(() => _isLoading = false);',1)
# handle non-200 too
part=part.replace('      }\n    } catch (_) {', '      } else {\n        if (mounted && _targetName == requestedTarget) setState(() => _isLoading = false);\n      }\n    } catch (_) {',1)
s=s[:start]+part+s[end:]
# Insert selector before music card comment (the source may contain mojibake emoji, find ASCII substring)
lines=s.splitlines(keepends=True)
indexes=[i for i,l in enumerate(lines) if 'STANDALONE MUSIC STATUS CARD' in l]
if len(indexes)!=1: sys.exit('ERROR: Cannot locate Music Status card insertion; no changes made.')
i=indexes[0]
indent=re.match(r'\s*',lines[i]).group(0)
selector='''// Household member picker - only registered names from live Flask API.
Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  decoration: BoxDecoration(
    color: isDark ? const Color(0xFF10192D) : Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0)),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('HOUSEHOLD MEMBER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
        color: isDark ? Colors.white70 : const Color(0xFF64748B))),
      const SizedBox(height: 5),
      if (_householdNames.isNotEmpty)
        DropdownButton<String>(
          isExpanded: true,
          value: _householdNames.contains(_targetName) ? _targetName : _householdNames.first,
          underline: const SizedBox.shrink(),
          items: _householdNames.map((name) => DropdownMenuItem<String>(
            value: name,
            child: Text(name, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF173630))),
          )).toList(),
          onChanged: _selectHouseholdMember,
        )
      else
        Text(_profileError ?? 'Loading registered household members...',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
    ],
  ),
),
const SizedBox(height: 12),
'''
lines.insert(i,''.join(indent+l if l.strip() else l for l in selector.splitlines(keepends=True)))
s=''.join(lines)
# Avoid showing 85% as accuracy: replace visual label only if present, retain real _confidence read
s=s.replace("'85% ACCURACY'", "'LIVE ESTIMATE'",1)
backup=Path('lib/emotion_screen.dart.before_household_profiles.bak')
if backup.exists(): sys.exit('ERROR: Backup exists; refusing overwrite.')
shutil.copy2(p,backup)
p.write_text(s,encoding='utf-8')
print('PATCHED:',p)
print('BACKUP:',backup)
print('Registered profile picker installed; run flutter analyze for validation.')
