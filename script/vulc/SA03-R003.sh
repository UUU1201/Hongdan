#!/bin/bash
# SA03-R003.sh: 계정 잠금 임계값 설정 점검 스크립트
LANG=ko_KR.utf8
export LANG

# 1. Samba 버전 확인
samba_version=$(samba -V | awk '{print $2}')
if [ -z "$samba_version" ]; then
    echo "Error: Samba 버전을 확인할 수 없습니다. Samba가 올바르게 설치되었는지 확인하세요."
    exit 1
fi

echo "현재 Samba 버전: $samba_version"

# 2. 계정 잠금 임계값 설정 점검
if [[ "$samba_version" > "4.6" ]]; then
    # Samba 버전 4.6 이상일 경우
    echo "Samba 버전 4.6 이상 - 계정 잠금 임계값 설정 확인 중..."
    lockout_threshold=$(samba-tool domain passwordsettings show | grep 'Lockout threshold' | awk -F': ' '{print $2}')

    if [[ -z "$lockout_threshold" || "$lockout_threshold" == "0" ]]; then
        lockout_status="취약"
        details="계정 잠금 임계값이 설정되어 있지 않거나 0으로 설정됨"
    elif [[ "$lockout_threshold" -gt 0 && "$lockout_threshold" -le 10 ]]; then
        lockout_status="양호"
        details="계정 잠금 임계값이 10회 이하로 설정됨"
    else
        lockout_status="취약"
        details="계정 잠금 임계값이 10회 이하로 설정되지 않음"
    fi
else
    # Samba 버전 4.6 이하일 경우
    echo "Samba 버전 4.6 이하 - smb.conf 파일에서 계정 잠금 임계값 설정 확인 중..."
    smb_conf_path="/etc/samba/smb.conf"
    if [ -f "$smb_conf_path" ]; then
        lockout_threshold=$(grep -i "account lockout threshold" "$smb_conf_path" | awk -F'=' '{print $2}' | tr -d ' ')
        if [[ -z "$lockout_threshold" || "$lockout_threshold" == "0" ]]; then
            lockout_status="취약"
            details="계정 잠금 임계값이 설정되어 있지 않거나 0으로 설정됨"
        elif [[ "$lockout_threshold" -gt 0 && "$lockout_threshold" -le 10 ]]; then
            lockout_status="양호"
            details="계정 잠금 임계값이 10회 이하로 설정됨"
        else
            lockout_status="취약"
            details="계정 잠금 임계값이 10회 이하로 설정되지 않음"
        fi
    else
        echo "Error: smb.conf 파일을 찾을 수 없습니다."
        exit 1
    fi
fi

# 3. 결과 출력
if [ "$lockout_status" == "양호" ]; then
    echo "Status: Secure"
else
    echo "Status: Vulnerable"
fi
echo "Details: $details"

