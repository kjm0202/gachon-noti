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

// Optional:
messaging.onBackgroundMessage((message) => {
  console.log("onBackgroundMessage", message);
});