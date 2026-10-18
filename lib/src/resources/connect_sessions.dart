import 'package:meta/meta.dart';

import '../http.dart';
import '../json.dart';
import '../models/connect_session.dart';
import 'base.dart';

/// Hosted connect links: a one-time page where one of your users connects an
/// account into your workspace.
///
/// Reach it as `client.connectSessions`.
class ConnectSessionsResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  ConnectSessionsResource(this._http);

  final FoPostHttp _http;

  /// Mints a link for [externalUserId], your own id for that user, offering
  /// [platforms]. Omit [workspaceId] for a key bound to one workspace.
  ///
  /// The response carries the hosted link once — hand `ConnectSession.url` to
  /// the user now.
  Future<ConnectSession> create({
    required String externalUserId,
    required List<String> platforms,
    String? workspaceId,
    String? redirectUrl,
    String? brandingName,
    String? brandingLogoUrl,
  }) async {
    final branding = pruned({'name': brandingName, 'logoUrl': brandingLogoUrl});
    final body = pruned({
      'workspaceId': workspaceId,
      'externalUserId': externalUserId,
      'platforms': platforms,
      'redirectUrl': redirectUrl,
      'branding': branding.isEmpty ? null : branding,
    });
    return ConnectSession.fromJson(
        await _http.object('POST', '/connect-sessions', body: body));
  }

  /// Returns where a session stands, and the account it connected once used.
  Future<ConnectSession> get(String id) async => ConnectSession.fromJson(
      await _http.object('GET', '/connect-sessions/${segment(id)}'));
}
