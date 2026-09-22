import test from 'node:test';
import assert from 'node:assert/strict';
import { crawlFeeds, deliverPending, parseFeed, parsePubDate, syncTopics, readAll } from '../src/crawler.js';

// Backend-only tests: no mobile interactions, production writes, or FCM sends.
function database(tables = {}) {
  return {
    tables,
    from(name) {
      const filters = [];
      let action = 'select', values, limit, range;
      const query = {
        select() { return this; }, order() { return this; },
        eq(k, v) { filters.push(r => r[k] === v); return this; },
        is(k, v) { filters.push(r => r[k] === v); return this; },
        lte(k, v) { filters.push(r => r[k] <= v); return this; },
        in(k, v) { filters.push(r => v.includes(r[k])); return this; },
        limit(n) { limit = n; return this; },
        range(a, b) { range = [a, b]; return this; },
        update(v) { action = 'update'; values = v; return this; },
        upsert(v) { action = 'upsert'; values = v; return this; },
        delete() { action = 'delete'; return this; },
        then(resolve, reject) {
          return Promise.resolve().then(() => {
            const rows = tables[name] ??= [];
            let matched = rows.filter(r => filters.every(f => f(r)));
            if (action === 'delete') tables[name] = rows.filter(r => !matched.includes(r));
            if (action === 'update') matched.forEach(r => Object.assign(r, values));
            if (action === 'upsert') for (const row of values) {
              if (!rows.some(r => r.board_id === row.board_id && r.fcm_token === row.fcm_token)) rows.push(row);
            }
            if (range) matched = matched.slice(range[0], range[1] + 1);
            if (limit) matched = matched.slice(0, limit);
            return { data: matched, error: null };
          }).then(resolve, reject);
        },
      };
      return query;
    },
  };
}

test('Korean wall time is interpreted as Asia/Seoul and invalid dates fail', () => {
  assert.equal(parsePubDate('2026.09.23 09:30:00'), '2026-09-23T00:30:00.000Z');
  assert.equal(parsePubDate('Wed, 23 Sep 2026 00:30:00 GMT'), '2026-09-23T00:30:00.000Z');
  assert.equal(parsePubDate(null), null);
  assert.throws(() => parsePubDate('not-a-date'));
});

test('RSS accepts zero/one items and rejects HTML and malformed XML', () => {
  assert.deepEqual(parseFeed('<rss><channel><title>Empty</title></channel></rss>'), []);
  assert.equal(parseFeed('<rss><channel><item><title><![CDATA[123]]></title></item></channel></rss>')[0].title, '123');
  assert.throws(() => parseFeed('<html>Unavailable</html>'));
  assert.throws(() => parseFeed('<rss><channel>'));
});

test('existing/pinned item does not hide later new items; one bad item does not stop the feed', async () => {
  const links = [];
  const db = { rpc: async (_, { p_post }) => {
    links.push(p_post.link);
    return { data: links.length === 1 ? null : 2, error: null };
  } };
  const xml = '<rss><channel><item><title>Old</title><link>https://example.org/old</link></item>' +
    '<item><title>Broken</title></item><item><title>New</title><link>https://example.org/new</link></item></channel></rss>';
  assert.equal(await crawlFeeds(db, async () => ({ ok: true, text: async () => xml }), [{ boardId: 'bachelor', url: 'test' }]), 1);
  assert.deepEqual(links, ['https://example.org/old', 'https://example.org/new']);
});

test('HTTP failures are counted and later feeds are still processed', async () => {
  let calls = 0;
  assert.equal(await crawlFeeds({}, async () => {
    calls++; return { ok: false, status: 503 };
  }, [{ boardId: 'bachelor' }, { boardId: 'job' }]), 2);
  assert.equal(calls, 2);
});

test('failed send remains pending; retry sends only the failed post', async () => {
  const db = database({ notification_outbox: [1, 2].map(post_id => ({ post_id, attempts: 0,
    next_attempt_at: '2000-01-01', sent_at: null, posts: { board_id: 'job', title: 'notice', link: 'https://example.org' } })) });
  const calls = [];
  const messaging = { send: async message => {
    calls.push(message.data.postId);
    assert.equal(message.topic, 'gachon_job');
    if (message.data.postId === '1' && calls.length === 1) throw new Error('Temporary outage');
  } };
  assert.equal(await deliverPending(db, messaging), 1);
  assert.equal(db.tables.notification_outbox[0].sent_at, null);
  assert.equal(db.tables.notification_outbox[0].attempts, 1);
  assert.ok(db.tables.notification_outbox[1].sent_at);
  db.tables.notification_outbox[0].next_attempt_at = '2000-01-01';
  assert.equal(await deliverPending(db, messaging), 0);
  assert.deepEqual(calls, ['1', '2', '1']);
});

test('topic reconciliation covers multiple devices, removals and restart idempotency', async () => {
  const db = database({ user_devices: [{ id: 1, user_id: 'u', fcm_token: 'a' }, { id: 2, user_id: 'u', fcm_token: 'b' }],
    subscriptions: [{ user_id: 'u', boards: ['job'] }],
    fcm_topic_memberships: [{ fcm_token: 'removed', board_id: 'job' }, { fcm_token: 'a', board_id: 'student' }] });
  const calls = [];
  const messaging = Object.fromEntries(['subscribeToTopic', 'unsubscribeFromTopic'].map(method => [method, async (tokens, topic) => {
    calls.push({ method, tokens, topic }); return { errors: [] };
  }]));
  await syncTopics(db, messaging);
  assert.equal(db.tables.fcm_topic_memberships.length, 2);
  assert.ok(db.tables.fcm_topic_memberships.every(row => row.board_id === 'job'));
  const count = calls.length;
  await syncTopics(db, messaging);
  assert.equal(calls.length, count);
});

test('partial subscription failure persists successes and retries failed tokens', async () => {
  const db = database({ user_devices: [{ id: 1, user_id: 'u', fcm_token: 'a' }, { id: 2, user_id: 'u', fcm_token: 'b' }],
    subscriptions: [{ user_id: 'u', boards: ['job'] }] });
  await assert.rejects(syncTopics(db, { subscribeToTopic: async () => ({ errors: [{ index: 1, error: { code: 'messaging/server-unavailable' } }] }) }));
  assert.deepEqual(db.tables.fcm_topic_memberships, [{ fcm_token: 'a', board_id: 'job' }]);
  await syncTopics(db, { subscribeToTopic: async tokens => {
    assert.deepEqual(tokens, ['b']); return { errors: [] };
  } });
  assert.equal(db.tables.fcm_topic_memberships.length, 2);
});

test('pagination reads beyond the first database page', async () => {
  const db = database({ user_devices: Array.from({ length: 1201 }, (_, id) => ({ id })) });
  assert.equal((await readAll(db, 'user_devices', 'id', ['id'])).length, 1201);
});
