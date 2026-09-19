import 'dart:convert';

import 'package:test/test.dart';

import 'support.dart';

const groupJson = {
  'id': 'grp_1',
  'name': 'Launch',
  'account_ids': ['acc_1', 'acc_2'],
  'created_at': '2026-09-19T10:00:00.000Z',
  'updated_at': '2026-09-19T10:00:00.000Z',
};

void main() {
  test('list, create, get, update and delete hit their paths', () async {
    final seen = RecordedRequests();
    final client = fakeClient((request) async {
      if (request.method == 'DELETE') {
        return jsonBare({'message': 'Account group deleted'});
      }
      return jsonOk(request.method == 'GET' && request.url.path.endsWith('s')
          ? [groupJson]
          : groupJson);
    }, recorder: seen);

    final groups = await client.accountGroups.list(workspaceId: 'ws_1');
    final created = await client.accountGroups
        .create(workspaceId: 'ws_1', name: 'Launch', accountIds: ['acc_1']);
    await client.accountGroups.get('grp_1');
    await client.accountGroups.update('grp_1', name: 'Launch');
    await client.accountGroups.delete('grp_1');

    expect(seen.all.map((r) => r.method),
        ['GET', 'POST', 'GET', 'PATCH', 'DELETE']);
    expect(seen.all.map((r) => r.url.path), [
      '/v1/account-groups',
      '/v1/account-groups',
      '/v1/account-groups/grp_1',
      '/v1/account-groups/grp_1',
      '/v1/account-groups/grp_1',
    ]);
    expect(seen.all[0].url.queryParameters, {'workspace_id': 'ws_1'});
    expect(jsonDecode(seen.all[1].body), {
      'workspace_id': 'ws_1',
      'name': 'Launch',
      'account_ids': ['acc_1'],
    });
    expect(jsonDecode(seen.all[3].body), {'name': 'Launch'});
    expect(groups.single.accountIds, ['acc_1', 'acc_2']);
    expect(created.createdAt, DateTime.utc(2026, 9, 19, 10));
    client.close();
  });

  test('setMembers replaces the account ids', () async {
    final seen = RecordedRequests();
    final client = fakeClient((_) async => jsonOk(groupJson), recorder: seen);

    final group = await client.accountGroups.setMembers('grp_1', ['acc_2']);

    expect(seen.last.method, 'PUT');
    expect(seen.last.url.path, '/v1/account-groups/grp_1/members');
    expect(jsonDecode(seen.last.body), {
      'account_ids': ['acc_2']
    });
    expect(group.id, 'grp_1');
    client.close();
  });
}
