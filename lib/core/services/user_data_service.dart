import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:follow_me/features/schedule_input/models/timetable_entry.dart';

class UserDataService {
  static const _keyName = 'user_name';
  static const _keyUserId = 'user_id';
  static const _keyBirthdate = 'user_birthdate';
  static const _keyGender = 'user_gender';
  static const _keyMyScores = 'my_personality_scores';
  static const _keyIdealScores = 'ideal_personality_scores';
  static const _keyTimetable = 'timetable_entries';
  static const _keyTotalMissionsDone = 'total_missions_done';

  static Future<void> saveProfile({
    required String name,
    required DateTime birthdate,
    required String gender,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyBirthdate, birthdate.toIso8601String());
    await prefs.setString(_keyGender, gender);
  }

  static Future<void> savePersonalityScores({
    required List<int> myScores,
    required List<int> idealScores,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMyScores, jsonEncode(myScores));
    await prefs.setString(_keyIdealScores, jsonEncode(idealScores));
  }

  static Future<void> saveTimetable(List<TimetableEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final data = entries.map((e) => e.toMap()).toList();
    await prefs.setString(_keyTimetable, jsonEncode(data));
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  static Future<DateTime?> getBirthdate() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_keyBirthdate);
    return s != null ? DateTime.tryParse(s) : null;
  }

  static Future<String?> getGender() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGender);
  }

  static Future<List<int>> getMyScores() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_keyMyScores);
    if (s == null) return [];
    return (jsonDecode(s) as List).cast<int>();
  }

  static Future<List<int>> getIdealScores() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_keyIdealScores);
    if (s == null) return [];
    return (jsonDecode(s) as List).cast<int>();
  }

  static Future<List<TimetableEntry>> getTimetable() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_keyTimetable);
    if (s == null) return [];
    final list = jsonDecode(s) as List;
    return list
        .map((e) => TimetableEntry.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveMyScores(List<int> scores) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMyScores, jsonEncode(scores));
  }

  static Future<void> saveIdealScores(List<int> scores) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyIdealScores, jsonEncode(scores));
  }

  static String _generateUserId() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final s = bytes.map(hex).join();
    return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
  }

  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_keyUserId);
    if (id == null) {
      id = _generateUserId();
      await prefs.setString(_keyUserId, id);
    }
    return id;
  }

  static Future<int> getTotalMissionsDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTotalMissionsDone) ?? 0;
  }

  static Future<void> incrementMissionsDone(int delta) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyTotalMissionsDone) ?? 0;
    await prefs.setInt(_keyTotalMissionsDone, (current + delta).clamp(0, 1000000));
  }
}
