#!/bin/bash
# SA08-D001.sh: SUID 및 SGID 설정 파일 점검 스크립트
LANG=ko_KR.utf8
export LANG

# 1. SUID가 설정된 파일 찾기
echo "=== 1. SUID가 설정된 파일 ==="
suid_files=$(find / -perm -4000 -type f 2>/dev/null)
if [ -z "$suid_files" ]; then
    echo "SUID가 설정된 파일이 없습니다."
    suid_status="양호"
    details="SUID 설정 파일 없음"
else
    echo "$suid_files"
    suid_status="취약"
    details="SUID 설정 파일 존재"
fi

# 2. SGID가 설정된 파일 찾기
echo "=== 2. SGID가 설정된 파일 ==="
sgid_files=$(find / -perm -2000 -type f 2>/dev/null)
if [ -z "$sgid_files" ]; then
    echo "SGID가 설정된 파일이 없습니다."
    sgid_status="양호"
    details="$details, SGID 설정 파일 없음"
else
    echo "$sgid_files"
    sgid_status="취약"
    details="$details, SGID 설정 파일 존재"
fi

# 3. 위험한 SUID/SGID 파일 확인
# 잠재적인 위험 파일 목록
suspicious_files=("/usr/bin/passwd" "/usr/bin/sudo" "/usr/bin/chsh" "/usr/bin/chfn" "/usr/bin/newgrp" "/bin/su")

echo "=== 3. 잠재적인 위험 SUID/SGID 파일 점검 ==="
suspicious_status="양호"
for file in "${suspicious_files[@]}"; do
    if [ -e "$file" ]; then
        echo "확인 필요: $file (SUID/SGID 비트 설정)"
        suspicious_status="취약"
        details="$details, 잠재적인 위험 파일 존재: $file"
    else
        echo "$file 파일이 존재하지 않습니다."
    fi
done

# 4. 결과 판단 및 출력
if [ "$suid_status" == "양호" ] && [ "$sgid_status" == "양호" ] && [ "$suspicious_status" == "양호" ]; then
    echo "Status: Secure"
    echo "Details: $details"
else
    echo "Status: Vulnerable"
    echo "Details: $details"
fi

