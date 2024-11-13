from django.db import models

# Create your models here.

class ScanResult(models.Model):
    name = models.CharField(max_length=100)  # 검사 이름 (예: "scan of 172.30.13.56")
    status = models.CharField(max_length=50)  # 상태 (예: "in progress... (30%)")
    report_link = models.URLField()  # 보고서 링크
    date = models.DateTimeField(auto_now_add=True)  # 날짜

    def __str__(self):
        return f"{self.name} - {self.status}"
        

