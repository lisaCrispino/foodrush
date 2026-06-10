import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/menu_item.dart';
import '../../../data/models/restaurant.dart';
import '../../home/providers/home_provider.dart';

final restaurantDetailProvider = FutureProvider.autoDispose.family<Restaurant?, String>(
  (ref, id) => ref.read(restaurantRepositoryProvider).getRestaurantById(id),
);

final restaurantMenuProvider = FutureProvider.autoDispose.family<List<MenuItem>, String>(
  (ref, restaurantId) =>
      ref.read(restaurantRepositoryProvider).getMenuItems(restaurantId),
);
