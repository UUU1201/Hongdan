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



def main():
    check_root()
    scripts = ["SA01-R001.sh", "SA02-R002.sh","SA03-R003.sh"]  # 실행할 스크립트 목록
    generate_report(scripts)
    print("Vulnerability check completed and report generated.")

if __name__ == "__main__":
    main()

