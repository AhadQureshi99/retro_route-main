import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retro_route/model/product_model.dart';
import 'package:retro_route/repository/water_test_repo.dart';

final waterTestProvider = FutureProvider<Product?>((ref) async {
  final repo = WaterTestRepo();
  return repo.getWaterTestService();
});
