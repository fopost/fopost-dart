import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('list sends the filters and reads rows, cursor and summary', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonBare({
              'data': [
                {
                  'id': 912,
                  'workspace_id': 'ws_1',
                  'time': '2026-10-18T09:00:00.000Z',
                  'auth_method': 'api_key',
                  'method': 'POST',
                  'route': '/v1/posts/{id}/publish',
                  'path': '/v1/posts/p_1/publish',
                  'status_code': 402,
                  'duration_ms': 48,
                  'platform': null,
                  'message': 'balance exhausted',
                }
              ],
              'meta': {'next_cursor': '911', 'has_more': true},
              'summary': {
                'since': '2026-10-11T09:00:00.000Z',
                'total': 120,
                'errors': 3,
                'buckets': [
                  {'at': '2026-10-18T00:00:00.000Z', 'total': 20, 'errors': 1}
                ],
              },
            }),
        recorder: seen);

    final page = await client.logs.list(
      workspaceId: 'ws_1',
      days: 7,
      status: 'failed',
      statusCode: 402,
      query: 'publish',
      limit: 50,
      before: '913',
    );

    expect(seen.last.method, 'GET');
    expect(seen.last.url.path, '/v1/logs');
    expect(seen.last.url.queryParameters, {
      'workspace_id': 'ws_1',
      'days': '7',
      'status': 'failed',
      'status_code': '402',
      'q': 'publish',
      'limit': '50',
      'before': '913',
    });
    expect(page.logs.single.id, 912);
    expect(page.logs.single.route, '/v1/posts/{id}/publish');
    expect(page.logs.single.statusCode, 402);
    expect(page.logs.single.authMethod, 'api_key');
    expect(page.logs.single.message, 'balance exhausted');
    expect(page.nextCursor, '911');
    expect(page.hasMore, isTrue);
    expect(page.summary.total, 120);
    expect(page.summary.errors, 3);
    expect(page.summary.buckets.single.errors, 1);
  });
}
