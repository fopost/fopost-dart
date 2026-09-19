import 'package:meta/meta.dart';

import '../http.dart';
import '../json.dart';
import '../models/account.dart';
import 'base.dart';

/// Connected social accounts.
///
/// Reach it as `client.accounts`.
class AccountsResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  AccountsResource(this._http);

  final FoPostHttp _http;

  /// Returns the connected accounts the key can reach, optionally narrowed to
  /// one workspace or one account group.
  Future<List<Account>> list({String? workspaceId, String? groupId}) async {
    final rows = await _http.objects('GET', '/accounts',
        query: {'workspaceId': workspaceId, 'group_id': groupId});
    return rows.map(Account.fromJson).toList();
  }

  /// Returns one account.
  Future<AccountDetail> get(String id) async => AccountDetail.fromJson(
      await _http.object('GET', '/accounts/${segment(id)}'));

  /// Connects an account from credentials you already hold.
  ///
  /// Platforms that use OAuth are connected in the dashboard instead.
  Future<AccountDetail> create({
    required String workspaceId,
    required String platform,
    required String username,
    required String name,
    String? avatar,
    Map<String, dynamic>? credentials,
  }) async {
    final body = pruned({
      'workspaceId': workspaceId,
      'platform': platform,
      'username': username,
      'name': name,
      'avatar': avatar,
      'credentials': credentials,
    });
    return AccountDetail.fromJson(
        await _http.object('POST', '/accounts', body: body));
  }

  /// Sets the name FoPost shows for an account. A null or empty
  /// [displayName] restores the platform's own name.
  Future<RenamedAccount> rename(String id, String? displayName) async =>
      RenamedAccount.fromJson(await _http.object(
          'PATCH', '/accounts/${segment(id)}',
          body: {'display_name': displayName}));

  /// Moves an account to another workspace the caller owns.
  ///
  /// A 409 with the code `move_blocked` lists the reasons under
  /// `blocking_tables` in [FoPostException.bodyMap].
  Future<MovedAccount> move(String id, {required String workspaceId}) async =>
      MovedAccount.fromJson(await _http.object(
          'POST', '/accounts/${segment(id)}/move',
          body: {'workspace_id': workspaceId}));

  /// Disconnects an account.
  Future<void> delete(String id) =>
      _http.discard('DELETE', '/accounts/${segment(id)}');

  /// Toggles which account leads its platform in the workspace.
  Future<PrimaryAccount> setPrimary(String id) async => PrimaryAccount.fromJson(
      await _http.object('POST', '/accounts/${segment(id)}/primary'));

  /// Checks an account's credentials against the platform.
  Future<AccountValidation> validate(String id) async =>
      AccountValidation.fromJson(
          await _http.object('POST', '/accounts/${segment(id)}/validate'));

  /// Returns an account's health.
  ///
  /// Pass [refresh] to re-check it live rather than reading the last stored
  /// result.
  Future<AccountHealth> health(String id, {bool refresh = false}) async =>
      AccountHealth.fromJson(await _http.object(
        'GET',
        '/accounts/${segment(id)}/health',
        query: {if (refresh) 'refresh': 'true'},
      ));

  /// Returns the health of every account, optionally narrowed to one workspace.
  Future<AccountHealthSummary> healthSummary({String? workspaceId}) async =>
      AccountHealthSummary.fromJson(await _http.object(
        'GET',
        '/accounts/health',
        query: {'workspaceId': workspaceId},
      ));

  /// Renews an account's OAuth token ahead of its expiry.
  Future<RefreshedToken> refreshToken(String id) async =>
      RefreshedToken.fromJson(
          await _http.object('POST', '/accounts/${segment(id)}/refresh-token'));

  /// Returns an account's stored snapshots, newest first.
  Future<AccountAnalyticsHistory> analytics(String id, {int? limit}) async =>
      AccountAnalyticsHistory.fromJson(await _http.object(
        'GET',
        '/accounts/${segment(id)}/analytics',
        query: {'limit': limit},
      ));

  /// Mints a one-time code, valid for 15 minutes. Sending `/connect <code>` to
  /// the bot in a chat connects that chat. Omit [workspaceId] for a key bound
  /// to one workspace.
  Future<TelegramConnectCode> createTelegramConnectCode(
          {String? workspaceId}) async =>
      TelegramConnectCode.fromJson(await _http.object(
        'POST',
        '/accounts/telegram/connect-code',
        body: pruned({'workspaceId': workspaceId}),
      ));

  /// Returns where a Telegram connect code stands: `pending`, `connected`,
  /// `failed`, or `expired`.
  Future<TelegramConnectStatus> getTelegramConnectStatus(String code) async =>
      TelegramConnectStatus.fromJson(await _http.object(
        'GET',
        '/accounts/telegram/connect-code/status',
        query: {'code': code},
      ));

  /// Returns the command menu the bot shows in a connected Telegram chat.
  Future<List<TelegramBotCommand>> getTelegramBotCommands(String id) async =>
      _commands(await _http.object(
          'GET', '/accounts/${segment(id)}/telegram/commands'));

  /// Replaces the command menu for a connected Telegram chat (1-100 commands).
  Future<List<TelegramBotCommand>> setTelegramBotCommands(
          String id, List<TelegramBotCommand> commands) async =>
      _commands(await _http.object(
        'PUT',
        '/accounts/${segment(id)}/telegram/commands',
        body: {'commands': commands.map((c) => c.toJson()).toList()},
      ));

  /// Clears the command menu for a connected Telegram chat.
  Future<List<TelegramBotCommand>> deleteTelegramBotCommands(String id) async =>
      _commands(await _http.object(
          'DELETE', '/accounts/${segment(id)}/telegram/commands'));

  List<TelegramBotCommand> _commands(Map<String, dynamic> json) =>
      asModelList(json['commands'], TelegramBotCommand.fromJson);
}
