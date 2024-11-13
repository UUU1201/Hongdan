#!/bin/bash
# SA14-N003.sh: Heap Buffer Overflow 취약점 점검을 위한 소스 코드 분석 스크립트
LANG=ko_KR.utf8
export LANG

# 전달된 인수
source_code_path="$1"         # 점검할 소스 코드 경로

# 1. 소스 코드 파일 존재 여부 확인 및 접근 권한 확인
if [ ! -f "$source_code_path" ]; then
    echo "Error: 지정된 소스 코드 파일 ($source_code_path)을 찾을 수 없습니다. 경로를 확인하세요."
    exit 1
fi

if [ ! -r "$source_code_path" ]; then
    echo "Error: 지정된 파일에 대한 읽기 권한이 없습니다. 파일의 접근 권한을 확인하세요."
    exit 1
fi

echo "Heap Buffer Overflow 및 기타 취약점 관련 함수 사용 여부 점검을 시작합니다: $source_code_path"

# 2. 위험한 함수 사용 여부 확인
dangerous_functions=("strcpy" "strcat" "gets" "scanf" "sprintf" "vsprintf" "gets")
details=""

for function in "${dangerous_functions[@]}"; do
    count=$(grep -c "$function" "$source_code_path")
    if [ "$count" -gt 0 ]; then
        echo "경고: $function 함수가 $count회 사용되었습니다. (Heap Buffer Overflow 위험이 있을 수 있음)"
        details="$details, $function 사용 감지 ($count회)"
    fi
done

# 3. 결과 판단 및 출력
if [ -z "$details" ]; then
    echo "결과: 양호 - 위험한 함수 사용이 발견되지 않았습니다."
    echo "Status: Secure"
    echo "Details: 위험한 함수 사용 없음"
else
    echo "결과: 취약 - 위험한 함수 사용이 발견되었습니다."
    echo "Status: Vulnerable"
    echo "Details: $details"
fi

