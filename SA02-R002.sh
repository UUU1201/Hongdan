#!/bin/bash
# SA02-R002.sh: 패스워드 복잡성 설정 점검 스크립트

# 1. 패스워드 정책 확인
password_settings=$(samba-tool domain passwordsettings show)
if [ -z "$password_settings" ]; then
    echo "Error: 패스워드 정책을 확인할 수 없습니다. Samba AD가 올바르게 설정되었는지 확인하세요."
    exit 1
fi

# 2. 패스워드 최소 길이 확인
min_length=$(echo "$password_settings" | grep 'Minimum password length' | awk -F': ' '{print $2}')

# 3. 패스워드 복잡성 요구사항 확인
complexity=$(echo "$password_settings" | grep 'Password complexity' | awk -F': ' '{print $2}')

# 4. 결과 판단
if [ "$min_length" -ge 8 ] && [[ "$complexity" == "on" ]]; then
    echo "결과: 양호 - 패스워드 최소 길이 8자리 이상이며 복잡성 요구사항이 적용되어 있습니다."
else
    echo "결과: 취약 - 패스워드에 복잡성 요구사항(대문자, 소문자, 숫자, 특수문자 포함)이 적용되지 않았거나 최소 길이가 8자 미만으로 설정되어 있습니다."
fi

