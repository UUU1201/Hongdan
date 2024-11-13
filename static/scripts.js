// 최신 로그 가져오기 함수
function fetchLatestLogs() {
    console.log("fetchLatestLogs 호출됨"); // 디버깅용 로그
    fetch('/get_latest_logs/')
        .then(response => response.json())
        .then(data => {
            console.log("서버에서 데이터 수신 완료:", data); // 디버깅용 로그
            if (data.latest_logs && data.latest_logs.length > 0) {
                const latestLog = data.latest_logs[0];
                const logId = latestLog._id;

                // 로컬 스토리지에 로그가 없으면 알림 표시
                if (!localStorage.getItem(`viewed_log_${logId}`)) {
                    showNotification(`New log!!!!: ${latestLog.message}`, logId);
                }
            }

            // 5초마다 최신 로그 확인
            setTimeout(fetchLatestLogs, 5000);
        })
        .catch(error => {
            console.error('Error fetching latest logs:', error);
            setTimeout(fetchLatestLogs, 5000);
        });
}

// 알람 표시 함수
function showNotification(message, logId) {
    const banner = document.getElementById('notification-banner');
    const messageSpan = document.getElementById('notification-message');

    // 알림 메시지 설정 및 표시
    messageSpan.textContent = message;
    banner.classList.remove('hidden');
    banner.style.top = '0';

    // 로그를 봤다고 서버에 알리기 (로컬 스토리지에도 저장)
    markLogAsViewed(logId);
    localStorage.setItem(`viewed_log_${logId}`, true);
}

// 알람 닫기 함수
function closeNotification() {
    const banner = document.getElementById('notification-banner');
    banner.style.top = '-100px';
    setTimeout(() => {
        banner.classList.add('hidden');
    }, 500);
}

// 로그를 확인했다고 서버에 알리기 위한 함수
function markLogAsViewed(logId) {
    fetch('/mark_log_as_viewed/', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRFToken': window.CSRF_TOKEN // CSRF Token 추가
        },
        body: JSON.stringify({ log_id: logId })
    })
    .then(response => response.json())
    .then(data => {
        if (data.status === "success") {
            console.log("Log marked as viewed successfully");
        } else {
            console.error("Error marking log as viewed:", data.message);
        }
    })
    .catch(error => {
        console.error("Error marking log as viewed:", error);
    });
}

// 페이지가 로드될 때 최신 로그 가져오기 시작
window.onload = function() {
    console.log("페이지가 로드되었음, fetchLatestLogs 호출 시작");
    fetchLatestLogs();
};

