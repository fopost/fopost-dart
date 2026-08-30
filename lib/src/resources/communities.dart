import 'package:meta/meta.dart';

import '../http.dart';
import '../json.dart';
import '../models/community.dart';
import 'base.dart';

/// The communities an account can post into.
///
/// Reach it as `client.communities`.
class CommunitiesResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  CommunitiesResource(this._http);

  final FoPostHttp _http;

  /// Returns the communities linked to an account.
  Future<List<Community>> list(String accountId) async {
    final rows = await _http
        .objects('GET', '/accounts/${segment(accountId)}/communities');
    return rows.map(Community.fromJson).toList();
  }

  /// Pulls the account's communities from the platform and stores them.
  Future<List<Community>> sync(String accountId) async {
    final rows = await _http
        .objects('POST', '/accounts/${segment(accountId)}/communities/sync');
    return rows.map(Community.fromJson).toList();
  }

  /// Looks a community up on the platform without linking it.
  Future<List<CommunitySearchResult>> search(String accountId, String query) async {
    final rows = await _http.objects(
      'GET',
      '/accounts/${segment(accountId)}/communities/search',
      query: {'q': query},
    );
    return rows.map(CommunitySearchResult.fromJson).toList();
  }

  /// Links a community to the account by its platform id, for the case where
  /// search and sync do not surface it.
  Future<Community> add(String accountId, String communityId, {String? name}) async {
    final body = pruned({'communityId': communityId, 'name': name});
    return Community.fromJson(await _http.object(
      'POST',
      '/accounts/${segment(accountId)}/communities/manual',
      body: body,
    ));
  }

  /// Unlinks a community. [id] is `Community.id`, not the platform's own id.
  Future<void> remove(String accountId, int id) =>
      _http.discard('DELETE', '/accounts/${segment(accountId)}/communities/$id');
}
