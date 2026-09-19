import 'package:meta/meta.dart';

import '../http.dart';
import '../json.dart';
import '../models/account_group.dart';
import 'base.dart';

/// Account groups, named sets of accounts a post can target at once.
///
/// Reach it as `client.accountGroups`.
class AccountGroupsResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  AccountGroupsResource(this._http);

  final FoPostHttp _http;

  /// Returns the groups the key can reach, optionally narrowed to one
  /// workspace.
  Future<List<AccountGroup>> list({String? workspaceId}) async {
    final rows = await _http.objects('GET', '/account-groups',
        query: {'workspace_id': workspaceId});
    return rows.map(AccountGroup.fromJson).toList();
  }

  /// Returns one group.
  Future<AccountGroup> get(String id) async => AccountGroup.fromJson(
      await _http.object('GET', '/account-groups/${segment(id)}'));

  /// Adds a group to a workspace, optionally with its first members.
  Future<AccountGroup> create({
    required String workspaceId,
    required String name,
    List<String>? accountIds,
  }) async {
    final body = pruned({
      'workspace_id': workspaceId,
      'name': name,
      'account_ids': accountIds,
    });
    return AccountGroup.fromJson(
        await _http.object('POST', '/account-groups', body: body));
  }

  /// Renames a group.
  Future<AccountGroup> update(String id, {required String name}) async =>
      AccountGroup.fromJson(await _http.object(
          'PATCH', '/account-groups/${segment(id)}',
          body: {'name': name}));

  /// Removes a group. The accounts in it stay connected.
  Future<void> delete(String id) =>
      _http.discard('DELETE', '/account-groups/${segment(id)}');

  /// Replaces a group's members with [accountIds].
  Future<AccountGroup> setMembers(String id, List<String> accountIds) async =>
      AccountGroup.fromJson(await _http.object(
          'PUT', '/account-groups/${segment(id)}/members',
          body: {'account_ids': accountIds}));
}
