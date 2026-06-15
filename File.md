# follow_me

## 프로젝트 개요

사용자의 페르소나와 삶의 패턴을 학습하여 미래를 시뮬레이션하는 **개인화 예측 AI 서비스 앱**.

사용자의 성향·일정·행동 패턴을 바탕으로 내일을 예측하고, 이상향에 가까워지도록 미션을 제공하며, 예측과 실제를 비교해 AI가 스스로 보정한다.

---

## 주요 플로우

| 단계 | 이름 | 설명 |
|------|------|------|
| 1 | **Onboarding** | MBTI, 인성검사, 가치관 조사로 사용자 성향 및 이상향 파악 |
| 2 | **Context Ingestion** | 일주일 고정 일정(시간표) 입력 |
| 3 | **Daily Prediction & Mission** | 내일 예측 브리핑 + 이상향에 가까워지는 미션 제공 |
| 4 | **Actual Report & Diary** | 일기·회고 기록 & 미션 달성 여부 체크 |
| 5 | **Self-Correction** | 예측 vs 실제 비교 후 AI 보정 |

---

## 기술 스택

### 프론트엔드
- **Flutter** (iOS / Android 타겟)
- 상태관리: **TBD**
- 라우팅: **TBD**

### 백엔드
- Python
- RAG (Retrieval-Augmented Generation)
- Vector DB: FAISS / Chroma

### 외부 API
- OpenAI API
- OpenWeatherMap API

---

## 현재 작업 범위

> **Figma 디자인을 Flutter UI로 구현하는 단계.**
> 백엔드 연동·상태관리·라우팅은 이후 단계에서 결정.

---

## 권장 폴더 구조

```
lib/
├── main.dart                    # 앱 진입점
│
├── core/                        # 앱 전반에서 공유하는 기반 코드
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── app_sizes.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       └── extensions.dart
│
├── features/                    # 기능 단위 모듈 (플로우별 1:1 대응)
│   ├── onboarding/              # 플로우 1: MBTI·인성검사·가치관
│   │   ├── screens/
│   │   └── widgets/
│   │
│   ├── schedule_input/          # 플로우 2: 주간 고정 일정 입력
│   │   ├── screens/
│   │   └── widgets/
│   │
│   ├── daily_prediction/        # 플로우 3: 내일 예측 브리핑 & 미션
│   │   ├── screens/
│   │   └── widgets/
│   │
│   ├── diary/                   # 플로우 4: 일기·회고·미션 체크
│   │   ├── screens/
│   │   └── widgets/
│   │
│   └── self_correction/         # 플로우 5: 예측 vs 실제 비교
│       ├── screens/
│       └── widgets/
│
└── shared/                      # 여러 feature에서 재사용하는 위젯·모델
    ├── widgets/                 # 공통 UI 컴포넌트 (버튼, 카드 등)
    └── models/                  # 공통 데이터 모델
```

### 구조 원칙
- **feature 폴더 = 플로우 단위**: 각 플로우는 독립적인 폴더로 관리한다.
- **screens vs widgets 분리**: 화면 전체는 `screens/`, 화면 내 재사용 컴포넌트는 `widgets/`.
- **core vs shared**: `core`는 테마·상수 등 설정성 코드, `shared`는 실제 재사용 위젯·모델.
- 상태관리 방식이 결정되면 각 feature 안에 `viewmodels/` 또는 `providers/` 추가.
