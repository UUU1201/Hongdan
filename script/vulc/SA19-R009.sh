#!/bin/bash
# SA16-A001.sh: DCE/RPC 조각 주입 취약성 방지를 위한 Samba 설정 점검 스크립트
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

# 2. DCE/RPC 취약성 완화 설정 확인
echo "=== 2. Samba 보안 설정 점검 ==="

# client ipc signing 설정 확인
client_ipc_signing=$(grep -i "client ipc signing" "$smb_conf_path" | awk -F'= ' '{print $2}' | xargs)
if [[ "$client_ipc_signing" == "auto" || "$client_ipc_signing" == "mandatory" ]]; then
    client_ipc_status="양호"
    details="client ipc signing 설정 양호 ($client_ipc_signing)"
else
    client_ipc_status="취약"
    details="client ipc signing 설정 필요 - 권장 설정은 'auto' 또는 'mandatory'"
fi

# server signing 설정 확인
server_signing=$(grep -i "server signing" "$smb_conf_path" | awk -F'= ' '{print $2}' | xargs)
if [[ "$server_signing" == "mandatory" ]]; then
    server_signing_status="양호"
    details="$details, server signing 설정 양호 ($server_signing)"
else
    server_signing_status="취약"
    details="$details, server signing 설정 필요 - 권장 설정은 'mandatory'"
fi

# restrict anonymous 설정 확인
restrict_anonymous=$(grep -i "restrict anonymous" "$smb_conf_path" | awk -F'= ' '{print $2}' | xargs)
if [[ "$restrict_anonymous" == "2" ]]; then
    restrict_anonymous_status="양호"
    details="$details, restrict anonymous 설정 양호 ($restrict_anonymous)"
else
    restrict_anonymous_status="취약"
    details="$details, restrict anonymous 설정 필요 - 권장 설정은 '2'"
fi

# 3. 결과 판단 및 출력
if [ "$client_ipc_status" == "양호" ] && [ "$server_signing_status" == "양호" ] && [ "$restrict_anonymous_status" == "양호" ]; then
    echo "Status: Secure"
    echo "Details: $details"
else
    echo "Status: Vulnerable"
    echo "Details: $details"
fi

