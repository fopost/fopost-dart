import 'dart:convert';

import 'package:test/test.dart';

import 'support.dart';

Map<String, dynamic> sourceJson() => {
      'id': 'know_1',
      'kind': 'url',
      'title': 'Refund policy',
      'status': 'ready',
      'statusMessage': null,
      'url': 'https://yourbrand.com/help/refunds',
      'mediaId': null,
      'brandVoiceId': null,
      'chunkCount': 3,
      'content': null,
      'lastSyncedAt': '2026-09-20T00:00:00.000Z',
      'createdAt': '2026-09-19T00:00:00.000Z',
      'updatedAt': '2026-09-20T00:00:00.000Z',
    };

void main() {
  test('list sends the workspace filter and reads the camelCase fields',
      () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (_) async => jsonBare({
        'data': [sourceJson()]
      }),
      recorder: seen,
    );

    final sources = await client.knowledge.list(workspaceId: 'ws_1');

    expect(seen.last.method, 'GET');
    expect(seen.last.url.path, '/v1/knowledge/sources');
    expect(seen.last.url.queryParameters, {'workspace_id': 'ws_1'});

    final source = sources.single;
    expect(source.id, 'know_1');
    expect(source.status, 'ready');
    expect(source.chunkCount, 3);
    expect(source.statusMessage, isNull);
    expect(source.lastSyncedAt, DateTime.parse('2026-09-20T00:00:00.000Z'));
  });

  test('create sends a snake_case body and omits what the kind does not use',
      () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (_) async => jsonBare({'data': sourceJson()}),
      recorder: seen,
    );

    await client.knowledge.create(
      kind: 'file',
      title: 'Price list',
      mediaId: 'media_1',
      workspaceId: 'ws_1',
    );

    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/knowledge/sources');

    final body = jsonDecode(seen.last.body) as Map<String, dynamic>;
    expect(body['kind'], 'file');
    expect(body['media_id'], 'media_1');
    expect(body['workspace_id'], 'ws_1');
    // Nothing the kind does not use reaches the wire.
    expect(body.containsKey('url'), isFalse);
    expect(body.containsKey('content'), isFalse);
  });

  test('update patches only the fields that were given', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (_) async => jsonBare({'data': sourceJson()}),
      recorder: seen,
    );

    await client.knowledge.update('know_1', title: 'Refunds');

    expect(seen.last.method, 'PATCH');
    expect(seen.last.url.path, '/v1/knowledge/sources/know_1');
    expect(jsonDecode(seen.last.body), {'title': 'Refunds'});
  });

  test('search sends top_k and reads the matches', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (_) async => jsonBare({
        'data': [
          {
            'sourceId': 'know_1',
            'sourceTitle': 'Refund policy',
            'sourceKind': 'url',
            'sourceUrl': 'https://yourbrand.com/help/refunds',
            'text': 'We refund within 30 days.',
            'score': 0.82,
          }
        ]
      }),
      recorder: seen,
    );

    final matches =
        await client.knowledge.search('how long do refunds take?', topK: 3);

    expect(seen.last.url.path, '/v1/knowledge/search');
    expect(seen.last.url.queryParameters,
        {'q': 'how long do refunds take?', 'top_k': '3'});

    final match = matches.single;
    expect(match.sourceTitle, 'Refund policy');
    expect(match.score, closeTo(0.82, 0.0001));
  });

  test('sync posts to the source sync path', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (_) async => jsonBare({
        'data': {'id': 'know_1', 'status': 'pending'}
      }),
      recorder: seen,
    );

    final queued = await client.knowledge.sync('know_1');

    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/knowledge/sources/know_1/sync');
    expect(queued.status, 'pending');
  });
}
