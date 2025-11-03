class Category {
  final String id;
  final String name;
  final int    passageCount;
  final String tagId;

  // NEW → the passage that should open directly when this category
  // is tapped and its parent tag has skipCategory == true
  final String? directPassageId;

  Category({
    required this.id,
    required this.name,
    required this.passageCount,
    required this.tagId,
    this.directPassageId,
  });

  factory Category.fromFirestore(String id, Map<String, dynamic> data) {
    return Category(
      id             : id,
      name           : data['name'] ?? 'Unnamed',
      passageCount   : data['passageCount'] ?? 0,
      tagId          : data['tagId'],
      directPassageId: data['directPassageId'],      // ← NEW
    );
  }

  Map<String, dynamic> toMap() => {
        'name'            : name,
        'passageCount'    : passageCount,
        'tagId'           : tagId,
        'directPassageId' : directPassageId,
      };
}