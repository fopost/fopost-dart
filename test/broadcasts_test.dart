import 'dart:convert';

import 'package:fopost/fopost.dart';
import 'package:test/test.dart';

import 'support.dart';

const broadcastJson = {
  'id': 'bc_1',
  'name': 'September check-in',
  'text': 'New colours just landed.',
  'account_id': 'acc_1',
  'audience': {
    'platforms': ['instagram'],
  },
  'status': 'sent',
  'scheduled_at': null,
  'sent_at': '2026-09-19T10:04:00.000Z',
  'created_at': '2026-09-19T09:58:00.000Z',
  'counts': {
    'total': 3,
    'sent': 2,
    'skipped': 1,
    'failed': 0,
    'pending': 0,
  },
};

void main() {
  test('list pages on `pagination`, not `meta`, and keeps the counts',
      () async {
    final seen = RecordedRequests();
    final client = fakeClient((request) async {
      return jsonBare({
        'data': [broadcastJson],
        'pagination': {'page': 1, 'per_page': 25, 'total': 1},
      });
    }, recorder: seen);

    final page =
        await client.broadcasts.list(workspaceId: 'ws_1', status: 'sent');

    expect(seen.last.url.path, '/v1/broadcasts');
    expect(seen.last.url.queryParameters,
        {'workspace_id': 'ws_1', 'status': 'sent'});
    expect(page.meta.total, 1);

    final broadcast = page.data.single;
    expect(broadcast.name, 'September check-in');
    expect(broadcast.counts?.sent, 2);
    expect(broadcast.counts?.skipped, 1);
    expect(broadcast.audience?.platforms, ['instagram']);
  });

  test('create sends the snake_case body', () async {
    final seen = RecordedRequests();
    final client =
        fakeClient((_) async => jsonOk(broadcastJson), recorder: seen);

    await client.broadcasts.create(
      workspaceId: 'ws_1',
      accountId: 'acc_1',
      name: 'September check-in',
      text: 'New colours just landed.',
      audience: const AudienceFilter(platforms: ['instagram']),
    );

    expect(seen.last.method, 'POST');
    expect(jsonDecode(seen.last.body), {
      'workspace_id': 'ws_1',
      'account_id': 'acc_1',
      'name': 'September check-in',
      'text': 'New colours just landed.',
      // An unset clause must not travel as null or as an empty list.
      'audience': {
        'platforms': ['instagram'],
      },
    });
  });

  test('a skipped recipient keeps its reason', () async {
    // A closed messaging window has to be readable, or a non-send is a mystery.
    final seen = RecordedRequests();
    final client = fakeClient(
      (_) async => jsonBare({
        'data': [
          {
            'contact_id': 'con_1',
            'display_name': 'Sam Rivera',
            'status': 'skipped',
            'skip_reason': 'window_closed',
            'sent_at': null,
            'error': null,
          },
        ],
        'pagination': {'page': 1, 'per_page': 50, 'total': 1},
      }),
      recorder: seen,
    );

    final page = await client.broadcasts.recipients('bc_1', status: 'skipped');

    expect(seen.last.url.path, '/v1/broadcasts/bc_1/recipients');
    expect(seen.last.url.queryParameters, {'status': 'skipped'});
    final recipient = page.data.single;
    expect(recipient.status, 'skipped');
    expect(recipient.skipReason, 'window_closed');
  });

  test('send reports how many matched', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (_) async => jsonOk({'id': 'bc_1', 'status': 'sending', 'recipients': 3}),
      recorder: seen,
    );

    final sent = await client.broadcasts.send('bc_1');

    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/broadcasts/bc_1/send');
    expect(sent.recipients, 3);
    expect(sent.status, 'sending');
  });

  test('sequence steps travel as given', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (_) async => jsonOk({
        'id': 'seq_1',
        'name': 'Welcome',
        'account_id': 'acc_1',
        'steps': [
          {'delay_hours': 0, 'text': 'Hi'},
          {'delay_hours': 48, 'text': 'Still here?'},
        ],
        'status': 'active',
        'created_at': '2026-09-12T08:00:00.000Z',
      }),
      recorder: seen,
    );

    final sequence = await client.sequences.create(
      workspaceId: 'ws_1',
      accountId: 'acc_1',
      name: 'Welcome',
      steps: const [SequenceStep(delayHours: 0, text: 'Hi')],
    );

    expect(sequence.steps[1].delayHours, 48);
    expect(jsonDecode(seen.last.body)['steps'], [
      {'delay_hours': 0.0, 'text': 'Hi'},
    ]);
  });

  test('enroll takes ids or an audience', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (_) async => jsonOk({'id': 'seq_1', 'enrolled': 2}),
      recorder: seen,
    );

    await client.sequences.enroll('seq_1', contactIds: ['con_1', 'con_2']);
    expect(jsonDecode(seen.last.body), {
      'contact_ids': ['con_1', 'con_2'],
    });

    await client.sequences.enroll('seq_1',
        audience: const AudienceFilter(platforms: ['telegram']));
    expect(jsonDecode(seen.last.body), {
      'audience': {
        'platforms': ['telegram'],
      },
    });
  });

  test('unenroll names the contacts it stops', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (_) async => jsonOk({'id': 'seq_1', 'stopped': 1}),
      recorder: seen,
    );

    final stopped = await client.sequences.unenroll('seq_1', ['con_1']);

    expect(seen.last.url.path, '/v1/sequences/seq_1/unenroll');
    expect(jsonDecode(seen.last.body), {
      'contact_ids': ['con_1'],
    });
    expect(stopped.stopped, 1);
  });
}
