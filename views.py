import subprocess
import os
import json
from django.views.decorators.csrf import csrf_exempt
from django.shortcuts import render, redirect, get_object_or_404
from django.http import JsonResponse, HttpResponse
from datetime import datetime
from pymongo import MongoClient
from bson import ObjectId  # MongoDB ObjectId를 처리하기 위해 필요
from bson.objectid import ObjectId
#from .models import ScanResult




def index(request):
    return render(request, 'index.html')

  
def dashboard(request):
    return render(request, 'dashboard.html')  # dashboard.html을 렌더링


# MongoDB 연결 설정
client = MongoClient("mongodb://127.0.0.1:27017/")
db = client["adsentinel_db"]
exploit_collection = db["exploit"]
exploit_result_collection = db["exploit_result"]
scan_results = db["scan_results"]
cve_db = db["cve_db"]
vul_check = db["VulCheck"]

# Red Flag 페이지 뷰
client = MongoClient("mongodb://3.39.47.208:27017/")
db = client["suricata_logs"]
logs_collection = db["logs"]


def get_mongo_collection():
    client = MongoClient("mongodb://127.0.0.1:27017/")
    db = client["adsentinel_db"]
    return db["scan_results"], db["VulCheck"]
    
    

# Dashboard 뷰 추가
def dashboard(request):
    # MongoDB 연결 설정
    client = MongoClient("mongodb://127.0.0.1:27017/")
    db = client["adsentinel_db"]

    # 마지막 3개의 보고서를 가져옴
    last_reports = list(scan_results.find().sort("timestamp", -1).limit(3))

    # Red Flag Alerts에서 마지막 3개의 로그 가져오기
    red_flags = list(logs_collection.find().sort([("date", -1), ("time", -1)]).limit(3))

    # 최근 exploit 결과 가져오기
    recent_exploits = list(exploit_result_collection.find().sort("timestamp", -1).limit(3))

    # 최근 CVE 정보 가져오기
    recent_cves = list(cve_db.find().sort("Published", -1).limit(3))

    # 최근 스캔 결과 가져오기
    last_scan = scan_results.find_one(sort=[("_id", -1)])
    ip_address = last_scan.get("ip_address", "N/A") if last_scan else "N/A"
    adsentinel_results = last_scan.get("ADSentinel_results", []) if last_scan else []
    status, status_class = calculate_risk_level(adsentinel_results)

    # 템플릿에 전달할 데이터
    context = {
        "last_reports": last_reports,
        "red_flags": red_flags,
        "recent_exploits": recent_exploits,
        "recent_cves": recent_cves,
        "ip_address": ip_address,
        "status": status,
        "status_class": status_class,
    }

    return render(request, 'dashboard.html', context)

       
    

def initiate_scan(request):
    if request.method == 'POST':
        ip_address = request.POST.get('ip_address')
        # 여기에서 스캔 로직을 실행하고 결과를 MongoDB에 저장합니다.
        
        # 예시: 결과 저장
        scan_results = get_mongo_collection()
        scan_results.insert_one({
            "ip_address": ip_address,
            "ADSentinel_results": [],  # 스캔 결과 추가
            "timestamp": datetime.now()
        })

        # 저장 후 가장 최근 스캔으로 리디렉션
        return redirect('scan_latest')

    return render(request, 'index.html')


def get_latest_scan_results():
    client = MongoClient("mongodb://127.0.0.1:27017/")
    db = client["adsentinel_db"]
    scan_results = db["scan_results"]
    last_scan = scan_results.find_one(sort=[("_id", -1)])
    
    # 필요한 값만 반환하도록 수정
    ip_address = last_scan.get("ip_address", "N/A")
    adsentinel_results = last_scan.get("ADSentinel_results", [])
    return ip_address, adsentinel_results


def calculate_risk_level(adsentinel_results):
    # 'Vulnerable' 상태인 항목 개수를 세서 위험 수준을 결정
    vulnerable_count = sum(1 for result in adsentinel_results if result['status'] == 'Vulnerable')
    if vulnerable_count >= 8:
        return "Danger", "Danger"
    elif 4 <= vulnerable_count < 8:
        return "warning", "warning"
    else:
        return "safe", "safe"
        
        
def run_scan(request):
    if request.method == 'POST':
        ip_address = request.POST.get('ip_address')  # 입력받은 IP 주소

        # ADSentinel.py 파일 실행 시 IP 주소를 인자로 전달
        result = subprocess.run(
            ["python3", "hd/script/ADSentinel.py", ip_address],
            capture_output=True,
            text=True
        )

        # 디버깅을 위해 실행된 명령어와 결과를 출력
        print("Executed command:", ["python3", "hd/script/ADSentinel.py", ip_address])
        print("STDOUT:", result.stdout)
        print("STDERR:", result.stderr)

        # 실행 결과와 오류 메시지를 포함하여 반환
        return JsonResponse({
            "message": "검사가 완료되었습니다.",
            "stdout": result.stdout,  # 표준 출력
            "stderr": result.stderr   # 표준 에러
        })
        
        


def scan(request, scan_id=None):
    # MongoDB 컬렉션 가져오기
    scan_results, vul_check = get_mongo_collection()  # 각각의 변수로 받기

    if scan_id:
        # 특정 scan_id가 주어진 경우 해당 스캔 결과를 가져오기
        last_scan = scan_results.find_one({"_id": ObjectId(scan_id)})
    else:
        # scan_id가 없으면 최근 스캔 결과를 가져오기
        last_scan = scan_results.find_one(sort=[("timestamp", -1)])

    if not last_scan:
        return render(request, '404.html')  # 기록이 없으면 404 페이지 반환

    # 나머지 코드 유지
    ip_address = last_scan.get("ip_address", "N/A")
    adsentinel_results = last_scan.get("ADSentinel_results", [])
    nmap_results = last_scan.get("nmap_results", {})
    enum4linux_results = last_scan.get("enum4linux_results", {})
    
    cve_results = last_scan.get("cve_results", {})
    cve_risk_results = last_scan.get("cve_risk_results", {})

    status, status_class = calculate_risk_level(adsentinel_results)
    password_policy = enum4linux_results.get("password_policy", "").replace("\n", "<br>")
    full_output = enum4linux_results.get("full_output", "").replace("\n", "<br>")
    

    detailed_results = []
    for result in adsentinel_results:
        vulc_id = result.get("vulc_id")
        vulc_info = vul_check.find_one({"VulC_Id": vulc_id})

        if vulc_info:
            detailed_results.append({
                "vulc_id": vulc_id,
                "status": result.get("status"),
                "title": vulc_info.get("VulC_Title", "N/A"),
                "summary": vulc_info.get("VulC_Des", "N/A"),
                "risk_level": vulc_info.get("VulC_Level", "N/A")
            })
        else:
            detailed_results.append({
                "vulc_id": vulc_id,
                "status": result.get("status"),
                "title": "N/A",
                "summary": "N/A",
                "risk_level": "N/A"
            })

    context = {
        "ip_address": ip_address,
        "status": status,
        "status_class": status_class,
        "adsentinel_results": detailed_results,
        "nmap_results": nmap_results,
        "enum4linux_results": enum4linux_results,
        "formatted_password_policy": password_policy,
        "formatted_full_output": full_output,
        "cve_results": cve_results,
        "cve_risk_results": cve_risk_results,

    }

    return render(request, 'scan.html', context)
    

# scan_detail 뷰 정의 (각 스캔의 상세 내용 표시)
def scan_detail(request, scan_id):
    scan_results, vul_check = get_mongo_collection()
    last_scan = scan_results.find_one({"_id": ObjectId(scan_id)})

    if not last_scan:
        return render(request, '404.html')

    ip_address = last_scan.get("ip_address", "N/A")
    adsentinel_results = last_scan.get("ADSentinel_results", [])
    nmap_results = last_scan.get("nmap_results", {})
    enum4linux_results = last_scan.get("enum4linux_results", {})

    status, status_class = calculate_risk_level(adsentinel_results)
    password_policy = enum4linux_results.get("password_policy", "").replace("\n", "<br>")
    full_output = enum4linux_results.get("full_output", "").replace("\n", "<br>")

    detailed_results = []
    for result in adsentinel_results:
        vulc_id = result.get("vulc_id")
        vulc_info = vul_check.find_one({"VulC_Id": vulc_id})

        if vulc_info:
            detailed_results.append({
                "vulc_id": vulc_id,
                "status": result.get("status"),
                "title": vulc_info.get("VulC_Title", "N/A"),
                "summary": vulc_info.get("VulC_Des", "N/A"),
                "risk_level": vulc_info.get("VulC_Level", "N/A")
            })
        else:
            detailed_results.append({
                "vulc_id": vulc_id,
                "status": result.get("status"),
                "title": "N/A",
                "summary": "N/A",
                "risk_level": "N/A"
            })

    context = {
        "ip_address": ip_address,
        "status": status,
        "status_class": status_class,
        "adsentinel_results": detailed_results,
        "nmap_results": nmap_results,
        "enum4linux_results": enum4linux_results,
        "formatted_password_policy": password_policy,
        "formatted_full_output": full_output,
    }

    return render(request, 'scan.html', context)
    

def vul_result(request, vulc_id, scan_id=None):
    # 취약점 상세 정보 가져오기
    vulc_record = vul_check.find_one({"VulC_Id": vulc_id})

    # 특정 scan_id에 따른 ADSentinel 결과 가져오기
    if scan_id:
        scan_result = scan_results.find_one({"_id": ObjectId(scan_id)})
        if scan_result:
            adsentinel_results = [result for result in scan_result.get("ADSentinel_results", []) if result.get("vulc_id") == vulc_id]
    else:
        # 최신 결과 가져오기
        latest_scan = scan_results.find_one(sort=[("timestamp", -1)])
        if latest_scan:
            adsentinel_results = [result for result in latest_scan.get("ADSentinel_results", []) if result.get("vulc_id") == vulc_id]
        else:
            adsentinel_results = []

    if not vulc_record:
        return render(request, '404.html')

    context = {
        "vulc_record": vulc_record,
        "adsentinel_results": adsentinel_results
    }

    return render(request, 'vul_result.html', context)
    
    
    
    
def reports_page(request):
    client = MongoClient("mongodb://127.0.0.1:27017/")
    db = client["adsentinel_db"]
    scan_results = db["scan_results"]
    all_scans = scan_results.find().sort("timestamp", -1)
    
    scan_records = []
    for scan in all_scans:
        ip_address = scan.get("ip_address", "N/A")
        timestamp = scan.get("timestamp", "N/A")
        adsentinel_results = scan.get("ADSentinel_results", [])
        domain = scan.get("enum4linux_results", {}).get("domain", "N/A")
        samba_version = scan.get("enum4linux_results", {}).get("samba_version", "N/A")
        target_os = scan.get("enum4linux_results", {}).get("target_os", "N/A")

        status, status_class = calculate_risk_level(adsentinel_results)

        # _id 값을 id로 변환하여 추가
        scan_records.append({
            'id': str(scan["_id"]),  # 템플릿에서 사용할 수 있도록 문자열로 변환
            'ip_address': ip_address,
            'timestamp': timestamp,
            'status': status,
            'status_class': status_class,
            'adsentinel_results': adsentinel_results,
            'domain': domain,
            'samba_version': samba_version,
            'target_os': target_os,
        })

    return render(request, 'reports.html', {'scan_records': scan_records})
    

    
def exploit_list(request):
    # Exploit 목록을 가져와서 exploit.html 페이지에 전달
    exploits = exploit_collection.find()
    # 최신 스캔의 IP 주소를 가져옴
    last_scan = db["scan_results"].find_one(sort=[("timestamp", -1)])
    ip_address = last_scan.get("ip_address", "N/A") if last_scan else "N/A"
    
    return render(request, 'exploit.html', {'exploits': exploits , 'ip_address': ip_address})




def exploit_detail(request, name):
    # MongoDB에서 이름이 `name`인 익스플로잇 정보를 찾음
    exploit = exploit_collection.find_one({"name": name})

    if not exploit:
        return redirect('exploit_list')  # Exploit이 없으면 목록 페이지로 돌아감
        
    # 최신 스캔의 IP 주소를 가져옴
    last_scan = db["scan_results"].find_one(sort=[("timestamp", -1)])
    ip_address = last_scan.get("ip_address", "N/A") if last_scan else "N/A"

    if request.method == "POST":
        # 웹에서 입력받은 IP 주소와 사용자명을 가져오기
        target_ip = request.POST.get('ip_address')
        username = request.POST.get('username')  # 텍스트로 입력받은 사용자명

        # 공격 코드 실행 - username이 필요한 경우와 필요하지 않은 경우를 분기
        if username:
            result = subprocess.run(
                ["python3", f"hd/script/exploit/{exploit['script']}", target_ip, username],
                capture_output=True,
                text=True
            )
        else:
            result = subprocess.run(
                ["python3", f"hd/script/exploit/{exploit['script']}", target_ip],
                capture_output=True,
                text=True
            )

        # 공격 결과에 따라 MongoDB에 저장
        exploit_result = {
            "name": name,
            "target_ip": target_ip,
            "username": username if username else "N/A",
            "output": result.stdout,
            "error": result.stderr,
            "timestamp": datetime.utcnow()
        }
        
        # 공격 성공 여부에 따라 상태 추가
        if "Success" in result.stdout:
            exploit_result["status"] = "Success"
        elif "Failure" in result.stdout:
            exploit_result["status"] = "Failure"
        else:
            exploit_result["status"] = "Error"

        # MongoDB에 저장
        exploit_result_collection.insert_one(exploit_result)

        # 결과 반환
        return JsonResponse({
            "message": "공격이 완료되었습니다.",
            "stdout": result.stdout,
            "stderr": result.stderr
        })
    
    # exploit_detail.html에 'exploit'과 'ip_address' 전달
    return render(request, 'exploit_detail.html', {'exploit': exploit, 'ip_address': ip_address})


    

def run_exploit(request, name):
    if request.method == "POST":
        target_ip = request.POST.get("ip_address")
        username = request.POST.get("username")

        # MongoDB에서 스크립트 정보 가져오기
        exploit = exploit_collection.find_one({"name": name})
        if not exploit:
            return JsonResponse({"error": "Exploit not found."})

        script_path = f"hd/script/{exploit['script']}"

        try:
            # 스크립트를 실행하고 결과를 한번에 가져옴
            result = subprocess.run(
                ["python3", script_path, target_ip, username],
                capture_output=True,
                text=True
            )

            # 결과를 JsonResponse로 반환
            return JsonResponse({
                "message": "공격이 완료되었습니다.",
                "stdout": result.stdout or "No output",
                "stderr": result.stderr or "No errors"
            })

        except Exception as e:
            return JsonResponse({
                "message": "스크립트 실행 중 오류가 발생했습니다.",
                "error": str(e)
            })

    return JsonResponse({"error": "Invalid request method."})
    
    
# CVE Results 페이지 뷰
def cve_results(request):
    # 가장 최신의 scan_result를 가져옵니다.
    scan_result = scan_results.find().sort("timestamp", -1).limit(1)[0]

    current_ip = scan_result.get("ip_address", "Unknown IP")
    cve_risk_results = scan_result.get("cve_risk_results", [])
    cve_results = scan_result.get("cve_results", [])

    # 전체 CVE 데이터를 페이지네이션
    page = int(request.GET.get("page", 1))
    page_size = 10
    total_cve_count = cve_db.count_documents({})
    paginated_cve_records = list(cve_db.find().skip((page - 1) * page_size).limit(page_size))

    # cve_risk_results와 cve_results의 score_data 키 변경
    for cve in cve_risk_results:
        if cve.get("score_data"):
            score = cve["score_data"][0]
            cve["Base_Severity"] = score.get("Base Severity", "N/A")
            cve["Impact_Score"] = score.get("Impact Score", "N/A")

    for cve in cve_results:
        if cve.get("score_data"):
            score = cve["score_data"][0]
            cve["Base_Severity"] = score.get("Base Severity", "N/A")
            cve["Impact_Score"] = score.get("Impact Score", "N/A")

    total_pages = (total_cve_count + page_size - 1) // page_size
    page_range = range(1, total_pages + 1)
    next_page = page + 1 if page < total_pages else None
    previous_page = page - 1 if page > 1 else None

    context = {
        "current_ip": current_ip,
        "cve_risk_results": cve_risk_results,
        "cve_results": cve_results,
        "total_cve_count": total_cve_count,
        "paginated_cve_records": paginated_cve_records,
        "next_page": next_page,
        "previous_page": previous_page,
        "current_page": page,
        "total_pages": total_pages,
        "page_range": page_range,
    }

    return render(request, "cve.html", context)
    
    
def cve_detail(request, cve_name):
    cve_record = cve_db.find_one({"CVE_name": cve_name})

    if not cve_record:
        return render(request, "404.html", {"message": "CVE Record not found"})

    # score_data 가공
    if "score_data" in cve_record and cve_record["score_data"]:
        score_data = cve_record["score_data"][0]
        cve_record["Base_Severity"] = score_data.get("Base Severity", "N/A")
        cve_record["Impact_Score"] = score_data.get("Impact Score", "N/A")
        cve_record["Score_Source"] = score_data.get("Score Source", "N/A")

    context = {
        "cve_record": cve_record
    }

    return render(request, "cve_detail.html", context)
    
    
    


def red_flag(request):
    # 가장 최신의 로그 데이터를 가져옵니다.
    latest_logs = list(logs_collection.find().sort("date", -1).sort("time", -1).limit(20))
    context = {
        "latest_logs": latest_logs
    }
    return render(request, "red_flag.html", context)



# Red Flag 페이지 뷰
def red_flag(request):
    # 가장 최신의 로그 데이터를 가져옵니다.
    latest_logs = list(logs_collection.find().sort([("date", -1), ("time", -1)]).limit(20))
    context = {
        "latest_logs": latest_logs
    }
    return render(request, "red_flag.html", context)

# 최신 로그 데이터를 JSON 형식으로 제공하는 뷰
def get_latest_logs(request):
    try:
        # 아직 viewed 상태가 아닌 로그만 가져오기
        latest_logs = list(logs_collection.find({"viewed": {"$ne": True}}).sort([("date", -1), ("time", -1)]).limit(50))

        # ObjectId를 문자열로 변환
        for log in latest_logs:
            log["_id"] = str(log["_id"])

        return JsonResponse({"latest_logs": latest_logs})
    except Exception as e:
        return JsonResponse({"error": str(e)})

# 로그 상태 업데이트 뷰
def mark_log_as_viewed(request, log_id):
    try:
        # 로그의 viewed 상태를 True로 업데이트 또는 없는 경우 추가
        logs_collection.update_one({"_id": ObjectId(log_id)}, {"$set": {"viewed": True}}, upsert=True)
        return JsonResponse({"status": "success"})
    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})

