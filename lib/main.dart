import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await SentryFlutter.init(
    (options) {
      options.dsn = dotenv.env['SENTRY_DSN'] ?? ''; // Carrega o DSN do .env
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
