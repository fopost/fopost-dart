import 'package:meta/meta.dart';

import '../http.dart';
import '../models/label.dart';
import 'base.dart';

/// Labels, the campaign tags posts are grouped by.
///
/// Reach it as `client.labels`.
class LabelsResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  LabelsResource(this._http);

  final FoPostHttp _http;

  /// Returns the labels the key can reach, optionally narrowed to one
  /// workspace.
  Future<List<Label>> list({String? workspaceId}) async {
    final rows =
        await _http.objects('GET', '/labels', query: {'workspace_id': workspaceId});
    return rows.map(Label.fromJson).toList();
  }

  /// Returns one label.
  Future<Label> get(String id) async =>
      Label.fromJson(await _http.object('GET', '/labels/${segment(id)}'));

  /// Adds a label to a workspace. [color] is a hex value, e.g. `#2563eb`.
  Future<Label> create({
    required String workspaceId,
    required String name,
    required String color,
  }) async {
    final body = {'workspace_id': workspaceId, 'name': name, 'color': color};
    return Label.fromJson(await _http.object('POST', '/labels', body: body));
  }

  /// Renames or recolors a label. Both fields are required by the API.
  Future<Label> update(String id, {required String name, required String color}) async {
    final body = {'name': name, 'color': color};
    return Label.fromJson(
        await _http.object('PUT', '/labels/${segment(id)}', body: body));
  }

  /// Removes a label and unlinks it from every post carrying it.
  Future<void> delete(String id) => _http.discard('DELETE', '/labels/${segment(id)}');
}
