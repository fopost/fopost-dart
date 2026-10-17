import 'dart:convert';

import 'package:fopost/fopost.dart';
import 'package:test/test.dart';

import 'support.dart';

const contactJson = {
  'id': 'con_1',
  'display_name': 'Ada Okafor',
  'channels': [
    {'platform': 'instagram', 'handle': 'adaokafor', 'externalId': '178414'},
    {'platform': 'x', 'handle': 'ada_writes', 'externalId': null},
  ],
  'source': 'inbox',
  'note': null,
  'first_seen_at': '2026-04-02T09:14:00.000Z',
  'last_seen_at': '2026-09-18T14:30:00.000Z',
  'fields': {'plan_tier': 'Pro'},
  'labels': [
    {'id': 'lbl_1', 'name': 'VIP', 'color': '#0070f3'},
  ],
};

void main() {
  test('list pages on `pagination`, not `meta`, and reads every channel',
      () async {
    final seen = RecordedRequests();
    final client = fakeClient((request) async {
      return jsonBare({
        'data': [contactJson],
        'pagination': {'page': 1, 'per_page': 25, 'total': 1},
      });
    }, recorder: seen);

    final page = await client.contacts.list(workspaceId: 'ws_1', search: 'ada');

    expect(seen.last.url.path, '/v1/contacts');
    expect(seen.last.url.queryParameters,
        {'workspace_id': 'ws_1', 'search': 'ada'});
    expect(page.meta.total, 1);
    expect(page.meta.perPage, 25);

    final contact = page.data.single;
    expect(contact.channels.map((c) => c.handle), ['adaokafor', 'ada_writes']);
    expect(contact.channels.first.externalId, '178414');
    expect(contact.channels.last.externalId, isNull);
    expect(contact.fields, {'plan_tier': 'Pro'});
    expect(contact.labels.single.name, 'VIP');
    expect(contact.firstSeenAt, isNotNull);
  });

  test('create sends the channels the API expects', () async {
    final seen = RecordedRequests();
    final client = fakeClient((_) async => jsonOk(contactJson), recorder: seen);

    await client.contacts.create(
      workspaceId: 'ws_1',
      channels: const [ContactChannel(platform: 'x', handle: 'ada_writes')],
      displayName: 'Ada Okafor',
    );

    expect(seen.last.method, 'POST');
    expect(jsonDecode(seen.last.body), {
      'workspace_id': 'ws_1',
      'channels': [
        {'platform': 'x', 'handle': 'ada_writes'},
      ],
      'display_name': 'Ada Okafor',
    });
  });

  test('a field create carries the workspace in the query too', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'id': 'fld_1',
              'key': 'plan_tier',
              'name': 'Plan Tier',
              'type': 'select',
              'options': ['Free', 'Pro']
            }),
        recorder: seen);

    final field = await client.contacts.createField(
      workspaceId: 'ws_1',
      key: 'plan_tier',
      name: 'Plan Tier',
      type: 'select',
      options: const ['Free', 'Pro'],
    );

    expect(seen.last.url.path, '/v1/contacts/fields');
    expect(seen.last.url.queryParameters, {'workspace_id': 'ws_1'});
    expect(field.options, ['Free', 'Pro']);
  });

  test('conversation analytics reads under analytics, and its key is a digest',
      () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'conversations': [
                {
                  'key': '9f2c7a10b4e83d5612ff0a8c4d1e6b73',
                  'accountId': 'acc_1',
                  'platform': 'instagram',
                  'received': 9,
                  'sent': 5,
                  'answered': 5,
                  'open': 1,
                  'medianResponseMinutes': 47,
                  'firstMessageAt': '2026-09-01T08:02:00.000Z',
                  'lastMessageAt': '2026-09-18T14:30:00.000Z',
                },
              ],
              'total': 128,
              'page': 1,
              'perPage': 25,
            }),
        recorder: seen);

    final analytics =
        await client.contacts.conversationAnalytics(days: 30, sort: 'slowest');

    expect(seen.last.url.path, '/v1/analytics/inbox/conversations');
    expect(seen.last.url.queryParameters, {'days': '30', 'sort': 'slowest'});
    expect(analytics.total, 128);
    expect(analytics.conversations.single.medianResponseMinutes, 47);
    // The digest, not a handle: nothing about who wrote it.
    expect(
        analytics.conversations.single.key, '9f2c7a10b4e83d5612ff0a8c4d1e6b73');
  });
}
