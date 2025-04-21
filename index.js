// index.js
import fetch from 'node-fetch';
import { XMLParser } from 'fast-xml-parser';
import { createClient } from '@supabase/supabase-js';
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
  // 1) 환경변수에서 Supabase 및 Firebase 인증 정보 받아옴
  const SUPABASE_URL = process.env.SUPABASE_URL;
  const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;

  // Firebase Admin SDK 초기화
  const FIREBASE_PROJECT_ID = process.env.FIREBASE_PROJECT_ID;
  const FIREBASE_CLIENT_EMAIL = process.env.FIREBASE_CLIENT_EMAIL;
  const FIREBASE_PRIVATE_KEY = process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n');
  
  if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
    throw new Error('Missing Supabase environment variables');
  }

  if (!FIREBASE_PROJECT_ID || !FIREBASE_CLIENT_EMAIL || !FIREBASE_PRIVATE_KEY) {
    throw new Error('Missing Firebase environment variables');
  }

  // Firebase 초기화
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: FIREBASE_PROJECT_ID,
      clientEmail: FIREBASE_CLIENT_EMAIL,
      privateKey: FIREBASE_PRIVATE_KEY,
    }),
  });

  // 2) Supabase Client 초기화 (서비스 계정 키 사용)
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  });

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
        const { data: existing, error: queryError } = await supabase
          .from('posts')
          .select('id')
          .eq('link', link)
          .maybeSingle();

        if (queryError) {
          console.error(`DB query error for ${boardId}:`, queryError);
          continue;
        }

        if (existing) {
          // 이미 존재 -> 여기서 나머지 아이템을 검사하지 않고 다음 게시판으로 넘어감
          console.log(`[OLD POST] boardId=${boardId}, title=${title.slice(0, 30)}. Skipping the rest of this feed...`);
          break;
        }

        // 새 게시물 -> Supabase에 저장
        const { data: newPost, error: insertError } = await supabase
          .from('posts')
          .insert({
            board_id: boardId,
            title,
            link,
            description,
            author,
            created_at: new Date().toISOString(),
          })
          .select()
          .single();

        if (insertError) {
          console.error(`Failed to save post for ${boardId}:`, insertError);
          continue;
        }

        console.log(`[NEW POST] boardId=${boardId}, title=${title.slice(0, 30)}`);
        
        // 해당 게시판을 구독한 사용자들에게 알림 발송
        await sendPushNotifications(supabase, boardId, title, link);
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
async function sendPushNotifications(supabase, boardId, title, link) {
  try {
    // 해당 게시판을 구독한 사용자 목록 조회 - Postgres 배열 contains 연산자 사용
    const { data: subscribers, error: subError } = await supabase
      .from('subscriptions')
      .select('id, user_id')
      .contains('boards', [boardId]);

    if (subError) {
      console.error(`Error fetching subscribers:`, subError);
      return;
    }

    if (!subscribers || subscribers.length === 0) {
      console.log(`No subscribers for boardId=${boardId}`);
      return;
    }

    console.log(`Found ${subscribers.length} subscribers for boardId=${boardId}`);

    // 사용자별 디바이스 토큰을 수집
    const userTokensMap = new Map(); // userId -> fcm tokens array

    // 모든 구독자의 디바이스 토큰 수집
    for (const subscriber of subscribers) {
      const userId = subscriber.user_id;
      
      // user_devices 테이블에서 해당 사용자의 디바이스 토큰 조회
      const { data: userDevices, error: deviceError } = await supabase
        .from('user_devices')
        .select('id, fcm_token')
        .eq('user_id', userId);
      
      if (deviceError) {
        console.error(`Error fetching devices for user ${userId}:`, deviceError);
        continue;
      }
      
      if (!userDevices || userDevices.length === 0) {
        console.log(`No devices found for user ${userId}`);
        continue;
      }
      
      console.log(`Found ${userDevices.length} devices for user ${userId}`);
      
      // 유효한 토큰만 수집
      const validTokens = userDevices
        .filter(device => device.fcm_token)
        .map(device => ({
          token: device.fcm_token,
          deviceId: device.id
        }));
      
      if (validTokens.length > 0) {
        userTokensMap.set(userId, validTokens);
      }
    }

    // FCM 메시지 기본 구성
    const baseMessage = {
      data: {
        boardName: getBoardName(boardId),
        title: title,
        postLink: link,
      }
    };

    // 각 사용자별로 알림 전송
    for (const [userId, devices] of userTokensMap.entries()) {
      console.log(`Sending notifications to user ${userId} with ${devices.length} devices`);
      
      // 각 디바이스별로 개별 메시지 생성
      const messages = devices.map(device => ({
        data: baseMessage.data,
        token: device.token
      }));
      
      try {
        // 메시지 전송
        const response = await admin.messaging().sendEach(messages);
        console.log(`Notifications for user ${userId}: ${response.successCount} successes, ${response.failureCount} failures`);
        
        // 실패한 토큰 처리
        if (response.failureCount > 0) {
          const failedTokens = response.responses
            .map((resp, idx) => !resp.success ? { token: devices[idx].token, error: resp.error, deviceId: devices[idx].deviceId } : null)
            .filter(Boolean);
          
          // 유효하지 않은 토큰 정리
          for (const {deviceId, error} of failedTokens) {
            if (
              error.code === 'messaging/invalid-registration-token' ||
              error.code === 'messaging/registration-token-not-registered'
            ) {
              console.log(`Removing invalid token for device ${deviceId}`);
              try {
                const { error: deleteError } = await supabase
                  .from('user_devices')
                  .delete()
                  .eq('id', deviceId);
                
                if (deleteError) {
                  console.error(`Error deleting invalid token:`, deleteError);
                }
              } catch (deleteError) {
                console.error(`Error deleting invalid token:`, deleteError);
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
    'dormGlobal': '글캠 기숙사',
    'dormMedical': '메캠 기숙사',
  };
  
  return boardNames[boardId] || boardId;
}

main().catch((err) => {
  console.error('Crawler failed:', err);
  process.exit(1);
});
