import os
import subprocess
from reportlab.lib.pagesizes import A4
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase import pdfmetrics 
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
import datetime
import sys

def check_root():
    if os.geteuid() != 0:
        print("This script must be run as root. Please re-run with 'sudo' or as the root user.")
        sys.exit(1)
    else:
        print("Running with root privileges.")

def run_check():
    print("관리자 계정(Administrator) 원격 접속 제한 설정 확인중...")
    result = subprocess.run(["./SA01-R001.sh"], capture_output=True, text=True)
    print(result.stdout)
    return result.stdout

def generate_report(output):
    # 현재 날짜와 시간으로 PDF 파일 이름 생성
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d%H%M")
    report_path = f"reports/report_{timestamp}.pdf"

    # reports 폴더가 없으면 생성
    if not os.path.exists("reports"):
        os.makedirs("reports")
        
    # 폰트 등록 (나눔 고딕)
    pdfmetrics.registerFont(TTFont('NanumGothic', '/usr/share/fonts/truetype/nanum/NanumGothic.ttf'))
    


    # PDF 보고서 생성
    c = canvas.Canvas(report_path, pagesize=A4)
    c.setFont("NanumGothic", 10)  # 등록한 한글 폰트를 설정
    c.drawString(100, 800, "Samba AD Vulnerability Report")
    c.drawString(100, 780, f"Date: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    c.drawString(100, 760, "---------------------------------------------------")

    # 점검 결과 출력
    y_position = 740
    for line in output.splitlines():
        if len(line) > 90:  # 한 줄의 길이가 너무 길면 줄바꿈 처리
            lines = [line[i:i+90] for i in range(0, len(line), 90)]
            for l in lines:
                c.drawString(100, y_position, l)
                y_position -= 20
        else:
            c.drawString(100, y_position, line)
            y_position -= 20

    c.save()
    print(f"Report generated at {report_path}")

def main():
    check_root()
    output = run_check()
    generate_report(output)
    print("Vulnerability check completed and report generated.")

if __name__ == "__main__":
    main()
