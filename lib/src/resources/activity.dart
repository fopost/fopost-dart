import 'package:meta/meta.dart';

import '../http.dart';
import '../models/activity.dart';

/// What happened in a workspace, including the security audit log.
///
/// Reach it as `client.activity`.
class ActivityResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  ActivityResource(this._http);

  final FoPostHttp _http;

  /// Returns activity newest first. Omit [workspaceId] to read every workspace
  /// the key can reach.
  ///
  /// [kind] of [ActivityKind.security] is the audit log: members joining,
  /// leaving or changing role and access, and changes to two-step
  /// verification, passkeys, single sign-on and signed-in devices. Those rows
  /// are append-only and never expire.
  Future<ActivityPage> list({
    String? workspaceId,
    String? kind,
    String? from,
    String? to,
    String? cursor,
    int? limit,
  }) async {
    // The response carries meta beside data, so it is read whole.
    final body = await _http.raw('GET', '/activity', query: {
      'workspace_id': workspaceId,
      'kind': kind,
      'from': from,
      'to': to,
      'cursor': cursor,
      'limit': limit,
    });
    return ActivityPage.fromJson(
        body is Map<String, dynamic> ? body : const {});
  }
}
