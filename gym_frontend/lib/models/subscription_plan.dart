class SubscriptionPlan {
  final int id;
  final String name;
  final String description;
  final double price;
  final int durationInMonths;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> features;
  final String? discountPercentage;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationInMonths,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.features,
    this.discountPercentage,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      durationInMonths: json['duration_value'] ?? json['duration_in_months'] ?? 1,
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_date'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_date'] ?? json['updated_at'] ?? DateTime.now().toIso8601String()),
      features: List<String>.from(json['features'] ?? []),
      discountPercentage: json['discount_percentage']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'duration_in_months': durationInMonths,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'features': features,
      'discount_percentage': discountPercentage,
    };
  }

  double get monthlyPrice => price / durationInMonths;
  
  String get formattedPrice => '₹${price.toStringAsFixed(2)}';
  
  String get formattedDuration => 
      durationInMonths == 1 ? '1 Month' : '$durationInMonths Months';
}