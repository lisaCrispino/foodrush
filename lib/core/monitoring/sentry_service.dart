import 'package:sentry_flutter/sentry_flutter.dart';

class SentryService {
  SentryService._();

  static Future<void> captureException(
    dynamic exception, {
    StackTrace? stackTrace,
    String? hint,
  }) async {
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      hint: hint != null ? Hint.withMap({'message': hint}) : null,
    );
  }

  static void addBreadcrumb(
    String message, {
    String? category,
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? data,
  }) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        level: level,
        data: data,
        timestamp: DateTime.now(),
      ),
    );
  }

  static Future<void> setUser({
    required String id,
    String? email,
    String? username,
    Map<String, dynamic>? extras,
  }) async {
    await Sentry.configureScope(
      (scope) => scope.setUser(
        SentryUser(
          id: id,
          email: email,
          username: username,
          data: extras,
        ),
      ),
    );
  }

  static Future<void> clearUser() async {
    await Sentry.configureScope((scope) => scope.setUser(null));
  }

  static ISentrySpan startTransaction(String name, String operation) {
    return Sentry.startTransaction(name, operation, bindToScope: true);
  }

  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
  }) async {
    await Sentry.captureMessage(message, level: level);
  }

  static Future<void> addTag(String key, String value) async {
    await Sentry.configureScope((scope) => scope.setTag(key, value));
  }
}
