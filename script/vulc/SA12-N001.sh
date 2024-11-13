#!/bin/bash
# SA12-N001.sh: 접속 IP 및 포트 제한 설정 점검 스크립트
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

# 2. 'hosts allow' 설정 확인
hosts_allow=$(grep -i "hosts allow" "$smb_conf_path" | awk -F'= ' '{print $2}')
if [ -z "$hosts_allow" ]; then
    echo "1. 'hosts allow' 옵션이 설정되어 있지 않습니다. 모든 IP에서 접근할 수 있습니다."
    hosts_allow_status="취약"
    details="hosts allow 설정 없음"
else
    echo "1. 'hosts allow' 설정 확인: $hosts_allow"
    hosts_allow_status="양호"
    details="hosts allow 설정 양호"
fi

# 3. 'interfaces' 및 'bind interfaces only' 설정 확인
interfaces=$(grep -i "^ *interfaces" "$smb_conf_path" | awk -F'= ' '{print $2}')
bind_interfaces=$(grep -i "^ *bind interfaces only" "$smb_conf_path" | awk -F'= ' '{print $2}')

if [ -z "$interfaces" ]; then
    echo "2. 'interfaces' 설정이 없습니다. 모든 네트워크 인터페이스에서 접근이 가능합니다."
    interfaces_status="취약"
    details="$details, interfaces 설정 없음"
else
    echo "2. 'interfaces' 설정 확인: $interfaces"
    interfaces_status="양호"
    details="$details, interfaces 설정 양호"
fi

if [ "$bind_interfaces" != "yes" ]; then
    echo "3. 'bind interfaces only' 옵션이 'yes'로 설정되지 않았습니다."
    bind_interfaces_status="취약"
    details="$details, bind interfaces only 설정 취약"
else
    echo "3. 'bind interfaces only' 설정 확인: $bind_interfaces"
    bind_interfaces_status="양호"
    details="$details, bind interfaces only 설정 양호"
fi

# 4. 결과 판단 및 출력
if [ "$hosts_allow_status" == "양호" ] && [ "$interfaces_status" == "양호" ] && [ "$bind_interfaces_status" == "양호" ]; then
    echo "Status: Secure"
    echo "Details: $details"
else
    echo "Status: Vulnerable"
    echo "Details: $details"
fi

