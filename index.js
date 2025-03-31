// index.js
const fetch = require('node-fetch');
const { XMLParser } = require('fast-xml-parser');
const { Client, Databases, Query } = require('node-appwrite');

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
  // 1) 환경변수에서 Appwrite 인증 정보 받아옴
  const APPWRITE_ENDPOINT = process.env.APPWRITE_ENDPOINT;
  const APPWRITE_API_KEY = process.env.APPWRITE_API_KEY;
  const APPWRITE_PROJECT_ID = process.env.APPWRITE_PROJECT_ID;
  const DATABASE_ID = process.env.APPWRITE_DATABASE_ID;
  const POSTS_COLLECTION_ID = process.env.APPWRITE_POSTS_COLLECTION_ID;

  if (!APPWRITE_ENDPOINT || !APPWRITE_API_KEY || !APPWRITE_PROJECT_ID || !DATABASE_ID || !POSTS_COLLECTION_ID) {
    throw new Error('Missing Appwrite environment variables');
  }

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
          // 이미 존재 -> 스킵
          continue;
        }

        // 새 게시물 -> Appwrite에 저장
        await databases.createDocument(DATABASE_ID, POSTS_COLLECTION_ID, 'unique()', {
          boardId,
          title,
          link,
          description,
          pubDate,
          author,
          createdAt: new Date().toISOString(),
        });

        console.log(`[NEW POST] boardId=${boardId}, title=${title.slice(0, 30)}`);
        // 알림 로직이 있다면 여기서 FCM 발송 or 큐잉
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

main().catch((err) => {
  console.error('Crawler failed:', err);
  process.exit(1);
});
