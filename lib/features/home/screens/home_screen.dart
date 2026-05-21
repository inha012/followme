import 'package:flutter/material.dart';
import 'package:follow_me/core/services/prediction_api_service.dart';
import 'package:follow_me/core/services/user_data_service.dart';
import 'package:follow_me/features/daily_prediction/models/prediction_result.dart';
import 'package:follow_me/features/daily_prediction/services/prediction_service.dart';
import 'package:follow_me/features/diary/screens/diary_write_screen.dart';
import 'package:follow_me/features/schedule_input/screens/schedule_tab_screen.dart';
import 'package:follow_me/features/settings/screens/settings_tab_screen.dart';
import 'package:follow_me/shared/widgets/floating_tab_bar.dart';
import 'package:follow_me/shared/widgets/teal_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedTab = 1;
  bool _showTooltip = false;
  List<bool> _missionChecked = [false, false, false, false];

  static final _tooltipGroupId = Object();

  String? _fortune;
  List<Mission> _missions = [];
  bool _isLoading = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadPrediction();
  }

  Future<void> _loadPrediction() async {
    setState(() => _isLoading = true);
    final result = await PredictionService.getToday();
    if (mounted) {
      setState(() {
        _fortune = result?.fortune;
        _missions = result?.missions ?? [];
        if (_missions.length != _missionChecked.length) {
          _missionChecked = List.filled(_missions.length, false);
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (_isGenerating) return;
    setState(() {
      _isGenerating = true;
      _missionChecked = [false, false, false, false];
    });
    await UserDataService.clearTodayGains();
    await PredictionService.generateAndSave();
    await _loadPrediction();
    if (!mounted) return;
    setState(() => _isGenerating = false);
    if (PredictionApiService.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '오류: ${PredictionApiService.lastError}',
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: const Color(0xFFD94C4C),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  bool get _allDone =>
      _missionChecked.isNotEmpty && _missionChecked.every((c) => c);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: FloatingTabBar(
            selectedIndex: _selectedTab,
            onTap: (i) {
              if (i == 0) {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondary) => const ScheduleTabScreen(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              } else if (i == 2) {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondary) => const SettingsTabScreen(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              } else {
                setState(() => _selectedTab = i);
              }
            },
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 33),
              _buildLogo(),
              const SizedBox(height: 24),
              _buildMissionSection(),
              const SizedBox(height: 30),
              _buildFortuneSection(),
              const SizedBox(height: 30),
              Center(child: _buildDiaryButton()),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '(로고)',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 24,
              height: 32 / 24,
              color: Color(0xFF262626),
            ),
          ),
          GestureDetector(
            onTap: _isGenerating ? null : _refresh,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE9F7F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isGenerating
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF208484),
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFF208484),
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '오늘의 미션',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              height: 22 / 16,
              color: Color(0xFF262626),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '완료한 미션을 체크해주세요.',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      height: 22 / 14,
                      color: Color(0xFF6F6F6F),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TapRegion(
                    groupId: _tooltipGroupId,
                    onTapOutside: (_) {
                      if (_showTooltip) setState(() => _showTooltip = false);
                    },
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _showTooltip = !_showTooltip),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 3),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: Color(0xFF8D8D8D),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_showTooltip)
                Positioned(
                  bottom: 26,
                  left: 163,
                  child: TapRegion(
                    groupId: _tooltipGroupId,
                    child: _buildTooltipCard(),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildMissionCard(),
        ),
      ],
    );
  }

  Widget _buildTooltipCard() {
    return Container(
      width: 143,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFDADFE5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '완료한 미션이 쌓일수록\n내 이상향에 가까워져요.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w500,
          fontSize: 12,
          height: 22 / 12,
          color: Color(0xFF262626),
        ),
      ),
    );
  }

  Widget _buildMissionCard() {
    if (_isLoading) {
      return _buildLoadingCard('미션을 생성하고 있어요...');
    }

    final missions = _missions.isNotEmpty
        ? _missions
        : [const Mission(text: '미션을 불러올 수 없습니다.', trait: 0)];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _allDone
                ? const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      '모든 미션을 완료했어요 🎉',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 22 / 14,
                        color: Color(0xFF208484),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          ...List.generate(missions.length, (i) {
            final checked =
                i < _missionChecked.length && _missionChecked[i];
            return Padding(
              padding: EdgeInsets.only(
                  bottom: i < missions.length - 1 ? 8 : 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (i < _missionChecked.length) {
                        final newChecked = !checked;
                        setState(() => _missionChecked[i] = newChecked);
                        final d = newChecked ? 1 : -1;
                        await Future.wait([
                          UserDataService.incrementMissionsDone(d),
                          UserDataService.updateMyScoreForTrait(
                              missions[i].trait, d * 0.25),
                          UserDataService.updateDailyMissionCount(d),
                        ]);
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: checked
                            ? const Color(0xFF208484)
                            : const Color(0xFFF7F7F7),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F000000),
                            blurRadius: 40,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: checked
                            ? Colors.white
                            : const Color(0xFFCCCCCC),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          missions[i].text,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            height: 24 / 14,
                            color: Color(0xFF262626),
                          ),
                        ),
                        if (missions[i].traitLabel.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF208484).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              missions[i].traitLabel,
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                                color: Color(0xFF208484),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFCCE8E8)),
          const SizedBox(height: 16),
          _buildProgressGauge(),
        ],
      ),
    );
  }

  Widget _buildProgressGauge() {
    final total = _missionChecked.length;
    final checkedCount = _missionChecked.where((c) => c).length;
    final percent = total == 0 ? 0.0 : checkedCount / total;
    final percentInt = (percent * 100).round();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (_, value, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '추구미와 가까워지는 중',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    height: 20 / 13,
                    color: Color(0xFF208484),
                  ),
                ),
                Text(
                  '$percentInt%',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 20 / 13,
                    color: Color(0xFF208484),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: const Color(0xFFCCE8E8),
                valueColor:
                    const AlwaysStoppedAnimation(Color(0xFF208484)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFortuneSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '오늘의 운세',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              height: 22 / 16,
              color: Color(0xFF262626),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _isLoading
              ? _buildLoadingCard('운세를 생성하고 있어요...')
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 21, 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F7F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _fortune ?? '운세 정보를 불러올 수 없습니다.',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      height: 24 / 14,
                      color: Color(0xFF262626),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF208484),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Color(0xFF6F6F6F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryButton() {
    return TealButton(
      label: '일기 쓰기',
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DiaryWriteScreen()),
        );
        // 일기 작성 후 돌아오면 예측 갱신 여부 체크
        _loadPrediction();
      },
    );
  }

}
