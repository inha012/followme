import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:follow_me/core/constants/app_constants.dart';
import 'package:follow_me/core/services/user_data_service.dart';
import 'package:follow_me/features/daily_prediction/models/prediction_result.dart';
import 'package:follow_me/features/diary/data/diary_database.dart';

class PredictionApiService {
  static String? lastError;

  /// FastAPI /predict 를 호출해 운세·미션을 반환. 실패 시 null.
  static Future<Map<String, dynamic>?> fetchPrediction() async {
    lastError = null;
    try {
      // ── 사용자 데이터 수집 ──────────────────────────────────────────
      final birthdate   = await UserDataService.getBirthdate();
      final gender      = await UserDataService.getGender();
      final myScores    = await UserDataService.getMyScores();
      final idealScores = await UserDataService.getIdealScores();
      final timetable   = await UserDataService.getTimetable();

      // 오늘 작성된 일기만 추출
      final allDiaries = await DiaryDatabase.getAll();
      final today = PredictionResult.todayKey();
      final todayDiary = allDiaries
          .where((d) => d.createdAt.toIso8601String().startsWith(today))
          .toList();

      // ── 요청 바디 조립 ──────────────────────────────────────────────
      final body = {
        'birthdate':    birthdate?.toIso8601String().split('T').first,
        'gender':       gender,
        'my_scores':    myScores,
        'ideal_scores': idealScores,
        'schedule':     timetable.map((e) => e.toMap()).toList(),
        'diary':        todayDiary.isEmpty ? null : todayDiary.first.text,
      };

      final uri = Uri.parse('${AppConstants.serverBaseUrl}/predict');
      debugPrint('[API] POST → $uri');

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 180));

      debugPrint('[API] status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      lastError = 'HTTP ${response.statusCode}: ${response.body}';
      debugPrint('[API] error: $lastError');
    } catch (e) {
      lastError = e.toString();
      debugPrint('[API] exception: $e');
    }
    return null;
  }
}
