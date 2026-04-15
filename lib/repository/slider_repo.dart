
import 'dart:developer';

import 'package:retro_route/services/data/network_api_services.dart';
import 'package:retro_route/utils/app_urls.dart';

import 'package:retro_route/model/slider_model.dart';
import 'package:retro_route/services/data/network_api_services.dart';
import 'package:retro_route/utils/app_urls.dart';

class SliderRepo {
  final _apiServices = NetworkApiServices();

  Future<List<SliderItem>> getSliderImages() async {
    try {
      final response =
          await _apiServices.getApi(AppUrls.getSlider, null);

      final sliderResponse = SliderResponse.fromJson(response);
      log("our slider is $sliderResponse");
      return sliderResponse.data;
    } catch (e) {
      throw Exception('Error fetching slider images: $e');
    }
  }
}
