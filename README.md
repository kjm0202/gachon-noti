# 가천 알림이

Flutter 앱과 GitHub Actions 기반 가천대학교 공지 알림 서비스입니다.

## 데이터 흐름

1. Actions가 5분 간격으로 8개 RSS의 최대 50개 항목을 모두 검사합니다.
2. `enqueue_rss_post` RPC가 새 `posts` 행과 `notification_outbox` 행을 같은 트랜잭션으로 저장합니다. 기존 링크는 건너뜁니다.
3. DB `subscriptions`와 `user_devices`를 기준으로 `gachon_<board_id>` FCM 토픽을 동기화합니다. `fcm_topic_memberships`는 성공한 구독 상태를 서버 전용으로 기록합니다.
4. 동기화가 완료되면 공지당 토픽 메시지 한 건을 전송합니다. 구독 변경은 다음 크롤러 실행에서 모든 등록 기기에 반영됩니다. 기존 앱도 서버에서 토픽에 등록되므로 업데이트 전에 수신할 수 있습니다.
5. 성공한 발송은 `sent_at`에 기록하고 실패는 다음 실행에서 재시도합니다. 재시도 간격은 1분부터 최대 1시간이며, 실제 실행 시점은 Actions 일정에 따릅니다.

## 실행 및 검증

Node.js 22 이상이 필요합니다.

```sh
npm ci
npm test
npm start
```

`npm start`는 실제 DB 저장과 알림 발송을 수행합니다. 테스트는 외부 서비스에 연결하지 않습니다.
Actions Secrets: `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`.

DB 추가 스키마는 `db/notification_pipeline.sql`에 있습니다. 연결된 `gachon_noti` DB에는 `notification_topic_pipeline` 마이그레이션으로 적용했습니다. 다른 DB에서는 기존 `posts`, `subscriptions`, `user_devices`를 먼저 준비한 후 한 번 적용합니다. 기존 공지를 대기열에 소급 등록하지 않습니다.

## 운영 특성

- Actions concurrency와 20분 DB lease로 중복 실행을 막습니다. 프로세스는 9분, Actions job은 10분 제한입니다. 강제 종료 시 lease 만료 후 다음 실행에서 복구됩니다.
- 실행당 최대 200건을 발송하며 나머지는 대기열에 남습니다. RSS 오류가 나도 다른 게시판을 검사하고 기존 대기열을 처리합니다. 토픽 동기화가 실패하면 잘못된 수신 대상에게 보내지 않도록 발송을 보류합니다.
- `notification_outbox`의 `sent_at is null`, `attempts`, `last_error`, `next_attempt_at`으로 지연·실패를 확인할 수 있습니다. 오류가 발생한 실행은 실패 상태로 종료합니다.
- FCM 접수와 DB 성공 기록은 하나의 트랜잭션이 아닙니다. 그 사이 종료되면 중복 발송될 수 있습니다(at-least-once). 앱은 안정적인 `postId` 기반 알림 ID로 같은 공지를 교체하지만 중복 소리까지 완전히 차단하지는 않습니다. `sent_at`은 FCM 접수 시각이며 기기 도착 확인이 아닙니다.
- data-only 메시지를 유지합니다. Android 우선순위와 APNs background 설정을 지정했지만 OS 절전·강제 종료 상태에서 즉시 전달을 보장하지 않습니다.
- 앱 로그아웃은 FCM 작업 종료·토큰 삭제 후 Supabase 로그아웃 순서입니다. 삭제된 기기의 토픽은 서버 스냅샷을 통해 정리합니다.
- 새 서버 테이블과 RPC는 `service_role` 전용입니다. 앱에는 서비스 키를 넣지 않습니다.
- 소스 변경 후 기본 브랜치에 반영해야 Actions에 적용됩니다. Flutter 변경은 앱 빌드·배포가 필요합니다. DB 스키마만 추가한 상태에서는 기존 크롤러 동작을 바꾸지 않습니다.

## 검증 범위

백엔드 테스트는 고정 공지 뒤 신규 공지, XML/HTTP 오류, 한국 시간 파싱, 발송 재시도, 다중 기기 토픽 동기화, 부분 실패 복구, DB 페이지네이션을 다룹니다.
DB에서는 롤백 트랜잭션으로 공지·대기열 원자성, 중복 방지, lease 배타성을 검증했습니다.
실제 RSS 8개, 400개 항목 파싱 및 Android debug APK 빌드도 통과했습니다. Flutter 정적 분석에는 기존 경고가 남아 있습니다. ARTEMIS 기기 검증은 제공자 API 키와 기기 연결이 필요합니다. 실제 FCM 발송은 수행하지 않았습니다.

기존 DB 보안 점검 결과(이번 추가 객체와 별개):
- `update_updated_at_column`의 [search_path 설정](https://supabase.com/docs/guides/database/database-linter?lint=0011_function_search_path_mutable)
- 기존 테이블의 [익명 인증 사용자 정책 검토](https://supabase.com/docs/guides/database/database-advisors?queryGroups=lint&lint=0012_auth_allow_anonymous_sign_ins)
- [유출 비밀번호 보호 설정](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection)
- [Postgres 보안 패치 업그레이드](https://supabase.com/docs/guides/platform/upgrading)
