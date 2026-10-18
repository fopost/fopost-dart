import 'package:meta/meta.dart';

import '../http.dart';
import '../models/request_log.dart';

/// The API request log: what the key and the dashboard asked for, and how the
/// API answered.
///
/// Reach it as `client.logs`.
class LogsResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  LogsResource(this._http);

  final FoPostHttp _http;

  /// Returns requests newest first, over the last [days] (1-30, default 7).
  /// Omit [workspaceId] to read every workspace the key can reach.
  ///
  /// [status] is `success` or `failed`; [route] is an exact route pattern such
  /// as `/v1/posts/{id}`; [query] matches the path and message. Pass
  /// `RequestLogPage.nextCursor` as [before] for the next page.
  Future<RequestLogPage> list({
    String? workspaceId,
    int? days,
    String? status,
    String? method,
    int? statusCode,
    String? platform,
    String? route,
    String? query,
    int? limit,
    String? before,
  }) async {
    // The response carries meta and a summary beside data, so it is read whole.
    final body = await _http.raw('GET', '/logs', query: {
      'workspace_id': workspaceId,
      'days': days,
      'status': status,
      'method': method,
      'status_code': statusCode,
      'platform': platform,
      'route': route,
      'q': query,
      'limit': limit,
      'before': before,
    });
    return RequestLogPage.fromJson(
        body is Map<String, dynamic> ? body : const {});
  }
}
