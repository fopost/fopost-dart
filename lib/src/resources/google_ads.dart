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

/// Google Ads: bid strategies, ad schedules, Local Services leads,
/// conversions and raw GAQL.
///
/// Audiences and insights are on `client.ads` and dispatch by connection; a
/// connection on another network answers 400 here.
/// Every call needs the `ads` scope, and anything that changes what a live
/// account serves or bids also needs `publish`. Amounts are in the account's
/// currency, in minor units. Reach it as `client.googleAds`.
class GoogleAdsResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  GoogleAdsResource(this._http);

  final FoPostHttp _http;

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

  Future<int> _uploaded(String path, Map<String, dynamic> body) =>
      _counted(path, 'uploaded', body);

  Future<int> _counted(
      String path, String key, Map<String, dynamic> body) async {
    final result = await _http.object('POST', path, body: body);
    return asInt(result[key]) ?? 0;
  }
}
