import json
import subprocess
import re

# 결과 저장할 JSON 파일 경로
parsed_results_path = "nmap_results.json"

# nmap 결과 파싱 함수
def parse_nmap_output(content):
    parsed_data = {"open_ports": [], "unknown_ports": []}

    # 포트 상태별로 파싱
    for line in content.splitlines():
        match = re.search(r"(\d+/tcp)\s+(\w+)\s+(\S+)", line)
        if match:
            port = match.group(1)
            state = match.group(2)
            service = match.group(3)

            if state == "open":
                parsed_data["open_ports"].append({"port": port, "service": service})
            else:
                parsed_data["unknown_ports"].append({"port": port, "state": state, "service": service})

    return parsed_data

# nmap 실행 및 저장
def main():
    target_ip = "172.30.1.57"
    
    print("Running nmap...")
    # nmap 실행 및 결과 가져오기
    nmap_result = subprocess.run(
        ["nmap", "-p", "53,88,135,137,138,139,389,445,464,636,3268,3269", target_ip],
        capture_output=True,
        text=True
    ).stdout
    
    # nmap 결과 파싱
    parsed_data = parse_nmap_output(nmap_result)
    
    # JSON 파일로 저장
    print("Saving parsed results to JSON file...")
    with open(parsed_results_path, 'w', encoding='utf-8') as json_file:
        json.dump(parsed_data, json_file, ensure_ascii=False, indent=4)
    print(f"Parsed results saved to {parsed_results_path}")

    # 화면에 결과 출력
    print("\n--- Parsed Information ---\n")
    print(json.dumps(parsed_data, indent=4))

if __name__ == "__main__":
    main()
