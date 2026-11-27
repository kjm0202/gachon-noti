import { setTimeout as delay } from 'node:timers/promises';
import { XMLParser, XMLValidator } from 'fast-xml-parser';
import { RSS_FEEDS } from '../rss-feeds.js';

const names = { bachelor: '학사', scholarship: '장학', student: '학생', job: '취업',
  extracurricular: '비교과', other: '기타', dormGlobal: '글캠 기숙사', dormMedical: '메캠 기숙사' };
export const topicName = board => `gachon_${board}`;
const invalidToken = error => ['messaging/invalid-registration-token',
  'messaging/registration-token-not-registered'].includes(error?.code);
const check = result => { if (result.error) throw result.error; return result.data; };

export function parsePubDate(value) {
  if (!value) return null;
  let text = String(value).trim();
  const local = /^(\d{4})[.-](\d{2})[.-](\d{2})(?:[ T](\d{2}:\d{2}(?::\d{2}(?:\.\d+)?)?)(Z|[+-]\d{2}:?\d{2})?)?$/i.exec(text);
  if (local) {
    const [, year, month, day, time = '00:00:00', zone = '+09:00'] = local;
    const ymd = `${year}-${month}-${day}`;
    const midnight = new Date(`${ymd}T00:00:00Z`);
    if (!Number.isFinite(+midnight) || midnight.toISOString().slice(0, 10) !== ymd ||
        Number(time.slice(0, 2)) > 23) throw new Error('Invalid publication date');
    text = `${ymd}T${time}${zone}`;
  } else {
    const rfc = /^(?:[A-Za-z]{3},\s*)?(\d{1,2}) ([A-Za-z]{3}) (\d{2}|\d{4}) (\d{2}:\d{2}(?::\d{2})?) (GMT|UT|UTC|[ECMP][SD]T|[+-]\d{4})$/i.exec(text);
    if (!rfc) throw new Error('Invalid publication date');
    const [, day, month, year, clock] = rfc;
    const wallTime = new Date(`${day} ${month} ${year} ${clock} GMT`);
    if (wallTime.getUTCDate() !== Number(day)) throw new Error('Invalid publication date');
  }
  const date = new Date(text);
  if (Number.isNaN(date.getTime())) throw new Error(`Invalid publication date: ${text}`);
  return date.toISOString();
}

export function parseFeed(xml) {
  if (XMLValidator.validate(xml) !== true) throw new Error('Invalid RSS XML');
  const parsed = new XMLParser({ ignoreAttributes: true, parseTagValue: false }).parse(xml);
  if (!parsed?.rss?.channel) throw new Error('Response is not an RSS feed');
  const items = parsed.rss.channel.item;
  return items ? (Array.isArray(items) ? items : [items]) : [];
}

export async function readAll(db, table, columns, order) {
  const rows = [];
  for (let offset = 0; ; offset += 500) {
    let query = db.from(table).select(columns);
    for (const column of order) query = query.order(column);
    const page = check(await query.range(offset, offset + 499));
    rows.push(...page);
    if (page.length < 500) return rows;
  }
}

// DB subscriptions are authoritative, including changes from older app versions.
export async function syncTopics(db, messaging) {
  const [devices, subscriptions, memberships] = await Promise.all([
    readAll(db, 'user_devices', 'id,user_id,fcm_token', ['id']),
    readAll(db, 'subscriptions', 'user_id,boards', ['id']),
    readAll(db, 'fcm_topic_memberships', 'fcm_token,board_id,pending', ['fcm_token', 'board_id']),
  ]);
  const boardsByUser = new Map(subscriptions.map(row => [row.user_id, row.boards ?? []]));
  const failedBoards = new Set();
  const invalid = new Set();
  for (const board of Object.keys(names)) {
    const desired = new Set(devices.filter(d => !invalid.has(d.fcm_token) && boardsByUser.get(d.user_id)?.includes(board))
      .map(d => d.fcm_token).filter(Boolean));
    const boardMemberships = memberships.filter(row => row.board_id === board && !invalid.has(row.fcm_token));
    const current = new Set(boardMemberships.map(row => row.fcm_token));
    const pending = new Set(boardMemberships.filter(row => row.pending).map(row => row.fcm_token));
    for (const subscribe of [false, true]) {
      const tokens = subscribe ? [...desired].filter(token => !current.has(token) || pending.has(token))
        : [...current].filter(token => !desired.has(token));
      for (let i = 0; i < tokens.length; i += 500) {
        const batch = tokens.slice(i, i + 500);
        // FCM operations are idempotent. Persist their uncertain state first so
        // a restart can reconcile even if the desired membership has changed.
        const starting = batch.filter(token => !pending.has(token));
        if (starting.length) {
          check(await db.from('fcm_topic_memberships').upsert(
            starting.map(fcm_token => ({ fcm_token, board_id: board, pending: true }))));
        }
        let result;
        try {
          result = await messaging[subscribe ? 'subscribeToTopic' : 'unsubscribeFromTopic'](batch, topicName(board));
        } catch {
          failedBoards.add(board);
          continue;
        }
        const failures = new Map(result.errors.map(e => [e.index, e.error]));
        const succeeded = [];
        for (let index = 0; index < batch.length; index++) {
          const error = failures.get(index);
          if (!error) { succeeded.push(batch[index]); continue; }
          if (invalidToken(error)) {
            invalid.add(batch[index]);
            check(await db.from('user_devices').delete().eq('fcm_token', batch[index]));
            check(await db.from('fcm_topic_memberships').delete().eq('fcm_token', batch[index]));
          } else failedBoards.add(board);
        }
        if (succeeded.length) {
          if (subscribe) check(await db.from('fcm_topic_memberships').upsert(
            succeeded.map(fcm_token => ({ fcm_token, board_id: board, pending: false }))));
          else {
            // PostgREST encodes the IN filter in the request URL.
            let group = [], bytes = 0;
            for (const token of succeeded) {
              const size = encodeURIComponent(token).length + 8;
              if (group.length && bytes + size > 4096) {
                check(await db.from('fcm_topic_memberships').delete().eq('board_id', board).in('fcm_token', group));
                group = [];
                bytes = 0;
              }
              group.push(token);
              bytes += size;
            }
            check(await db.from('fcm_topic_memberships').delete().eq('board_id', board).in('fcm_token', group));
          }
        }
      }
    }
  }
  return failedBoards;
}

export async function crawlFeeds(db, fetcher = fetch, feeds = RSS_FEEDS) {
  let failures = 0;
  for (const feed of feeds) {
    try {
      const response = await fetcher(feed.url, { signal: AbortSignal.timeout(20_000) });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const items = parseFeed(await response.text());
      for (const item of items) {
        try {
          const link = String(item.link ?? '').trim();
          const title = String(item.title ?? '').trim();
          const url = new URL(link);
          if (!title || !/^https:\/\//i.test(link) || url.origin !== 'https://www.gachon.ac.kr' || link.split('/')[2].includes('@') ||
              /[\s\\]/.test(link)) throw new Error('Missing title or invalid notice link');
          const id = check(await db.rpc('enqueue_rss_post', { p_post: {
            board_id: feed.boardId, title, link,
            description: String(item.description ?? '').trim(),
            author: String(item.author || '관리자'), pub_date: parsePubDate(item.pubDate),
          } }));
          if (id) console.log(`Queued post ${id} (${feed.boardId})`);
        } catch (error) { failures++; console.error(`Post error (${feed.boardId}): ${error.message}`); }
      }
    } catch (error) { failures++; console.error(`Feed error (${feed.boardId}): ${error.message}`); }
  }
  return failures;
}

function notificationData(post, postId) {
  const data = { boardName: names[post.board_id], postId: String(postId), postLink: post.link, title: '' };
  // Use a conservative budget for the 2048-byte topic message, including wrappers.
  const budget = 1800;
  if (Buffer.byteLength(JSON.stringify(data)) > budget) data.postLink = 'https://www.gachon.ac.kr/';
  let remaining = budget - Buffer.byteLength(JSON.stringify(data));
  for (const char of post.title) {
    remaining -= Buffer.byteLength(JSON.stringify(char)) - 2;
    if (remaining < 0) break;
    data.title += char;
  }
  return data;
}

async function markPostsSent(db, ids, sentAt, attempts) {
  for (let attempt = 1; ; attempt++) {
    try {
      check(await db.from('notification_outbox')
        .update({ sent_at: sentAt, attempts, last_error: null })
        .in('post_id', ids));
      return;
    } catch (error) {
      if (attempt === 3) throw error;
      await delay(100 * attempt);
    }
  }
}

export async function deliverPending(db, messaging, failedBoards = new Set()) {
  const readyBoards = Object.keys(names).filter(board => !failedBoards.has(board));
  if (!readyBoards.length) return 0;
  const pending = check(await db.from('notification_outbox')
    .select('post_id,attempts,posts!inner(board_id,title,link)')
    .in('posts.board_id', readyBoards)
    .is('sent_at', null).lte('next_attempt_at', new Date().toISOString())
    .order('next_attempt_at').order('post_id').limit(200));
  let failures = 0;
  // sendEach accepts at most 500 messages per call.
  for (let i = 0; i < pending.length; i += 500) {
    const batch = pending.slice(i, i + 500);
    let responses;
    try {
      ({ responses } = await messaging.sendEach(batch.map(({ post_id, posts: post }) => ({
        topic: topicName(post.board_id),
        data: notificationData(post, post_id),
        android: { priority: 'high' },
        apns: { headers: { 'apns-push-type': 'background', 'apns-priority': '5' },
          payload: { aps: { contentAvailable: true } } },
      }))));
    } catch (error) {
      // The whole call failed (e.g. auth or network): every post in it is retried.
      responses = batch.map(() => ({ success: false, error }));
    }
    // Retry the DB acknowledgement only. An unrecorded send may be repeated on a later run.
    const sent = batch.filter((_, index) => responses[index].success);
    const sentAt = new Date().toISOString();
    for (const attempts of new Set(sent.map(entry => entry.attempts))) {
      const ids = sent.filter(entry => entry.attempts === attempts).map(entry => entry.post_id);
      await markPostsSent(db, ids, sentAt, attempts + 1);
    }
    for (const [index, entry] of batch.entries()) {
      const { success, error } = responses[index];
      if (success) continue;
      failures++;
      console.error(`Delivery failed for post ${entry.post_id}: ${error?.code ?? error?.message}`);
      const delay = Math.min(3600, 60 * 2 ** Math.min(entry.attempts, 6));
      check(await db.from('notification_outbox').update({ attempts: entry.attempts + 1,
        next_attempt_at: new Date(Date.now() + delay * 1000).toISOString(),
        last_error: String(error?.code ?? error?.message).slice(0, 500),
      }).eq('post_id', entry.post_id));
    }
  }
  return failures;
}

export async function runCrawler(db, messaging) {
  const failures = await crawlFeeds(db);
  // Do not send to a partially reconciled audience. Pending posts remain durable.
  const failedBoards = await syncTopics(db, messaging);
  const deliveryFailures = await deliverPending(db, messaging, failedBoards);
  if (failures || failedBoards.size || deliveryFailures) {
    throw new Error(`${failures} collection, ${[...failedBoards].join(', ') || 'no'} topic sync, ${deliveryFailures} delivery errors`);
  }
  console.log('RSS collection, topic sync and delivery complete');
}
