import '../json.dart';

/// The statuses a connect session moves through.
abstract final class ConnectSessionStatus {
  /// Waiting for the user to connect.
  static const String pending = 'pending';

  /// An account was connected through it.
  static const String used = 'used';

  /// It ran out before being used.
  static const String expired = 'expired';
}

/// The name and logo the hosted connect page shows.
class ConnectSessionBranding {
  /// Creates branding.
  const ConnectSessionBranding({this.name, this.logoUrl});

  /// Reads branding.
  factory ConnectSessionBranding.fromJson(Map<String, dynamic> json) =>
      ConnectSessionBranding(
        name: asString(json['name']),
        logoUrl: asString(json['logo_url']),
      );

  /// The name shown on the page.
  final String? name;

  /// The logo shown on the page.
  final String? logoUrl;

  @override
  String toString() => 'ConnectSessionBranding(${name ?? ''})';
}

/// A hosted link that lets one of your users connect an account into your
/// workspace without seeing the dashboard.
class ConnectSession {
  /// Creates a session.
  const ConnectSession({
    required this.id,
    required this.status,
    required this.externalUserId,
    required this.platforms,
    this.redirectUrl,
    this.branding,
    this.accountId,
    this.url,
    this.expiresAt,
    this.usedAt,
    this.createdAt,
  });

  /// Reads a session.
  ///
  /// [url] is only present on the response that created it.
  factory ConnectSession.fromJson(Map<String, dynamic> json) => ConnectSession(
        id: asString(json['id']) ?? '',
        status: asString(json['status']) ?? ConnectSessionStatus.pending,
        externalUserId: asString(json['external_user_id']) ?? '',
        platforms: asStringList(json['platforms']),
        redirectUrl: asString(json['redirect_url']),
        branding: json['branding'] is Map
            ? ConnectSessionBranding.fromJson(asMap(json['branding']))
            : null,
        accountId: asString(json['account_id']),
        url: asString(json['url']),
        expiresAt: asDate(json['expires_at']),
        usedAt: asDate(json['used_at']),
        createdAt: asDate(json['created_at']),
      );

  /// The session's id.
  final String id;

  /// One of [ConnectSessionStatus].
  final String status;

  /// Your own id for the user the link was made for.
  final String externalUserId;

  /// The networks the user may pick from.
  final List<String> platforms;

  /// Where the user is sent after connecting.
  final String? redirectUrl;

  /// What the hosted page shows as the brand.
  final ConnectSessionBranding? branding;

  /// The connected account, once the session is used.
  final String? accountId;

  /// The hosted link to hand to your user, shown once at creation.
  final String? url;

  /// When the link stops working.
  final DateTime? expiresAt;

  /// When the account was connected.
  final DateTime? usedAt;

  /// When the session was created.
  final DateTime? createdAt;

  @override
  String toString() => 'ConnectSession($id, $status)';
}
