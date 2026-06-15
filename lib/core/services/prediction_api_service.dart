import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cupertino_http/cupertino_http.dart';
import 'package:follow_me/core/constants/app_constants.dart';
import 'package:follow_me/core/services/user_data_service.dart';
import 'package:follow_me/features/diary/data/diary_database.dart';

http.Client _buildClient() {
  if (Platform.isIOS || Platform.isMacOS) {
    return CupertinoClient.defaultSessionConfiguration();
  }
  return http.Client();
}

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

      // 어제 작성된 일기 추출 (RAG 검색 기준)
      final allDiaries = await DiaryDatabase.getAll();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayKey =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      final yesterdayDiary = allDiaries
          .where((d) => d.createdAt.toIso8601String().startsWith(yesterdayKey))
          .toList();

      final userId = await UserDataService.getUserId();

      // ── 요청 바디 조립 ──────────────────────────────────────────────
      final body = {
        'user_id':      userId,
        'birthdate':    birthdate?.toIso8601String().split('T').first,
        'gender':       gender,
        'my_scores':    myScores,
        'ideal_scores': idealScores,
        'schedule':     timetable.map((e) => e.toMap()).toList(),
        'diary':        yesterdayDiary.isEmpty ? null : yesterdayDiary.first.text,
      };

      final uri = Uri.parse('${AppConstants.serverBaseUrl}/predict');
      debugPrint('[API] POST → $uri');

      final client = _buildClient();
      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 180));
      client.close();

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

  /// 일기를 서버에 동기화 (RAG 저장용). 실패해도 로컬 저장에 영향 없음.
  static Future<void> syncDiary(String text, DateTime date) async {
    try {
      final userId = await UserDataService.getUserId();
      final uri = Uri.parse('${AppConstants.serverBaseUrl}/diary');
      final client = _buildClient();
      await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'text': text,
              'date': date.toIso8601String().split('T').first,
            }),
          )
          .timeout(const Duration(seconds: 30));
      client.close();
      debugPrint('[API] diary synced');
    } catch (e) {
      debugPrint('[API] diary sync failed (ignored): $e');
    }
  }
}
