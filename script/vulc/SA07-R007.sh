#!/bin/bash
# SA07-R007.sh: RC4 및 NTLM 설정 점검 스크립트
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

# 2. NTLM 인증 설정 확인
ntlm_setting=$(grep -i "ntlm auth" "$smb_conf_path")
if [ -z "$ntlm_setting" ]; then
    echo "1. NTLM 인증 설정 없음 - 기본적으로 비활성화되어 있을 수 있습니다."
    ntlm_status="양호"
    details="NTLM 인증 설정 없음"
else
    echo "1. NTLM 인증 설정 확인:"
    echo "$ntlm_setting"
    if [[ "$ntlm_setting" == *"no"* ]]; then
        ntlm_status="양호"
        details="NTLM 인증 설정 비활성화"
    else
        ntlm_status="취약"
        details="NTLM 인증 설정 활성화"
    fi
fi

# 3. RC4 암호화 설정 확인
rc4_setting=$(grep -i "client ipc signing" "$smb_conf_path")
if [ -z "$rc4_setting" ]; then
    echo "2. RC4 암호화 설정 없음 - 기본적으로 비활성화되어 있을 수 있습니다."
    rc4_status="양호"
    details="$details, RC4 암호화 설정 없음"
else
    echo "2. RC4 암호화 설정 확인:"
    echo "$rc4_setting"
    if [[ "$rc4_setting" == *"no"* ]]; then
        rc4_status="양호"
        details="$details, RC4 암호화 설정 비활성화"
    else
        rc4_status="취약"
        details="$details, RC4 암호화 설정 활성화"
    fi
fi

# 4. 결과 판단 및 출력
if [ "$ntlm_status" == "양호" ] && [ "$rc4_status" == "양호" ]; then
    echo "Status: Secure"
    echo "Details: $details"
else
    echo "Status: Vulnerable"
    echo "Details: $details"
fi

