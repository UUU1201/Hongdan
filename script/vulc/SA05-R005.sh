#!/bin/bash
# SA05-R005.sh: LDAP 인증 보호 설정 점검 스크립트
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

# 2. LDAP 인증 보호 설정 확인
ldap_tls=$(grep -i "ldap ssl" "$smb_conf_path" | awk -F'= ' '{print $2}')
ldap_encryption=$(grep -i "ldap server require strong auth" "$smb_conf_path" | awk -F'= ' '{print $2}')

# LDAP TLS 설정 확인
if [[ "$ldap_tls" == "start_tls" || "$ldap_tls" == "on" ]]; then
    echo "1. 'ldap ssl' 설정 확인: $ldap_tls"
    ldap_tls_status="양호"
    details="ldap ssl 설정 양호"
else
    echo "1. 'ldap ssl' 설정이 누락되어 있습니다."
    ldap_tls_status="취약"
    details="ldap ssl 설정 누락"
fi

# LDAP 서버 강력 인증 요구 설정 확인
if [[ "$ldap_encryption" == "yes" ]]; then
    echo "2. 'ldap server require strong auth' 설정 확인: $ldap_encryption"
    ldap_encryption_status="양호"
    details="$details, ldap server require strong auth 설정 양호"
else
    echo "2. 'ldap server require strong auth' 설정이 누락되어 있습니다."
    ldap_encryption_status="취약"
    details="$details, ldap server require strong auth 설정 누락"
fi

# 3. 결과 판단 및 출력
if [ "$ldap_tls_status" == "양호" ] && [ "$ldap_encryption_status" == "양호" ]; then
    echo "Status: Secure"
    echo "Details: $details"
else
    echo "Status: Vulnerable"
    echo "Details: $details"
fi

