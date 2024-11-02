import os
import subprocess
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
import datetime
import sys

def check_root():
    # 현재 사용자가 root 권한인지 확인
    if os.geteuid() != 0:
        print("This script must be run as root. Please re-run with 'sudo' or as the root user.")
        sys.exit(1)
    else:
        print("Running with root privileges.")

def run_check():
    # Shell 스크립트 실행
    print("Running SA01-R001.sh script...")
    result = subprocess.run(["./SA01-R001.sh"], capture_output=True, text=True)
    print(result.stdout)
    return result.stdout

def generate_report(output):
    # 현재 날짜와 시간으로 PDF 파일 이름 생성
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d%H%M")
    report_path = f"reports/report_{timestamp}.pdf"
    c = canvas.Canvas(report_path, pagesize=A4)
    c.drawString(100, 800, "Samba AD Vulnerability Report")
    c.drawString(100, 780, f"Date: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    c.drawString(100, 760, "---------------------------------------------------")
    
    # 점검 결과 출력
    y_position = 740
    for line in output.splitlines():
        c.drawString(100, y_position, line)
        y_position -= 20
    
    c.save()
    print(f"Report generated at {report_path}")

def main():
    # root 권한 확인
    check_root()

    # 취약점 점검 실행
    output = run_check()
    
    # PDF 보고서 생성
    generate_report(output)
    print("Vulnerability check completed and report generated.")

if __name__ == "__main__":
    main()
