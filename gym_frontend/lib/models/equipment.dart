class Equipment {
  final int? id;
  final String name;
  final String equipmentType;
  final String brand;
  final String? model;
  final DateTime purchaseDate;
  final double? purchasePrice;
  final DateTime warrantyExpiry;
  final bool isWorking;
  final String condition;
  final DateTime? lastMaintenanceDate;
  final DateTime? nextMaintenanceDate;
  final String maintenanceNotes;
  final String? equipmentId;
  final int quantity;
  final String? serialNumber;
  final String? locationInGym;
  final String? imageUrl;

  Equipment({
    this.id,
    required this.name,
    required this.equipmentType,
    required this.brand,
    this.model,
    required this.purchaseDate,
    this.purchasePrice,
    required this.warrantyExpiry,
    this.isWorking = true,
    this.condition = 'excellent',
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
    this.maintenanceNotes = '',
    this.equipmentId,
    this.quantity = 1,
    this.serialNumber,
    this.locationInGym,
    this.imageUrl,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'],
      name: json['name'] ?? '',
      equipmentType: json['equipment_type'] ?? 'cardio',
      brand: json['brand'] ?? '',
      model: json['model'],
      purchaseDate: DateTime.parse(json['purchase_date']),
      purchasePrice: json['purchase_price'] != null ? double.tryParse(json['purchase_price'].toString()) : null,
      warrantyExpiry: DateTime.parse(json['warranty_expiry']),
      isWorking: json['is_working'] ?? true,
      condition: json['condition'] ?? 'excellent',
      lastMaintenanceDate: json['last_maintenance_date'] != null ? DateTime.parse(json['last_maintenance_date']) : null,
      nextMaintenanceDate: json['next_maintenance_date'] != null ? DateTime.parse(json['next_maintenance_date']) : null,
      maintenanceNotes: json['maintenance_notes'] ?? '',
      equipmentId: json['equipment_id'],
      quantity: json['quantity'] ?? 1,
      serialNumber: json['serial_number'],
      locationInGym: json['location_in_gym'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'equipment_type': equipmentType,
      'brand': brand,
      'purchase_date': purchaseDate.toIso8601String().split('T')[0],
      'warranty_expiry': warrantyExpiry.toIso8601String().split('T')[0],
      'is_working': isWorking,
      'condition': condition,
      'maintenance_notes': maintenanceNotes,
      'quantity': quantity,
    };
    
    // Only include optional fields if they have values
    if (id != null) json['id'] = id;
    if (model != null && model!.isNotEmpty) json['model'] = model;
    if (purchasePrice != null) json['purchase_price'] = purchasePrice;
    if (lastMaintenanceDate != null) json['last_maintenance_date'] = lastMaintenanceDate!.toIso8601String().split('T')[0];
    if (nextMaintenanceDate != null) json['next_maintenance_date'] = nextMaintenanceDate!.toIso8601String().split('T')[0];
    if (equipmentId != null && equipmentId!.isNotEmpty) json['equipment_id'] = equipmentId;
    if (serialNumber != null && serialNumber!.isNotEmpty) json['serial_number'] = serialNumber;
    if (locationInGym != null && locationInGym!.isNotEmpty) json['location_in_gym'] = locationInGym;
    if (imageUrl != null && imageUrl!.isNotEmpty) json['image_url'] = imageUrl;
    
    return json;
  }

  String get displayName => '$name - $brand';
  String get statusText => isWorking ? 'Working' : 'Under Maintenance';
}