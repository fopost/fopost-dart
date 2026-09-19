import 'dart:convert';

import 'package:fopost/fopost.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('rename sends an explicit null to restore the platform name', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async =>
            jsonOk({'id': 'acc_1', 'name': 'Acme', 'platform_name': 'Acme'}),
        recorder: seen);

    final result = await client.accounts.rename('acc_1', null);

    expect(seen.last.method, 'PATCH');
    expect(seen.last.url.path, '/v1/accounts/acc_1');
    expect(seen.last.body, '{"display_name":null}');
    expect(result.platformName, 'Acme');
    client.close();
  });

  test('move posts the target workspace and surfaces a blocked move', () async {
    final seen = RecordedRequests();
    var calls = 0;
    final client = fakeClient((_) async {
      calls++;
      return calls == 1
          ? jsonOk({'id': 'acc_1', 'workspace_id': 'ws_2'})
          : jsonError(409, 'move_blocked', 'Blocked', extra: {
              'blocking_tables': ['ads']
            });
    }, recorder: seen);

    final moved = await client.accounts.move('acc_1', workspaceId: 'ws_2');
    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/accounts/acc_1/move');
    expect(jsonDecode(seen.last.body), {'workspace_id': 'ws_2'});
    expect(moved.workspaceId, 'ws_2');

    await expectLater(
      client.accounts.move('acc_1', workspaceId: 'ws_2'),
      throwsA(predicate<FoPostException>((e) =>
          e.statusCode == 409 &&
          e.code == 'move_blocked' &&
          (e.bodyMap['blocking_tables'] as List).single == 'ads')),
    );
    client.close();
  });

  test('list filters by group and reads the platform name', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk([
              {
                'id': 'acc_1',
                'platform': 'bluesky',
                'username': 'yourbrand',
                'name': 'Brand',
                'platformName': 'Acme',
              }
            ]),
        recorder: seen);

    final accounts = await client.accounts.list(groupId: 'grp_1');

    expect(seen.last.url.queryParameters, {'group_id': 'grp_1'});
    expect(accounts.single.name, 'Brand');
    expect(accounts.single.platformName, 'Acme');
    client.close();
  });
}
