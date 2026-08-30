/// Decoding helpers shared by every model. The API leaves optional fields out
/// rather than sending null, and numbers occasionally arrive as strings, so
/// every reader here is permissive by design.
library;

String? asString(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

int? asInt(Object? value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool? asBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value == 'true') return true;
  if (value == 'false') return false;
  return null;
}

DateTime? asDate(Object? value) {
  if (value is! String) return null;
  final raw = value.trim();
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toUtc();
}

Map<String, dynamic> asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

Map<String, dynamic>? asMapOrNull(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

List<String> asStringList(Object? value) => value is List
    ? value.where((e) => e != null).map((e) => e.toString()).toList()
    : const <String>[];

List<T> asModelList<T>(Object? value, T Function(Map<String, dynamic>) parse) {
  if (value is! List) return <T>[];
  return value
      .whereType<Map>()
      .map((e) => parse(Map<String, dynamic>.from(e)))
      .toList();
}

/// Drops the keys whose value is null, so an unset option is simply not sent
/// and the API applies its own default.
Map<String, dynamic> pruned(Map<String, dynamic> body) {
  final out = <String, dynamic>{};
  body.forEach((key, value) {
    if (value != null) out[key] = value;
  });
  return out;
}

/// Renders a query map as strings, dropping unset entries. A list becomes a
/// comma-joined value, which is what the API's filters read.
Map<String, String> queryOf(Map<String, dynamic>? query) {
  final out = <String, String>{};
  if (query == null) return out;
  query.forEach((key, value) {
    if (value == null) return;
    if (value is Iterable) {
      final joined = value.map((e) => '$e').join(',');
      if (joined.isEmpty) return;
      out[key] = joined;
      return;
    }
    if (value is DateTime) {
      out[key] = value.toUtc().toIso8601String();
      return;
    }
    final text = '$value';
    if (text.isEmpty) return;
    out[key] = text;
  });
  return out;
}
