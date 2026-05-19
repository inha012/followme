import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:follow_me/core/services/user_data_service.dart';
import 'package:follow_me/core/utils/personality_type_utils.dart';
import 'package:follow_me/shared/widgets/teal_button.dart';

// 공통으로 쓰이는 텍스트 스타일을 상수로 추출해 중복을 줄입니다.
const _titleTextStyle = TextStyle(
  fontFamily: 'Pretendard',
  fontWeight: FontWeight.w700,
  fontSize: 24,
  height: 32 / 24,
  color: Color(0xFF262626),
);
const _labelTextStyle = TextStyle(
  fontFamily: 'Pretendard',
  fontWeight: FontWeight.w400,
  fontSize: 15,
  height: 22 / 15,
  color: Color(0xFF6F6F6F),
);
const _typeNameTextStyle = TextStyle(
  fontFamily: 'Pretendard',
  fontWeight: FontWeight.w600,
  fontSize: 16,
  height: 22 / 16,
  color: Color(0xFF222222),
);
const _descTextStyle = TextStyle(
  fontFamily: 'Pretendard',
  fontWeight: FontWeight.w400,
  fontSize: 15,
  height: 22 / 15,
  color: Color(0xFF525252),
);

class SettingsPersonalityResultScreen extends StatelessWidget {
  const SettingsPersonalityResultScreen({
    super.key,
    required this.isIdeal,
    required this.scores,
    required this.onDone,
    this.gender,
  });

  final bool isIdeal;
  final List<int> scores;
  final String? gender;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isIdeal ? const Color(0xFFFEF6DA) : const Color(0xFFE9F7F7);
    final accentColor =
        isIdeal ? const Color(0xFFEEC22A) : const Color(0xFF208484);
    final textColor =
        isIdeal ? const Color(0xFFB8920E) : const Color(0xFF208484);
    final label = isIdeal ? '이상향 성향' : '현재 성향';
    final personality = classifyPersonality(scores, gender: gender);
    final typeName = personality.name;
    final description = personality.description;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 33),
                    // 헤더: 제목 + 닫기 버튼
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        const Text('성향 분석 결과', style: _titleTextStyle),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Icon(
                              Icons.close,
                              size: 24,
                              color: Color(0xFF6F6F6F),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 39),
                    Text(label, style: _labelTextStyle),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(typeName, style: _typeNameTextStyle),
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
                                  style: _descTextStyle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isIdeal
                            ? '이상향 성향이 업데이트되었습니다.\n앞으로의 미션이 새로운 이상향에 맞춰 제공돼요.'
                            : '현재 성향이 업데이트되었습니다.\n앞으로의 예측과 미션에 반영될 거예요.',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          height: 22 / 14,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 완료 버튼 (오른쪽 정렬)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: TealButton(
                  label: '완료',
                  onTap: () async {
                    if (isIdeal) {
                      await UserDataService.saveIdealScores(scores);
                    } else {
                      await UserDataService.saveMyScores(scores);
                    }
                    onDone();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ],
        ),
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
  final List<int> scores;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = size.width / 2.5;

    final bgPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    const sides = 6;
    final degToRad = math.pi / 180;
    final bgPoints = <Offset>[];
    for (int i = 0; i < sides; i++) {
      final angle = (i * 60 - 90) * degToRad;
      final x = centerX + maxRadius * math.cos(angle);
      final y = centerY + maxRadius * math.sin(angle);
      bgPoints.add(Offset(x, y));
    }

    final bgPath = Path()..moveTo(bgPoints[0].dx, bgPoints[0].dy);
    for (int i = 1; i < sides; i++) {
      bgPath.lineTo(bgPoints[i].dx, bgPoints[i].dy);
    }
    bgPath.close();
    canvas.drawPath(bgPath, bgPaint);

    final borderPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(bgPath, borderPaint);

    final dataPoints = <Offset>[];
    for (int i = 0; i < sides; i++) {
      final angle = (i * 60 - 90) * degToRad;
      final normalized = ((i < scores.length ? scores[i] : 0) / 25).clamp(0.0, 1.0);
      final radius = maxRadius * normalized;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      dataPoints.add(Offset(x, y));
    }

    final dataPath = Path()..moveTo(dataPoints[0].dx, dataPoints[0].dy);
    for (int i = 1; i < sides; i++) {
      dataPath.lineTo(dataPoints[i].dx, dataPoints[i].dy);
    }
    dataPath.close();

    final fillPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, fillPaint);

    final linePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(dataPath, linePaint);

    final centerPointPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), 4, centerPointPaint);
  }

  @override
  bool shouldRepaint(_HexagonPainter old) =>
      old.accentColor != accentColor || old.scores != scores;
}
