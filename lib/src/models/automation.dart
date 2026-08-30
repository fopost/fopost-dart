import '../json.dart';

/// The events that can start an automation.
abstract final class AutomationTrigger {
  /// A post published from one account is mirrored to others.
  static const String crossPost = 'cross_post';

  /// A new item in an RSS feed.
  static const String rssFeed = 'rss_feed';

  /// An inbound call to the automation's own webhook.
  static const String apiWebhook = 'api_webhook';

  /// A recurring schedule.
  static const String schedule = 'schedule';
}

/// The actions an automation step can take.
abstract final class AutomationAction {
  /// Compose and publish a post.
  static const String publish = 'publish';

  /// Wait before the next step.
  static const String delay = 'delay';

  /// Rewrite the payload the next step reads.
  static const String transform = 'transform';
}

/// One action in an automation, in position order.
class AutomationStep {
  /// Creates a step.
  const AutomationStep(
      {required this.actionType,
      this.actionConfig = const {},
      this.id,
      this.position});

  /// Reads a step.
  factory AutomationStep.fromJson(Map<String, dynamic> json) => AutomationStep(
        actionType: asString(json['actionType']) ?? '',
        actionConfig: asMap(json['actionConfig']),
        id: asInt(json['id']),
        position: asInt(json['position']),
      );

  /// One of [AutomationAction].
  final String actionType;

  /// The action's own options.
  final Map<String, dynamic> actionConfig;

  /// The step's id, on a stored automation.
  final int? id;

  /// Where the step sits in the sequence.
  final int? position;

  /// Renders the step for a request body.
  Map<String, dynamic> toJson() => pruned({
        'actionType': actionType,
        if (actionConfig.isNotEmpty) 'actionConfig': actionConfig,
        'position': position,
      });

  @override
  String toString() => 'AutomationStep($actionType)';
}

/// One trigger and the steps behind it.
class Automation {
  /// Creates an automation.
  const Automation({
    required this.id,
    required this.name,
    required this.triggerType,
    this.workspaceId,
    this.triggerConfig = const {},
    this.active = true,
    this.lastTriggeredAt,
    this.runCount,
    this.steps = const [],
    this.secret,
    this.createdAt,
    this.updatedAt,
  });

  /// Reads an automation.
  ///
  /// [secret] is only present on the response that created an `api_webhook`
  /// automation.
  factory Automation.fromJson(Map<String, dynamic> json) => Automation(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        triggerType: asString(json['triggerType']) ?? '',
        workspaceId: asString(json['workspaceId']),
        triggerConfig: asMap(json['triggerConfig']),
        active: asBool(json['active']) ?? true,
        lastTriggeredAt: asDate(json['lastTriggeredAt']),
        runCount: asInt(json['runCount']),
        steps: asModelList(json['steps'], AutomationStep.fromJson),
        secret: asString(json['secret']),
        createdAt: asDate(json['createdAt']),
        updatedAt: asDate(json['updatedAt']),
      );

  /// The automation's id.
  final String id;

  /// The automation's name.
  final String name;

  /// One of [AutomationTrigger].
  final String triggerType;

  /// The workspace it runs in.
  final String? workspaceId;

  /// The trigger's own options.
  final Map<String, dynamic> triggerConfig;

  /// Whether it is switched on.
  final bool active;

  /// When it last fired.
  final DateTime? lastTriggeredAt;

  /// How many times it has run.
  final int? runCount;

  /// The steps, in order.
  final List<AutomationStep> steps;

  /// The signing secret, shown once at creation — store it now.
  final String? secret;

  /// When the automation was created.
  final DateTime? createdAt;

  /// When it last changed.
  final DateTime? updatedAt;

  @override
  String toString() => 'Automation($name, $triggerType)';
}

/// One step's log entry within a run.
class AutomationRunLog {
  /// Creates a log entry.
  const AutomationRunLog({
    required this.id,
    required this.stepPosition,
    required this.status,
    this.inputSnapshot = const {},
    this.outputSnapshot = const {},
    this.startedAt,
    this.completedAt,
    this.durationMs,
    this.errorMessage,
  });

  /// Reads a log entry.
  factory AutomationRunLog.fromJson(Map<String, dynamic> json) =>
      AutomationRunLog(
        id: asInt(json['id']) ?? 0,
        stepPosition: asInt(json['stepPosition']) ?? 0,
        status: asString(json['status']) ?? '',
        inputSnapshot: asMap(json['inputSnapshot']),
        outputSnapshot: asMap(json['outputSnapshot']),
        startedAt: asDate(json['startedAt']),
        completedAt: asDate(json['completedAt']),
        durationMs: asInt(json['durationMs']),
        errorMessage: asString(json['errorMessage']),
      );

  /// The log entry's id.
  final int id;

  /// Which step it belongs to.
  final int stepPosition;

  /// How the step ended.
  final String status;

  /// What the step was given.
  final Map<String, dynamic> inputSnapshot;

  /// What the step produced.
  final Map<String, dynamic> outputSnapshot;

  /// When the step started.
  final DateTime? startedAt;

  /// When the step finished.
  final DateTime? completedAt;

  /// How long the step took.
  final int? durationMs;

  /// Why the step failed, if it did.
  final String? errorMessage;

  @override
  String toString() => 'AutomationRunLog(step $stepPosition, $status)';
}

/// One execution of an automation.
class AutomationRun {
  /// Creates a run.
  const AutomationRun({
    required this.id,
    required this.status,
    this.automationId,
    this.currentStep,
    this.triggerEvent = const {},
    this.context = const {},
    this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.logs = const [],
  });

  /// Reads a run.
  factory AutomationRun.fromJson(Map<String, dynamic> json) => AutomationRun(
        id: asInt(json['id']) ?? 0,
        status: asString(json['status']) ?? '',
        automationId: asString(json['automationId']),
        currentStep: asInt(json['currentStep']),
        triggerEvent: asMap(json['triggerEvent']),
        context: asMap(json['context']),
        startedAt: asDate(json['startedAt']),
        completedAt: asDate(json['completedAt']),
        errorMessage: asString(json['errorMessage']),
        logs: asModelList(json['logs'], AutomationRunLog.fromJson),
      );

  /// The run's id.
  final int id;

  /// How the run ended, or where it is.
  final String status;

  /// The automation that ran.
  final String? automationId;

  /// Which step is executing.
  final int? currentStep;

  /// What started the run.
  final Map<String, dynamic> triggerEvent;

  /// The state carried between steps.
  final Map<String, dynamic> context;

  /// When the run started.
  final DateTime? startedAt;

  /// When the run finished.
  final DateTime? completedAt;

  /// Why the run failed, if it did.
  final String? errorMessage;

  /// One entry per step, on a single run's response.
  final List<AutomationRunLog> logs;

  @override
  String toString() => 'AutomationRun($id, $status)';
}

/// An automation's active flag after toggling.
class AutomationToggle {
  /// Creates a toggle result.
  const AutomationToggle({required this.id, required this.active});

  /// Reads a toggle result.
  factory AutomationToggle.fromJson(Map<String, dynamic> json) =>
      AutomationToggle(
        id: asString(json['id']) ?? '',
        active: asBool(json['active']) ?? false,
      );

  /// The automation's id.
  final String id;

  /// Whether it is now switched on.
  final bool active;

  @override
  String toString() => 'AutomationToggle($id, $active)';
}

/// The run a webhook trigger started.
class AutomationTriggerResult {
  /// Creates a trigger result.
  const AutomationTriggerResult({required this.runId, required this.triggered});

  /// Reads a trigger result.
  factory AutomationTriggerResult.fromJson(Map<String, dynamic> json) =>
      AutomationTriggerResult(
        runId: asInt(json['runId']) ?? 0,
        triggered: asBool(json['triggered']) ?? false,
      );

  /// The run that was started.
  final int runId;

  /// Whether the automation actually fired.
  final bool triggered;

  @override
  String toString() => 'AutomationTriggerResult($runId, $triggered)';
}

/// A run as it appears in the dashboard roll-up.
class AutomationRunSummary {
  /// Creates a run summary.
  const AutomationRunSummary({
    required this.id,
    required this.status,
    this.automationId,
    this.startedAt,
    this.completedAt,
  });

  /// Reads a run summary.
  factory AutomationRunSummary.fromJson(Map<String, dynamic> json) =>
      AutomationRunSummary(
        id: asInt(json['id']) ?? 0,
        status: asString(json['status']) ?? '',
        automationId: asString(json['automationId']),
        startedAt: asDate(json['startedAt']),
        completedAt: asDate(json['completedAt']),
      );

  /// The run's id.
  final int id;

  /// How the run ended.
  final String status;

  /// The automation that ran.
  final String? automationId;

  /// When the run started.
  final DateTime? startedAt;

  /// When the run finished.
  final DateTime? completedAt;

  @override
  String toString() => 'AutomationRunSummary($id, $status)';
}

/// Automation counts and recent runs.
class AutomationStats {
  /// Creates a stats roll-up.
  const AutomationStats({
    this.totalAutomations = 0,
    this.activeAutomations = 0,
    this.totalRuns24h = 0,
    this.runsByStatus = const {},
    this.recentRuns = const [],
  });

  /// Reads a stats roll-up.
  factory AutomationStats.fromJson(Map<String, dynamic> json) {
    final byStatus = <String, int>{};
    asMap(json['runsByStatus']).forEach((key, value) {
      final count = asInt(value);
      if (count != null) byStatus[key] = count;
    });
    return AutomationStats(
      totalAutomations: asInt(json['totalAutomations']) ?? 0,
      activeAutomations: asInt(json['activeAutomations']) ?? 0,
      totalRuns24h: asInt(json['totalRuns24h']) ?? 0,
      runsByStatus: byStatus,
      recentRuns:
          asModelList(json['recentRuns'], AutomationRunSummary.fromJson),
    );
  }

  /// How many automations exist.
  final int totalAutomations;

  /// How many are switched on.
  final int activeAutomations;

  /// Runs in the last 24 hours.
  final int totalRuns24h;

  /// Those runs, counted by status.
  final Map<String, int> runsByStatus;

  /// The most recent runs.
  final List<AutomationRunSummary> recentRuns;

  @override
  String toString() =>
      'AutomationStats($activeAutomations/$totalAutomations active)';
}
