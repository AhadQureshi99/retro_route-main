class ReviewResponse {
  final int? statusCode;
  final Message? message;
  final String? data;
  final bool? success;

  ReviewResponse({
    this.statusCode,
    this.message,
    this.data,
    this.success,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      statusCode: json['statusCode'] as int?,
      message: json['data'] != null && json['data'] is Map<String, dynamic>
          ? Message.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      data: json['message'] as String?,
      success: json['success'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'statusCode': statusCode,
        'message': message?.toJson(),
        'data': data,
        'success': success,
      };
}

class Message {
  final List<Review>? reviews;
  final int? totalReviews;
  final double? averageRating;
  final int? currentPage;
  final int? totalPages;

  Message({
    this.reviews,
    this.totalReviews,
    this.averageRating,
    this.currentPage,
    this.totalPages,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      reviews: (json['reviews'] as List<dynamic>?)
          ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalReviews: json['totalReviews'] as int?,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      currentPage: json['currentPage'] as int?,
      totalPages: json['totalPages'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'reviews': reviews?.map((e) => e.toJson()).toList(),
        'totalReviews': totalReviews,
        'averageRating': averageRating,
        'currentPage': currentPage,
        'totalPages': totalPages,
      };
}

class Review {
  final String? id;
  final String? productId;
  final User? userId; // nested user object
  final int? rating;
  final String? title;
  final String? comment;
  final List<String>? images;
  final int? helpful;
  final int? unhelpful;
  final bool? verified;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v; // __v

  Review({
    this.id,
    this.productId,
    this.userId,
    this.rating,
    this.title,
    this.comment,
    this.images,
    this.helpful,
    this.unhelpful,
    this.verified,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id'] as String?,
      productId: json['productId'] as String?,
      userId: json['userId'] != null
          ? User.fromJson(json['userId'] as Map<String, dynamic>)
          : null,
      rating: json['rating'] as int?,
      title: json['title'] as String?,
      comment: json['comment'] as String?,
      images: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
      helpful: json['helpful'] as int?,
      unhelpful: json['unhelpful'] as int?,
      verified: json['verified'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      v: json['__v'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'productId': productId,
        'userId': userId?.toJson(),
        'rating': rating,
        'title': title,
        'comment': comment,
        'images': images,
        'helpful': helpful,
        'unhelpful': unhelpful,
        'verified': verified,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        '__v': v,
      };
}

class User {
  final String? id;
  final String? name;
  final String? email;
  final String? avatar;

  User({
    this.id,
    this.name,
    this.email,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'avatar': avatar,
      };
}