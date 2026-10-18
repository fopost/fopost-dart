import '../json.dart';

/// One API request the key or a signed-in user made.
class RequestLog {
  /// Creates a log row.
  const RequestLog({
    required this.id,
    required this.method,
    required this.route,
    required this.path,
    required this.statusCode,
    this.workspaceId,
    this.time,
    this.authMethod,
    this.durationMs,
    this.platform,
    this.message,
  });

  /// Reads a log row.
  factory RequestLog.fromJson(Map<String, dynamic> json) => RequestLog(
        id: asInt(json['id']) ?? 0,
        workspaceId: asString(json['workspace_id']),
        time: asDate(json['time']),
        authMethod: asString(json['auth_method']),
        method: asString(json['method']) ?? '',
        route: asString(json['route']) ?? '',
        path: asString(json['path']) ?? '',
        statusCode: asInt(json['status_code']) ?? 0,
        durationMs: asInt(json['duration_ms']),
        platform: asString(json['platform']),
        message: asString(json['message']),
      );

  /// The row's id, which [RequestLogPage.nextCursor] points at.
  final int id;

  /// The workspace the request ran against; null for account-level requests.
  final String? workspaceId;

  /// When the request arrived.
  final DateTime? time;

  /// `jwt` or `api_key`.
  final String? authMethod;

  /// The HTTP method.
  final String method;

  /// The route pattern, e.g. `/v1/posts/{id}`.
  final String route;

  /// The path as requested.
  final String path;

  /// The status the API answered with.
  final int statusCode;

  /// How long the request took.
  final int? durationMs;

  /// The network the request touched, where there was one.
  final String? platform;

  /// The error text, on a failed request.
  final String? message;

  @override
  String toString() => 'RequestLog($method $path $statusCode)';
}

/// Request and error counts for one interval of the summary.
class RequestLogBucket {
  /// Creates a bucket.
  const RequestLogBucket({this.at, required this.total, required this.errors});

  /// Reads a bucket.
  factory RequestLogBucket.fromJson(Map<String, dynamic> json) =>
      RequestLogBucket(
        at: asDate(json['at']),
        total: asInt(json['total']) ?? 0,
        errors: asInt(json['errors']) ?? 0,
      );

  /// When the interval starts.
  final DateTime? at;

  /// Requests in the interval.
  final int total;

  /// Failed requests in the interval.
  final int errors;

  @override
  String toString() => 'RequestLogBucket($total, $errors errors)';
}

/// Totals over the whole window the page was read from.
class RequestLogSummary {
  /// Creates a summary.
  const RequestLogSummary({
    this.since,
    required this.total,
    required this.errors,
    required this.buckets,
  });

  /// Reads a summary.
  factory RequestLogSummary.fromJson(Map<String, dynamic> json) =>
      RequestLogSummary(
        since: asDate(json['since']),
        total: asInt(json['total']) ?? 0,
        errors: asInt(json['errors']) ?? 0,
        buckets: asModelList(json['buckets'], RequestLogBucket.fromJson),
      );

  /// Where the window starts.
  final DateTime? since;

  /// Requests in the window.
  final int total;

  /// Failed requests in the window.
  final int errors;

  /// The window split into intervals.
  final List<RequestLogBucket> buckets;

  @override
  String toString() => 'RequestLogSummary($total, $errors errors)';
}

/// One page of request logs, newest first.
class RequestLogPage {
  /// Creates a page.
  const RequestLogPage({
    required this.logs,
    required this.summary,
    this.nextCursor,
    this.hasMore = false,
  });

  /// Reads a page from the whole response body.
  factory RequestLogPage.fromJson(Map<String, dynamic> json) {
    final meta = asMap(json['meta']);
    return RequestLogPage(
      logs: asModelList(json['data'], RequestLog.fromJson),
      summary: RequestLogSummary.fromJson(asMap(json['summary'])),
      nextCursor: asString(meta['next_cursor']),
      hasMore: asBool(meta['has_more']) ?? false,
    );
  }

  /// The rows on this page.
  final List<RequestLog> logs;

  /// Totals over the whole window.
  final RequestLogSummary summary;

  /// Pass back as `before` for the next page; null on the last page.
  final String? nextCursor;

  /// Whether another page follows this one.
  final bool hasMore;

  @override
  String toString() => 'RequestLogPage(${logs.length} rows)';
}
