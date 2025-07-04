class Equipment {
  final int? id;
  final String name;
  final String equipmentType;
  final String brand;
  final DateTime purchaseDate;
  final DateTime warrantyExpiry;
  final bool isWorking;
  final String maintenanceNotes;

  Equipment({
    this.id,
    required this.name,
    required this.equipmentType,
    required this.brand,
    required this.purchaseDate,
    required this.warrantyExpiry,
    this.isWorking = true,
    this.maintenanceNotes = '',
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'],
      name: json['name'],
      equipmentType: json['equipment_type'],
      brand: json['brand'],
      purchaseDate: DateTime.parse(json['purchase_date']),
      warrantyExpiry: DateTime.parse(json['warranty_expiry']),
      isWorking: json['is_working'],
      maintenanceNotes: json['maintenance_notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'equipment_type': equipmentType,
      'brand': brand,
      'purchase_date': purchaseDate.toIso8601String().split('T')[0],
      'warranty_expiry': warrantyExpiry.toIso8601String().split('T')[0],
      'is_working': isWorking,
      'maintenance_notes': maintenanceNotes,
    };
  }

  String get displayName => '$name - $brand';
  String get statusText => isWorking ? 'Working' : 'Under Maintenance';
}