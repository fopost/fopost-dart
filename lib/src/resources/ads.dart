import 'package:meta/meta.dart';

import '../http.dart';
import '../json.dart';
import '../models/ad.dart';
import 'base.dart';

/// Ads: boosts, standalone ads, audiences and lead forms on connected ad
/// accounts.
///
/// Every call needs the `ads` scope. [boost], [create], [setStatus] and
/// [delete] spend money and need the `publish` scope as well. Reach it as
/// `client.ads`.
class AdsResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  AdsResource(this._http);

  final FoPostHttp _http;

  /// Boosts and ads created through FoPost, with insights from their last
  /// refresh.
  Future<List<Ad>> list({String? workspaceId}) async {
    final rows = await _http
        .objects('GET', '/ads', query: {'workspace_id': workspaceId});
    return rows.map(Ad.fromJson).toList();
  }

  /// Ads on the connected ad accounts that were made elsewhere. Read live,
  /// never stored.
  Future<List<ExternalAd>> external({String? workspaceId}) async {
    final rows = await _http
        .objects('GET', '/ads/external', query: {'workspace_id': workspaceId});
    return rows.map(ExternalAd.fromJson).toList();
  }

  /// Published posts a boost can promote.
  Future<List<BoostablePost>> boostable({String? workspaceId}) async {
    final rows = await _http
        .objects('GET', '/ads/boostable', query: {'workspace_id': workspaceId});
    return rows.map(BoostablePost.fromJson).toList();
  }

  /// The ad connections the key can reach.
  Future<List<AdConnection>> connections({String? workspaceId}) async {
    final rows = await _http.objects('GET', '/ads/connections',
        query: {'workspace_id': workspaceId});
    return rows.map(AdConnection.fromJson).toList();
  }

  /// Each connection with the ad accounts and Pages its grant reaches.
  Future<List<AdSource>> sources({String? workspaceId}) async {
    final rows = await _http
        .objects('GET', '/ads/sources', query: {'workspace_id': workspaceId});
    return rows.map(AdSource.fromJson).toList();
  }

  /// Starts a Meta ads connection: returns the login URL the user finishes in
  /// their own browser. [method] is `business` or `user`.
  Future<String> authorizeMeta({
    required String workspaceId,
    String? method,
    String? returnTo,
  }) async {
    final body = pruned({
      'workspaceId': workspaceId,
      'method': method,
      'returnTo': returnTo,
    });
    final result = await _http.object('POST', '/ads/connections/meta/authorize',
        body: body);
    return asString(result['url']) ?? '';
  }

  /// Removes a connection, and with it every ad record created through it.
  Future<void> deleteConnection(String id, {required String workspaceId}) =>
      _http.discard('DELETE', '/ads/connections/${segment(id)}',
          query: {'workspace_id': workspaceId});

  /// Promotes a post FoPost already published.
  ///
  /// Needs the `publish` scope as well as `ads`. The boost starts paused
  /// unless [paused] is `false`.
  Future<Ad> boost({
    required String workspaceId,
    required String connectionId,
    required String adAccountId,
    required String postId,
    required String accountId,
    required String name,
    required String goal,
    required AdBudget budget,
    required AdTargeting targeting,
    bool? paused,
  }) async {
    final body = pruned({
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'adAccountId': adAccountId,
      'postId': postId,
      'accountId': accountId,
      'name': name,
      'goal': goal,
      'budget': budget.toJson(),
      'targeting': targeting.toJson(),
      'paused': paused,
    });
    return Ad.fromJson(await _http.object('POST', '/ads/boost', body: body));
  }

  /// Creates a standalone ad from a creative, published as [pageId].
  ///
  /// Needs the `publish` scope as well as `ads`. The ad starts paused unless
  /// [paused] is `false`.
  Future<Ad> create({
    required String workspaceId,
    required String connectionId,
    required String adAccountId,
    required String pageId,
    required String name,
    required String goal,
    required AdBudget budget,
    required AdTargeting targeting,
    required String text,
    String? headline,
    String? destinationUrl,
    String? mediaUrl,
    bool? paused,
  }) async {
    final body = pruned({
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'adAccountId': adAccountId,
      'pageId': pageId,
      'name': name,
      'goal': goal,
      'budget': budget.toJson(),
      'targeting': targeting.toJson(),
      'text': text,
      'headline': headline,
      'destinationUrl': destinationUrl,
      'mediaUrl': mediaUrl,
      'paused': paused,
    });
    return Ad.fromJson(await _http.object('POST', '/ads', body: body));
  }

  /// Reads the delivery status and lifetime insights from the platform.
  Future<Ad> refresh(String id, {required String workspaceId}) async =>
      Ad.fromJson(await _http.object('POST', '/ads/${segment(id)}/refresh',
          query: {'workspace_id': workspaceId}));

  /// Sets an ad to [status], one of [AdStatus].
  ///
  /// Needs the `publish` scope as well as `ads`.
  Future<Ad> setStatus(
    String id, {
    required String workspaceId,
    required String status,
  }) async =>
      Ad.fromJson(await _http.object(
        'PATCH',
        '/ads/${segment(id)}',
        body: {'status': status},
        query: {'workspace_id': workspaceId},
      ));

  /// Ends delivery and deletes the ad on the platform as well as here.
  ///
  /// Needs the `publish` scope as well as `ads`.
  Future<void> delete(String id, {required String workspaceId}) =>
      _http.discard('DELETE', '/ads/${segment(id)}',
          query: {'workspace_id': workspaceId});

  /// The saved audiences and pixels on an ad account.
  Future<AudiencesResult> audiences({
    required String connectionId,
    required String adAccountId,
    String? workspaceId,
  }) async =>
      AudiencesResult.fromJson(
          await _http.object('GET', '/ads/audiences', query: {
        'workspace_id': workspaceId,
        'connection_id': connectionId,
        'ad_account_id': adAccountId,
      }));

  /// Saves an audience built from [spec].
  Future<AudienceCreated> createAudience({
    required String workspaceId,
    required String connectionId,
    required String adAccountId,
    required String name,
    required AudienceSpec spec,
    String? description,
  }) async {
    final body = pruned({
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'adAccountId': adAccountId,
      'name': name,
      'description': description,
      'spec': spec.toJson(),
    });
    return AudienceCreated.fromJson(
        await _http.object('POST', '/ads/audiences', body: body));
  }

  /// Looks up locations, interests, behaviors and income brackets as the
  /// platform names them. [type] is one of [TargetingType].
  Future<List<TargetingOption>> searchTargeting({
    required String connectionId,
    required String type,
    String? q,
    String? workspaceId,
  }) async {
    final rows = await _http.objects('GET', '/ads/targeting/search', query: {
      'workspace_id': workspaceId,
      'connection_id': connectionId,
      'type': type,
      'q': q,
    });
    return rows.map(TargetingOption.fromJson).toList();
  }

  /// Each connection's Page with the lead forms on it.
  Future<List<LeadFormSource>> leadForms({String? workspaceId}) async {
    final rows = await _http.objects('GET', '/ads/lead-forms',
        query: {'workspace_id': workspaceId});
    return rows.map(LeadFormSource.fromJson).toList();
  }

  /// Creates an instant form on a Page and returns its id. [questions] are
  /// from [LeadFormQuestion].
  Future<String> createLeadForm({
    required String workspaceId,
    required String connectionId,
    required String pageId,
    required String name,
    required List<String> questions,
    required String privacyPolicyUrl,
    required String thankYouMessage,
    String? followUpUrl,
  }) async {
    final body = pruned({
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'pageId': pageId,
      'name': name,
      'questions': questions,
      'privacyPolicyUrl': privacyPolicyUrl,
      'thankYouMessage': thankYouMessage,
      'followUpUrl': followUpUrl,
    });
    final result = await _http.object('POST', '/ads/lead-forms', body: body);
    return asString(result['id']) ?? '';
  }

  /// One page of a form's leads; pass `nextCursor` back as [after] for the
  /// next.
  Future<LeadsPage> leads(
    String formId, {
    required String connectionId,
    required String pageId,
    String? after,
    String? workspaceId,
  }) async =>
      LeadsPage.fromJson(await _http.object(
        'GET',
        '/ads/lead-forms/${segment(formId)}/leads',
        query: {
          'workspace_id': workspaceId,
          'connection_id': connectionId,
          'page_id': pageId,
          'after': after,
        },
      ));
}
