# hd/urls.py

from . import views
from django.urls import path
from .views import exploit_list, exploit_detail, run_exploit  # Make sure to import your views

urlpatterns = [
    path('', views.index, name='index'),  # 메인 페이지
    
    #scan
    path('run_scan/', views.run_scan, name='run_scan'),  # 스캔 실행
    path('dashboard/', views.dashboard, name='dashboard'),
    path('scan/', views.scan, name='scan_latest'),  # 최신 스캔 결과 보기
    path('initiate_scan/', views.initiate_scan, name='initiate_scan'),  # 스캔 시작
    path('scan/<str:scan_id>/', views.scan, name='scan'),  # 특정 스캔 기록 조회
    
    #vulc
    path('vul_result/<str:vulc_id>/', views.vul_result, name='vul_result'),
    path('vul_result/<str:vulc_id>/<str:scan_id>/', views.vul_result, name='vul_result_with_scan_id'),

    
    #reports
    path('reports/', views.reports_page, name='reports_page'),
    path('reports/detail/<str:scan_id>/', views.scan_detail, name='scan_detail'),  # 스캔 상세 페이지

    # Exploit 관련 경로
    path('exploit/', views.exploit_list, name='exploit_list'),  # Exploit 목록 페이지
    path('exploit/<str:name>/', views.exploit_detail, name='exploit_detail'),  # Exploit 세부 페이지
    path('run_exploit/<str:name>/', views.run_exploit, name='run_exploit'),  # 공격 실행 URL
    
    #cve
    path('cve/', views.cve_results, name='cve'),
    path('cve_detail/<str:cve_name>/', views.cve_detail, name='cve_detail'),
    
    #redflag
    path('red_flag/', views.red_flag, name='red_flag'),
    path('get_latest_logs/', views.get_latest_logs, name='get_latest_logs'),
    path('mark_log_as_viewed/<str:log_id>/', views.mark_log_as_viewed, name='mark_log_as_viewed'),
    
]

