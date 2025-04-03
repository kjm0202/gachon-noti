// index.js
import fetch from 'node-fetch';
import { XMLParser } from 'fast-xml-parser';
import { Client, Databases, Query } from 'node-appwrite';
import admin from 'firebase-admin';

// RSS 목록 정의
const RSS_FEEDS = [
  { boardId: 'bachelor', url: 'https://www.gachon.ac.kr/bbs/kor/475/rssList.do?row=50' },
  { boardId: 'scholarship', url: 'https://www.gachon.ac.kr/bbs/kor/478/rssList.do?row=50' },
  { boardId: 'student', url: 'https://www.gachon.ac.kr/bbs/kor/479/rssList.do?row=50' },
  { boardId: 'job', url: 'https://www.gachon.ac.kr/bbs/kor/480/rssList.do?row=50' },
  { boardId: 'extracurricular', url: 'https://www.gachon.ac.kr/bbs/kor/743/rssList.do?row=50' },
  { boardId: 'other', url: 'https://www.gachon.ac.kr/bbs/kor/740/rssList.do?row=50' },
  { boardId: 'dormGlobal', url: 'https://www.gachon.ac.kr/bbs/dormitory/330/rssList.do?row=50' },
  { boardId: 'dormMedical', url: 'https://www.gachon.ac.kr/bbs/dormitory/334/rssList.do?row=50' },
];

async function main() {
  // 1) 환경변수에서 Appwrite 및 Firebase 인증 정보 받아옴
  const APPWRITE_ENDPOINT = process.env.APPWRITE_ENDPOINT;
  const APPWRITE_API_KEY = process.env.APPWRITE_API_KEY;
  const APPWRITE_PROJECT_ID = process.env.APPWRITE_PROJECT_ID;
  const DATABASE_ID = process.env.APPWRITE_DATABASE_ID;
  const POSTS_COLLECTION_ID = process.env.APPWRITE_POSTS_COLLECTION_ID;
  const SUBSCRIPTIONS_COLLECTION_ID = process.env.APPWRITE_SUBSCRIPTIONS_COLLECTION_ID;
  const USER_DEVICES_COLLECTION_ID = process.env.APPWRITE_USER_DEVICES_COLLECTION_ID;

  // Firebase Admin SDK 초기화
  const FIREBASE_PROJECT_ID = process.env.FIREBASE_PROJECT_ID;
  const FIREBASE_CLIENT_EMAIL = process.env.FIREBASE_CLIENT_EMAIL;
  const FIREBASE_PRIVATE_KEY = process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n');
  
  if (!APPWRITE_ENDPOINT || !APPWRITE_API_KEY || !APPWRITE_PROJECT_ID || !DATABASE_ID || !POSTS_COLLECTION_ID) {
    throw new Error('Missing Appwrite environment variables');
  }

  if (!FIREBASE_PROJECT_ID || !FIREBASE_CLIENT_EMAIL || !FIREBASE_PRIVATE_KEY) {
    throw new Error('Missing Firebase environment variables');
  }

  if (!USER_DEVICES_COLLECTION_ID) {
    throw new Error('Missing APPWRITE_USER_DEVICES_COLLECTION_ID environment variable');
  }

  // Firebase 초기화
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: FIREBASE_PROJECT_ID,
      clientEmail: FIREBASE_CLIENT_EMAIL,
      privateKey: FIREBASE_PRIVATE_KEY,
    }),
  });

  // 2) Appwrite Client 초기화
  const client = new Client()
    .setEndpoint(APPWRITE_ENDPOINT)
    .setProject(APPWRITE_PROJECT_ID)
    .setKey(APPWRITE_API_KEY);

  const databases = new Databases(client);

  // 3) RSS 파서 준비
  const parser = new XMLParser({
    ignoreAttributes: false,
    attributeNamePrefix: '',
  });

  // 4) 각 RSS에 대해 순회
  for (const feed of RSS_FEEDS) {
    const { boardId, url } = feed;
    console.log(`Checking RSS: ${boardId} => ${url}`);

    try {
      // 4-1) RSS XML 요청
      const response = await fetch(url);
      const xmlData = await response.text();

      // 4-2) XML 파싱
      const parsed = parser.parse(xmlData);
      const items = parsed?.rss?.channel?.item;
      if (!items) {
        console.log(`No items found in RSS for boardId=${boardId}`);
        continue;
      }

      // RSS 항목이 1개인 경우에도 배열처럼 처리하기 위해 변환
      const rssItems = Array.isArray(items) ? items : [items];

      // 4-3) 각 item을 확인
      for (const item of rssItems) {
        const link = item.link;
        const title = parseCDATA(item.title);
        const description = parseCDATA(item.description);
        const pubDate = parsePubDate(item.pubDate);
        const author = item.author || '관리자';

        // 중복 체크: link를 unique key로 사용
        const existing = await databases.listDocuments(DATABASE_ID, POSTS_COLLECTION_ID, [
          Query.equal('link', link),
        ]);

        if (existing.total > 0) {
          // 이미 존재 -> 여기서 나머지 아이템을 검사하지 않고 다음 게시판으로 넘어감
          console.log(`[OLD POST] boardId=${boardId}, title=${title.slice(0, 30)}. Skipping the rest of this feed...`);
          break;
        }

        // 새 게시물 -> Appwrite에 저장
        const newPost = await databases.createDocument(DATABASE_ID, POSTS_COLLECTION_ID, 'unique()', {
          boardId,
          title,
          link,
          description,
          pubDate,
          author,
          createdAt: new Date().toISOString(),
        });

        console.log(`[NEW POST] boardId=${boardId}, title=${title.slice(0, 30)}`);
        
        // 해당 게시판을 구독한 사용자들에게 알림 발송
        await sendPushNotifications(databases, DATABASE_ID, SUBSCRIPTIONS_COLLECTION_ID, USER_DEVICES_COLLECTION_ID, boardId, title, link);
      }
    } catch (err) {
      console.error(`Failed to parse feed ${boardId}:`, err);
    }
  }

  console.log('RSS crawling complete');
}

/** Helper: CDATA or plain text 파싱 */
function parseCDATA(value) {
  if (!value) return '';
  if (value.includes('<![CDATA[')) {
    // CDATA 제거
    return value
      .replace('<![CDATA[', '')
      .replace(']]>', '')
      .trim();
  }
  return value.trim();
}

/** Helper: pubDate -> ISO8601 변환 */
function parsePubDate(dateStr) {
  if (!dateStr) return null;
  // 예: "2025.03.12 15:53:29" 형태 → "2025-03-12T15:53:29"
  // 아래는 단순 예시. 실제 포맷에 맞춰 파싱
  const replaced = dateStr.replace(/\./g, '-'); // 2025-03-12 15:53:29
  const isoLike = replaced.replace(' ', 'T');  // 2025-03-12T15:53:29
  return isoLike;
}

/**
 * 사용자들에게 푸시 알림 발송
 */
async function sendPushNotifications(databases, databaseId, subscriptionsCollectionId, userDevicesCollectionId, boardId, title, link) {
  try {
    // 해당 게시판을 구독한 사용자 목록 조회
    const subscribers = await databases.listDocuments(databaseId, subscriptionsCollectionId, [
      Query.equal('boards', [boardId]),  // 사용자가 구독한 게시판 배열에 현재 게시판이 포함된 경우
    ]);

    if (subscribers.total === 0) {
      console.log(`No subscribers for boardId=${boardId}`);
      return;
    }

    console.log(`Found ${subscribers.total} subscribers for boardId=${boardId}`);

    // 사용자별 디바이스 토큰을 수집
    // 각 사용자마다 한 번씩만 처리하기 위해 Map으로 관리
    const userTokensMap = new Map(); // userId -> fcm tokens array

    // 모든 구독자의 디바이스 토큰 수집
    for (const subscriber of subscribers.documents) {
      const userId = subscriber.userId;
      
      // user_devices 컬렉션에서 해당 사용자의 디바이스 토큰 조회
      const userDevices = await databases.listDocuments(databaseId, userDevicesCollectionId, [
        Query.equal('userId', userId),
      ]);
      
      if (userDevices.total === 0) {
        console.log(`No devices found for user ${userId}`);
        continue;
      }
      
      console.log(`Found ${userDevices.total} devices for user ${userId}`);
      
      // 유효한 토큰만 수집
      const validTokens = userDevices.documents
        .filter(device => device.fcmToken)
        .map(device => ({
          token: device.fcmToken,
          deviceId: device.$id
        }));
      
      if (validTokens.length > 0) {
        userTokensMap.set(userId, validTokens);
      }
    }

    // FCM 메시지 기본 구성
    const baseMessage = {
      notification: {
        title: `[${getBoardName(boardId)}] 새 공지사항`,
        body: title,
      },
      data: {
        boardId: boardId,
        postLink: link,
        createdAt: new Date().toISOString(),
      }
    };

    // 각 사용자별로 한 번씩만 처리
    for (const [userId, devices] of userTokensMap.entries()) {
      console.log(`Sending notifications to user ${userId} with ${devices.length} devices`);
      
      try {
        // 각 디바이스별로 개별 메시지 생성 (sendEach 방식)
        const messages = devices.map(device => ({
          notification: baseMessage.notification,
          data: baseMessage.data,
          token: device.token
        }));
        
        // sendEach로 메시지 전송 (각 메시지는 완전한 형태여야 함)
        const response = await admin.messaging().sendEach(messages);
        
        console.log(`Notifications for user ${userId}: ${response.successCount} successes, ${response.failureCount} failures`);
        
        // 실패한 토큰 처리
        if (response.failureCount > 0) {
          const failedTokens = [];
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              const failedToken = devices[idx].token;
              const deviceId = devices[idx].deviceId;
              failedTokens.push({
                token: failedToken,
                error: resp.error,
                deviceId: deviceId
              });
            }
          });
          

          // 토큰이 유효하지 않거나 만료된 경우
          if (error.code === 'messaging/invalid-registration-token' || 
              error.code === 'messaging/registration-token-not-registered') {
            // 토큰 무효화를 위해 해당 디바이스 문서 삭제
            console.log(`Removing invalid token for device ${device.$id}`);
            await databases.deleteDocument(databaseId, userDevicesCollectionId, device.$id);

          // 유효하지 않은 토큰 정리
          for (const {token, error, deviceId} of failedTokens) {
            if (
              error.code === 'messaging/invalid-registration-token' ||
              error.code === 'messaging/registration-token-not-registered'
            ) {
              console.log(`Removing invalid token for device ${deviceId}`);
              try {
                await databases.deleteDocument(
                  databaseId,
                  process.env.APPWRITE_USER_DEVICES_COLLECTION_ID,
                  deviceId
                );
              } catch (deleteError) {
                console.error(`Error deleting invalid token document:`, deleteError);
              }
            } else {
              console.error(`FCM error for device ${deviceId}:`, error);
            }
          }
        }
      } catch (error) {
        console.error(`Error sending messages to user ${userId}:`, error);
      }
    }
  } catch (error) {
    console.error('Error in push notification process:', error);
  }
}

/** 게시판 ID에서 읽기 쉬운 이름으로 변환 */
function getBoardName(boardId) {
  const boardNames = {
    'bachelor': '학사',
    'scholarship': '장학',
    'student': '학생',
    'job': '취업',
    'extracurricular': '비교과',
    'other': '기타',
    'dormGlobal': '글로벌 기숙사',
    'dormMedical': '의학 기숙사',
  };
  
  return boardNames[boardId] || boardId;
}

main().catch((err) => {
  console.error('Crawler failed:', err);
  process.exit(1);
});
