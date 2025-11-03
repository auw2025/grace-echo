// lib/models/tag_model.dart
class Tag {
  final String id;
  final String name;
  final int    order;
  final bool   skipCategory;
  final String? directPassageId;      // ← NEW (nullable)

  Tag({
    required this.id,
    required this.name,
    required this.order,
    this.skipCategory = false,
    this.directPassageId,
  });

  factory Tag.fromFirestore(String id, Map<String, dynamic> data) {
    return Tag(
      id             : id,
      name           : data['name']  ?? 'Unnamed',
      order          : data['order'] ?? 9999,
      skipCategory   : data['skipCategory'] ?? false,
      directPassageId: data['directPassageId'],        // ← NEW
    );
  }

  Map<String, dynamic> toMap() => {
        'name'            : name,
        'order'           : order,
        'skipCategory'    : skipCategory,
        'directPassageId' : directPassageId,
      };
}