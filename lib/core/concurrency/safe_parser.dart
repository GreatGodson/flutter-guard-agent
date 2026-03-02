import 'dart:convert';
import 'dart:isolate';

/// Utility for performing heavy JSON parsing work off the main isolate.
///
/// This demonstrates the "jank-free data layering" pattern the agent
/// is specialised to encourage. It is intentionally small and focused.
class SafeParser {
  /// Parse [rawJson] in a background isolate and map it to [T] using [mapper].
  ///
  /// Example:
  /// ```dart
  /// final user = await SafeParser.parseInBackground(
  ///   rawJsonString,
  ///   (json) => User.fromJson(json),
  /// );
  /// ```
  static Future<T> parseInBackground<T>(
    String rawJson,
    T Function(Map<String, dynamic>) mapper,
  ) async {
    return Isolate.run(() {
      final Map<String, dynamic> data = jsonDecode(rawJson);
      return mapper(data);
    });
  }
}

