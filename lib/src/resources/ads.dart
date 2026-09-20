import 'package:meta/meta.dart';

import '../http.dart';
import '../json.dart';
import '../models/ad.dart';
import '../models/ad_extras.dart';
import 'base.dart';

/// Ads: boosts, standalone ads, the campaign tree, creatives, catalogs,
/// audiences, predictions, the public ad archive, insights and lead forms on
/// connected ad accounts.
///
/// Every call needs the `ads` scope. [boost], [create], [setStatus],
/// [delete], [bulkSetStatus] and every create, update, delete and duplicate
/// on campaigns, ad sets and network ads spend money and need the `publish`
/// scope as well. Campaigns, ad sets, network ads, creatives and audiences are
/// addressed by the platform's own ids plus a `connectionId`, and are read
/// live, never stored. Reach it as `client.ads`.
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

  /// The Google login URL. The caller finishes it in their own browser
  /// session: the callback checks that the same user came back.
  Future<String> authorizeGoogle({
    required String workspaceId,
    String? returnTo,
  }) async {
    final body = pruned({'workspaceId': workspaceId, 'returnTo': returnTo});
    final result = await _http
        .object('POST', '/ads/connections/google/authorize', body: body);
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
  /// [urlTags] is a query string appended to every link in the ad, e.g.
  /// `utm_source=meta&utm_medium=paid`. Needs the `publish` scope as well as
  /// `ads`. The ad starts paused unless [paused] is `false`.
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
    String? urlTags,
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
      'urlTags': urlTags,
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

  /// An ad account's campaigns, each with its ad sets and their ads.
  Future<AdAccountTree> accountTree(
    String adAccountId, {
    required String connectionId,
    String? workspaceId,
  }) async =>
      AdAccountTree.fromJson(await _http.object(
          'GET', '/ads/accounts/${segment(adAccountId)}/tree',
          query: _meta(workspaceId, connectionId)));

  /// Creates a campaign. [goal] is one of [AdGoal].
  ///
  /// Needs the `publish` scope as well as `ads`. It starts paused unless
  /// [paused] is `false`.
  Future<AdCampaign> createCampaign({
    required String workspaceId,
    required String connectionId,
    required String adAccountId,
    required String name,
    required String goal,
    bool? paused,
  }) async {
    final body = pruned({
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'adAccountId': adAccountId,
      'name': name,
      'goal': goal,
      'paused': paused,
    });
    return AdCampaign.fromJson(
        await _http.object('POST', '/ads/campaigns', body: body));
  }

  /// One campaign, read live.
  Future<AdCampaign> campaign(
    String id, {
    required String connectionId,
    String? workspaceId,
  }) async =>
      AdCampaign.fromJson(await _http.object(
          'GET', '/ads/campaigns/${segment(id)}',
          query: _meta(workspaceId, connectionId)));

  /// Renames a campaign or sets its [status], one of [AdStatus].
  ///
  /// Needs the `publish` scope as well as `ads`.
  Future<AdCampaign> updateCampaign(
    String id, {
    required String workspaceId,
    required String connectionId,
    String? name,
    String? status,
  }) async =>
      AdCampaign.fromJson(await _http.object(
        'PATCH',
        '/ads/campaigns/${segment(id)}',
        body: pruned({'name': name, 'status': status}),
        query: _meta(workspaceId, connectionId),
      ));

  /// Deletes a campaign on the platform.
  ///
  /// Needs the `publish` scope as well as `ads`.
  Future<void> deleteCampaign(
    String id, {
    required String workspaceId,
    required String connectionId,
  }) =>
      _http.discard('DELETE', '/ads/campaigns/${segment(id)}',
          query: _meta(workspaceId, connectionId));

  /// Copies a campaign and returns the copy's id.
  ///
  /// Needs the `publish` scope as well as `ads`. The copy starts paused
  /// unless [paused] is `false`.
  Future<String> duplicateCampaign(
    String id, {
    required String workspaceId,
    required String connectionId,
    bool? paused,
  }) =>
      _duplicate(
          '/ads/campaigns/${segment(id)}', workspaceId, connectionId, paused);

  /// Creates an ad set in a campaign, running as [pageId].
  ///
  /// Needs the `publish` scope as well as `ads`. It starts paused unless
  /// [paused] is `false`.
  Future<AdSet> createAdSet({
    required String workspaceId,
    required String connectionId,
    required String campaignId,
    required String pageId,
    required String name,
    required String goal,
    required AdBudget budget,
    required AdTargeting targeting,
    bool? paused,
  }) async {
    final body = pruned({
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'campaignId': campaignId,
      'pageId': pageId,
      'name': name,
      'goal': goal,
      'budget': budget.toJson(),
      'targeting': targeting.toJson(),
      'paused': paused,
    });
    return AdSet.fromJson(
        await _http.object('POST', '/ads/ad-sets', body: body));
  }

  /// One ad set, read live.
  Future<AdSet> adSet(
    String id, {
    required String connectionId,
    String? workspaceId,
  }) async =>
      AdSet.fromJson(await _http.object('GET', '/ads/ad-sets/${segment(id)}',
          query: _meta(workspaceId, connectionId)));

  /// Changes an ad set's name, status, budget, end or targeting.
  ///
  /// [budgetMinor] keeps the budget type set at creation. Needs the `publish`
  /// scope as well as `ads`.
  Future<AdSet> updateAdSet(
    String id, {
    required String workspaceId,
    required String connectionId,
    String? name,
    String? status,
    int? budgetMinor,
    DateTime? endAt,
    AdTargeting? targeting,
  }) async =>
      AdSet.fromJson(await _http.object(
        'PATCH',
        '/ads/ad-sets/${segment(id)}',
        body: pruned({
          'name': name,
          'status': status,
          'budgetMinor': budgetMinor,
          'endAt': endAt?.toUtc().toIso8601String(),
          'targeting': targeting?.toJson(),
        }),
        query: _meta(workspaceId, connectionId),
      ));

  /// Deletes an ad set on the platform.
  ///
  /// Needs the `publish` scope as well as `ads`.
  Future<void> deleteAdSet(
    String id, {
    required String workspaceId,
    required String connectionId,
  }) =>
      _http.discard('DELETE', '/ads/ad-sets/${segment(id)}',
          query: _meta(workspaceId, connectionId));

  /// Copies an ad set and returns the copy's id.
  ///
  /// Needs the `publish` scope as well as `ads`.
  Future<String> duplicateAdSet(
    String id, {
    required String workspaceId,
    required String connectionId,
    bool? paused,
  }) =>
      _duplicate(
          '/ads/ad-sets/${segment(id)}', workspaceId, connectionId, paused);

  /// Creates an ad inside an ad set from an existing creative.
  ///
  /// Unlike [create], nothing is stored in FoPost. Needs the `publish` scope
  /// as well as `ads`. It starts paused unless [paused] is `false`.
  Future<NetworkAd> createNetworkAd({
    required String workspaceId,
    required String connectionId,
    required String adSetId,
    required String creativeId,
    required String name,
    bool? paused,
  }) async {
    final body = pruned({
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'adSetId': adSetId,
      'creativeId': creativeId,
      'name': name,
      'paused': paused,
    });
    return NetworkAd.fromJson(
        await _http.object('POST', '/ads/ads', body: body));
  }

  /// One ad inside an ad set, read live.
  Future<NetworkAd> networkAd(
    String id, {
    required String connectionId,
    String? workspaceId,
  }) async =>
      NetworkAd.fromJson(await _http.object('GET', '/ads/ads/${segment(id)}',
          query: _meta(workspaceId, connectionId)));

  /// Renames an ad, sets its status, or swaps its creative.
  ///
  /// Needs the `publish` scope as well as `ads`.
  Future<NetworkAd> updateNetworkAd(
    String id, {
    required String workspaceId,
    required String connectionId,
    String? name,
    String? status,
    String? creativeId,
  }) async =>
      NetworkAd.fromJson(await _http.object(
        'PATCH',
        '/ads/ads/${segment(id)}',
        body:
            pruned({'name': name, 'status': status, 'creativeId': creativeId}),
        query: _meta(workspaceId, connectionId),
      ));

  /// Deletes an ad on the platform.
  ///
  /// Needs the `publish` scope as well as `ads`.
  Future<void> deleteNetworkAd(
    String id, {
    required String workspaceId,
    required String connectionId,
  }) =>
      _http.discard('DELETE', '/ads/ads/${segment(id)}',
          query: _meta(workspaceId, connectionId));

  /// Copies an ad and returns the copy's id.
  ///
  /// Needs the `publish` scope as well as `ads`.
  Future<String> duplicateNetworkAd(
    String id, {
    required String workspaceId,
    required String connectionId,
    bool? paused,
  }) =>
      _duplicate('/ads/ads/${segment(id)}', workspaceId, connectionId, paused);

  /// Pauses or resumes up to 50 campaigns, ad sets and ads at once; each
  /// reports its own outcome. [status] is one of [AdStatus].
  ///
  /// Needs the `publish` scope as well as `ads`.
  Future<List<BulkAdStatusResult>> bulkSetStatus({
    required String workspaceId,
    required String connectionId,
    required String status,
    required List<AdObjectRef> objects,
  }) async {
    final rows = await _http.objects('POST', '/ads/status', body: {
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'status': status,
      'objects': objects.map((o) => o.toJson()).toList(),
    });
    return rows.map(BulkAdStatusResult.fromJson).toList();
  }

  /// The creatives in an ad account's library.
  Future<AdCreativesResult> creatives({
    required String connectionId,
    required String adAccountId,
    String? workspaceId,
  }) async =>
      AdCreativesResult.fromJson(
          await _http.object('GET', '/ads/creatives', query: {
        ..._meta(workspaceId, connectionId),
        'ad_account_id': adAccountId,
      }));

  /// Builds an image, video or carousel creative. [format] is one of
  /// [AdCreativeFormat]; a video needs [mediaUrl], a carousel two to ten
  /// [cards]. [callToAction] defaults to `LEARN_MORE`.
  Future<AdCreative> createCreative({
    required String workspaceId,
    required String connectionId,
    required String adAccountId,
    required String pageId,
    required String name,
    required String format,
    required String text,
    String? headline,
    String? destinationUrl,
    String? callToAction,
    String? urlTags,
    String? mediaUrl,
    String? thumbnailMediaUrl,
    List<AdCreativeCard>? cards,
  }) async {
    final body = pruned({
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'adAccountId': adAccountId,
      'pageId': pageId,
      'name': name,
      'format': format,
      'text': text,
      'headline': headline,
      'destinationUrl': destinationUrl,
      'callToAction': callToAction,
      'urlTags': urlTags,
      'mediaUrl': mediaUrl,
      'thumbnailMediaUrl': thumbnailMediaUrl,
      'cards': cards?.map((c) => c.toJson()).toList(),
    });
    return AdCreative.fromJson(
        await _http.object('POST', '/ads/creatives', body: body));
  }

  /// One creative, read live.
  Future<AdCreative> creative(
    String id, {
    required String connectionId,
    String? workspaceId,
  }) async =>
      AdCreative.fromJson(await _http.object(
          'GET', '/ads/creatives/${segment(id)}',
          query: _meta(workspaceId, connectionId)));

  /// Deletes a creative from the library.
  Future<void> deleteCreative(
    String id, {
    required String workspaceId,
    required String connectionId,
  }) =>
      _http.discard('DELETE', '/ads/creatives/${segment(id)}',
          query: _meta(workspaceId, connectionId));

  /// One saved audience, read live.
  Future<Audience> audience(
    String id, {
    required String connectionId,
    String? workspaceId,
  }) async =>
      Audience.fromJson(await _http.object(
          'GET', '/ads/audiences/${segment(id)}',
          query: _meta(workspaceId, connectionId)));

  /// Renames an audience or changes its description.
  Future<Audience> updateAudience(
    String id, {
    required String workspaceId,
    required String connectionId,
    String? name,
    String? description,
  }) async =>
      Audience.fromJson(await _http.object(
        'PATCH',
        '/ads/audiences/${segment(id)}',
        body: pruned({'name': name, 'description': description}),
        query: _meta(workspaceId, connectionId),
      ));

  /// Deletes an audience on the platform.
  Future<void> deleteAudience(
    String id, {
    required String workspaceId,
    required String connectionId,
  }) =>
      _http.discard('DELETE', '/ads/audiences/${segment(id)}',
          query: _meta(workspaceId, connectionId));

  /// Adds a customer list to a custom audience and returns how many emails
  /// were sent. They are hashed before they leave the API.
  Future<int> addAudienceUsers(
    String id, {
    required String workspaceId,
    required String connectionId,
    required List<String> emails,
  }) async {
    final result = await _http.object(
      'POST',
      '/ads/audiences/${segment(id)}/users',
      body: {'emails': emails},
      query: _meta(workspaceId, connectionId),
    );
    return asInt(result['added']) ?? 0;
  }

  /// How many people [targeting] could reach from an ad account.
  Future<ReachEstimate> estimateReach({
    required String workspaceId,
    required String connectionId,
    required String adAccountId,
    required String pageId,
    required AdTargeting targeting,
  }) async =>
      ReachEstimate.fromJson(
          await _http.object('POST', '/ads/reach-estimate', body: {
        'workspaceId': workspaceId,
        'connectionId': connectionId,
        'adAccountId': adAccountId,
        'pageId': pageId,
        'targeting': targeting.toJson(),
      }));

  /// Insights for any campaign, ad set or ad on the platform between [since]
  /// and [until] (`YYYY-MM-DD`). [breakdown] is one of
  /// [AdInsightsBreakdown]; [daily] adds a per-day timeline.
  Future<AdInsightsReport> insights({
    required String connectionId,
    required String objectId,
    required String since,
    required String until,
    String? breakdown,
    bool? daily,
    String? workspaceId,
  }) async =>
      AdInsightsReport.fromJson(
          await _http.object('GET', '/ads/insights', query: {
        ..._meta(workspaceId, connectionId),
        'object_id': objectId,
        'since': since,
        'until': until,
        'breakdown': breakdown,
        'daily': daily,
      }));

  /// Insights for a boost or ad created through FoPost, by its FoPost id.
  Future<AdInsightsReport> adInsights(
    String id, {
    required String workspaceId,
    required String since,
    required String until,
    String? breakdown,
    bool? daily,
  }) async =>
      AdInsightsReport.fromJson(
          await _http.object('GET', '/ads/${segment(id)}/insights', query: {
        'workspace_id': workspaceId,
        'since': since,
        'until': until,
        'breakdown': breakdown,
        'daily': daily,
      }));

  /// One lead form with its settings.
  Future<LeadFormDetail> leadForm(
    String formId, {
    required String connectionId,
    required String pageId,
    String? workspaceId,
  }) async =>
      LeadFormDetail.fromJson(await _http
          .object('GET', '/ads/lead-forms/${segment(formId)}', query: {
        ..._meta(workspaceId, connectionId),
        'page_id': pageId,
      }));

  /// Archives a lead form so it stops collecting leads.
  Future<LeadFormDetail> archiveLeadForm(
    String formId, {
    required String workspaceId,
    required String connectionId,
    required String pageId,
  }) async =>
      LeadFormDetail.fromJson(await _http
          .object('POST', '/ads/lead-forms/${segment(formId)}/archive', body: {
        'workspaceId': workspaceId,
        'connectionId': connectionId,
        'pageId': pageId,
      }));

  /// Leads stored from subscribed Pages, newest first; pass `nextCursor`
  /// back as [cursor] for the next page. [limit] is 1 to 100.
  Future<LeadsFeedPage> leadsFeed({
    String? workspaceId,
    String? formId,
    String? pageId,
    String? cursor,
    int? limit,
  }) async =>
      LeadsFeedPage.fromJson(await _http.object('GET', '/ads/leads', query: {
        'workspace_id': workspaceId,
        'form_id': formId,
        'page_id': pageId,
        'cursor': cursor,
        'limit': limit,
      }));

  /// The Pages whose leads are stored into [leadsFeed].
  Future<List<LeadPage>> leadPages({String? workspaceId}) async {
    final rows = await _http.objects('GET', '/ads/lead-pages',
        query: {'workspace_id': workspaceId});
    return rows.map(LeadPage.fromJson).toList();
  }

  /// Starts storing a Page's leads; recent ones are backfilled.
  Future<LeadPageSubscription> subscribeLeadPage({
    required String workspaceId,
    required String connectionId,
    required String pageId,
  }) async =>
      LeadPageSubscription.fromJson(
          await _http.object('POST', '/ads/lead-pages', body: {
        'workspaceId': workspaceId,
        'connectionId': connectionId,
        'pageId': pageId,
      }));

  /// Stops storing a Page's leads.
  Future<void> unsubscribeLeadPage(
    String pageId, {
    required String workspaceId,
    required String connectionId,
  }) =>
      _http.discard('DELETE', '/ads/lead-pages/${segment(pageId)}',
          query: _meta(workspaceId, connectionId));

  Future<String> _duplicate(
    String path,
    String workspaceId,
    String connectionId,
    bool? paused,
  ) async {
    final result = await _http.object(
      'POST',
      '$path/duplicate',
      body: pruned({'paused': paused}),
      query: _meta(workspaceId, connectionId),
    );
    return asString(result['id']) ?? '';
  }

  // ─── Goals ──────────────────────────────────────────────────────

  /// The goals this connection's ad platform can run right now.
  ///
  /// Ask rather than assume: a goal the deployment is not set up for is absent
  /// here and is refused if you send it anyway.
  Future<List<String>> goals({
    required String connectionId,
    String? workspaceId,
  }) async {
    final rows = await _http.raw('GET', '/ads/goals',
        query: _meta(workspaceId, connectionId));
    return asStringList(rows);
  }

  // ─── Product catalogs ───────────────────────────────────────────

  /// Catalogs the connection's business portfolios reach. Read live, never
  /// stored.
  Future<List<ProductCatalog>> catalogs({
    required String connectionId,
    String? workspaceId,
  }) async {
    final result = await _http.object('GET', '/ads/catalogs',
        query: _meta(workspaceId, connectionId));
    return asModelList(result['catalogs'], ProductCatalog.fromJson);
  }

  /// Created on the connection's business portfolio. Also needs `publish`.
  Future<ProductCatalog> createCatalog({
    required String workspaceId,
    required String connectionId,
    required String name,
    String? vertical,
  }) async {
    final body = pruned({
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'name': name,
      'vertical': vertical,
    });
    return ProductCatalog.fromJson(
        await _http.object('POST', '/ads/catalogs', body: body));
  }

  /// One catalog, read live.
  Future<ProductCatalog> catalog(
    String id, {
    required String connectionId,
    String? workspaceId,
  }) async =>
      ProductCatalog.fromJson(await _http.object(
          'GET', '/ads/catalogs/${segment(id)}',
          query: _meta(workspaceId, connectionId)));

  /// Renames a catalog. Also needs `publish`.
  Future<ProductCatalog> updateCatalog(
    String id, {
    required String workspaceId,
    required String connectionId,
    required String name,
  }) async {
    final body = {
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'name': name,
    };
    return ProductCatalog.fromJson(await _http.object(
        'PATCH', '/ads/catalogs/${segment(id)}',
        body: body, query: _meta(workspaceId, connectionId)));
  }

  /// Deletes every product, feed and set in it. Also needs `publish`.
  Future<void> deleteCatalog(
    String id, {
    required String workspaceId,
    required String connectionId,
  }) =>
      _http.discard('DELETE', '/ads/catalogs/${segment(id)}',
          query: _meta(workspaceId, connectionId));

  /// One page of products; pass `nextCursor` back as [after].
  Future<CatalogProductsPage> catalogProducts(
    String id, {
    required String connectionId,
    String? workspaceId,
    String? after,
  }) async =>
      CatalogProductsPage.fromJson(await _http.object(
          'GET', '/ads/catalogs/${segment(id)}/products',
          query: {..._meta(workspaceId, connectionId), 'after': after}));

  /// Up to 500 upserts and deletes in one batch, keyed by your own retailer
  /// id. Also needs `publish`.
  Future<CatalogBatchResult> writeCatalogProducts(
    String id, {
    required String workspaceId,
    required String connectionId,
    required List<CatalogProductWrite> products,
  }) async {
    final body = {
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'products': products.map((p) => p.toJson()).toList(),
    };
    return CatalogBatchResult.fromJson(await _http
        .object('POST', '/ads/catalogs/${segment(id)}/products', body: body));
  }

  /// The feeds keeping a catalog in step with a hosted product file.
  Future<List<ProductFeed>> productFeeds(
    String id, {
    required String connectionId,
    String? workspaceId,
  }) async {
    final rows = await _http.objects(
        'GET', '/ads/catalogs/${segment(id)}/feeds',
        query: _meta(workspaceId, connectionId));
    return rows.map(ProductFeed.fromJson).toList();
  }

  /// A [schedule] needs a [url]. Also needs `publish`.
  Future<ProductFeed> createProductFeed(
    String id, {
    required String workspaceId,
    required String connectionId,
    required String name,
    String? url,
    String? schedule,
  }) async {
    final body = pruned({
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'name': name,
      'url': url,
      'schedule': schedule,
    });
    return ProductFeed.fromJson(await _http
        .object('POST', '/ads/catalogs/${segment(id)}/feeds', body: body));
  }

  /// Also needs `publish`.
  Future<void> deleteProductFeed(
    String id,
    String feedId, {
    required String workspaceId,
    required String connectionId,
  }) =>
      _http.discard(
          'DELETE', '/ads/catalogs/${segment(id)}/feeds/${segment(feedId)}',
          query: _meta(workspaceId, connectionId));

  /// Each run the ad platform made of the feed.
  Future<List<ProductFeedUpload>> feedUploads(
    String id,
    String feedId, {
    required String connectionId,
    String? workspaceId,
  }) async {
    final rows = await _http.objects(
        'GET', '/ads/catalogs/${segment(id)}/feeds/${segment(feedId)}/uploads',
        query: _meta(workspaceId, connectionId));
    return rows.map(ProductFeedUpload.fromJson).toList();
  }

  /// Fetches the feed now; the id of the run. Also needs `publish`.
  Future<String> startFeedUpload(
    String id,
    String feedId, {
    required String workspaceId,
    required String connectionId,
    String? url,
  }) async {
    final body = pruned({
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'url': url,
    });
    final result = await _http.object(
        'POST', '/ads/catalogs/${segment(id)}/feeds/${segment(feedId)}/uploads',
        body: body);
    return asString(result['id']) ?? '';
  }

  /// A catalog ad runs from a product set, not the whole catalog.
  Future<List<ProductSet>> productSets(
    String id, {
    required String connectionId,
    String? workspaceId,
  }) async {
    final rows = await _http.objects(
        'GET', '/ads/catalogs/${segment(id)}/product-sets',
        query: _meta(workspaceId, connectionId));
    return rows.map(ProductSet.fromJson).toList();
  }

  /// Without a [filter] the set is the whole catalog. Also needs `publish`.
  Future<ProductSet> createProductSet(
    String id, {
    required String workspaceId,
    required String connectionId,
    required String name,
    Map<String, dynamic>? filter,
  }) async {
    final body = pruned({
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'name': name,
      'filter': filter,
    });
    return ProductSet.fromJson(await _http.object(
        'POST', '/ads/catalogs/${segment(id)}/product-sets',
        body: body));
  }

  /// Also needs `publish`.
  Future<ProductSet> updateProductSet(
    String id,
    String setId, {
    required String workspaceId,
    required String connectionId,
    required String name,
    Map<String, dynamic>? filter,
  }) async {
    final body = pruned({
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'name': name,
      'filter': filter,
    });
    return ProductSet.fromJson(await _http.object(
        'PATCH', '/ads/catalogs/${segment(id)}/product-sets/${segment(setId)}',
        body: body, query: _meta(workspaceId, connectionId)));
  }

  /// Also needs `publish`.
  Future<void> deleteProductSet(
    String id,
    String setId, {
    required String workspaceId,
    required String connectionId,
  }) =>
      _http.discard('DELETE',
          '/ads/catalogs/${segment(id)}/product-sets/${segment(setId)}',
          query: _meta(workspaceId, connectionId));

  // ─── Reach and frequency ────────────────────────────────────────

  /// The predictions on one ad account.
  Future<List<ReachFrequencyPrediction>> reachFrequency({
    required String connectionId,
    required String adAccountId,
    String? workspaceId,
  }) async {
    final result = await _http.object('GET', '/ads/reach-frequency',
        query: _account(workspaceId, connectionId, adAccountId));
    return asModelList(
        result['predictions'], ReachFrequencyPrediction.fromJson);
  }

  /// Prices a flight. Nothing is bought until you reserve it.
  Future<ReachFrequencyPrediction> createReachFrequency({
    required String workspaceId,
    required String connectionId,
    required String adAccountId,
    required String name,
    required AdTargeting targeting,
    required List<String> placements,
    required int budgetMinor,
    required DateTime startAt,
    required DateTime endAt,
    int? frequencyCap,
  }) async {
    final body = pruned({
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'adAccountId': adAccountId,
      'name': name,
      'targeting': targeting.toJson(),
      'placements': placements,
      'budgetMinor': budgetMinor,
      'startAt': startAt.toUtc().toIso8601String(),
      'endAt': endAt.toUtc().toIso8601String(),
      'frequencyCap': frequencyCap,
    });
    return ReachFrequencyPrediction.fromJson(
        await _http.object('POST', '/ads/reach-frequency', body: body));
  }

  /// One prediction, read live.
  Future<ReachFrequencyPrediction> reachFrequencyPrediction(
    String id, {
    required String connectionId,
    required String adAccountId,
    String? workspaceId,
  }) async =>
      ReachFrequencyPrediction.fromJson(await _http.object(
          'GET', '/ads/reach-frequency/${segment(id)}',
          query: _account(workspaceId, connectionId, adAccountId)));

  /// Holds the inventory the prediction priced. Also needs `publish`.
  Future<ReachFrequencyPrediction> reserveReachFrequency(
    String id, {
    required String workspaceId,
    required String connectionId,
    required String adAccountId,
  }) =>
      _reachFrequencyAction(
          id, 'reserve', workspaceId, connectionId, adAccountId);

  /// Also needs `publish`.
  Future<ReachFrequencyPrediction> cancelReachFrequency(
    String id, {
    required String workspaceId,
    required String connectionId,
    required String adAccountId,
  }) =>
      _reachFrequencyAction(
          id, 'cancel', workspaceId, connectionId, adAccountId);

  // ─── Ad Library ─────────────────────────────────────────────────

  /// The public ad archive: ads anyone is running, by keyword or by Page.
  ///
  /// Read live on every call and stored nowhere, so an ad that stops running
  /// is simply absent from the next search. [countries] are two-letter codes
  /// the ad reached.
  Future<AdLibraryPage> library({
    required String connectionId,
    required List<String> countries,
    String? q,
    List<String>? pageIds,
    String? activeStatus,
    int? limit,
    String? after,
    String? workspaceId,
  }) async =>
      AdLibraryPage.fromJson(await _http.object('GET', '/ads/library', query: {
        ..._meta(workspaceId, connectionId),
        'countries': countries.join(','),
        'q': q,
        'page_ids': pageIds?.join(','),
        'active_status': activeStatus,
        'limit': limit,
        'after': after,
      }));

  // ─── Partnership ads ────────────────────────────────────────────

  /// Creators who allowlisted this Page to run partnership ads on their posts.
  Future<List<PartnershipCreator>> partnershipCreators({
    required String connectionId,
    required String pageId,
    String? workspaceId,
  }) async {
    final rows = await _http.objects('GET', '/ads/partnership/creators',
        query: {..._meta(workspaceId, connectionId), 'page_id': pageId});
    return rows.map(PartnershipCreator.fromJson).toList();
  }

  /// Asks a creator for permission; the list as it now stands.
  Future<List<PartnershipCreator>> requestPartnership({
    required String workspaceId,
    required String connectionId,
    required String pageId,
    required String creatorId,
  }) async {
    final body = {
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'pageId': pageId,
      'creatorId': creatorId,
    };
    final rows =
        await _http.objects('POST', '/ads/partnership/creators', body: body);
    return rows.map(PartnershipCreator.fromJson).toList();
  }

  /// Revokes a creator's partnership permission.
  Future<void> revokePartnership(
    String creatorId, {
    required String workspaceId,
    required String connectionId,
    required String pageId,
  }) =>
      _http.discard('DELETE', '/ads/partnership/creators/${segment(creatorId)}',
          query: {..._meta(workspaceId, connectionId), 'page_id': pageId});

  // ─── Ad account settings ────────────────────────────────────────

  /// Who changed what on the ad account, and when. Dates are `YYYY-MM-DD`.
  Future<List<AdActivity>> accountActivity({
    required String connectionId,
    required String adAccountId,
    String? since,
    String? until,
    String? workspaceId,
  }) async {
    final result = await _http.object('GET', '/ads/account/activity', query: {
      ..._account(workspaceId, connectionId, adAccountId),
      'since': since,
      'until': until,
    });
    return asModelList(result['activity'], AdActivity.fromJson);
  }

  /// The labels on an ad account.
  Future<List<AdLabel>> labels({
    required String connectionId,
    required String adAccountId,
    String? workspaceId,
  }) async {
    final rows = await _http.objects('GET', '/ads/account/labels',
        query: _account(workspaceId, connectionId, adAccountId));
    return rows.map(AdLabel.fromJson).toList();
  }

  /// Creates a label.
  Future<AdLabel> createLabel({
    required String workspaceId,
    required String connectionId,
    required String adAccountId,
    required String name,
  }) async =>
      AdLabel.fromJson(await _http.object('POST', '/ads/account/labels',
          body: _labelBody(workspaceId, connectionId, adAccountId, name)));

  /// Renames a label.
  Future<AdLabel> updateLabel(
    String id, {
    required String workspaceId,
    required String connectionId,
    required String adAccountId,
    required String name,
  }) async =>
      AdLabel.fromJson(await _http.object(
          'PATCH', '/ads/account/labels/${segment(id)}',
          body: _labelBody(workspaceId, connectionId, adAccountId, name),
          query: _meta(workspaceId, connectionId)));

  /// Deletes a label.
  Future<void> deleteLabel(
    String id, {
    required String workspaceId,
    required String connectionId,
    required String adAccountId,
  }) =>
      _http.discard('DELETE', '/ads/account/labels/${segment(id)}',
          query: _account(workspaceId, connectionId, adAccountId));

  /// Puts a label on a campaign, ad set or ad, keeping whatever labels it
  /// already carries. [level] is `campaign`, `ad_set` or `ad`.
  Future<void> applyLabel(
    String id, {
    required String workspaceId,
    required String connectionId,
    required String adAccountId,
    required String objectId,
    required String level,
  }) =>
      _http.discard('POST', '/ads/account/labels/${segment(id)}/apply', body: {
        'workspaceId': workspaceId,
        'connectionId': connectionId,
        'adAccountId': adAccountId,
        'objectId': objectId,
        'level': level,
      });

  /// The A/B studies on an ad account.
  Future<List<AdStudy>> studies({
    required String connectionId,
    required String adAccountId,
    String? workspaceId,
  }) async {
    final rows = await _http.objects('GET', '/ads/account/studies',
        query: _account(workspaceId, connectionId, adAccountId));
    return rows.map(AdStudy.fromJson).toList();
  }

  /// Splits traffic evenly across the cells for the length of the flight.
  Future<AdStudy> createStudy({
    required String workspaceId,
    required String connectionId,
    required String adAccountId,
    required String name,
    required DateTime startAt,
    required DateTime endAt,
    required List<AdStudyCell> cells,
    String? description,
  }) async {
    final body = pruned({
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'adAccountId': adAccountId,
      'name': name,
      'startAt': startAt.toUtc().toIso8601String(),
      'endAt': endAt.toUtc().toIso8601String(),
      'cells': cells.map((c) => c.toJson()).toList(),
      'description': description,
    });
    return AdStudy.fromJson(
        await _http.object('POST', '/ads/account/studies', body: body));
  }

  /// One A/B study, read live.
  Future<AdStudy> study(
    String id, {
    required String connectionId,
    required String adAccountId,
    String? workspaceId,
  }) async =>
      AdStudy.fromJson(await _http.object(
          'GET', '/ads/account/studies/${segment(id)}',
          query: _account(workspaceId, connectionId, adAccountId)));

  /// Deletes an A/B study.
  Future<void> deleteStudy(
    String id, {
    required String workspaceId,
    required String connectionId,
    required String adAccountId,
  }) =>
      _http.discard('DELETE', '/ads/account/studies/${segment(id)}',
          query: _account(workspaceId, connectionId, adAccountId));

  /// How many iOS 14 campaigns the account may run at once, per app.
  Future<List<IosCampaignLimits>> iosCampaignLimits({
    required String connectionId,
    required String adAccountId,
    String? workspaceId,
  }) async {
    final rows = await _http.objects('GET', '/ads/account/ios-limits',
        query: _account(workspaceId, connectionId, adAccountId));
    return rows.map(IosCampaignLimits.fromJson).toList();
  }

  /// The high-demand windows declared on an ad account.
  Future<List<HighDemandPeriod>> highDemandPeriods({
    required String connectionId,
    required String adAccountId,
    String? workspaceId,
  }) async {
    final rows = await _http.objects('GET', '/ads/account/high-demand-periods',
        query: _account(workspaceId, connectionId, adAccountId));
    return rows.map(HighDemandPeriod.fromJson).toList();
  }

  /// Tells the ad platform to expect heavier spend over a window, so pacing
  /// allows for it. [budgetValueType] is `ABSOLUTE` or `MULTIPLIER`.
  Future<HighDemandPeriod> createHighDemandPeriod({
    required String workspaceId,
    required String connectionId,
    required String adAccountId,
    required DateTime startAt,
    required DateTime endAt,
    required double budgetValue,
    required String budgetValueType,
  }) async {
    final body = {
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'adAccountId': adAccountId,
      'startAt': startAt.toUtc().toIso8601String(),
      'endAt': endAt.toUtc().toIso8601String(),
      'budgetValue': budgetValue,
      'budgetValueType': budgetValueType,
    };
    return HighDemandPeriod.fromJson(await _http
        .object('POST', '/ads/account/high-demand-periods', body: body));
  }

  /// Deletes a high-demand window.
  Future<void> deleteHighDemandPeriod(
    String id, {
    required String workspaceId,
    required String connectionId,
    required String adAccountId,
  }) =>
      _http.discard('DELETE', '/ads/account/high-demand-periods/${segment(id)}',
          query: _account(workspaceId, connectionId, adAccountId));

  /// The value rule sets on an ad account.
  Future<List<ValueRuleSet>> valueRuleSets({
    required String connectionId,
    required String adAccountId,
    String? workspaceId,
  }) async {
    final rows = await _http.objects('GET', '/ads/account/value-rule-sets',
        query: _account(workspaceId, connectionId, adAccountId));
    return rows.map(ValueRuleSet.fromJson).toList();
  }

  /// Weights conversions so some audiences count for more than others.
  Future<ValueRuleSet> createValueRuleSet({
    required String workspaceId,
    required String connectionId,
    required String adAccountId,
    required String name,
    required List<ValueRule> rules,
  }) async {
    final body = {
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'adAccountId': adAccountId,
      'name': name,
      'rules': rules.map((r) => r.toJson()).toList(),
    };
    return ValueRuleSet.fromJson(
        await _http.object('POST', '/ads/account/value-rule-sets', body: body));
  }

  /// Deletes a value rule set.
  Future<void> deleteValueRuleSet(
    String id, {
    required String workspaceId,
    required String connectionId,
    required String adAccountId,
  }) =>
      _http.discard('DELETE', '/ads/account/value-rule-sets/${segment(id)}',
          query: _account(workspaceId, connectionId, adAccountId));

  Future<ReachFrequencyPrediction> _reachFrequencyAction(
    String id,
    String action,
    String workspaceId,
    String connectionId,
    String adAccountId,
  ) async {
    final body = {
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'adAccountId': adAccountId,
    };
    return ReachFrequencyPrediction.fromJson(await _http.object(
        'POST', '/ads/reach-frequency/${segment(id)}/$action',
        body: body));
  }

  Map<String, dynamic> _labelBody(
    String workspaceId,
    String connectionId,
    String adAccountId,
    String name,
  ) =>
      {
        'workspaceId': workspaceId,
        'connectionId': connectionId,
        'adAccountId': adAccountId,
        'name': name,
      };

  Map<String, dynamic> _account(
    String? workspaceId,
    String connectionId,
    String adAccountId,
  ) =>
      {..._meta(workspaceId, connectionId), 'ad_account_id': adAccountId};

  Map<String, dynamic> _meta(String? workspaceId, String connectionId) =>
      {'workspace_id': workspaceId, 'connection_id': connectionId};
}
