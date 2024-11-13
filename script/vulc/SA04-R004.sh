#!/bin/bash
# SA04-R004.sh: Kerberos 티켓 만료 시간 설정 스크립트
LANG=ko_KR.utf8
export LANG

# 전달된 인수
smb_conf_path="$1"          # smb.conf 파일 경로

# 1. smb.conf 파일 확인
if [ ! -f "$smb_conf_path" ]; then
    echo "Error: 지정된 smb.conf 파일 ($smb_conf_path)을 찾을 수 없습니다."
    exit 1
fi

echo "smb.conf 파일 위치: $smb_conf_path"

# 2. Kerberos 티켓 만료 시간 설정 확인
ticket_lifetime=$(grep -i "ticket lifetime" "$smb_conf_path" | awk -F'=' '{print $2}' | tr -d ' ')
renew_lifetime=$(grep -i "renewable lifetime" "$smb_conf_path" | awk -F'=' '{print $2}' | tr -d ' ')

# 기본 값 설정 (티켓 만료 시간 10시간, 갱신 만료 시간 7일)
default_ticket_lifetime="10h"
default_renew_lifetime="7d"

# 티켓 만료 시간 확인
if [ -z "$ticket_lifetime" ]; then
    echo "1. 'ticket lifetime' 설정 없음 - 기본값 ($default_ticket_lifetime) 사용 중일 수 있습니다."
    ticket_lifetime_status="취약"
    details="ticket lifetime 설정 없음"
else
    echo "1. 'ticket lifetime' 설정 확인: $ticket_lifetime"
    ticket_lifetime_status="양호"
    details="ticket lifetime 설정 양호"
fi

# 갱신 만료 시간 확인
if [ -z "$renew_lifetime" ]; then
    echo "2. 'renewable lifetime' 설정 없음 - 기본값 ($default_renew_lifetime) 사용 중일 수 있습니다."
    renew_lifetime_status="취약"
    details="$details, renewable lifetime 설정 없음"
else
    echo "2. 'renewable lifetime' 설정 확인: $renew_lifetime"
    renew_lifetime_status="양호"
    details="$details, renewable lifetime 설정 양호"
fi

# 4. 결과 판단 및 출력
if [ "$ticket_lifetime_status" == "양호" ] && [ "$renew_lifetime_status" == "양호" ]; then
    echo "Status: Secure"
    echo "Details: $details"
else
    echo "Status: Vulnerable"
    echo "Details: $details"
fi

