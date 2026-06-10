import '../datasources/mock_data.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import '../../core/monitoring/sentry_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class RestaurantRepository {
  Future<List<Restaurant>> getRestaurants({String? category}) async {
    final transaction = SentryService.startTransaction('load.restaurants', 'db');
    final span = transaction.startChild('fetch.list');

    try {
      await Future.delayed(const Duration(milliseconds: 600));

      var restaurants = MockData.restaurants;

      if (category != null && category != 'all') {
        restaurants = restaurants.where((r) => r.category == category).toList();
      }

      SentryService.addBreadcrumb(
        'Restaurantes carregados',
        category: 'data',
        data: {'count': restaurants.length, 'filter': category ?? 'all'},
      );

      await span.finish(status: SpanStatus.ok());
      await transaction.finish(status: SpanStatus.ok());
      return restaurants;
    } catch (e, st) {
      await span.finish(status: SpanStatus.internalError());
      await transaction.finish(status: SpanStatus.internalError());
      await SentryService.captureException(e, stackTrace: st, hint: 'getRestaurants failed');
      rethrow;
    }
  }

  Future<List<Restaurant>> searchRestaurants(String query) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final q = query.toLowerCase();
      final results = MockData.restaurants
          .where((r) =>
              r.name.toLowerCase().contains(q) ||
              r.category.toLowerCase().contains(q) ||
              r.description.toLowerCase().contains(q))
          .toList();
      return results;
    } catch (e, st) {
      await SentryService.captureException(e, stackTrace: st);
      rethrow;
    }
  }

  Future<Restaurant?> getRestaurantById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return MockData.restaurants.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<MenuItem>> getMenuItems(String restaurantId) async {
    final transaction =
        SentryService.startTransaction('load.menu', 'db');
    final span = transaction.startChild('fetch.menu_items');

    try {
      await Future.delayed(const Duration(milliseconds: 400));
      final items = MockData.menuItems[restaurantId] ?? [];

      await span.finish(status: SpanStatus.ok());
      await transaction.finish(status: SpanStatus.ok());
      return items;
    } catch (e, st) {
      await span.finish(status: SpanStatus.internalError());
      await transaction.finish(status: SpanStatus.internalError());
      await SentryService.captureException(e, stackTrace: st);
      rethrow;
    }
  }

  Future<List<Restaurant>> getFeatured() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockData.restaurants.where((r) => r.featured).toList();
  }
}
