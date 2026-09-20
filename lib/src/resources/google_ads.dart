import 'package:meta/meta.dart';

import '../http.dart';
import '../json.dart';
import '../models/google_ad.dart';

/// The connection and the Google Ads account a call runs against.
///
/// [customerId] is digits only and has to name an account the connection's
/// grant reaches: any other answers 404. [workspaceId] may be left out on a
/// read, and is required on a write.
class GoogleAdsScope {
  /// Creates a scope.
  const GoogleAdsScope({
    required this.connectionId,
    required this.customerId,
    this.workspaceId,
  });

  /// The ad connection.
  final String connectionId;

  /// The Google Ads customer id, digits only.
  final String customerId;

  /// The workspace the connection lives in.
  final String? workspaceId;

  /// The scope as a request body carries it.
  Map<String, dynamic> get body => pruned({
        'workspaceId': workspaceId,
        'connectionId': connectionId,
        'customerId': customerId,
      });

  /// The scope as a query string carries it.
  Map<String, dynamic> get query => {
        'workspace_id': workspaceId,
        'connection_id': connectionId,
        'customer_id': customerId,
      };
}

/// Google Ads: keywords, assets, Performance Max asset groups, Local Services
/// leads, conversions and raw GAQL.
///
/// Campaigns, ad groups, ads, audiences and insights are on `client.ads` and
/// dispatch by connection; a connection on another network answers 400 here.
/// Every call needs the `ads` scope, and anything that changes what a live
/// account serves or bids also needs `publish`. Amounts are in the account's
/// currency, in minor units. Reach it as `client.googleAds`.
class GoogleAdsResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  GoogleAdsResource(this._http);

  final FoPostHttp _http;

  // ── Keywords ──

  /// Keywords on the account, or on one ad group.
  Future<List<GoogleKeyword>> keywords(
    GoogleAdsScope scope, {
    String? adGroupId,
  }) async {
    final rows = await _http.objects('GET', '/ads/google/keywords',
        query: {...scope.query, 'ad_group_id': adGroupId});
    return rows.map(GoogleKeyword.fromJson).toList();
  }

  /// Adds a keyword. Needs the `publish` scope as well as `ads`.
  Future<String> createKeyword(
    GoogleAdsScope scope, {
    required String adGroupId,
    required String text,
    required String matchType,
    int? cpcBidMinor,
  }) =>
      _id('POST', '/ads/google/keywords', {
        ...scope.body,
        ...pruned({
          'adGroupId': adGroupId,
          'text': text,
          'matchType': matchType,
          'cpcBidMinor': cpcBidMinor,
        }),
      });

  /// Pauses, resumes or rebids a keyword. Needs `publish` as well as `ads`.
  Future<String> updateKeyword(
    String keywordId,
    GoogleAdsScope scope, {
    String? status,
    int? cpcBidMinor,
  }) =>
      _id('PATCH', '/ads/google/keywords/$keywordId', {
        ...scope.body,
        ...pruned({'status': status, 'cpcBidMinor': cpcBidMinor}),
      });

  /// Removes a keyword. Needs `publish` as well as `ads`.
  Future<void> deleteKeyword(String keywordId, GoogleAdsScope scope) => _http
      .discard('DELETE', '/ads/google/keywords/$keywordId', body: scope.body);

  /// Ideas from seed keywords, a landing page, or both.
  Future<List<GoogleKeywordIdea>> keywordIdeas(
    GoogleAdsScope scope, {
    List<String>? seeds,
    String? url,
    String? languageId,
    List<String>? geoTargetIds,
  }) async {
    final rows =
        await _http.objects('POST', '/ads/google/keyword-ideas', body: {
      ...scope.body,
      ...pruned({
        'seeds': seeds,
        'url': url,
        'languageId': languageId,
        'geoTargetIds': geoTargetIds,
      }),
    });
    return rows.map(GoogleKeywordIdea.fromJson).toList();
  }

  /// Historical metrics for keywords you already have.
  Future<List<GoogleKeywordIdea>> keywordMetrics(
    GoogleAdsScope scope, {
    required List<String> keywords,
  }) async {
    final rows = await _http.objects('POST', '/ads/google/keyword-metrics',
        body: {...scope.body, 'keywords': keywords});
    return rows.map(GoogleKeywordIdea.fromJson).toList();
  }

  /// What people actually searched, with the metrics each term earned.
  Future<List<GoogleSearchTerm>> searchTerms(
    GoogleAdsScope scope, {
    required String since,
    required String until,
  }) async {
    final rows = await _http.objects('GET', '/ads/google/search-terms',
        query: {...scope.query, 'since': since, 'until': until});
    return rows.map(GoogleSearchTerm.fromJson).toList();
  }

  // ── Bid strategies and ad schedule ──

  /// The account's portfolio bid strategies.
  Future<List<GoogleBidStrategy>> bidStrategies(GoogleAdsScope scope) async {
    final rows = await _http.objects('GET', '/ads/google/bid-strategies',
        query: scope.query);
    return rows.map(GoogleBidStrategy.fromJson).toList();
  }

  /// Adds a bid strategy. Needs `publish` as well as `ads`.
  Future<String> createBidStrategy(
    GoogleAdsScope scope, {
    required String name,
    required String type,
    int? targetMinor,
  }) =>
      _id('POST', '/ads/google/bid-strategies', {
        ...scope.body,
        ...pruned({'name': name, 'type': type, 'targetMinor': targetMinor}),
      });

  /// A campaign's ad schedule.
  Future<List<GoogleAdScheduleSlot>> adSchedule(
    GoogleAdsScope scope, {
    required String campaignId,
  }) async {
    final rows = await _http.objects('GET', '/ads/google/ad-schedule',
        query: {...scope.query, 'campaign_id': campaignId});
    return rows.map(GoogleAdScheduleSlot.fromJson).toList();
  }

  /// Replaces every slot on the campaign: Google has no partial edit for a
  /// schedule. Needs `publish` as well as `ads`.
  Future<int> setAdSchedule(
    GoogleAdsScope scope, {
    required String campaignId,
    required List<Map<String, dynamic>> slots,
  }) async {
    final result = await _http.object('PUT', '/ads/google/ad-schedule',
        body: {...scope.body, 'campaignId': campaignId, 'slots': slots});
    return asInt(result['slots']) ?? 0;
  }

  // ── Negative keyword lists ──

  /// The account's negative keyword lists.
  Future<List<GoogleSharedSet>> negativeKeywordLists(
      GoogleAdsScope scope) async {
    final rows = await _http.objects('GET', '/ads/google/negative-keywords',
        query: scope.query);
    return rows.map(GoogleSharedSet.fromJson).toList();
  }

  /// Creates a negative keyword list. Needs `publish` as well as `ads`.
  Future<String> createNegativeKeywordList(
    GoogleAdsScope scope, {
    required String name,
  }) =>
      _id('POST', '/ads/google/negative-keywords',
          {...scope.body, 'name': name});

  /// Adds keywords to a list; answers how many landed. Needs `publish`.
  Future<int> addNegativeKeywords(
    GoogleAdsScope scope, {
    required String sharedSetId,
    required List<Map<String, dynamic>> keywords,
  }) async {
    final result = await _http.object(
        'POST', '/ads/google/negative-keywords/keywords', body: {
      ...scope.body,
      'sharedSetId': sharedSetId,
      'keywords': keywords
    });
    return asInt(result['added']) ?? 0;
  }

  /// Puts a list on a campaign. Needs `publish` as well as `ads`.
  Future<void> attachNegativeKeywordList(
    GoogleAdsScope scope, {
    required String sharedSetId,
    required String campaignId,
  }) =>
      _http.discard('POST', '/ads/google/negative-keywords/attach', body: {
        ...scope.body,
        'sharedSetId': sharedSetId,
        'campaignId': campaignId,
      });

  // ── Assets ──

  /// Sitelinks, callouts and snippets, with the links that place each one.
  Future<GoogleAssets> assets(GoogleAdsScope scope) async =>
      GoogleAssets.fromJson(
          await _http.object('GET', '/ads/google/assets', query: scope.query));

  /// Adds an asset to the library. Needs `publish` as well as `ads`.
  ///
  /// [spec] is a sitelink, callout or snippet.
  Future<String> createAsset(
    GoogleAdsScope scope, {
    required Map<String, dynamic> spec,
  }) =>
      _id('POST', '/ads/google/assets', {...scope.body, 'spec': spec});

  /// Puts an asset under the ads it belongs to. Needs `publish`.
  Future<void> attachAsset(
    GoogleAdsScope scope, {
    required String assetId,
    required String fieldType,
    String? campaignId,
  }) =>
      _http.discard('POST', '/ads/google/assets/attach', body: {
        ...scope.body,
        ...pruned({
          'assetId': assetId,
          'fieldType': fieldType,
          'campaignId': campaignId,
        }),
      });

  /// Removes the links that put an asset under an ad; on Google the asset
  /// itself is permanent. Needs `publish` as well as `ads`.
  Future<void> deleteAsset(String assetId, GoogleAdsScope scope) =>
      _http.discard('DELETE', '/ads/google/assets/$assetId', body: scope.body);

  // ── Performance Max asset groups ──

  /// Performance Max asset groups on the account, or on one campaign.
  Future<List<GoogleAssetGroup>> assetGroups(
    GoogleAdsScope scope, {
    String? campaignId,
  }) async {
    final rows = await _http.objects('GET', '/ads/google/asset-groups',
        query: {...scope.query, 'campaign_id': campaignId});
    return rows.map(GoogleAssetGroup.fromJson).toList();
  }

  /// Creates an asset group, paused unless [status] says otherwise. Needs
  /// `publish` as well as `ads`.
  Future<String> createAssetGroup(
    GoogleAdsScope scope, {
    required String campaignId,
    required String name,
    required List<String> finalUrls,
    String? status,
  }) =>
      _id('POST', '/ads/google/asset-groups', {
        ...scope.body,
        ...pruned({
          'campaignId': campaignId,
          'name': name,
          'finalUrls': finalUrls,
          'status': status,
        }),
      });

  /// Renames, pauses or resumes an asset group. Needs `publish`.
  Future<String> updateAssetGroup(
    String assetGroupId,
    GoogleAdsScope scope, {
    String? name,
    String? status,
  }) =>
      _id('PATCH', '/ads/google/asset-groups/$assetGroupId', {
        ...scope.body,
        ...pruned({'name': name, 'status': status}),
      });

  /// Removes an asset group. Needs `publish` as well as `ads`.
  Future<void> deleteAssetGroup(String assetGroupId, GoogleAdsScope scope) =>
      _http.discard('DELETE', '/ads/google/asset-groups/$assetGroupId',
          body: scope.body);

  // ── Local Services leads ──

  /// Leads from Local Services Ads, read live and never stored.
  Future<List<GoogleLocalServicesLead>> localServicesLeads(
    GoogleAdsScope scope, {
    required String since,
    required String until,
  }) async {
    final rows = await _http.objects('GET', '/ads/google/local-services',
        query: {...scope.query, 'since': since, 'until': until});
    return rows.map(GoogleLocalServicesLead.fromJson).toList();
  }

  // ── Conversions ──

  /// The account's conversion actions.
  Future<List<GoogleConversionAction>> conversionActions(
      GoogleAdsScope scope) async {
    final rows = await _http.objects('GET', '/ads/google/conversions',
        query: scope.query);
    return rows.map(GoogleConversionAction.fromJson).toList();
  }

  /// Adds a conversion action. Needs `publish` as well as `ads`.
  Future<String> createConversionAction(
    GoogleAdsScope scope, {
    required String name,
    required String category,
    int? valueMinor,
    String? countingType,
  }) =>
      _id('POST', '/ads/google/conversions', {
        ...scope.body,
        ...pruned({
          'name': name,
          'category': category,
          'valueMinor': valueMinor,
          'countingType': countingType,
        }),
      });

  /// Sends offline conversions; answers how many landed. Needs `publish`.
  Future<int> uploadConversions(
    GoogleAdsScope scope, {
    required List<Map<String, dynamic>> conversions,
  }) =>
      _uploaded('/ads/google/conversions/upload',
          {...scope.body, 'conversions': conversions});

  /// Sends conversion adjustments; answers how many landed. Needs `publish`.
  Future<int> uploadConversionAdjustments(
    GoogleAdsScope scope, {
    required List<Map<String, dynamic>> adjustments,
  }) =>
      _uploaded('/ads/google/conversions/adjustments',
          {...scope.body, 'adjustments': adjustments});

  // ── GAQL ──

  /// Runs a read-only GAQL SELECT; rows come back as Google sends them.
  Future<List<Map<String, dynamic>>> query(
    GoogleAdsScope scope, {
    required String query,
  }) async {
    final result = await _http.object('POST', '/ads/insights/query',
        body: {...scope.body, 'query': query});
    final rows = result['rows'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<String> _id(
      String method, String path, Map<String, dynamic> body) async {
    final result = await _http.object(method, path, body: body);
    return asString(result['id']) ?? '';
  }

  Future<int> _uploaded(String path, Map<String, dynamic> body) async {
    final result = await _http.object('POST', path, body: body);
    return asInt(result['uploaded']) ?? 0;
  }
}
