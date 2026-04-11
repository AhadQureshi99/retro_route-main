class CategoryModel {
  final int? statusCode;
  final String? message;
  final List<Category>? data;
  final bool? success;

  CategoryModel({
    this.statusCode,
    this.message,
    this.data,
    this.success,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      statusCode: json['statusCode'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? List<Category>.from(
              (json['data'] as List).map(
                (x) => Category.fromJson(x as Map<String, dynamic>),
              ),
            )
          : null,
      success: json['success'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'message': message,
      'data': data?.map((x) => x.toJson()).toList(),
      'success': success,
    };
  }
}




class Category {
  final String? id;
  final String? name;
  final String? image;
  final String? parentCategory;
  final String? parentCategoryName;
  final bool isSubcategory;
  final List<Category> subcategories;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  Category({
    this.id,
    this.name,
    this.image,
    this.parentCategory,
    this.parentCategoryName,
    this.isSubcategory = false,
    this.subcategories = const [],
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    String? parentCatId;
    String? parentCatName;
    final pc = json['parentCategory'];
    if (pc is String) {
      parentCatId = pc;
    } else if (pc is Map) {
      parentCatId = pc['_id'] as String?;
      parentCatName = pc['name'] as String?;
    }

    return Category(
      id: json['_id'] as String?,
      name: json['name'] as String?,
      image: json['image'] as String?,
      parentCategory: parentCatId,
      parentCategoryName: parentCatName,
      isSubcategory: json['isSubcategory'] == true,
      subcategories: json['subcategories'] != null
          ? List<Category>.from(
              (json['subcategories'] as List).map(
                (x) => Category.fromJson(x as Map<String, dynamic>),
              ),
            )
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      v: json['__v'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'image': image,
      'parentCategory': parentCategory,
      'parentCategoryName': parentCategoryName,
      'isSubcategory': isSubcategory,
      'subcategories': subcategories.map((x) => x.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      '__v': v,
    };
  }
  
  String get safeName => name ?? 'No Name';
  String get safeImage => image ?? '';
  bool get hasSubcategories => subcategories.isNotEmpty;
}