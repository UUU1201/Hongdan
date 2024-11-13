from pymongo import MongoClient
import subprocess
from datetime import datetime
from Scan_enum4 import parse_enum4linux_output, remove_ansi_codes
from Scan_nmap import parse_nmap_output
import os


# MongoDB에 연결
client = MongoClient("mongodb://localhost:27017/")
db = client["adsentinel_db"]
scan_results_collection = db["scan_results"]

def save_scan_results(ip_address, result_data):
    try:
        # 데이터 삽입
        document = {
            "ip_address": ip_address,
            "scan_results": result_data,
            "timestamp": datetime.now()
        }
        result = scan_results_collection.insert_one(document)
        print(f"Inserted document with ID: {result.inserted_id}")
    except Exception as e:
        print(f"Error inserting document: {e}")

# 예제 데이터 저장
save_scan_results("121.0.0.1", {"status": "Vulnerable", "details": "Sample result details"})
