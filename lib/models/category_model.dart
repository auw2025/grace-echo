class Category {
  /// Firestore document id – useful for updates / deletes.
  final String id;

  /// Human-readable name shown in the UI.
  final String name;

  /// Number of passages that belong to this category.
  final int passageCount;

  /// Reference to the parent tag document (tags/{tagId})
  final String tagId;

  Category({
    required this.id,
    required this.name,
    required this.passageCount,
    required this.tagId,
  });

  /// Convenience factory when you already have the doc id.
  factory Category.fromFirestore(String id, Map<String, dynamic> data) {
    return Category(
      id           : id,
      name         : data['name'] ?? 'Unnamed',
      passageCount : data['passageCount'] ?? 0,
      tagId        : data['tagId'] ?? '',
    );
  }

  /// Handy when you need to send the object back to Firestore.
  Map<String, dynamic> toMap() => {
        'name'         : name,
        'passageCount' : passageCount,
        'tagId'        : tagId,
      };
}