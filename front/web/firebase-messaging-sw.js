// Please see this file for the latest firebase-js-sdk version:
// https://github.com/firebase/flutterfire/blob/master/packages/firebase_core/firebase_core_web/lib/src/firebase_sdk_version.dart
importScripts("https://www.gstatic.com/firebasejs/10.11.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.11.1/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: 'AIzaSyAY2__3KRqGTiavmyJhVo35L1t0IqOlqYA',
    appId: '1:1006219923383:web:341ae36a5cfd4c4371e232',
    messagingSenderId: '1006219923383',
    projectId: 'gachon-dorm-noti',
    authDomain: 'gachon-dorm-noti.firebaseapp.com',
    storageBucket: 'gachon-dorm-noti.firebasestorage.app',
    measurementId: 'G-9V0X2ZYRZ7',
});

const messaging = firebase.messaging();

// Flutter 앱에서 알림을 처리하므로 백그라운드 메시지 핸들러를 최소화
// 알림 표시는 FCM 서버에서 직접 처리하도록 하고 여기서는 최소한의 처리만 수행
messaging.onBackgroundMessage(async (message) => {
  console.log("[SW] Background message received", message);
  // 여기서는 알림을 직접 생성하지 않음
  // FCM이 자동으로 생성한 알림만 사용하여 중복 방지
  return Promise.resolve();
});

// 알림 클릭 이벤트 처리 - 이 부분이 안드로이드 Chrome에서 필요한 핵심 기능
self.addEventListener('notificationclick', (event) => {
  console.log('[SW] Notification clicked', event);
  
  // 알림 닫기
  event.notification.close();
  
  // 데이터 추출
  const data = event.notification.data || {};
  const link = data.link;
  
  // URL 결정
  let url = '/';
  if (link) {
    // 외부 링크인 경우 직접 열기
    if (link.startsWith('http')) {
      url = link;
    } else {
      // 내부 경로인 경우 도메인 추가
      url = self.location.origin + link;
    }
  }
  
  // 클라이언트 창 탐색 또는 새 창 열기
  const promiseChain = clients.matchAll({
    type: 'window',
    includeUncontrolled: true
  })
  .then((windowClients) => {
    // 열린 창이 있는지 확인
    for (let i = 0; i < windowClients.length; i++) {
      const client = windowClients[i];
      
      // 이미 열린 창이 있으면 포커스
      if ('focus' in client) {
        client.focus();
        
        if ('navigate' in client && url) {
          return client.navigate(url);
        }
        return;
      }
    }
    
    // 열린 창이 없으면 새 창 열기
    if (clients.openWindow) {
      return clients.openWindow(url);
    }
  });
  
  event.waitUntil(promiseChain);
});