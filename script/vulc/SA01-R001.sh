#!/bin/bash
# SA01-R001.sh: Samba AD 원격 접속 제한 점검 스크립트
LANG=ko_KR.utf8
export LANG


# 전달된 인수
smb_conf_path="$1"         # smb.conf 파일 경로
hosts_allow_value="$2"      # 허용된 hosts allow 설정 값
admin_invalid_value="$3"    # 'invalid users'에 포함되어야 할 사용자 이름 (예: administrator)

# 1. smb.conf 파일 확인
if [ ! -f "$smb_conf_path" ]; then
    echo "Error: 지정된 smb.conf 파일 ($smb_conf_path)을 찾을 수 없습니다."
    exit 1
fi

echo "smb.conf 파일 위치: $smb_conf_path"

# 2. hosts allow 설정 확인
hosts_allow=$(grep -i "hosts allow" "$smb_conf_path")
if [ -z "$hosts_allow" ]; then
    echo "1. 'hosts allow' 옵션이 설정되어 있지 않습니다."
    hosts_allow_status="취약"
    details="hosts allow 설정 없음"
else
    echo "1. 'hosts allow' 설정 확인:"
    echo "$hosts_allow"
    if [[ "$hosts_allow" == *"$hosts_allow_value"* ]]; then
        hosts_allow_status="양호"
        details="hosts allow 설정 양호"
    else
        hosts_allow_status="취약"
        details="hosts allow 설정 취약"
    fi
fi

# 3. 'invalid users'에 administrator 설정 확인
admin_invalid=$(grep -i "invalid users" "$smb_conf_path" | grep -i "$admin_invalid_value")
if [ -z "$admin_invalid" ]; then
    echo "2. 'invalid users' 옵션에 '$admin_invalid_value' 설정이 없습니다."
    admin_invalid_status="취약"
    details="$details, invalid users 설정 취약"
else
    echo "2. 'invalid users'에 '$admin_invalid_value' 설정 확인:"
    echo "$admin_invalid"
    admin_invalid_status="양호"
    details="$details, invalid users 설정 양호"
fi

# 4. 결과 판단 및 출력
if [ "$hosts_allow_status" == "양호" ] && [ "$admin_invalid_status" == "양호" ]; then
    echo "Status: Secure"
    echo "Details: $details"
else
    echo "Status: Vulnerable"
    echo "Details: $details"
fi

