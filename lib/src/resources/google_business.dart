import 'package:meta/meta.dart';

import '../http.dart';
import '../json.dart';
import '../models/account.dart';
import 'base.dart';

/// Manage a connected Google Business Profile location: the profile itself,
/// attributes, food menus, services, photos, place action links, verification
/// and performance.
///
/// Google grants Business Profile API access per project. Until that grant
/// lands on a deployment every call here throws a 503 `configuration_error`.
///
/// Responses relay Google's own shape, field for field, so they come back as
/// plain maps rather than models we would have to keep chasing.
///
/// Reach it as `client.googleBusiness`.
class GoogleBusinessResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  GoogleBusinessResource(this._http);

  final FoPostHttp _http;

  /// The daily metrics fetched when a caller names none.
  static const defaultDailyMetrics = [
    'BUSINESS_IMPRESSIONS_DESKTOP_MAPS',
    'BUSINESS_IMPRESSIONS_DESKTOP_SEARCH',
    'BUSINESS_IMPRESSIONS_MOBILE_MAPS',
    'BUSINESS_IMPRESSIONS_MOBILE_SEARCH',
    'CALL_CLICKS',
    'WEBSITE_CLICKS',
    'BUSINESS_DIRECTION_REQUESTS',
  ];

  String _path(String id, String suffix) =>
      '/accounts/${segment(id)}/gbp$suffix';

  /// Returns the connected location, in the Business Information shape.
  Future<Map<String, dynamic>> getLocation(String accountId) =>
      _http.object('GET', _path(accountId, '/location'));

  /// Patches the profile.
  ///
  /// Only the keys [fields] carries change, and a null value clears that
  /// field. Keys are the API's own snake_case names: `title`, `description`,
  /// `website_uri`, `primary_phone`, `additional_phones`, `store_code` and
  /// `regular_hours`.
  Future<Map<String, dynamic>> updateLocation(
    String accountId,
    Map<String, dynamic> fields,
  ) =>
      _http.object('PATCH', _path(accountId, '/location'), body: fields);

  /// Returns the attribute values set on the location, or, with [available],
  /// the attributes Google offers for its category and region.
  Future<Map<String, dynamic>> getAttributes(
    String accountId, {
    bool available = false,
    String? categoryName,
    String? regionCode,
    String? languageCode,
  }) =>
      _http.object('GET', _path(accountId, '/attributes'), query: {
        'available': available ? 'true' : null,
        'category_name': categoryName,
        'region_code': regionCode,
        'language_code': languageCode,
      });

  /// Changes only the named attributes; every other one is left alone.
  Future<Map<String, dynamic>> updateAttributes(
    String accountId,
    List<Map<String, dynamic>> attributes,
  ) =>
      _http.object('PATCH', _path(accountId, '/attributes'),
          body: {'attributes': attributes});

  /// Returns the location's food menus.
  Future<Map<String, dynamic>> getMenus(String accountId) =>
      _http.object('GET', _path(accountId, '/menus'));

  /// Replaces the whole menu set; Google has no per-section patch.
  Future<Map<String, dynamic>> replaceMenus(
    String accountId,
    List<Map<String, dynamic>> menus,
  ) =>
      _http.object('PUT', _path(accountId, '/menus'), body: {'menus': menus});

  /// Returns the location's service list.
  Future<Map<String, dynamic>> getServices(String accountId) =>
      _http.object('GET', _path(accountId, '/services'));

  /// Replaces the whole service list.
  Future<Map<String, dynamic>> replaceServices(
    String accountId,
    List<Map<String, dynamic>> serviceItems,
  ) =>
      _http.object('PUT', _path(accountId, '/services'),
          body: {'service_items': serviceItems});

  /// Returns the photos on the location.
  Future<Map<String, dynamic>> listMedia(
    String accountId, {
    int? pageSize,
    String? pageToken,
  }) =>
      _http.object('GET', _path(accountId, '/media'),
          query: {'page_size': pageSize, 'page_token': pageToken});

  /// Adds a photo from the media library.
  ///
  /// The asset has to be in a workspace the caller can reach, and JPEG or PNG.
  Future<Map<String, dynamic>> addMedia(
    String accountId, {
    required String mediaId,
    String category = 'ADDITIONAL',
    String? description,
  }) =>
      _http.object('POST', _path(accountId, '/media'),
          body: pruned({
            'media_id': mediaId,
            'category': category,
            'description': description,
          }));

  /// Removes a photo by the media key Google returned.
  Future<Map<String, dynamic>> deleteMedia(String accountId, String mediaKey) =>
      _http.object('DELETE', _path(accountId, '/media/${segment(mediaKey)}'));

  /// Returns the Book, Order and Reserve links on the listing.
  Future<Map<String, dynamic>> listPlaceActions(String accountId) =>
      _http.object('GET', _path(accountId, '/place-actions'));

  /// Adds an action link to the listing.
  Future<Map<String, dynamic>> createPlaceAction(
    String accountId, {
    required String uri,
    required String placeActionType,
    bool? isPreferred,
  }) =>
      _http.object('POST', _path(accountId, '/place-actions'),
          body: pruned({
            'uri': uri,
            'place_action_type': placeActionType,
            'is_preferred': isPreferred,
          }));

  /// Patches one action link; an omitted argument is left alone.
  Future<Map<String, dynamic>> updatePlaceAction(
    String accountId,
    String linkId, {
    String? uri,
    bool? isPreferred,
  }) =>
      _http.object(
          'PATCH', _path(accountId, '/place-actions/${segment(linkId)}'),
          body: pruned({'uri': uri, 'is_preferred': isPreferred}));

  /// Removes one action link.
  Future<Map<String, dynamic>> deletePlaceAction(
          String accountId, String linkId) =>
      _http.object(
          'DELETE', _path(accountId, '/place-actions/${segment(linkId)}'));

  /// Returns the ways Google will let this location be verified.
  Future<Map<String, dynamic>> getVerificationOptions(
    String accountId, {
    String? languageCode,
  }) =>
      _http.object('GET', _path(accountId, '/verification'),
          query: {'language_code': languageCode});

  /// Starts a verification.
  ///
  /// [method] is `ADDRESS`, `EMAIL`, `PHONE_CALL`, `SMS`, `AUTO` or
  /// `VETTED_PARTNER`; the response names the pending verification to complete
  /// with the PIN.
  Future<Map<String, dynamic>> startVerification(
    String accountId, {
    required String method,
    String? languageCode,
    String? phoneNumber,
    String? emailAddress,
    String? mailerContactName,
  }) =>
      _http.object('POST', _path(accountId, '/verification/start'),
          body: pruned({
            'method': method,
            'language_code': languageCode,
            'phone_number': phoneNumber,
            'email_address': emailAddress,
            'mailer_contact_name': mailerContactName,
          }));

  /// Completes a pending verification with the PIN Google sent.
  Future<Map<String, dynamic>> completeVerification(
    String accountId, {
    required String verificationName,
    required String pin,
  }) =>
      _http.object('POST', _path(accountId, '/verification/complete'),
          body: {'verification_name': verificationName, 'pin': pin});

  /// Returns daily impressions, calls, direction requests and clicks for the
  /// range. An omitted [dailyMetrics] leaves the API's own default set.
  Future<Map<String, dynamic>> getPerformance(
    String accountId, {
    required String startDate,
    required String endDate,
    List<String>? dailyMetrics,
  }) =>
      _http.object('GET', _path(accountId, '/performance'), query: {
        'start_date': startDate,
        'end_date': endDate,
        'daily_metrics': dailyMetrics,
      });

  /// Returns the search terms people used to find the listing, by month.
  Future<Map<String, dynamic>> getSearchKeywords(
    String accountId, {
    required String startDate,
    required String endDate,
    String? pageToken,
  }) =>
      _http.object('GET', _path(accountId, '/performance'), query: {
        'keywords': 'true',
        'start_date': startDate,
        'end_date': endDate,
        'page_token': pageToken,
      });

  /// Hands the location to another workspace the caller owns.
  ///
  /// The connection and every row keyed to it move in one transaction.
  Future<MovedAccount> assign(
    String accountId, {
    required String workspaceId,
  }) async =>
      MovedAccount.fromJson(await _http.object(
          'POST', _path(accountId, '/assign'),
          body: {'workspace_id': workspaceId}));
}
