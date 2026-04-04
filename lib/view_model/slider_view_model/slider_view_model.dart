import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retro_route/model/slider_model.dart';
import 'package:retro_route/repository/slider_repo.dart';

final sliderProvider =
    FutureProvider<List<SliderItem>>((ref) async {
  final repo = SliderRepo();
  return repo.getSliderImages();
});
