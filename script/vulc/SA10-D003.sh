#!/bin/bash
# SA10-D003.sh: Samba 설정 파일 권한 점검 스크립트
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

# 2. smb.conf 파일 권한 확인
permissions=$(stat -c "%a" "$smb_conf_path")
owner=$(stat -c "%U" "$smb_conf_path")

echo "=== 2. smb.conf 파일 권한 및 소유자 확인 ==="
echo "smb.conf 파일 권한: $permissions, 소유자: $owner"

# 권한 확인
if [ "$permissions" -le 640 ]; then
    permissions_status="양호"
    details="smb.conf 파일 권한 설정 양호 (권한: $permissions)"
else
    permissions_status="취약"
    details="smb.conf 파일 권한 설정 취약 (권한: $permissions)"
fi

# 소유자 확인
if [ "$owner" == "root" ]; then
    owner_status="양호"
    details="$details, smb.conf 파일 소유자 설정 양호"
else
    owner_status="취약"
    details="$details, smb.conf 파일 소유자 설정 취약 - 소유자가 root가 아님"
fi

# 3. 결과 판단 및 출력
if [ "$permissions_status" == "양호" ] && [ "$owner_status" == "양호" ]; then
    echo "Status: Secure"
    echo "Details: $details"
else
    echo "Status: Vulnerable"
    echo "Details: $details"
fi

