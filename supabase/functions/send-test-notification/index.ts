// Supabase Edge Function: send-test-notification
// 디버그 모드에서 테스트 데이터를 posts 테이블에 넣고,
// 요청한 기기의 FCM 토큰으로 직접 알림을 전송한다.
//
// 배포 방법:
//   supabase functions deploy send-test-notification
//
// 필요한 환경 변수 (Supabase Dashboard > Edge Functions > Secrets):
//   FIREBASE_PROJECT_ID
//   FIREBASE_CLIENT_EMAIL
//   FIREBASE_PRIVATE_KEY

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// --- Google OAuth2 JWT 기반 Access Token 발급 ---

/** Base64url 인코딩 */
function base64url(data: Uint8Array): string {
  let binary = "";
  for (const byte of data) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

/** PEM → CryptoKey 변환 */
async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const pemBody = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binary = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    "pkcs8",
    binary,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

/** Google OAuth2 Access Token을 서비스 계정 JWT로 발급 */
async function getAccessToken(
  clientEmail: string,
  privateKey: string,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: clientEmail,
    sub: clientEmail,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };

  const enc = new TextEncoder();
  const headerB64 = base64url(enc.encode(JSON.stringify(header)));
  const payloadB64 = base64url(enc.encode(JSON.stringify(payload)));
  const unsigned = `${headerB64}.${payloadB64}`;

  const key = await importPrivateKey(privateKey);
  const signature = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, enc.encode(unsigned)),
  );
  const jwt = `${unsigned}.${base64url(signature)}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Token exchange failed: ${res.status} ${text}`);
  }
  const data = await res.json();
  return data.access_token;
}

// --- 메인 핸들러 ---

const boardNames: Record<string, string> = {
  bachelor: "학사",
  scholarship: "장학",
  student: "학생",
  job: "취업",
  extracurricular: "비교과",
  other: "기타",
  dormGlobal: "글캠 기숙사",
  dormMedical: "메캠 기숙사",
};

Deno.serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
      },
    });
  }

  try {
    const { fcmToken, boardId } = await req.json();

    if (!fcmToken || typeof fcmToken !== "string") {
      return jsonResponse({ error: "fcmToken is required" }, 400);
    }

    const selectedBoard = boardId && boardNames[boardId] ? boardId : "bachelor";
    const boardName = boardNames[selectedBoard];

    // Supabase service-role 클라이언트 생성
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const db = createClient(supabaseUrl, supabaseServiceKey);

    // 1. 테스트 게시물 데이터 생성
    const now = new Date();
    const testPost = {
      board_id: selectedBoard,
      title: `[테스트] ${boardName} 공지 테스트 (${now.toLocaleString("ko-KR", { timeZone: "Asia/Seoul" })})`,
      link: `https://www.gachon.ac.kr/test/${Date.now()}`,
      description: "디버그 모드에서 생성된 테스트 알림입니다. 이 게시물은 테스트 목적으로 생성되었습니다.",
      author: "테스트",
      pub_date: now.toISOString(),
    };

    // posts 테이블에 삽입
    const { data: insertedPost, error: insertError } = await db
      .from("posts")
      .insert(testPost)
      .select("id")
      .single();

    if (insertError) {
      // link unique 충돌 시에도 진행 (테스트이므로)
      console.error("Post insert error (proceeding):", insertError.message);
    }

    const postId = insertedPost?.id ?? String(Date.now());

    // 2. FCM v1 HTTP API로 단일 기기에 메시지 전송
    const projectId = Deno.env.get("FIREBASE_PROJECT_ID");
    const clientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL");
    const rawPrivateKey = Deno.env.get("FIREBASE_PRIVATE_KEY");

    if (!projectId || !clientEmail || !rawPrivateKey) {
      const missing = [
        !projectId && "FIREBASE_PROJECT_ID",
        !clientEmail && "FIREBASE_CLIENT_EMAIL",
        !rawPrivateKey && "FIREBASE_PRIVATE_KEY",
      ].filter(Boolean).join(", ");
      console.error(`Missing Firebase secrets: ${missing}`);
      return jsonResponse(
        {
          error: `Supabase Secrets에 Firebase 환경 변수가 누락되었습니다: ${missing}. Supabase Dashboard의 Edge Functions Secrets에 등록해주세요.`,
        },
        500,
      );
    }

    const privateKey = rawPrivateKey.replace(/\\n/g, "\n");

    const accessToken = await getAccessToken(clientEmail, privateKey);

    const fcmPayload = {
      message: {
        token: fcmToken,
        data: {
          boardName,
          title: testPost.title,
          postLink: testPost.link,
          postId: String(postId),
        },
        android: { priority: "high" },
        apns: {
          headers: { "apns-push-type": "background", "apns-priority": "5" },
          payload: { aps: { "content-available": 1 } },
        },
      },
    };

    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
    const fcmRes = await fetch(fcmUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(fcmPayload),
    });

    if (!fcmRes.ok) {
      const errorText = await fcmRes.text();
      console.error("FCM send error:", errorText);
      return jsonResponse(
        {
          success: false,
          error: `FCM send failed: ${fcmRes.status}`,
          postInserted: !!insertedPost,
          postId,
        },
        500,
      );
    }

    const fcmResult = await fcmRes.json();

    return jsonResponse({
      success: true,
      postId,
      fcmMessageName: fcmResult.name,
      boardId: selectedBoard,
      boardName,
      title: testPost.title,
    });
  } catch (err) {
    console.error("Handler error:", err);
    return jsonResponse({ error: String(err) }, 500);
  }
});

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}
