import 'dart:io';

/// Reads an environment variable. Available wherever `dart:io` is.
String? envValue(String name) {
  try {
    return Platform.environment[name];
  } on Object {
    return null;
  }
}
