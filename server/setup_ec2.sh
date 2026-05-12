#!/bin/bash
# FollowMe 서버 EC2 자동 설치 스크립트
# Ubuntu 22.04 LTS (t3.large 이상 권장) 에서 실행
# 사용법: chmod +x setup_ec2.sh && ./setup_ec2.sh

set -e
echo "====== FollowMe 서버 설치 시작 ======"

# 1. 시스템 업데이트
echo "[1/6] 시스템 업데이트..."
sudo apt-get update -y && sudo apt-get upgrade -y

# 2. Python 3.11 + pip 설치
echo "[2/6] Python 설치..."
sudo apt-get install -y python3.11 python3.11-venv python3-pip curl git

# 3. Ollama 설치 + 모델 다운로드
echo "[3/6] Ollama 설치..."
curl -fsSL https://ollama.ai/install.sh | sh

# Ollama를 백그라운드로 시작하고 모델 pull
sudo systemctl enable ollama
sudo systemctl start ollama
sleep 5
echo "  gemma3:1b 모델 다운로드 중 (약 815MB)..."
ollama pull gemma3:1b

# 4. FastAPI 서버 의존성 설치
echo "[4/6] Python 패키지 설치..."
cd ~/followme-server 2>/dev/null || mkdir -p ~/followme-server && cd ~/followme-server
python3.11 -m venv venv
source venv/bin/activate
pip install fastapi==0.115.0 uvicorn[standard]==0.30.6 httpx==0.27.2 pydantic==2.9.2 python-dotenv==1.0.1

# 5. systemd 서비스 등록 (서버 재시작 시 자동 실행)
echo "[5/6] 서비스 등록..."
sudo tee /etc/systemd/system/followme.service > /dev/null <<EOF
[Unit]
Description=FollowMe FastAPI Server
After=network.target ollama.service

[Service]
User=$USER
WorkingDirectory=$HOME/followme-server
ExecStart=$HOME/followme-server/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5
EnvironmentFile=$HOME/followme-server/.env

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable followme

echo "[6/6] 설치 완료!"
echo ""
echo "====== 다음 단계 ======"
echo "1. main.py, .env 파일을 ~/followme-server/ 에 업로드하세요"
echo "   scp server/main.py ubuntu@<EC2_IP>:~/followme-server/"
echo "   scp server/.env   ubuntu@<EC2_IP>:~/followme-server/"
echo ""
echo "2. 서버 시작:"
echo "   sudo systemctl start followme"
echo ""
echo "3. 서버 상태 확인:"
echo "   sudo systemctl status followme"
echo "   curl http://localhost:8000/health"
echo ""
echo "4. EC2 보안 그룹에서 포트 8000 (TCP) 인바운드 허용 필요"
