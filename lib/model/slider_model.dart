class SliderItem {
  final String id;
  final String image;
  final String title;
  final bool isActive;
  final int order;

  SliderItem({
    required this.id,
    required this.image,
    required this.title,
    required this.isActive,
    required this.order,
  });

  factory SliderItem.fromJson(Map<String, dynamic> json) {
    return SliderItem(
      id: json['_id'] ?? '',
      image: json['image'] ?? '',
      title: json['title'] ?? '',
      isActive: json['isActive'] ?? false,
      order: json['order'] ?? 0,
    );
  }
}

class SliderResponse {
  final int statusCode;
  final bool success;
  final String message;
  final List<SliderItem> data;

  SliderResponse({
    required this.statusCode,
    required this.success,
    required this.message,
    required this.data,
  });

  factory SliderResponse.fromJson(Map<String, dynamic> json) {
    return SliderResponse(
      statusCode: json['statusCode'] ?? 0,
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List)
          .map((e) => SliderItem.fromJson(e))
          .toList(),
    );
  }
}
