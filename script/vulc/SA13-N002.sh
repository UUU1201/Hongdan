#!/bin/bash
# SA13-N002.sh: Samba 서비스 접근 제어 방화벽 설정 점검 스크립트
LANG=ko_KR.utf8
export LANG

# Samba 포트 목록
samba_ports=(139 445)

# 1. UFW 방화벽 상태 확인
ufw_status=$(sudo ufw status | grep -i "Status: active")
if [ -n "$ufw_status" ]; then
    echo "1. UFW 방화벽이 활성화되어 있습니다."
    ufw_status_result="양호"
    details="UFW 방화벽 활성화"

    # 2. UFW에서 Samba 포트에 대한 규칙 확인
    for port in "${samba_ports[@]}"; do
        rule=$(sudo ufw status | grep "$port/tcp")
        if [ -n "$rule" ]; then
            echo "포트 $port에 대한 UFW 규칙:"
            echo "$rule"

            # 특정 IP로 접근이 제한되어 있는지 확인
            if [[ "$rule" == *"ALLOW IN"* && "$rule" != *"Anywhere"* ]]; then
                echo "포트 $port은 특정 IP에 대해서만 접근이 허용되어 있습니다."
                details="$details, 포트 $port 접근 제한 양호"
            else
                echo "포트 $port에 대한 접근이 제한되어 있지 않습니다. 특정 IP에 대해서만 접근을 허용하는 것이 좋습니다."
                ufw_status_result="취약"
                details="$details, 포트 $port 접근 제한 없음"
            fi
        else
            echo "포트 $port에 대한 UFW 규칙이 설정되어 있지 않습니다."
            ufw_status_result="취약"
            details="$details, 포트 $port 규칙 없음"
        fi
    done
else
    echo "1. UFW 방화벽이 활성화되어 있지 않습니다. iptables 규칙을 확인합니다."
    ufw_status_result="취약"
    details="UFW 방화벽 비활성화"

    # 3. iptables에서 Samba 포트에 대한 규칙 확인
    for port in "${samba_ports[@]}"; do
        iptables_rule=$(sudo iptables -L INPUT -v -n | grep "dpt:$port")
        if [ -n "$iptables_rule" ]; then
            echo "포트 $port에 대한 iptables 규칙:"
            echo "$iptables_rule"

            # 특정 IP로 접근이 제한되어 있는지 확인
            if [[ "$iptables_rule" == *"ACCEPT"* && "$iptables_rule" != *"0.0.0.0/0"* ]]; then
                echo "포트 $port은 특정 IP에 대해서만 접근이 허용되어 있습니다."
                details="$details, 포트 $port 접근 제한 양호 (iptables)"
            else
                echo "포트 $port에 대한 접근이 제한되어 있지 않습니다. 특정 IP에 대해서만 접근을 허용하는 것이 좋습니다."
                ufw_status_result="취약"
                details="$details, 포트 $port 접근 제한 없음 (iptables)"
            fi
        else
            echo "포트 $port에 대한 iptables 규칙이 설정되어 있지 않습니다."
            ufw_status_result="취약"
            details="$details, 포트 $port 규칙 없음 (iptables)"
        fi
    done
fi

# 4. 결과 판단 및 출력
if [ "$ufw_status_result" == "양호" ]; then
    echo "Status: Secure"
    echo "Details: $details"
else
    echo "Status: Vulnerable"
    echo "Details: $details"
fi

