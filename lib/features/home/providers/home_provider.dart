import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/restaurant.dart';
import '../../../data/repositories/restaurant_repository.dart';

final restaurantRepositoryProvider = Provider<RestaurantRepository>((_) => RestaurantRepository());

final selectedCategoryProvider = StateProvider<String>((ref) => 'all');

final homeRestaurantsProvider = FutureProvider.autoDispose<List<Restaurant>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  return ref.read(restaurantRepositoryProvider).getRestaurants(category: category);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<Restaurant>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return Future.value([]);
  return ref.read(restaurantRepositoryProvider).searchRestaurants(query);
});
