import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = ''; // Deixe vazio para desativar ou coloque sua chave DSN do sentry.io
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;
      options.attachScreenshot = true;
      options.attachViewHierarchy = true;
      options.environment = kReleaseMode ? 'production' : 'development';
      options.debug = kDebugMode;
      options.sendDefaultPii = true;
      options.maxBreadcrumbs = 150;
      options.enableAutoSessionTracking = true;
    },
    appRunner: () => runApp(
      ProviderScope(
        child: SentryWidget(child: const FoodRushApp()),
      ),
    ),
  );
}
