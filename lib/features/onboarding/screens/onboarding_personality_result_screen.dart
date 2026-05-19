import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:follow_me/core/services/user_data_service.dart';
import 'package:follow_me/core/utils/personality_type_utils.dart';
import 'package:follow_me/features/schedule_input/screens/onboarding_timetable_screen.dart';
import 'package:follow_me/shared/widgets/next_button.dart';

class OnboardingPersonalityResultScreen extends StatelessWidget {
  const OnboardingPersonalityResultScreen({
    super.key,
    required this.userName,
    required this.myPersonalityScores,
    required this.idealPersonalityScores,
  });

  final String userName;
  final List<int> myPersonalityScores;
  final List<int> idealPersonalityScores;

  static const _bgColor = Color(0xFFFFFFFF);
  static const _titleColor = Color(0xFF262626);
  static const _labelColor = Color(0xFF6F6F6F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: FutureBuilder<String?>(
          future: UserDataService.getGender(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF208484)),
              );
            }

            final gender = snapshot.data;
            final myType = classifyPersonality(myPersonalityScores, gender: gender);
            final idealType = classifyPersonality(idealPersonalityScores, gender: gender);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 33),
                        const Text(
                          '성향 분석 결과',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                            height: 32 / 24,
                            color: _titleColor,
                          ),
                        ),
                        const SizedBox(height: 39),
                        const Text(
                          '현재 성향',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w400,
                            fontSize: 15,
                            height: 22 / 15,
                            color: _labelColor,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _PersonalityCard(
                          bgColor: const Color(0xFFE9F7F7),
                          accentColor: const Color(0xFF208484),
                          typeName: myType.name,
                          description: myType.description,
                          scores: myPersonalityScores,
                        ),
                        const SizedBox(height: 49),
                        const Text(
                          '이상향 성향',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w400,
                            fontSize: 15,
                            height: 22 / 15,
                            color: _labelColor,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _PersonalityCard(
                          bgColor: const Color(0xFFFEF6DA),
                          accentColor: const Color(0xFFEEC22A),
                          typeName: idealType.name,
                          description: idealType.description,
                          scores: idealPersonalityScores,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: NextButton(
                    onTap: () async {
                      await UserDataService.savePersonalityScores(
                        myScores: myPersonalityScores,
                        idealScores: idealPersonalityScores,
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OnboardingTimetableScreen(
                            userName: userName,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PersonalityCard extends StatelessWidget {
  const _PersonalityCard({
    required this.bgColor,
    required this.accentColor,
    required this.typeName,
    required this.description,
    required this.scores,
  });

  final Color bgColor;
  final Color accentColor;
  final String typeName;
  final String description;
  final List<int> scores;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            typeName,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              height: 22 / 16,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _HexagonPainter(
                    accentColor: accentColor,
                    scores: scores,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    fontSize: 15,
                    height: 22 / 15,
                    color: Color(0xFF525252),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HexagonPainter extends CustomPainter {
  const _HexagonPainter({
    required this.accentColor,
    required this.scores,
  });

  final Color accentColor;
  final List<int> scores; // 6개의 카테고리 점수 [0-25점]

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = size.width / 2.5; // 최대 반지름

    // 배경 육각형 그리기 (밝은 회색)
    final bgPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    const sides = 6;
    final degToRad = math.pi / 180;
    final bgPoints = <Offset>[];
    for (int i = 0; i < sides; i++) {
      final angle = (i * 60 - 90) * degToRad; // 0번이 12시 방향
      final x = centerX + maxRadius * math.cos(angle);
      final y = centerY + maxRadius * math.sin(angle);
      bgPoints.add(Offset(x, y));
    }

    final bgPath = Path()
      ..moveTo(bgPoints[0].dx, bgPoints[0].dy);
    for (int i = 1; i < sides; i++) {
      bgPath.lineTo(bgPoints[i].dx, bgPoints[i].dy);
    }
    bgPath.close();
    canvas.drawPath(bgPath, bgPaint);

    // 배경 육각형 테두리 그리기
    final borderPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(bgPath, borderPaint);

    // 실제 점수 데이터 육각형 그리기
    final dataPoints = <Offset>[];
    for (int i = 0; i < sides; i++) {
      final angle = (i * 60 - 90) * degToRad;
      // 점수 정규화 (0-25 → 0-1)
      final normalized = ((i < scores.length ? scores[i] : 0) / 25).clamp(0.0, 1.0);
      final radius = maxRadius * normalized;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      dataPoints.add(Offset(x, y));
    }

    final dataPath = Path()
      ..moveTo(dataPoints[0].dx, dataPoints[0].dy);
    for (int i = 1; i < sides; i++) {
      dataPath.lineTo(dataPoints[i].dx, dataPoints[i].dy);
    }
    dataPath.close();

    // 데이터 영역 채우기
    final fillPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, fillPaint);

    // 데이터 라인 그리기
    final linePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(dataPath, linePaint);

    // 중심에 점 그리기
    final centerPointPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), 4, centerPointPaint);
  }

  @override
  bool shouldRepaint(_HexagonPainter old) =>
      old.accentColor != accentColor || old.scores != scores;
}
