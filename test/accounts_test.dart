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

  test('createTelegramConnectCode posts the workspace', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'code': 'ABC123',
              'command': '/connect ABC123',
              'bot_username': 'fopost_bot',
              'deep_link': null,
              'group_link': null,
              'expires_at': '2026-09-19T12:15:00.000Z',
            }),
        recorder: seen);

    final code =
        await client.accounts.createTelegramConnectCode(workspaceId: 'ws_1');

    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/accounts/telegram/connect-code');
    expect(jsonDecode(seen.last.body), {'workspaceId': 'ws_1'});
    expect(code.command, '/connect ABC123');
    expect(code.botUsername, 'fopost_bot');
    expect(code.deepLink, isNull);
    client.close();
  });

  test('getTelegramConnectStatus reads the failure reason', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'status': 'failed',
              'account_id': null,
              'reason': 'card_required',
            }),
        recorder: seen);

    final status = await client.accounts.getTelegramConnectStatus('ABC123');

    expect(seen.last.url.path, '/v1/accounts/telegram/connect-code/status');
    expect(seen.last.url.queryParameters, {'code': 'ABC123'});
    expect(status.status, 'failed');
    expect(status.reason, 'card_required');
    client.close();
  });

  test('Telegram bot commands are read, replaced and cleared', () async {
    final seen = RecordedRequests();
    final menu = {
      'commands': [
        {'command': 'start', 'description': 'Start'}
      ]
    };
    var calls = 0;
    final client = fakeClient((_) async {
      calls++;
      return jsonOk(calls < 3 ? menu : {'commands': []});
    }, recorder: seen);

    final listed = await client.accounts.getTelegramBotCommands('acc_1');
    expect(seen.last.method, 'GET');
    expect(listed.single.command, 'start');

    await client.accounts.setTelegramBotCommands('acc_1',
        [const TelegramBotCommand(command: 'start', description: 'Start')]);
    expect(seen.last.method, 'PUT');
    expect(seen.last.url.path, '/v1/accounts/acc_1/telegram/commands');
    expect(jsonDecode(seen.last.body), menu);

    final cleared = await client.accounts.deleteTelegramBotCommands('acc_1');
    expect(seen.last.method, 'DELETE');
    expect(cleared, isEmpty);
    client.close();
  });

  test('slack channels and members read the list', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (request) async => request.url.path.endsWith('/channels')
            ? jsonOk([
                {
                  'id': 'C1',
                  'name': 'general',
                  'is_private': false,
                  'is_member': true,
                  'is_current': true,
                }
              ])
            : jsonOk([
                {
                  'id': 'U1',
                  'name': 'ada',
                  'real_name': 'Ada',
                  'display_name': null,
                  'avatar': null,
                  'is_bot': false,
                }
              ]),
        recorder: seen);

    final channels = await client.accounts.slackChannels('acc_1');
    expect(seen.last.url.path, '/v1/accounts/acc_1/slack/channels');
    expect(channels.single.isCurrent, isTrue);

    final members = await client.accounts.slackMembers('acc_1');
    expect(seen.last.url.path, '/v1/accounts/acc_1/slack/members');
    expect(members.single.realName, 'Ada');
    expect(members.single.displayName, isNull);
    client.close();
  });

  test('slack identity update omits unset fields and sends null to clear',
      () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk(
            {'username': 'Bot', 'icon_url': null, 'icon_emoji': ':rocket:'}),
        recorder: seen);

    final current = await client.accounts.getSlackIdentity('acc_1');
    expect(seen.last.url.path, '/v1/accounts/acc_1/slack/identity');
    expect(current.iconEmoji, ':rocket:');

    await client.accounts
        .updateSlackIdentity('acc_1', username: 'Bot', clearIconUrl: true);
    expect(seen.last.method, 'PATCH');
    expect(jsonDecode(seen.last.body), {'username': 'Bot', 'icon_url': null});
    client.close();
  });

  test('slack calls surface a webhook connection as a 409', () async {
    final client = fakeClient(
        (_) async => jsonError(409, 'webhook_connection', 'Reconnect'));

    await expectLater(
      client.accounts.slackChannels('acc_1'),
      throwsA(predicate<FoPostException>(
          (e) => e.statusCode == 409 && e.code == 'webhook_connection')),
    );
    client.close();
  });
}
