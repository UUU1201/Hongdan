#!/bin/bash
# SA02-R002.sh: 패스워드 복잡성 설정 점검 스크립트

# MongoDB에서 스캔 결과 가져오기
scan_results=$(mongo ADSentinel_DB --quiet --eval "db.VulCheck.find({ip_address: '$1'}).toArray()")

# Password Policy 가져오기
password_policy=$(echo "$scan_results" | jq -r '.[0].enum4linux_results.password_policy')

if [ "$password_policy" != "null" ]; then
    # 1. password_policy가 MongoDB에 존재할 경우 검사 수행
    echo "패스워드 정책을 MongoDB에서 가져왔습니다:"
    echo "$password_policy"

    # 최소 길이 확인
    min_length=$(echo "$password_policy" | grep 'Minimum password length' | awk -F': ' '{print $2}')
    complexity="$(echo "$password_policy" | grep 'Password complexity' | awk -F': ' '{print $2}')"

    # 결과 판단 및 출력
    if [[ "$min_length" -ge 8 && "$complexity" == *"on"* ]]; then
        echo "Status: Secure"
    else
        echo "Status: Vulnerable"
    fi
else
    # 2. MongoDB에 password_policy가 없을 경우 직접 검사
# 현재 IP가 로컬 IP인지 확인하고 로컬일 경우만 Samba 도메인 패스워드 정책을 확인합니다.
local_ip=$(hostname -I | awk '{print $1}')
if [ "$1" == "$local_ip" ]; then
    password_settings=$(samba-tool domain passwordsettings show)
    if [ -z "$password_settings" ]; then
        echo "Error: 패스워드 정책을 확인할 수 없습니다. Samba AD가 올바르게 설정되었는지 확인하세요."
        echo "Status: Unknown"
        # 3. IP 기반 추가 검사 수행
    ip_based_policy=$(nmap -p 139,445 --script smb-enum-shares.nse,smb-enum-users.nse "$1")
    if [ -z "$ip_based_policy" ]; then
            echo "Error: IP 기반으로 패스워드 정책을 확인할 수 없습니다."
            echo "Status: Unknown"
        else
            echo "패스워드 정책을 IP 기반으로 가져왔습니다:"
            echo "$ip_based_policy"
            # 추가 검사 로직 필요 시 여기에 추가
            echo "Status: Unknown"  # 임시로 Unknown 출력
        fi
        exit 1
    fi
else
    echo "Error: 로컬 IP와 일치하지 않아 Samba 패스워드 정책을 확인할 수 없습니다."
    echo "Status: Unknown"
fi

    # 패스워드 최소 길이 확인
    min_length=$(echo "$password_settings" | grep 'Minimum password length' | awk -F': ' '{print $2}')
    # 패스워드 복잡성 요구사항 확인
    complexity=$(echo "$password_settings" | grep 'Password complexity' | awk -F': ' '{print $2}')

    # 결과 판단
    if [[ "$min_length" -ge 8 && "$complexity" == *"on"* ]]; then
    echo "결과: 양호 - 패스워드 최소 길이 8자리 이상이며 복잡성 요구사항이 적용되어 있습니다."
    echo "Status: Secure"
else
    if [ -z "$min_length" ] || [ -z "$complexity" ]; then
        echo "결과: 알 수 없음 - 패스워드 정책이 불완전하거나 확인할 수 없습니다."
        echo "Status: Unknown"
    else
        echo "결과: 취약 - 패스워드에 복잡성 요구사항(대문자, 소문자, 숫자, 특수문자 포함)이 적용되지 않았거나 최소 길이가 8자 미만으로 설정되어 있습니다."
        echo "Status: Vulnerable"
    fi
    fi
fi

