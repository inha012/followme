class AppConstants {
  // ── FastAPI 서버 URL ───────────────────────────────────────────────────────
  // 개발(Mac): 'http://192.168.0.151:8000'
  // EC2 배포 후: 'http://<EC2_PUBLIC_IP>:8000'
  static const serverBaseUrl = 'http://192.168.0.151:8000';

  // ── Ollama 직접 연결 (레거시 / 로컬 테스트용) ──────────────────────────────
  static const ollamaBaseUrl = 'http://192.168.0.151:11434';
  static const ollamaModel = 'gemma3:1b';
}
