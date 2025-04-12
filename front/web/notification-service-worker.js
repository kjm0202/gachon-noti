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
  
  // 알림 데이터(URL) 가져오기
  const url = event.notification.data;
  
  if (url) {
    console.log('이동할 URL:', url);
    
    // 클라이언트 창 제어
    event.waitUntil(
      clients.matchAll({type: 'window'}).then((clientList) => {
        // 이미 열려있는 창이 있는지 확인
        for (let i = 0; i < clientList.length; i++) {
          const client = clientList[i];
          
          // 현재 사이트의 창이 있으면 포커스하고 메시지 전송
          if ('focus' in client) {
            client.focus();
            
            // 클라이언트에 메시지 전송 (handleNotificationClick 함수 호출)
            client.postMessage({
              type: 'NOTIFICATION_CLICK',
              url: url
            });
            return;
          }
        }
        
        // 열린 창이 없으면 새 창 열기 (URL 파라미터 추가로 알림 처리를 위한 정보 전달)
        if (clients.openWindow) {
          // URL이 상대 경로인 경우 처리
          if (url.startsWith('http')) {
            // 외부 URL은 그대로 사용
            return clients.openWindow(url);
          } else {
            // 상대 경로인 경우 현재 origin에 notification 파라미터 추가
            const appUrl = new URL(self.registration.scope);
            appUrl.searchParams.set('notification', 'true');
            appUrl.searchParams.set('url', url);
            return clients.openWindow(appUrl.toString());
          }
        }
      })
    );
  }
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
        icon: '/icons/app_icon.png',
        badge: '/icons/app_icon.png',
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