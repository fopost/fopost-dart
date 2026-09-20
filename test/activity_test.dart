import 'package:fopost/fopost.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('reads the audit log and keeps the cursor', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (_) async => jsonBare({
        'data': [
          {
            'id': 'evt_1',
            'workspace_id': 'ws_1',
            'kind': 'security',
            'ref_type': 'member_removed',
            'ref_id': 'usr_2',
            'summary': 'Removed sam@example.com',
            'actor': {'type': 'user', 'name': 'Ada'},
            'time': '2026-09-20T10:00:00.000Z',
          }
        ],
        'meta': {'next_cursor': '42'},
      }),
      recorder: seen,
    );

    final page = await client.activity.list(
      workspaceId: 'ws_1',
      kind: ActivityKind.security,
      limit: 1,
    );

    expect(seen.last.method, 'GET');
    expect(seen.last.url.path, '/v1/activity');
    expect(seen.last.url.queryParameters, {
      'workspace_id': 'ws_1',
      'kind': 'security',
      'limit': '1',
    });
    expect(page.events.single.refType, 'member_removed');
    expect(page.events.single.actor.name, 'Ada');
    expect(page.nextCursor, '42');

    client.close();
  });

  test('the end of the list is a null cursor', () async {
    final client = fakeClient(
      (_) async => jsonBare({
        'data': <Object>[],
        'meta': {'next_cursor': null},
      }),
    );

    final page = await client.activity.list();

    expect(page.events, isEmpty);
    expect(page.nextCursor, isNull);

    client.close();
  });
}
