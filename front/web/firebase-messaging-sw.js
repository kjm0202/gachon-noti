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

// 백그라운드 메시지 처리
messaging.onBackgroundMessage((message) => {
  console.log("onBackgroundMessage", message);
  
  const notification = message.notification;
  
  // 알림을 생성하고 표시
  const notificationTitle = notification?.title || '가천대학교 공지사항';
  const notificationOptions = {
    body: notification?.body || '새로운 공지사항이 있습니다.',
    icon: '/icons/Icon-192.png',
    data: message.data, // 데이터 전달
    tag: 'gachon-notice', // 알림 그룹화
    click_action: '/', // 기본 URL
  };
  
  if (message.data && message.data.link) {
    notificationOptions.click_action = message.data.link;
  }
  
  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// 알림 클릭 이벤트 처리
self.addEventListener('notificationclick', (event) => {
  console.log('Notification clicked', event);
  
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