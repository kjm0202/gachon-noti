// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders,
    },
  });
}

Deno.serve(async (req) => {
  // CORS Preflight
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders,
    });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Authorization 헤더가 누락되었습니다." }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // 1. 요청자의 JWT를 이용해 현재 인증된 사용자 정보 가져오기
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();

    if (userError || !user) {
      console.error("인증 실패:", userError?.message);
      return jsonResponse(
        { error: "유효하지 않은 세션이거나 로그인되지 않은 사용자입니다." },
        401,
      );
    }

    const userId = user.id;
    console.log(`회원탈퇴 진행: userId=${userId}, email=${user.email}`);

    // 2. Service Role 클라이언트로 데이터 삭제 진행 (RLS 바이패스)
    const adminClient = createClient(supabaseUrl, supabaseServiceKey);

    // 2-1. 사용자의 FCM 토큰 조회 후 토픽 구독(fcm_topic_memberships) 정리
    try {
      const { data: userDevices } = await adminClient
        .from("user_devices")
        .select("fcm_token")
        .eq("user_id", userId);

      if (userDevices && userDevices.length > 0) {
        const tokens = userDevices
          .map((d: { fcm_token: string }) => d.fcm_token)
          .filter(Boolean);

        if (tokens.length > 0) {
          await adminClient
            .from("fcm_topic_memberships")
            .delete()
            .in("fcm_token", tokens);
        }
      }
    } catch (tokenErr) {
      console.warn("fcm_topic_memberships 삭제 중 경고:", tokenErr);
    }

    // 2-2. user_devices 삭제
    const { error: deviceError } = await adminClient
      .from("user_devices")
      .delete()
      .eq("user_id", userId);

    if (deviceError) {
      console.error("user_devices 삭제 오류:", deviceError.message);
    }

    // 2-3. subscriptions 삭제
    const { error: subError } = await adminClient
      .from("subscriptions")
      .delete()
      .eq("user_id", userId);

    if (subError) {
      console.error("subscriptions 삭제 오류:", subError.message);
    }

    // 2-4. Supabase Auth에서 사용자 영구 삭제 (auth.users)
    const { error: deleteAuthError } =
      await adminClient.auth.admin.deleteUser(userId);

    if (deleteAuthError) {
      console.error("auth.admin.deleteUser 오류:", deleteAuthError.message);
      return jsonResponse(
        { error: `계정 삭제 중 오류 발생: ${deleteAuthError.message}` },
        500,
      );
    }

    console.log(`회원탈퇴 완료: userId=${userId}`);

    return jsonResponse({
      success: true,
      message: "회원탈퇴가 완료되었습니다.",
      userId,
    });
  } catch (err) {
    console.error("Handler error:", err);
    return jsonResponse({ error: String(err) }, 500);
  }
});
