#!/usr/bin/env bash
# =======================================
# @desc : Docker 및 Docker Compose 배포 환경 구성을 위한 자원 다운로드 스크립트
# =======================================

echo "🚀 [배포 환경 구성] 관련 자원 다운로드를 시작합니다..."
echo "================================================================================"

# 1. Docker 디렉토리 다운로드
echo "📥 [1/2] 'docker' 디렉토리 자원을 가져오는 중입니다..."
git-getpr.sh --git-url https://github.com/parkjunhong --project maven-deploy-config --branch main --resource-type directory --resource docker
echo ""

# 2. Docker Compose 디렉토리 다운로드
echo "📥 [2/2] 'docker-compose' 디렉토리 자원을 가져오는 중입니다..."
git-getpr.sh --git-url https://github.com/parkjunhong --project maven-deploy-config --branch main --resource-type directory --resource docker-compose
echo ""

# 3. 완료 및 안내 메시지 출력
echo "✅ 모든 자원 다운로드가 완료되었습니다!"
echo "================================================================================"
echo "📖 설명에 관한 자세한 사항은 아래 가이드 링크를 확인해 주시기 바랍니다."
echo "🔗 https://gitlab.ymtech.co.kr/parkjunhong-workspaces/thisnthat/blob/main/springproject/guide/deploy/docker-%EB%B0%B0%ED%8F%AC/docker-%EB%B0%B0%ED%8F%AC%EB%B0%A9%EC%8B%9D-%EC%A0%81%EC%9A%A9%EA%B0%80%EC%9D%B4%EB%93%9C.md"
echo "================================================================================"

exit 0

