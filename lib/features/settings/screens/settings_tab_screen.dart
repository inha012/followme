import 'package:flutter/material.dart';
import 'package:follow_me/core/services/user_data_service.dart';
import 'package:follow_me/core/utils/personality_type_utils.dart';
import 'package:follow_me/features/onboarding/screens/personality_questions.dart';
import 'package:follow_me/features/onboarding/screens/personality_test_screen.dart';
import 'package:follow_me/features/settings/screens/personality_detail_screen.dart';
import 'package:follow_me/features/settings/screens/settings_personality_result_screen.dart';
import 'package:follow_me/shared/widgets/floating_tab_bar.dart';
import 'package:follow_me/shared/widgets/mission_heatmap.dart';
import 'package:follow_me/shared/widgets/personality_radar_chart.dart';

class SettingsTabScreen extends StatefulWidget {
  const SettingsTabScreen({super.key});

  @override
  State<SettingsTabScreen> createState() => _SettingsTabScreenState();
}

class _SettingsTabScreenState extends State<SettingsTabScreen> {
  String _userName = '';
  String? _gender;
  List<int> _myScores = [];
  List<int> _idealScores = [];
  Map<int, double> _todayGains = {};
  Map<String, int> _missionHistory = {};
  int _selectedYear = DateTime.now().year;
  bool _isLoading = true;

  static const _traitLabels = ['모험적', '사색적', '외향적', '주도적', '다정함', '논리적'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      UserDataService.getName(),
      UserDataService.getGender(),
      UserDataService.getMyScores(),
      UserDataService.getIdealScores(),
      UserDataService.getTodayScoreGains(),
      UserDataService.getMissionHistory(),
    ]);
    if (mounted) {
      setState(() {
        _userName = (results[0] as String?) ?? '';
        _gender = results[1] as String?;
        _myScores = (results[2] as List<double>).map((e) => e.round()).toList();
        _idealScores = results[3] as List<int>;
        _todayGains = results[4] as Map<int, double>;
        _missionHistory = results[5] as Map<String, int>;
        _isLoading = false;
      });
    }
  }

  void _retakeMyPersonality() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PersonalityTestScreen(
        title: '지금 성향 검사',
        subtitle: '성향을 분석할게요.',
        accentColor: const Color(0xFF208484),
        cardBgColor: const Color(0xFFE9F7F7),
        questions: kPersonalityQuestions,
        showExitConfirm: true,
        onComplete: (scores) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => SettingsPersonalityResultScreen(
              isIdeal: false,
              scores: scores,
              gender: _gender,
              onDone: () {
                setState(() => _myScores = scores);
              },
            ),
          ));
        },
      ),
    ));
  }

  void _retakeIdealPersonality() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PersonalityTestScreen(
        title: '이상향 검사',
        subtitle: "추구하는 모습을 선택해주세요.",
        accentColor: const Color(0xFFEEC22A),
        cardBgColor: const Color(0xFFFEF6DA),
        questions: kIdealQuestions,
        showExitConfirm: true,
        onComplete: (scores) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => SettingsPersonalityResultScreen(
              isIdeal: true,
              scores: scores,
              gender: _gender,
              onDone: () {
                setState(() => _idealScores = scores);
              },
            ),
          ));
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF208484)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 33),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        '설정',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          height: 32 / 24,
                          color: Color(0xFF262626),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // ── 프로필 카드 ──────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 아바타
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFE9F7F7),
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 44,
                                color: Color(0xFF208484),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // 이름
                            Text(
                              _userName,
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Color(0xFF262626),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // 육각형 레이더 차트
                            PersonalityRadarChart(
                              myScores: _myScores,
                              idealScores: _idealScores,
                              todayGains: _todayGains,
                            ),
                            const SizedBox(height: 10),
                            // 범례
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF208484),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '지금 성향',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 11,
                                    color: Color(0xFF6F6F6F),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFEEC22A),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '이상향',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 11,
                                    color: Color(0xFF6F6F6F),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // 두 성향 알약
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      const Text(
                                        '지금 성향',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12,
                                          color: Color(0xFF8D8D8D),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => PersonalityDetailScreen(
                                              isIdeal: false,
                                              scores: _myScores,
                                              gender: _gender,
                                            ),
                                          ),
                                        ),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 11),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE9F7F7),
                                            borderRadius:
                                                BorderRadius.circular(100),
                                          ),
                                          child: Center(
                                            child: Text(
                                              _myScores.isEmpty
                                                  ? '-'
                                                  : classifyPersonality(
                                                      _myScores,
                                                      gender: _gender,
                                                    ).name,
                                              style: const TextStyle(
                                                fontFamily: 'Pretendard',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: Color(0xFF208484),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    children: [
                                      const Text(
                                        '이상향',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12,
                                          color: Color(0xFF8D8D8D),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => PersonalityDetailScreen(
                                              isIdeal: true,
                                              scores: _idealScores,
                                              gender: _gender,
                                            ),
                                          ),
                                        ),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 11),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF6DA),
                                            borderRadius:
                                                BorderRadius.circular(100),
                                          ),
                                          child: Center(
                                            child: Text(
                                              _idealScores.isEmpty
                                                  ? '-'
                                                  : classifyPersonality(
                                                      _idealScores,
                                                      gender: _gender,
                                                    ).name,
                                              style: const TextStyle(
                                                fontFamily: 'Pretendard',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: Color(0xFFB8920E),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // ── 활동 기록 히트맵 ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '미션 기록',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF262626),
                                  ),
                                ),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => setState(
                                          () => _selectedYear--),
                                      child: const Icon(
                                        Icons.chevron_left,
                                        size: 18,
                                        color: Color(0xFF6F6F6F),
                                      ),
                                    ),
                                    Text(
                                      '$_selectedYear',
                                      style: const TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                        color: Color(0xFF444444),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _selectedYear <
                                              DateTime.now().year
                                          ? () => setState(
                                              () => _selectedYear++)
                                          : null,
                                      child: Icon(
                                        Icons.chevron_right,
                                        size: 18,
                                        color: _selectedYear <
                                                DateTime.now().year
                                            ? const Color(0xFF6F6F6F)
                                            : const Color(0xFFCCCCCC),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            MissionHeatmap(
                              history: _missionHistory,
                              year: _selectedYear,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // ── 재검사 링크 ──────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _RetakeTextButton(
                            label: '성향 분석 다시 하기',
                            onTap: _retakeMyPersonality,
                          ),
                          const SizedBox(width: 16),
                          _RetakeTextButton(
                            label: '이상향 설정 다시 하기',
                            onTap: _retakeIdealPersonality,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _RetakeTextButton extends StatelessWidget {
  const _RetakeTextButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w400,
          fontSize: 12,
          color: Color(0xFFAAAAAA),
          decoration: TextDecoration.underline,
          decorationColor: Color(0xFFAAAAAA),
        ),
      ),
    );
  }
}
