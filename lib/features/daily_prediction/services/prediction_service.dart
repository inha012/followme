import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:follow_me/core/services/prediction_api_service.dart';
import 'package:follow_me/features/daily_prediction/models/prediction_result.dart';

class PredictionService {
  static const _keyDate     = 'prediction_date';
  static const _keyFortune  = 'prediction_fortune';
  static const _keyMissions = 'prediction_missions';

  /// 저장된 오늘 예측을 불러옴. 없으면 null.
  static Future<PredictionResult?> getToday() async {
    final prefs = await SharedPreferences.getInstance();
    final fortune      = prefs.getString(_keyFortune);
    final missionsJson = prefs.getString(_keyMissions);
    if (fortune == null || missionsJson == null) return null;
    final raw = jsonDecode(missionsJson) as List;
    final missions = raw.map((e) {
      if (e is Map<String, dynamic>) return Mission.fromJson(e);
      return Mission(text: e.toString(), trait: 0);
    }).toList();
    return PredictionResult(
      fortune:  fortune,
      missions: missions,
      date:     prefs.getString(_keyDate) ?? '',
    );
  }

  /// 서버에 예측 요청 후 결과를 로컬에 저장.
  static Future<void> generateAndSave() async {
    final data = await PredictionApiService.fetchPrediction();
    if (data == null) return;

    final fortune = data['fortune'] as String? ?? '';
    final rawList = data['missions'];
    if (fortune.isEmpty || rawList is! List || rawList.length != 4) return;

    final missions = rawList.map<Mission>((e) {
      if (e is Map<String, dynamic>) return Mission.fromJson(e);
      return Mission(text: e.toString(), trait: 0);
    }).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDate,     PredictionResult.todayKey());
    await prefs.setString(_keyFortune,  fortune);
    await prefs.setString(_keyMissions, jsonEncode(missions.map((m) => m.toJson()).toList()));
  }
}
