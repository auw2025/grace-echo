class Category {
  final String name;
  final int passageCount;

  Category({
    required this.name,
    required this.passageCount,
  });

  factory Category.fromFirestore(Map<String, dynamic> data) {
    return Category(
      name: data['name'] ?? 'Unnamed',
      passageCount: data['passageCount'] ?? 0,
    );
  }
}