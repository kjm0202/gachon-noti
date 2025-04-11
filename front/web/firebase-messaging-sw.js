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

// 백그라운드 메시지 수신
messaging.onBackgroundMessage(async (payload) => {
  console.log("[SW] Background message received", payload);
  const notificationTitle = "[" + payload.data.boardName + "] 새 공지";
  const notificationOptions = {
    body: payload.data.title,
    icon: "/icons/Icon-192.png",
    data: payload.data.postLink,
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});

// 알림 클릭 이벤트 처리
self.addEventListener('notificationclick', (event) => {
  console.log('[SW] Notification clicked', event);

  event.notification.close();

  const postLink = event.notification.data;
  const urlToOpen = postLink ? new URL(postLink) : new URL('/', self.location.origin);

  // 비동기 작업을 수행하기 위한 메서드로 아래 Promise가 완료될 때까지 이벤트 수명을 연장
  event.waitUntil(
    clients // 서비스 워커에서 현재 제어하는 클라이언트 목록 
      .matchAll({
        type: "window",
        includeUncontrolled: true, // 제어하고 있지 않은 클라이언트까지 포함 (백그라운드)
      })
      .then((windowClients) => {
        let foundWindowClient = null;
        // 이미 열려 있는 창에서 서비스와 관련된 URL을 찾기 위한 로직 추가
        for (let i = 0; i < windowClients.length; i++) {
          const client = windowClients[i];

          if (
            (new URL(client.url).hostname.includes("gachon")) &&
            "focus" in client
          ) {
            foundWindowClient = client;
            break;
          }
        }

        // 만약 백그라운드에 해당 서비스가 있다면 
        if (foundWindowClient) {
          // 해당 탭을 focus하여 이동시킴
          return foundWindowClient.focus().then((focusedClient) => {
            if ("navigate" in focusedClient) {
              // 원하는 주소로 이동
              focusedClient.postMessage(urlToOpen.href);
            }
          });

          // 그게 아니라면 새창을 열어서 원하는 URL로 이동시킴 
        } else if (clients.openWindow) {
          return clients.openWindow(urlToOpen.href);
        }
      }),
  );
});