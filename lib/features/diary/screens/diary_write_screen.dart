import 'package:flutter/material.dart';
import 'package:follow_me/core/services/prediction_api_service.dart';
import 'package:follow_me/features/diary/data/diary_database.dart';
import 'package:follow_me/features/diary/models/diary_entry.dart';
import 'package:follow_me/shared/widgets/teal_button.dart';

class DiaryWriteScreen extends StatefulWidget {
  const DiaryWriteScreen({super.key, this.date});

  /// 특정 날짜의 일기를 작성할 때 지정. null이면 오늘 날짜로 저장.
  final DateTime? date;

  @override
  State<DiaryWriteScreen> createState() => _DiaryWriteScreenState();
}

class _DiaryWriteScreenState extends State<DiaryWriteScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleClose() async {
    if (_controller.text.trim().isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(
            '일기 작성 취소',
            style: TextStyle(
                fontFamily: 'Pretendard', fontWeight: FontWeight.w700),
          ),
          content: const Text(
            '지금까지 쓴 일기가 사라져요.',
            style: TextStyle(fontFamily: 'Pretendard'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('취소',
                  style: TextStyle(color: Color(0xFF6F6F6F))),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('확인',
                  style: TextStyle(color: Color(0xFF208484))),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) Navigator.of(context).pop();
    } else {
      Navigator.of(context).pop();
    }
  }

  String _formatDate(DateTime d) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${d.year}년 ${d.month}월 ${d.day}일 (${weekdays[d.weekday - 1]})';
  }

  @override
  Widget build(BuildContext context) {
    final targetDate = widget.date;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleClose();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 33),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '일기 쓰기',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        height: 32 / 24,
                        color: Color(0xFF262626),
                      ),
                    ),
                    GestureDetector(
                      onTap: _handleClose,
                      child: const Icon(
                        Icons.close,
                        size: 24,
                        color: Color(0xFF6F6F6F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  targetDate != null
                      ? _formatDate(targetDate)
                      : '자세히 쓸 수록 앞으로 제공되는 운세의 정확도가 높아져요.',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 22 / 14,
                    color: Color(0xFF6F6F6F),
                  ),
                ),
              ),
              const SizedBox(height: 33),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 300,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F7F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      height: 24 / 14,
                      color: Color(0xFF222222),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '오늘 하루를 기록해보세요.',
                      hintStyle: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        height: 24 / 14,
                        color: Color(0xFF8D8D8D),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TealButton(
                  label: '완료',
                  onTap: () async {
                    final text = _controller.text.trim();
                    if (text.isEmpty) return;
                    final date = targetDate ?? DateTime.now();
                    await DiaryDatabase.insert(
                      DiaryEntry(text: text, createdAt: date),
                    );
                    PredictionApiService.syncDiary(text, date);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
