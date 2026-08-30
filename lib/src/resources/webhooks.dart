import 'package:meta/meta.dart';

import '../http.dart';
import '../json.dart';
import '../models/common.dart';
import '../models/webhook.dart';
import 'base.dart';

/// Outbound webhooks, the push counterpart to polling a post's deliveries.
///
/// Reach it as `client.webhooks`.
class WebhooksResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  WebhooksResource(this._http);

  final FoPostHttp _http;

  /// Returns the webhooks the key can reach.
  Future<List<Webhook>> list() async {
    final rows = await _http.objects('GET', '/webhooks');
    return rows.map(Webhook.fromJson).toList();
  }

  /// Subscribes an endpoint to a workspace's events.
  ///
  /// The response carries the signing secret once — store `Webhook.secret` now.
  Future<Webhook> create({
    required String workspaceId,
    required String url,
    required List<String> events,
  }) async {
    final body = {'workspaceId': workspaceId, 'url': url, 'events': events};
    return Webhook.fromJson(
        await _http.object('POST', '/webhooks', body: body));
  }

  /// Changes a subscription's endpoint, events, or active flag.
  Future<Webhook> update(
    String id, {
    String? url,
    List<String>? events,
    bool? active,
  }) async {
    final body = pruned({'url': url, 'events': events, 'active': active});
    return Webhook.fromJson(
        await _http.object('PUT', '/webhooks/${segment(id)}', body: body));
  }

  /// Removes a subscription.
  Future<void> delete(String id) =>
      _http.discard('DELETE', '/webhooks/${segment(id)}');

  /// Sends a sample event to the subscribed endpoint.
  Future<ApiMessage> test(String id) async {
    final body = await _http.raw('POST', '/webhooks/${segment(id)}/test');
    return ApiMessage.fromJson(body is Map<String, dynamic> ? body : {});
  }
}
