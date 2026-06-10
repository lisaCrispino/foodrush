import 'package:dio/dio.dart';

import '../monitoring/sentry_service.dart';

class DioClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.foodrush.app/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          SentryService.addBreadcrumb(
            'HTTP ${options.method} ${options.path}',
            category: 'http.request',
            data: {'url': options.uri.toString(), 'method': options.method},
          );
          handler.next(options);
        },
        onResponse: (response, handler) {
          SentryService.addBreadcrumb(
            'HTTP ${response.statusCode} ${response.requestOptions.path}',
            category: 'http.response',
            data: {
              'url': response.requestOptions.uri.toString(),
              'status': response.statusCode,
            },
          );
          handler.next(response);
        },
        onError: (error, handler) async {
          await SentryService.captureException(
            error,
            stackTrace: error.stackTrace,
            hint: 'HTTP ${error.requestOptions.method} ${error.requestOptions.path}',
          );
          handler.next(error);
        },
      ),
    );

    return dio;
  }
}
