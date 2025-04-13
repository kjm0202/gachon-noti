// 서비스 워커 설치 이벤트
self.addEventListener('install', (event) => {
  console.log('알림 서비스 워커가 설치되었습니다.');
  self.skipWaiting(); // 서비스 워커를 즉시 활성화
});

// 서비스 워커 활성화 이벤트
self.addEventListener('activate', (event) => {
  console.log('알림 서비스 워커가 활성화되었습니다.');
  // 새 서비스 워커가 즉시 제어권을 가져옴
  event.waitUntil(self.clients.claim());
});

// 알림 클릭 이벤트 리스너
self.addEventListener('notificationclick', (event) => {
  console.log('알림이 클릭되었습니다:', event);
  
  // 알림 닫기
  event.notification.close();
  
  // URL 추출 시도
  let url = null;
  
  try {
    console.log('알림 데이터 타입:', typeof event.notification.data);
    console.log('알림 데이터 값:', event.notification.data);
    
    // 문자열인 경우 직접 사용
    if (typeof event.notification.data === 'string') {
      url = event.notification.data;
    } 
    // 객체인 경우 toString 호출
    else if (event.notification.data) {
      url = event.notification.data.toString();
    }
    
    // URL 유효성 검사
    if (!url || url === 'undefined' || url === '[object Object]') {
      url = 'https://www.gachon.ac.kr/kor/index.do'; // 기본 URL
    }
    
    // 상대 URL을 절대 URL로 변환
    if (url && !url.startsWith('http')) {
      url = self.registration.scope + url.replace(/^\//, '');
    }
    
    console.log('최종 URL:', url);
  } catch (error) {
    console.error('URL 처리 중 오류:', error);
    url = 'https://www.gachon.ac.kr/kor/index.do'; // 오류 시 기본 URL
  }
  
  // URL 열기
  event.waitUntil(
    // 별도의 처리 없이 바로 URL 열기
    self.clients.openWindow(url)
      .then(windowClient => {
        console.log('창이 열렸습니다:', windowClient);
      })
      .catch(error => {
        console.error('창 열기 실패:', error);
        // 실패 시 기본 URL로 다시 시도
        return self.clients.openWindow('https://www.gachon.ac.kr/kor/index.do');
      })
  );
});

// 푸시 이벤트 리스너 (백그라운드 푸시 알림용)
self.addEventListener('push', (event) => {
  console.log('푸시 알림이 수신되었습니다:', event);
  
  if (event.data) {
    try {
      const data = event.data.json();
      
      // 알림 표시
      const notificationOptions = {
        body: data.body || '새 알림이 있습니다.',
        data: data.postLink,
        requireInteraction: true
      };
      
      event.waitUntil(
        self.registration.showNotification(data.title || '가천 알림이', notificationOptions)
      );
    } catch (e) {
      console.error('푸시 데이터 처리 중 오류:', e);
    }
  }
});

// 메시지 수신 이벤트 리스너
self.addEventListener('message', (event) => {
  console.log('서비스 워커가 메시지를 수신했습니다:', event.data);
  
  // 메인 앱에서 보낸 메시지 처리
  if (event.data && event.data.type === 'PING') {
    // 연결 확인용 응답
    event.ports[0].postMessage({
      type: 'PONG',
      status: 'Service Worker is active'
    });
  }
}); 