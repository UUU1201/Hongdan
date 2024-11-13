#!/bin/bash
# SA15-S001.sh: Samba 서비스 최신 보안 패치 적용 여부 점검 스크립트
LANG=ko_KR.utf8
export LANG

# 1. Samba 버전 확인
samba_version=$(smbd --version 2>/dev/null | awk '{print $2}')
if [ -z "$samba_version" ]; then
    echo "Error: Samba가 설치되어 있지 않거나 버전을 확인할 수 없습니다."
    status="Unknown"
    details="Samba 버전을 확인할 수 없습니다."
    echo "Status: $status"
    echo "Details: $details"
    exit 0
fi

echo "현재 Samba 버전: $samba_version"

# 2. 최신 안정 Samba 버전 확인 (인터넷 연결 필요)
if ! command -v curl &> /dev/null; then
    echo "Error: curl 명령을 찾을 수 없습니다. curl을 설치하고 다시 시도하세요."
    status="Unknown"
    details="curl 명령을 사용할 수 없어 최신 버전을 확인할 수 없습니다."
    echo "Status: $status"
    echo "Details: $details"
    exit 0
fi

latest_version=$(curl -s https://download.samba.org/pub/samba/stable/ | grep -oP 'samba-\K[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -1)
if [ -z "$latest_version" ]; then
    echo "Error: 최신 안정 Samba 버전을 확인할 수 없습니다. 인터넷 연결 또는 Samba 공식 사이트를 확인하세요."
    status="Unknown"
    details="최신 Samba 버전을 확인할 수 없습니다."
    echo "Status: $status"
    echo "Details: $details"
    exit 0
fi

echo "최신 안정 Samba 버전: $latest_version"

# 3. 버전 비교 및 결과 판단
if [ "$samba_version" == "$latest_version" ]; then
    echo "결과: 양호 - Samba가 최신 버전으로 업데이트되어 있습니다."
    status="Secure"
    details="Samba가 최신 버전으로 업데이트되어 있음 (버전: $samba_version)"
else
    echo "결과: 취약 - Samba가 최신 버전이 아닙니다. 보안 패치를 위해 Samba를 $latest_version 버전으로 업데이트하는 것이 좋습니다."
    status="Vulnerable"
    details="Samba가 최신 버전이 아님 (현재 버전: $samba_version, 최신 버전: $latest_version)"
fi

# 4. 최종 결과 출력
echo "Status: $status"
echo "Details: $details"

