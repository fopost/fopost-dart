import 'package:meta/meta.dart';

import '../http.dart';
import '../json.dart';
import '../models/workspace.dart';
import 'base.dart';

/// Workspaces, the tenant boundary every other resource is scoped to.
///
/// Reach it as `client.workspaces`.
class WorkspacesResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  WorkspacesResource(this._http);

  final FoPostHttp _http;

  /// Returns every workspace the key can reach.
  ///
  /// A key bound to a single workspace sees only that one.
  Future<List<Workspace>> list() async {
    final rows = await _http.objects('GET', '/workspaces');
    return rows.map(Workspace.fromJson).toList();
  }

  /// Returns one workspace with its connected accounts.
  Future<Workspace> get(String id) async =>
      Workspace.fromJson(await _http.object('GET', '/workspaces/${segment(id)}'));

  /// Adds a workspace.
  ///
  /// Plans cap how many an account may have, so this answers `402` once the
  /// limit is reached.
  Future<Workspace> create({
    required String name,
    required String slug,
    String? type,
    String? logo,
    String? website,
    String? timezone,
    String? country,
    String? description,
    String? language,
  }) async {
    final body = pruned({
      'name': name,
      'slug': slug,
      'type': type,
      'logo': logo,
      'website': website,
      'timezone': timezone,
      'country': country,
      'description': description,
      'language': language,
    });
    return Workspace.fromJson(await _http.object('POST', '/workspaces', body: body));
  }

  /// Edits a workspace. Only the fields you pass are sent.
  Future<Workspace> update(
    String id, {
    String? name,
    String? slug,
    String? type,
    String? logo,
    String? website,
    String? timezone,
    String? country,
    String? description,
    String? language,
    bool? requireApproval,
    bool? aiAltTextEnabled,
    String? brandColor,
  }) async {
    final body = pruned({
      'name': name,
      'slug': slug,
      'type': type,
      'logo': logo,
      'website': website,
      'timezone': timezone,
      'country': country,
      'description': description,
      'language': language,
      'requireApproval': requireApproval,
      'aiAltTextEnabled': aiAltTextEnabled,
      'brandColor': brandColor,
    });
    return Workspace.fromJson(
        await _http.object('PUT', '/workspaces/${segment(id)}', body: body));
  }

  /// Removes a workspace and everything scoped to it.
  Future<void> delete(String id) =>
      _http.discard('DELETE', '/workspaces/${segment(id)}');

  /// Returns a workspace's follower and post totals.
  Future<WorkspaceAnalytics> analytics(String id) async => WorkspaceAnalytics.fromJson(
      await _http.object('GET', '/workspaces/${segment(id)}/analytics'));
}
