#!/bin/bash
# SA03-R003.sh: 계정 잠금 임계값 설정 점검 스크립트

# 1. Samba 버전 확인
samba_version=$(samba -V 2>/dev/null | awk '{print $2}')
if [ -z "$samba_version" ]; then
    echo "Error: Samba 버전을 확인할 수 없습니다. Samba가 올바르게 설치되었는지 확인하세요."
    exit 1
fi

# 버전 출력
echo "현재 Samba 버전: $samba_version"

# 최신 패치 필요 여부 확인
echo "Samba 최신 패치를 진행하시겠습니까? (yes/no, 기본값: no)"
read -r update_choice
if [ -z "$update_choice" ]; then
    update_choice="no"
fi

if [[ "$update_choice" == "yes" ]]; then
    echo "Samba 패치를 진행합니다..."
    sudo apt update && sudo apt upgrade samba -y
    echo "패치가 완료되었습니다."
fi

# 2. 계정 잠금 임계값 설정 점검
if [[ "$samba_version" > "4.6" ]]; then
    # Samba 버전 4.6 이상일 경우
    echo "Samba 버전 4.6 이상 - 계정 잠금 임계값 설정 확인 중..."
    lockout_threshold=$(samba-tool domain passwordsettings show | grep 'Lockout threshold' | awk -F': ' '{print $2}')
    
    if [ -z "$lockout_threshold" ]; then
        echo "계정 잠금 임계값이 설정되어 있지 않습니다."
    elif [ "$lockout_threshold" -le 10 ]; then
        echo "결과: 양호 - 계정 잠금 임계값이 10회 이하로 설정되어 있습니다."
    else
        echo "결과: 취약 - 계정 잠금 임계값이 10회 이하로 설정되지 않았습니다."
    fi
else
    # Samba 버전 4.6 이하일 경우
    echo "Samba 버전 4.6 이하 - smb.conf 파일에서 설정 확인 중..."
    smb_conf_path="/etc/samba/smb.conf"
    if [ -f "$smb_conf_path" ]; then
        lockout_threshold=$(grep -i "Account lockout threshold" "$smb_conf_path" | awk -F': ' '{print $2}')
        if [ -z "$lockout_threshold" ]; then
            echo "계정 잠금 임계값이 설정되어 있지 않습니다."
        elif [ "$lockout_threshold" -le 10 ]; then
            echo "결과: 양호 - 계정 잠금 임계값이 10회 이하로 설정되어 있습니다."
        else
            echo "결과: 취약 - 계정 잠금 임계값이 10회 이하로 설정되지 않았습니다."
        fi
    else
        echo "Error: smb.conf 파일을 찾을 수 없습니다."
    fi
fi
