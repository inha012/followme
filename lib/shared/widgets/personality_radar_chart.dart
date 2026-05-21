import 'dart:math';
import 'package:flutter/material.dart';

class PersonalityRadarChart extends StatelessWidget {
  const PersonalityRadarChart({
    super.key,
    required this.myScores,
    required this.idealScores,
    this.todayGains = const {},
    this.size = 260,
  });

  final List<int> myScores;
  final List<int> idealScores;
  final Map<int, double> todayGains;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RadarPainter(
          myScores: myScores,
          idealScores: idealScores,
          todayGains: todayGains,
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.myScores,
    required this.idealScores,
    required this.todayGains,
  });

  final List<int> myScores;
  final List<int> idealScores;
  final Map<int, double> todayGains;

  static const _labels = ['모험적', '사색적', '외향적', '주도적', '다정함', '논리적'];
  static const _maxScore = 25.0;
  static const _gridLevels = 4;
  static const _count = 6;
  static const _startAngle = -pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final chartRadius = size.width * 0.30;
    final labelRadius = size.width * 0.43;

    _drawGrid(canvas, center, chartRadius);
    if (idealScores.length == _count) {
      _drawPolygon(canvas, center, chartRadius, idealScores,
          const Color(0xFFEEC22A), isIdeal: true);
    }
    if (myScores.length == _count) {
      _drawPolygon(canvas, center, chartRadius, myScores,
          const Color(0xFF208484), isIdeal: false);
      _drawDots(canvas, center, chartRadius, myScores);
    }
    _drawLabels(canvas, center, labelRadius);
  }

  void _drawGrid(Canvas canvas, Offset center, double radius) {
    final gridPaint = Paint()
      ..color = const Color(0xFFDDDDDD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int level = 1; level <= _gridLevels; level++) {
      final r = radius * level / _gridLevels;
      canvas.drawPath(_hexPath(center, r), gridPaint);
    }

    final axisPaint = Paint()
      ..color = const Color(0xFFDDDDDD)
      ..strokeWidth = 0.8;

    for (int i = 0; i < _count; i++) {
      final angle = _startAngle + 2 * pi * i / _count;
      canvas.drawLine(
        center,
        Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle)),
        axisPaint,
      );
    }
  }

  Path _hexPath(Offset center, double r) {
    final path = Path();
    for (int i = 0; i < _count; i++) {
      final angle = _startAngle + 2 * pi * i / _count;
      final pt = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    return path..close();
  }

  void _drawPolygon(Canvas canvas, Offset center, double radius,
      List<int> scores, Color color, {required bool isIdeal}) {
    final path = Path();
    for (int i = 0; i < _count; i++) {
      final angle = _startAngle + 2 * pi * i / _count;
      final r = radius * scores[i].clamp(0, 25) / _maxScore;
      final pt = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: isIdeal ? 0.18 : 0.28)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isIdeal ? 1.5 : 2.0,
    );
  }

  void _drawDots(Canvas canvas, Offset center, double radius, List<int> scores) {
    final paint = Paint()
      ..color = const Color(0xFF208484)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < _count; i++) {
      final angle = _startAngle + 2 * pi * i / _count;
      final r = radius * scores[i].clamp(0, 25) / _maxScore;
      canvas.drawCircle(
        Offset(center.dx + r * cos(angle), center.dy + r * sin(angle)),
        3.5,
        paint,
      );
    }
  }

  void _drawLabels(Canvas canvas, Offset center, double labelRadius) {
    for (int i = 0; i < _count; i++) {
      final angle = _startAngle + 2 * pi * i / _count;
      final lx = center.dx + labelRadius * cos(angle);
      final ly = center.dy + labelRadius * sin(angle);

      final gain = todayGains[i];
      final hasGain = gain != null && gain > 0;

      final labelPainter = TextPainter(
        text: TextSpan(
          text: _labels[i],
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelY = hasGain
          ? ly - labelPainter.height / 2 - 6
          : ly - labelPainter.height / 2;

      labelPainter.paint(
        canvas,
        Offset(lx - labelPainter.width / 2, labelY),
      );

      if (hasGain) {
        final gainPainter = TextPainter(
          text: TextSpan(
            text: '+${_fmtGain(gain)}',
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB8920E),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        gainPainter.paint(
          canvas,
          Offset(
            lx - gainPainter.width / 2,
            labelY + labelPainter.height + 1,
          ),
        );
      }
    }
  }

  String _fmtGain(double g) {
    if (g == g.truncateToDouble()) return g.toInt().toString();
    var s = g.toStringAsFixed(2);
    while (s.endsWith('0')) { s = s.substring(0, s.length - 1); }
    if (s.endsWith('.')) { s = s.substring(0, s.length - 1); }
    return s;
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.myScores != myScores ||
      old.idealScores != idealScores ||
      old.todayGains != todayGains;
}
