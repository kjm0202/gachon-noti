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
  if (/^\d{4}\.\d{2}\.\d{2}/.test(text)) text = text.replaceAll('.', '-');
  if (/^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}(:\d{2})?$/.test(text)) {
    text = text.replace(' ', 'T') + '+09:00';
  }
  const date = new Date(text);
  if (Number.isNaN(date.getTime())) throw new Error(`Invalid publication date: ${text}`);
  return date.toISOString();
}

export function parseFeed(xml) {
  if (XMLValidator.validate(xml) !== true) throw new Error('Invalid RSS XML');
  const parsed = new XMLParser({ ignoreAttributes: false, parseTagValue: false }).parse(xml);
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
    readAll(db, 'fcm_topic_memberships', 'fcm_token,board_id', ['fcm_token', 'board_id']),
  ]);
  const boardsByUser = new Map(subscriptions.map(row => [row.user_id, row.boards ?? []]));
  const errors = [];
  const invalid = new Set();
  for (const board of Object.keys(names)) {
    const desired = new Set(devices.filter(d => !invalid.has(d.fcm_token) && boardsByUser.get(d.user_id)?.includes(board))
      .map(d => d.fcm_token).filter(Boolean));
    const current = new Set(memberships.filter(m => !invalid.has(m.fcm_token) && m.board_id === board).map(m => m.fcm_token));
    for (const subscribe of [false, true]) {
      const tokens = subscribe ? [...desired].filter(t => !current.has(t))
        : [...current].filter(t => !desired.has(t));
      for (let i = 0; i < tokens.length; i += 500) {
        const batch = tokens.slice(i, i + 500);
        const result = await messaging[subscribe ? 'subscribeToTopic' : 'unsubscribeFromTopic'](batch, topicName(board));
        const failures = new Map(result.errors.map(e => [e.index, e.error]));
        const succeeded = [];
        for (let index = 0; index < batch.length; index++) {
          const error = failures.get(index);
          if (!error) { succeeded.push(batch[index]); continue; }
          if (invalidToken(error)) {
            invalid.add(batch[index]);
            check(await db.from('user_devices').delete().eq('fcm_token', batch[index]));
            check(await db.from('fcm_topic_memberships').delete().eq('fcm_token', batch[index]));
          } else errors.push(`${board}: ${error.code}`);
        }
        if (succeeded.length) {
          if (subscribe) check(await db.from('fcm_topic_memberships').upsert(
            succeeded.map(fcm_token => ({ fcm_token, board_id: board }))));
          else check(await db.from('fcm_topic_memberships').delete().eq('board_id', board).in('fcm_token', succeeded));
        }
      }
    }
  }
  if (errors.length) throw new Error(`Topic sync failed: ${errors.join(', ')}`);
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
          if (!title || !/^https?:\/\//i.test(link)) throw new Error('Missing title or valid link');
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

export async function deliverPending(db, messaging) {
  const pending = check(await db.from('notification_outbox')
    .select('post_id,attempts,posts!inner(board_id,title,link)')
    .is('sent_at', null).lte('next_attempt_at', new Date().toISOString())
    .order('next_attempt_at').order('post_id').limit(200));
  let failures = 0;
  for (const entry of pending) {
    const post = entry.posts;
    try {
      await messaging.send({ topic: topicName(post.board_id),
        data: { boardName: names[post.board_id] ?? post.board_id,
          title: post.title, postLink: post.link, postId: String(entry.post_id) },
        android: { priority: 'high' },
        apns: { headers: { 'apns-push-type': 'background', 'apns-priority': '5' },
          payload: { aps: { contentAvailable: true } } },
      });
      check(await db.from('notification_outbox').update({
        sent_at: new Date().toISOString(), attempts: entry.attempts + 1, last_error: null,
      }).eq('post_id', entry.post_id));
    } catch (error) {
      failures++;
      console.error(`Delivery failed for post ${entry.post_id}: ${error.code ?? error.message}`);
      const delay = Math.min(3600, 60 * 2 ** Math.min(entry.attempts, 6));
      check(await db.from('notification_outbox').update({ attempts: entry.attempts + 1,
        next_attempt_at: new Date(Date.now() + delay * 1000).toISOString(),
        last_error: String(error.code ?? error.message).slice(0, 500),
      }).eq('post_id', entry.post_id));
    }
  }
  return failures;
}

export async function runCrawler(db, messaging) {
  const failures = await crawlFeeds(db);
  // Do not send to a partially reconciled audience. Pending posts remain durable.
  await syncTopics(db, messaging);
  const deliveryFailures = await deliverPending(db, messaging);
  if (failures + deliveryFailures) throw new Error(`${failures} collection, ${deliveryFailures} delivery errors`);
  console.log('RSS collection, topic sync and delivery complete');
}
