import subprocess
from pymongo import MongoClient
from datetime import datetime
from Scan_enum4 import parse_enum4linux_output, remove_ansi_codes
from Scan_nmap import parse_nmap_output
import os
import sys

# MongoDB 설정
client = MongoClient("mongodb://127.0.0.1:27017/")
db = client["adsentinel_db"]
scan_results = db["scan_results"]
vul_check_collection = db["VulCheck"]

# nmap 검사 함수 정의
def run_nmap_scan(ip_address):
    print("Running nmap...")
    nmap_result = subprocess.run(
        ["nmap", "-p", "53,88,135,137,138,139,389,445,464,636,3268,3269", ip_address],
        capture_output=True,
        text=True
    ).stdout
    parsed_nmap_results = parse_nmap_output(nmap_result) if 'parse_nmap_output' in globals() else nmap_result
    return parsed_nmap_results

# enum4linux 검사 함수 정의
def run_enum4linux_scan(ip_address):
    print("Running enum4linux...")
    enum4linux_result = subprocess.run(
        ["/usr/local/bin/enum4linux", "-U", "-S", "-P", "-o", "-A", ip_address],
        capture_output=True,
        text=True
    ).stdout
    clean_content = remove_ansi_codes(enum4linux_result)
    parsed_enum_results = parse_enum4linux_output(clean_content)
    return parsed_enum_results

# 동적으로 검사 항목별 스크립트를 실행하는 함수
def run_inspection_check(vulc_id, ip_address):
    item = vul_check_collection.find_one({"VulC_Id": vulc_id})
    if not item:
        print(f"{vulc_id} 항목을 찾을 수 없습니다.")
        return

    # VulCheck 컬렉션에서 각 설정 값을 가져옴
    smb_conf_path = item.get("smb_conf_path", "/etc/samba/smb.conf")
    hosts_allow_value = item["VulC_Check"].get("Secure", "127.0.0.1")  # 기본값을 안전한 값으로 설정
    admin_invalid_value = "administrator"
    secure_message = item["VulC_Check"].get("Secure", "")
    vulnerable_message = item["VulC_Check"].get("Vulnerable", "")
        
    
    script_path = f"hd/script/{vulc_id}.sh"
    if not os.path.isfile(script_path):
        print(f"{script_path} 스크립트 파일이 존재하지 않습니다.")
        return

    # 진행 상태 출력
    print(f"실행 중인 항목: {vulc_id} - 스크립트: {script_path}")

    # subprocess.Popen으로 실시간 출력 표시
    process = subprocess.Popen(
        [script_path, smb_conf_path, hosts_allow_value, admin_invalid_value],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )

    status, details = "", ""
    for line in process.stdout:
        print(line, end="")  # 터미널에 실시간 출력 표시
        if "Status:" in line:
            status = line.split(":")[1].strip()
        elif "Details:" in line:
            details += line.strip() + " "

    # 오류 메시지 출력 (있을 경우)
    for error_line in process.stderr:
        print(error_line, end="")

    # 완료된 항목 표시
    print(f"완료된 항목: {vulc_id} - 상태: {status}")
    
    # 결과 메시지 설정
    if status == "Secure":
        details = secure_message
    else:
        details = vulnerable_message
    
    return {"status": status, "details": details.strip()}

# ADSentinel 전체 검사 함수 정의
def run_ADSentinel_scan(ip_address):
    inspection_items = vul_check_collection.find()
    adsentinel_results = []

    for item in inspection_items:
        vulc_id = item["VulC_Id"]
        print(f"\n--- {vulc_id} 검사 시작 ---")
        check_result = run_inspection_check(vulc_id, ip_address)
        if check_result:
            adsentinel_results.append({
                "vulc_id": vulc_id,
                "status": check_result["status"],
                "details": check_result["details"]
            })
        else:
            adsentinel_results.append({
                "vulc_id": vulc_id,
                "status": "Not Checked",
                "details": "검사 항목 코드 없음"
            })

    return adsentinel_results

# 검사 결과를 MongoDB에 저장하는 함수 정의
def save_scan_results(ip_address, nmap_data, enum4linux_data, adsentinel_data):
    data = {
        "ip_address": ip_address,
        "timestamp": datetime.utcnow(),
        "nmap_results": nmap_data,
        "enum4linux_results": enum4linux_data,
        "ADSentinel_results": adsentinel_data
    }
    scan_results.insert_one(data)
    print(f"{ip_address}의 검사 결과가 MongoDB에 저장되었습니다.")

# 메인 함수 정의
def main():
#   ip_address = input(" input ip")
    # sys.argv로 IP 주소를 전달받도록 수정
    ip_address = sys.argv[1] if len(sys.argv) > 1 else None
    if not ip_address:
        print("IP 주소가 제공되지 않았습니다.")
        return

    print(f"{ip_address}에 대해 nmap 검사를 시작합니다...")
    nmap_data = run_nmap_scan(ip_address)
    
    print(f"{ip_address}에 대해 enum4linux 검사를 시작합니다...")
    enum4linux_data = run_enum4linux_scan(ip_address)
    
    print(f"{ip_address}에 대해 ADSentinel 검사를 시작합니다...")
    adsentinel_data = run_ADSentinel_scan(ip_address)
    
    save_scan_results(ip_address, nmap_data, enum4linux_data, adsentinel_data)
    print(f"{ip_address}에 대한 모든 검사가 완료되었습니다.")

# 스크립트 실행 시 메인 함수 호출
if __name__ == "__main__":
    main()

