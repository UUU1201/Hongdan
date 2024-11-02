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

def run_check(script_name):
    print(f"Running {script_name}...")
    result = subprocess.run([f"./{script_name}"], capture_output=True, text=True)
    print(result.stdout)
    return result.stdout

def generate_report(scripts):
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
    c.setFont("NanumGothic", 10)  # 등록한 한글 폰트를 기본 설정

    y_position = 800

    for script in scripts:
        # 타이틀을 bold와 큰 폰트로 출력
        script_title = f"{script}: " + subprocess.check_output(["head", "-n", "1", script], text=True).strip()
        c.setFont("NanumGothic", 18)
        c.drawString(100, y_position, script_title)
        y_position -= 30  # 타이틀 아래 간격 추가

        # 스크립트의 출력 결과 출력
        output = run_check(script)
        c.setFont("NanumGothic", 10)  # 출력 결과는 기본 폰트 크기로 설정
        for line in output.splitlines():
            if len(line) > 90:  # 한 줄의 길이가 너무 길면 줄바꿈 처리
                lines = [line[i:i + 90] for i in range(0, len(line), 90)]
                for l in lines:
                    c.drawString(100, y_position, l)
                    y_position -= 20
            else:
                c.drawString(100, y_position, line)
                y_position -= 20

        y_position -= 20  # 각 스크립트 사이에 추가 간격

        # 페이지 끝에 도달하면 새로운 페이지 생성
        if y_position < 50:
            c.showPage()
            c.setFont("NanumGothic", 10)
            y_position = 800

    c.save()
    print(f"Report generated at {report_path}")

def main():
    check_root()
    scripts = ["SA01-R001.sh", "SA01-R002.sh", "SA01-R003.sh"]  # 실행할 스크립트 목록
    generate_report(scripts)
    print("Vulnerability check completed and report generated.")

if __name__ == "__main__":
    main()
