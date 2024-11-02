#!/bin/bash
# SA01-R001.sh: Samba AD 원격 접속 제한 점검 스크립트

# 1. smb.conf 파일 위치 확인
smb_conf_path=""
if [ -f /etc/samba/smb.conf ]; then
    smb_conf_path="/etc/samba/smb.conf"
else
    smb_conf_path=$(find / -name smb.conf 2>/dev/null | head -n 1)
    if [ -z "$smb_conf_path" ]; then
        echo "Error: smb.conf 파일을 찾을 수 없습니다."
        exit 1
    fi
fi

echo "smb.conf 파일 위치: $smb_conf_path"

# 2. hosts allow 설정 확인
hosts_allow=$(grep -i "hosts allow" "$smb_conf_path")
if [ -z "$hosts_allow" ]; then
    echo "1. 'hosts allow' 옵션이 설정되어 있지 않습니다."
else
    echo "1. 'hosts allow' 설정 확인:"
    echo "$hosts_allow"
fi

# 3. 'invalid users'에 administrator 설정 확인
admin_invalid=$(grep -i "invalid users" "$smb_conf_path" | grep -i "administrator")
if [ -z "$admin_invalid" ]; then
    echo "2. 'invalid users' 옵션에 'administrator' 설정이 없습니다."
else
    echo "2. 'invalid users'에 'administrator' 설정 확인:"
    echo "$admin_invalid"
fi

# 4. 결과 판단
if [ -n "$hosts_allow" ] && [ -n "$admin_invalid" ]; then
    echo "결과: 양호 - 관리자 계정이 원격으로 접속할 수 없도록 설정 또는 제한된 방법(SMB over VPN 등)으로만 접속이 허용됨."
else
    echo "결과: 취약 - 관리자 계정(Administrator) 원격 접속 허용되어 있음."
fi
