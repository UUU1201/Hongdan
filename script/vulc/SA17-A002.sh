#!/bin/bash
# SA17-A002.sh: 익명 로그인 취약점 점검 스크립트 (smb.conf 파일 점검 방식)

# smb.conf 파일 위치 확인
smb_conf_path="/etc/samba/smb.conf"

# smb.conf 파일이 존재하는지 확인
if [ ! -f "$smb_conf_path" ]; then
    echo "Error: 지정된 smb.conf 파일 ($smb_conf_path)을 찾을 수 없습니다."
    exit 1
fi

# 익명 로그인 관련 설정 점검
guest_ok=$(grep -i "guest ok" "$smb_conf_path" | grep -i "yes")
map_to_guest=$(grep -i "map to guest" "$smb_conf_path" | grep -i "bad user\|always")

# 결과 판단 및 출력
if [ -n "$guest_ok" ] || [ -n "$map_to_guest" ]; then
    echo "Status: Vulnerable"
    echo "Details: 익명 로그인 허용 설정이 감지되었습니다. (guest ok 또는 map to guest 설정)"
else
    echo "Status: Secure"
    echo "Details: 익명 로그인 허용 설정이 없습니다."
fi

# 종료 메시지
echo "[INFO] 점검 완료."

