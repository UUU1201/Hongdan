#!/bin/bash
# SA06-R006.sh: SMB 서명 활성화 설정 점검 스크립트
LANG=ko_KR.utf8
export LANG

# 전달된 인수
smb_conf_path="$1"         # smb.conf 파일 경로

# 1. smb.conf 파일 확인
if [ ! -f "$smb_conf_path" ]; then
    echo "Error: 지정된 smb.conf 파일 ($smb_conf_path)을 찾을 수 없습니다."
    exit 1
fi

echo "smb.conf 파일 위치: $smb_conf_path"

# 2. 'server signing' 설정 확인
server_signing=$(grep -i "server signing" "$smb_conf_path" | awk -F'= ' '{print $2}' | tr -d ' ')

# SMB 서명 설정 확인
if [[ "$server_signing" == "mandatory" || "$server_signing" == "auto" ]]; then
    echo "1. 'server signing' 설정 확인: $server_signing"
    server_signing_status="양호"
    details="server signing 설정 양호"
else
    echo "1. 'server signing' 설정이 누락되어 있습니다."
    server_signing_status="취약"
    details="server signing 설정 누락"
fi

# 3. 결과 판단 및 출력
if [ "$server_signing_status" == "양호" ]; then
    echo "Status: Secure"
    echo "Details: $details"
else
    echo "Status: Vulnerable"
    echo "Details: $details"
fi
