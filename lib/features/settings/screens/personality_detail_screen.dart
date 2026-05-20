import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:follow_me/core/utils/personality_type_utils.dart';
import 'package:follow_me/features/settings/screens/personality_all_screen.dart';
import 'package:follow_me/shared/widgets/floating_tab_bar.dart';

class PersonalityDetailScreen extends StatelessWidget {
  const PersonalityDetailScreen({
    super.key,
    required this.isIdeal,
    required this.scores,
    this.gender,
  });

  final bool isIdeal;
  final List<int> scores;
  final String? gender;

  @override
  Widget build(BuildContext context) {
    final color =
        isIdeal ? const Color(0xFFEEC22A) : const Color(0xFF208484);
    final title = isIdeal ? '현재 이상향' : '현재 내 성향';
    final personality = classifyPersonality(scores, gender: gender);
    final typeName = scores.isEmpty ? 'OO 성향' : personality.name;
    final description = scores.isEmpty
        ? '성향 분석을 완료하면 그래프가 업데이트돼요.'
        : personality.description;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: FloatingTabBar(
            selectedIndex: 2,
            onTap: (i) {
              if (i != 2) Navigator.of(context).pop();
            },
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.chevron_left,
                        size: 28,
                        color: Color(0xFF262626),
                      ),
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Color(0xFF262626),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 성향 카드
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 24,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 성향 이름
                    Text(
                      typeName,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: Color(0xFF262626),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 성향 설명
                    Text(
                      scores.isEmpty
                          ? '성향 분석을 완료하면 그래프가 업데이트돼요.'
                          : description,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: Color(0xFF6F6F6F),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // 도형 자리
                    Center(
                      child: SizedBox(
                        width: 200,
                        height: 185,
                        child: CustomPaint(
                          painter: _HexagonPainter(
                            color: color,
                            scores: scores,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 다른 성향 보기 버튼
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PersonalityAllScreen(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '다른 성향 보기',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Color(0xFF444444),
                      ),
                    ),
                  ),
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
    required this.color,
    required this.scores,
  });

  final Color color;
  final List<int> scores;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = size.width / 2.5;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
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
      ..color = color.withValues(alpha: 0.2)
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
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(dataPath, linePaint);

    final centerPointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), 4, centerPointPaint);
  }

  @override
  bool shouldRepaint(_HexagonPainter old) =>
      old.color != color || old.scores != scores;
}
