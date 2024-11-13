import re
from pymongo import MongoClient
from datetime import datetime

# MongoDB 설정
client = MongoClient("mongodb://127.0.0.1:27017/")
db = client["adsentinel_db"]
scan_results = db["scan_results"]
cve_db = db["cve_db"]  # cve_db 컬렉션 추가

# Samba 버전 매칭 함수 정의
def match_samba_version(samba_version, cve_versions):
    samba_version_major_minor = ".".join(samba_version.split(".")[:2])  # 주 버전과 부 버전만 추출
    for cve_version in cve_versions:
        # CVE 버전 정보와 주/부 버전을 비교
        cve_major_minor = ".".join(cve_version.split(".")[:2])
        if samba_version_major_minor == cve_major_minor:
            return cve_version
    return None

# 검사 결과를 MongoDB에 저장하면서 CVE 데이터 추가
def save_scan_results_with_cve(ip_address, nmap_data, enum4linux_data, adsentinel_data):
    samba_version = enum4linux_data.get("samba_version", "")
    if not samba_version:
        print("Samba 버전 정보가 없습니다.")
        return

    # CVE 데이터베이스에서 일치하는 Samba 버전 찾기
    cve_records = cve_db.find({})
    matching_cves = []

    for cve_record in cve_records:
        cve_versions = cve_record.get("samba_version", [])
        if match_samba_version(samba_version, cve_versions):
            matching_cves.append(cve_record)

    # 검사 결과 데이터 구성
    data = {
        "ip_address": ip_address,
        "timestamp": datetime.utcnow(),
        "nmap_results": nmap_data,
        "enum4linux_results": enum4linux_data,
        "ADSentinel_results": adsentinel_data,
        "cve_results": matching_cves  # 매칭된 CVE 추가
    }

    # MongoDB에 저장
    scan_results.insert_one(data)
    print(f"{ip_address}의 검사 결과가 MongoDB에 저장되었습니다.")

# 예시 실행
if __name__ == "__main__":
    ip_address = "192.168.0.1"
    nmap_data = ""  # nmap 검사 데이터
    enum4linux_data = {
        "samba_version": "4.15.13"
    }
    adsentinel_data = []  # ADSentinel 검사 데이터

    save_scan_results_with_cve(ip_address, nmap_data, enum4linux_data, adsentinel_data)
