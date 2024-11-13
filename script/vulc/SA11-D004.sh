#!/bin/bash
# SA11-D004.sh: /etc/hosts 파일 권한 점검 스크립트
LANG=ko_KR.utf8
export LANG

# /etc/hosts 파일 위치 확인
hosts_file="/etc/hosts"

# 1. /etc/hosts 파일 존재 여부 확인
if [ ! -f "$hosts_file" ]; then
    echo "Error: /etc/hosts 파일을 찾을 수 없습니다."
    exit 1
fi

echo "/etc/hosts 파일 위치: $hosts_file"

# 2. /etc/hosts 파일 권한 및 소유자 확인
permissions=$(stat -c "%a" "$hosts_file")
owner=$(stat -c "%U" "$hosts_file")
group=$(stat -c "%G" "$hosts_file")

echo "=== 2. /etc/hosts 파일 권한 및 소유자 확인 ==="
echo "/etc/hosts 파일 권한: $permissions, 소유자: $owner, 그룹: $group"

# 권한 확인
if [ "$permissions" -le 644 ]; then
    permissions_status="양호"
    details="/etc/hosts 파일 권한 설정 양호 (권한: $permissions)"
else
    permissions_status="취약"
    details="/etc/hosts 파일 권한 설정 취약 (권한: $permissions)"
fi

# 소유자 및 그룹 확인
if [ "$owner" == "root" ] && [ "$group" == "root" ]; then
    owner_group_status="양호"
    details="$details, /etc/hosts 파일 소유자 및 그룹 설정 양호"
else
    owner_group_status="취약"
    details="$details, /etc/hosts 파일 소유자 또는 그룹 설정 취약 - 소유자 또는 그룹이 root가 아님"
fi

# 3. 결과 판단 및 출력
if [ "$permissions_status" == "양호" ] && [ "$owner_group_status" == "양호" ]; then
    echo "Status: Secure"
    echo "Details: $details"
else
    echo "Status: Vulnerable"
    echo "Details: $details"
fi

