import json
import os
import re
from datetime import datetime, timedelta
from typing import List, Optional

import httpx
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="FollowMe Prediction API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── 환경변수 ───────────────────────────────────────────────────────────────────
LLM_PROVIDER = os.getenv("LLM_PROVIDER", "ollama")   # "ollama" | "openai"

OLLAMA_URL   = os.getenv("OLLAMA_URL",   "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "gemma3:1b")

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
OPENAI_MODEL   = os.getenv("OPENAI_MODEL",   "gpt-4o-mini")

WEATHER_API_KEY = os.getenv("WEATHER_API_KEY", "")
WEATHER_CITY    = os.getenv("WEATHER_CITY", "Seoul")

DAY_LABELS = ["월", "화", "수", "목", "금", "토", "일"]

# ── 요청/응답 스키마 ───────────────────────────────────────────────────────────
class ScheduleEntry(BaseModel):
    name: str
    dayIndex: int
    startHour: int
    startMinute: int
    endHour: int
    endMinute: int

class PredictRequest(BaseModel):
    birthdate: Optional[str] = None
    gender: Optional[str] = None
    my_scores: Optional[List[int]] = []
    ideal_scores: Optional[List[int]] = []
    schedule: Optional[List[ScheduleEntry]] = []
    diary: Optional[str] = None

class PredictResponse(BaseModel):
    fortune: str
    missions: List[str]

# ── 날씨 조회 ──────────────────────────────────────────────────────────────────
async def get_tomorrow_weather() -> str:
    if not WEATHER_API_KEY:
        return "날씨 정보 없음 (API 키 미설정)"
    try:
        tomorrow = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
        async with httpx.AsyncClient() as client:
            r = await client.get(
                "https://api.openweathermap.org/data/2.5/forecast",
                params={"q": WEATHER_CITY, "appid": WEATHER_API_KEY,
                        "lang": "kr", "units": "metric"},
                timeout=10,
            )
        if r.status_code != 200:
            return "날씨 정보를 가져올 수 없습니다."
        items = r.json().get("list", [])
        best = None
        for item in items:
            if item["dt_txt"].startswith(tomorrow):
                best = item
                if "12:00" in item["dt_txt"]:
                    break
        if not best:
            return "내일 날씨 정보 없음"
        desc     = best["weather"][0]["description"]
        temp     = round(best["main"]["temp"])
        temp_min = round(best["main"]["temp_min"])
        temp_max = round(best["main"]["temp_max"])
        return f"{desc}, 기온 {temp}°C (최저 {temp_min}°C / 최고 {temp_max}°C)"
    except Exception:
        return "날씨 정보를 가져올 수 없습니다."

# ── 프롬프트 조립 ──────────────────────────────────────────────────────────────
def build_prompt(req: PredictRequest, weather: str) -> str:
    birthdate_str = req.birthdate or "정보 없음"
    gender_str = "남성" if req.gender == "M" else ("여성" if req.gender == "F" else "정보 없음")
    my_avg    = f"{sum(req.my_scores)/len(req.my_scores):.1f}"    if req.my_scores    else "-"
    ideal_avg = f"{sum(req.ideal_scores)/len(req.ideal_scores):.1f}" if req.ideal_scores else "-"

    if req.schedule:
        schedule_str = "\n".join(
            f"{DAY_LABELS[e.dayIndex]}요일 "
            f"{e.startHour:02d}:{e.startMinute:02d} - "
            f"{e.endHour:02d}:{e.endMinute:02d} {e.name}"
            for e in req.schedule
        )
    else:
        schedule_str = "등록된 고정 일정 없음"

    diary_section = f"\n오늘의 일기:\n{req.diary}" if req.diary else ""

    return f"""아래 정보를 바탕으로 내일의 운세와 미션을 한국어로 생성하세요.

사용자 정보:
- 생년월일: {birthdate_str}
- 성별: {gender_str}
- 현재 성향 점수 평균 (1-5점): {my_avg}
- 이상향 성향 점수 평균 (1-5점): {ideal_avg}

내일 날씨: {weather}

주간 고정 일정:
{schedule_str}{diary_section}

반드시 아래 JSON 형식만 출력하세요 (다른 설명 없이):
{{"fortune":"운세를 2~3문장으로 작성","missions":["미션1","미션2","미션3","미션4"]}}"""

# ── JSON 파싱 공통 ─────────────────────────────────────────────────────────────
def parse_llm_response(raw: str) -> dict:
    match = re.search(r"\{[\s\S]*\}", raw)
    if match:
        try:
            data     = json.loads(match.group(0))
            fortune  = data.get("fortune", "")
            missions = data.get("missions", [])
            if fortune and len(missions) == 4:
                return {"fortune": fortune, "missions": missions}
        except json.JSONDecodeError:
            pass
    return {
        "fortune": "오늘도 차분하게 하루를 시작해보세요. 작은 것에 집중하다 보면 큰 흐름이 만들어집니다.",
        "missions": ["물 8잔 마시기", "10분 산책하기", "감사한 일 3가지 적기", "일찍 자기"],
    }

# ── Ollama 호출 ────────────────────────────────────────────────────────────────
async def call_ollama(prompt: str) -> dict:
    async with httpx.AsyncClient() as client:
        r = await client.post(
            f"{OLLAMA_URL}/api/generate",
            json={"model": OLLAMA_MODEL, "prompt": prompt, "stream": False},
            timeout=180,
        )
        r.raise_for_status()
    return parse_llm_response(r.json().get("response", ""))

# ── OpenAI 호출 ────────────────────────────────────────────────────────────────
async def call_openai(prompt: str) -> dict:
    if not OPENAI_API_KEY:
        raise ValueError("OPENAI_API_KEY 환경변수가 설정되지 않았습니다.")
    async with httpx.AsyncClient() as client:
        r = await client.post(
            "https://api.openai.com/v1/chat/completions",
            headers={"Authorization": f"Bearer {OPENAI_API_KEY}",
                     "Content-Type": "application/json"},
            json={
                "model": OPENAI_MODEL,
                "messages": [{"role": "user", "content": prompt}],
                "temperature": 0.8,
            },
            timeout=60,
        )
        r.raise_for_status()
    raw = r.json()["choices"][0]["message"]["content"]
    return parse_llm_response(raw)

# ── 엔드포인트 ─────────────────────────────────────────────────────────────────
@app.get("/health")
async def health():
    return {"status": "ok", "provider": LLM_PROVIDER,
            "model": OPENAI_MODEL if LLM_PROVIDER == "openai" else OLLAMA_MODEL}

@app.post("/predict", response_model=PredictResponse)
async def predict(req: PredictRequest):
    try:
        weather = await get_tomorrow_weather()
        prompt  = build_prompt(req, weather)
        result  = await call_openai(prompt) if LLM_PROVIDER == "openai" \
                  else await call_ollama(prompt)
        return PredictResponse(**result)
    except httpx.RequestError as e:
        raise HTTPException(status_code=503, detail=f"LLM 연결 실패: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
