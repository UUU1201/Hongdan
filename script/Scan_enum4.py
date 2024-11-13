from parse import parse
import re
import json
import subprocess

# 결과 저장할 JSON 파일 경로
parsed_results_path = "parsed_results.json"

# ANSI 색상 코드 제거 함수
def remove_ansi_codes(text):
    ansi_escape = re.compile(r'\x1B[@-_][0-?]*[ -/]*[@-~]')
    return ansi_escape.sub('', text)

# 결과 파싱 함수
def parse_enum4linux_output(content):
    # full_output을 제외한 정보 저장
    parsed_data = {}

    print("Parsing specific information...")

    # Target OS와 Samba Version 파싱
    os_samba_match = re.search(r"Samba\s+([\d\.]+)-(\S+)", content)
    if os_samba_match:
        parsed_data["samba_version"] = os_samba_match.group(1).strip()
        parsed_data["target_os"] = os_samba_match.group(2).strip()

    # Known Usernames 파싱
    known_usernames_template = "Known Usernames .. {usernames}\n"
    known_usernames_match = parse(known_usernames_template, content)
    if known_usernames_match:
        parsed_data['known_usernames'] = [user.strip() for user in known_usernames_match['usernames'].split(",")]

    # Domain Name 파싱
    domain_match = re.search(r"Domain Name:\s+(\S+)", content)
    if domain_match:
        parsed_data["domain"] = domain_match.group(1)

    # 사용자 목록 파싱
    parsed_data['users'] = re.findall(r"user:\[(.*?)\]", content)
 
    # Password Policy 전체 섹션 파싱
    password_policy_match = re.search(
       r"\[\+\] Password Info for Domain:.*?\n(.*?)\n(?=\s*enum4linux complete)", 
       content, re.DOTALL
    )
    if password_policy_match:
       parsed_data["password_policy"] = password_policy_match.group(1).strip()

    # full_output을 마지막에 추가
    parsed_data["full_output"] = content

    return parsed_data

# 실행 및 저장
def main():
    target_ip = "172.30.1.57"
    
    print("Running enum4linux...")
    # enum4linux 실행 및 결과 가져오기
    enum4linux_result = subprocess.run(["enum4linux","-U -S -P -o -A", target_ip], capture_output=True, text=True).stdout
    
    # ANSI 코드 제거 및 특정 정보 파싱
    clean_content = remove_ansi_codes(enum4linux_result)
    parsed_data = parse_enum4linux_output(clean_content)
    
    # JSON 파일로 저장
    print("Saving parsed results to JSON file...")
    with open(parsed_results_path, 'w', encoding='utf-8') as json_file:
        json.dump(parsed_data, json_file, ensure_ascii=False, indent=4)
    print(f"Parsed results saved to {parsed_results_path}")

    # 화면에 특정 정보 및 전체 결과 출력
    print("\n--- Parsed Information ---\n")
    for key, value in parsed_data.items():
        print(f"{key}: {value}")

if __name__ == "__main__":
    main()

