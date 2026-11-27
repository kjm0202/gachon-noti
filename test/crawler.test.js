import test from 'node:test';
import assert from 'node:assert/strict';
import { crawlFeeds, deliverPending, parseFeed, parsePubDate, syncTopics, readAll } from '../src/crawler.js';

// Backend-only tests: no mobile interactions, production writes, or FCM sends.
function database(tables = {}, beforeWrite = () => {}) {
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
        in(k, v) { filters.push(r => v.includes(k === 'posts.board_id' ? r.posts.board_id : r[k])); return this; },
        limit(n) { limit = n; return this; },
        range(a, b) { range = [a, b]; return this; },
        update(v) { action = 'update'; values = v; return this; },
        upsert(v) { action = 'upsert'; values = v; return this; },
        delete() { action = 'delete'; return this; },
        then(resolve, reject) {
          return Promise.resolve().then(() => {
            const rows = tables[name] ??= [];
            let matched = rows.filter(r => filters.every(f => f(r)));
            if (action !== 'select') beforeWrite(name, action, values, matched);
            if (action === 'delete') tables[name] = rows.filter(r => !matched.includes(r));
            if (action === 'update') matched.forEach(r => Object.assign(r, values));
            if (action === 'upsert') for (const row of values) {
              const existing = rows.find(r => r.board_id === row.board_id && r.fcm_token === row.fcm_token);
              if (existing) Object.assign(existing, row);
              else rows.push(row);
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
  const xml = '<rss><channel><item><title>Old</title><link>https://www.gachon.ac.kr/old</link></item>' +
    '<item><title>Broken</title></item><item><title>New</title><link>https://www.gachon.ac.kr/new</link></item></channel></rss>';
  assert.equal(await crawlFeeds(db, async () => ({ ok: true, text: async () => xml }), [{ boardId: 'bachelor', url: 'test' }]), 1);
  assert.deepEqual(links, ['https://www.gachon.ac.kr/old', 'https://www.gachon.ac.kr/new']);
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
  const messaging = { sendEach: async messages => {
    calls.push(messages.map(message => message.data.postId));
    return { responses: messages.map(message => {
      assert.equal(message.topic, 'gachon_job');
      return message.data.postId === '1' && calls.length === 1
        ? { success: false, error: { code: 'messaging/unavailable' } } : { success: true };
    }) };
  } };
  assert.equal(await deliverPending(db, messaging), 1);
  assert.equal(db.tables.notification_outbox[0].sent_at, null);
  assert.equal(db.tables.notification_outbox[0].attempts, 1);
  assert.equal(db.tables.notification_outbox[0].last_error, 'messaging/unavailable');
  assert.ok(db.tables.notification_outbox[1].sent_at);
  assert.equal(db.tables.notification_outbox[1].attempts, 1);
  db.tables.notification_outbox[0].next_attempt_at = '2000-01-01';
  assert.equal(await deliverPending(db, messaging), 0);
  assert.equal(db.tables.notification_outbox[0].attempts, 2);
  assert.deepEqual(calls, [['1', '2'], ['1']]);
});

for (const failures of [2, 3]) {
  test(`successful delivery with ${failures} failed acknowledgement writes`, async () => {
    const writes = [];
    const row = { post_id: 7, attempts: 2, sent_at: null, next_attempt_at: '2000-01-01',
      posts: { board_id: 'job', title: 'notice', link: 'https://www.gachon.ac.kr/' } };
    const db = database({ notification_outbox: [row] }, (_, action, values) => {
      assert.equal(action, 'update');
      writes.push(values);
      if (writes.length <= failures) throw new Error('acknowledgement unavailable');
    });
    let sends = 0;
    const messaging = { sendEach: async () => {
      sends++;
      return { responses: [{ success: true }] };
    } };
    if (failures === 3) {
      await assert.rejects(deliverPending(db, messaging), /acknowledgement unavailable/);
      assert.equal(row.sent_at, null);
    } else {
      assert.equal(await deliverPending(db, messaging), 0);
      assert.ok(row.sent_at);
      assert.equal(row.attempts, 3);
      assert.equal(await deliverPending(db, messaging), 0);
    }
    assert.equal(sends, 1);
    assert.equal(writes.length, 3);
    assert.deepEqual(writes, [writes[0], writes[0], writes[0]]);
  });
}

test('a rejected sendEach call leaves every post in it pending', async () => {
  const db = database({ notification_outbox: [1, 2].map(post_id => ({ post_id, attempts: 0,
    next_attempt_at: '2000-01-01', sent_at: null, posts: { board_id: 'job', title: 'notice', link: 'https://example.org' } })) });
  const messaging = { sendEach: async () => { throw Object.assign(new Error('auth'), { code: 'app/invalid-credential' }); } };
  assert.equal(await deliverPending(db, messaging), 2);
  assert.ok(db.tables.notification_outbox.every(row => row.sent_at === null && row.attempts === 1
    && row.last_error === 'app/invalid-credential'));
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
  assert.deepEqual(await syncTopics(db, { subscribeToTopic: async () => ({ errors: [{ index: 1, error: { code: 'messaging/server-unavailable' } }] }) }), new Set(['job']));
  assert.deepEqual(db.tables.fcm_topic_memberships, [
    { fcm_token: 'a', board_id: 'job', pending: false },
    { fcm_token: 'b', board_id: 'job', pending: true },
  ]);
  await syncTopics(db, { subscribeToTopic: async tokens => {
    assert.deepEqual(tokens, ['b']); return { errors: [] };
  } });
  assert.equal(db.tables.fcm_topic_memberships.length, 2);
});

test('pagination reads beyond the first database page', async () => {
  const db = database({ user_devices: Array.from({ length: 1201 }, (_, id) => ({ id })) });
  assert.equal((await readAll(db, 'user_devices', 'id', ['id'])).length, 1201);
});

test('RSS dates and attributed text retain their Korean publication values', () => {
  assert.equal(parsePubDate('2026.11.27 09:00:00.125'), '2026-11-27T00:00:00.125Z');
  assert.equal(parsePubDate('2026-11-27'), '2026-11-26T15:00:00.000Z');
  assert.throws(() => parsePubDate('2026-02-29'));
  assert.throws(() => parsePubDate('Sat, 30 Feb 2026 09:00:00 GMT'));
  assert.equal(parseFeed('<rss><channel><item><title lang="ko">공지</title></item></channel></rss>')[0].title, '공지');
});

test('crawler stores only HTTPS notices from the school origin', async () => {
  const links = ['https://example.org/a', 'http://www.gachon.ac.kr/a', 'https://www.gachon.ac.kr/good'];
  const xml = '<rss><channel>' + links.map(link => `<item><title>A</title><link>${link}</link></item>`).join('') + '</channel></rss>';
  const stored = [];
  const db = {rpc: async (_, {p_post}) => { stored.push(p_post.link); return {data: 1}; }};
  assert.equal(await crawlFeeds(db, async () => ({ok: true, text: async () => xml}), [{boardId: 'job'}]), 2);
  assert.deepEqual(stored, links.slice(-1));
});

test('a failed topic stays pending, healthy board sends bounded Unicode payload', async () => {
  const db = database({ notification_outbox: ['job', 'student'].map((board_id, id) => ({
    post_id: id + 1, attempts: 0, next_attempt_at: '2000-01-01', sent_at: null,
    posts: { board_id, title: '공지😀'.repeat(400), link: 'https://www.gachon.ac.kr/' },
  })) });
  await deliverPending(db, {sendEach: async messages => {
    assert.equal(messages.length, 1);
    assert.equal(messages[0].topic, 'gachon_student');
    assert.ok(Buffer.byteLength(JSON.stringify(messages[0])) <= 2048);
    return {responses: [{success: true}]};
  }}, new Set(['job']));
  assert.equal(db.tables.notification_outbox[0].sent_at, null);
  assert.ok(db.tables.notification_outbox[1].sent_at);
});

test('changed subscription is reconciled after FCM succeeds and the DB acknowledgement fails', async () => {
  let fail = true;
  const db = database({
    user_devices: [{ id: 1, user_id: 'u', fcm_token: 'a' }],
    subscriptions: [{ user_id: 'u', boards: ['job'] }],
  }, (_, action, values) => {
    if (fail && action === 'upsert' && values[0].pending === false) throw new Error('offline');
  });
  let subscribed = false;
  const messaging = {
    subscribeToTopic: async () => { subscribed = true; return { errors: [] }; },
    unsubscribeFromTopic: async () => { subscribed = false; return { errors: [] }; },
  };
  await assert.rejects(syncTopics(db, messaging), /offline/);
  assert.ok(subscribed);
  assert.equal(db.tables.fcm_topic_memberships[0].pending, true);
  fail = false;
  db.tables.subscriptions[0].boards = [];
  await syncTopics(db, messaging);
  assert.equal(subscribed, false);
  assert.deepEqual(db.tables.fcm_topic_memberships, []);
});

test('mass removals keep individual REST deletion requests small', async () => {
  const memberships = Array.from({ length: 500 }, (_, i) => ({
    board_id: 'job', fcm_token: 'x'.repeat(155) + i,
  }));
  let deletes = 0;
  const db = database({ fcm_topic_memberships: memberships }, (_, action, values, matched) => {
    if (action === 'delete') {
      deletes++;
      assert.ok(matched.map(row => row.fcm_token).join(',').length < 4096);
    }
  });
  await syncTopics(db, { unsubscribeFromTopic: async () => ({ errors: [] }) });
  assert.ok(deletes > 1);
  assert.deepEqual(db.tables.fcm_topic_memberships, []);
});

test('expired token is pruned from every topic without blocking peers', async () => {
  const db = database({user_devices: ['expired', 'live'].map((fcm_token, id) => ({id, fcm_token, user_id: 'u'})),
    subscriptions: [{user_id: 'u', boards: ['job', 'other']}]});
  const failed = await syncTopics(db, {subscribeToTopic: async tokens => ({
    errors: tokens.includes('expired') ? [{index: tokens.indexOf('expired'), error: {code: 'messaging/registration-token-not-registered'}}] : [],
  })});
  assert.equal(failed.size, 0);
  assert.deepEqual(db.tables.user_devices.map(row => row.fcm_token), ['live']);
  assert.ok(db.tables.fcm_topic_memberships.every(row => row.fcm_token === 'live' && !row.pending));
});
