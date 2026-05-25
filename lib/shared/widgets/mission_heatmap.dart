import 'package:flutter/material.dart';

class MissionHeatmap extends StatelessWidget {
  const MissionHeatmap({
    super.key,
    required this.history,
    required this.year,
  });

  final Map<String, int> history;
  final int year;

  static const _cellSize = 11.0;
  static const _gap = 2.5;
  static const _monthNames = [
    '1월', '2월', '3월', '4월', '5월', '6월',
    '7월', '8월', '9월', '10월', '11월', '12월',
  ];
  static const _colors = [
    Color(0xFFEBEBEB), // 0개 — 없음
    Color(0xFFCCE8E8), // 1개 — 매우 연한 teal
    Color(0xFF8EC8C8), // 2개 — 연한 teal
    Color(0xFF4AA8A8), // 3개 — teal
    Color(0xFF208484), // 4개 — 진한 teal
  ];

  @override
  Widget build(BuildContext context) {
    final jan1 = DateTime(year, 1, 1);
    final dec31 = DateTime(year, 12, 31);

    // 해당 연도의 1월 1일이 속한 주의 월요일부터 시작
    final gridStart = jan1.subtract(Duration(days: jan1.weekday - 1));
    // 12월 31일이 속한 주의 일요일로 끝
    final remaining = dec31.weekday == 7 ? 0 : 7 - dec31.weekday;
    final gridEnd = dec31.add(Duration(days: remaining));
    final totalWeeks = gridEnd.difference(gridStart).inDays ~/ 7 + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _buildGrid(gridStart, totalWeeks, jan1, dec31),
        ),
        const SizedBox(height: 6),
        _buildLegend(),
      ],
    );
  }

  Widget _buildGrid(DateTime gridStart, int totalWeeks, DateTime jan1, DateTime dec31) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final columns = <Widget>[];
    String? lastMonthLabel;

    for (int w = 0; w < totalWeeks; w++) {
      final weekStart = gridStart.add(Duration(days: w * 7));

      // 이 주에 1일이 있으면 월 레이블 표시
      String? monthLabel;
      for (int d = 0; d < 7; d++) {
        final day = weekStart.add(Duration(days: d));
        if (day.year == year && day.day == 1) {
          final label = _monthNames[day.month - 1];
          if (label != lastMonthLabel) {
            monthLabel = label;
            lastMonthLabel = label;
          }
          break;
        }
      }

      columns.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 14,
              child: monthLabel != null
                  ? Text(
                      monthLabel,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 9,
                        color: Color(0xFF8D8D8D),
                      ),
                    )
                  : null,
            ),
            for (int d = 0; d < 7; d++) ...[
              _buildCell(weekStart.add(Duration(days: d)), today, jan1, dec31),
              if (d < 6) const SizedBox(height: _gap),
            ],
          ],
        ),
      );

      if (w < totalWeeks - 1) {
        columns.add(const SizedBox(width: _gap));
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columns,
    );
  }

  Widget _buildCell(DateTime date, DateTime today, DateTime jan1, DateTime dec31) {
    final Color color;
    if (date.isBefore(jan1) || date.isAfter(dec31)) {
      // 해당 연도 범위 밖 — 투명
      color = Colors.transparent;
    } else if (date.isAfter(today)) {
      // 미래 날짜 — 빈 셀
      color = _colors[0];
    } else {
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      color = _colors[(history[key] ?? 0).clamp(0, 4)];
    }

    return Container(
      width: _cellSize,
      height: _cellSize,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '적음',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 9,
            color: Color(0xFF8D8D8D),
          ),
        ),
        const SizedBox(width: 3),
        for (final color in _colors)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        const SizedBox(width: 3),
        const Text(
          '많음',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 9,
            color: Color(0xFF8D8D8D),
          ),
        ),
      ],
    );
  }
}
