#!/bin/bash
# SA09-D002.sh: Samba 공유 디렉터리 권한 및 경로 설정 점검 스크립트
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

# 2. 공유 디렉터리 설정 확인
shared_dirs=$(grep -E "^\[.*\]" "$smb_conf_path" | tr -d '[]')
if [ -z "$shared_dirs" ]; then
    echo "Error: 공유 설정이 smb.conf 파일에 없습니다."
    shared_dirs_status="취약"
    details="공유 설정 없음"
else
    shared_dirs_status="양호"
    details="공유 설정 존재"
fi

# 3. 각 공유 디렉터리에 대한 권한 및 경로 점검
echo "=== 3. 공유 디렉터리 권한 및 경로 설정 점검 ==="
for dir in $shared_dirs; do
    path=$(grep -A 5 "^\[$dir\]" "$smb_conf_path" | grep -i "path" | awk -F'=' '{print $2}' | xargs)
    if [ -z "$path" ]; then
        echo "[$dir] 공유 폴더에 'path' 설정이 없습니다. 점검이 필요합니다."
        shared_dirs_status="취약"
        details="$details, [$dir] 공유 폴더에 'path' 설정 없음"
        continue
    fi

    # 경로에 대한 권한 확인
    if [ -d "$path" ]; then
        permissions=$(stat -c "%a" "$path")
        echo "[$dir] 공유 폴더 경로: $path, 권한: $permissions"

        # 권한이 770 이하인지 확인
        if [ "$permissions" -le 770 ]; then
            echo "[$dir] 폴더 권한 설정 양호 (권한: $permissions)"
            details="$details, [$dir] 폴더 권한 설정 양호"
        else
            echo "[$dir] 폴더 권한 설정 취약 - 권한이 너무 넓게 열려 있습니다. 권한을 770 이하로 제한하는 것이 좋습니다."
            shared_dirs_status="취약"
            details="$details, [$dir] 폴더 권한 설정 취약"
        fi
    else
        echo "경고: [$dir] 공유 폴더 경로 ($path)가 존재하지 않습니다. 설정을 확인하세요."
        shared_dirs_status="취약"
        details="$details, [$dir] 공유 폴더 경로 없음"
    fi
done

# 4. 결과 판단 및 출력
if [ "$shared_dirs_status" == "양호" ]; then
    echo "Status: Secure"
    echo "Details: $details"
else
    echo "Status: Vulnerable"
    echo "Details: $details"
fi

