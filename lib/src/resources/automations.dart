import 'package:meta/meta.dart';

import '../http.dart';
import '../json.dart';
import '../models/automation.dart';
import '../models/common.dart';
import 'base.dart';

/// Automations: a trigger plus the steps it runs.
///
/// Reach it as `client.automations`.
class AutomationsResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  AutomationsResource(this._http);

  final FoPostHttp _http;

  /// Returns the automations the key can reach.
  Future<List<Automation>> list() async {
    final rows = await _http.objects('GET', '/automations');
    return rows.map(Automation.fromJson).toList();
  }

  /// Returns one automation with its steps.
  Future<Automation> get(String id) async => Automation.fromJson(
      await _http.object('GET', '/automations/${segment(id)}'));

  /// Adds an automation.
  ///
  /// For an `api_webhook` trigger the response carries the signing secret
  /// once — store `Automation.secret` now.
  Future<Automation> create({
    required String workspaceId,
    required String name,
    required String triggerType,
    required List<AutomationStep> steps,
    Map<String, dynamic>? triggerConfig,
    bool? active,
  }) async {
    final body = pruned({
      'workspaceId': workspaceId,
      'name': name,
      'triggerType': triggerType,
      'steps': steps.map((s) => s.toJson()).toList(),
      'triggerConfig': triggerConfig,
      'active': active,
    });
    return Automation.fromJson(
        await _http.object('POST', '/automations', body: body));
  }

  /// Edits an automation. Passing [steps] replaces the whole list.
  Future<Automation> update(
    String id, {
    String? name,
    Map<String, dynamic>? triggerConfig,
    List<AutomationStep>? steps,
    bool? active,
  }) async {
    final body = pruned({
      'name': name,
      'triggerConfig': triggerConfig,
      'steps': steps?.map((s) => s.toJson()).toList(),
      'active': active,
    });
    return Automation.fromJson(
        await _http.object('PUT', '/automations/${segment(id)}', body: body));
  }

  /// Removes an automation.
  Future<void> delete(String id) =>
      _http.discard('DELETE', '/automations/${segment(id)}');

  /// Switches an automation on or off.
  Future<AutomationToggle> toggle(String id) async => AutomationToggle.fromJson(
      await _http.object('POST', '/automations/${segment(id)}/toggle'));

  /// Lists an automation's executions.
  Future<Page<AutomationRun>> runs(String id, {int? page, int? perPage}) async {
    final body = await _http.raw(
      'GET',
      '/automations/${segment(id)}/runs',
      query: {'page': page, 'per_page': perPage},
    );
    return Page.fromJson(
        body is Map<String, dynamic> ? body : {}, AutomationRun.fromJson);
  }

  /// Returns one execution, with a log per step.
  Future<AutomationRun> run(String id, int runId) async =>
      AutomationRun.fromJson(
          await _http.object('GET', '/automations/${segment(id)}/runs/$runId'));

  /// Fires an `api_webhook` automation with a payload its steps can read.
  Future<AutomationTriggerResult> trigger(
    String id, {
    Map<String, dynamic>? payload,
  }) async =>
      AutomationTriggerResult.fromJson(await _http.object(
        'POST',
        '/automations/${segment(id)}/trigger',
        body: payload ?? <String, dynamic>{},
      ));

  /// Returns automation counts and recent runs.
  Future<AutomationStats> stats() async =>
      AutomationStats.fromJson(await _http.object('GET', '/automations/stats'));
}
