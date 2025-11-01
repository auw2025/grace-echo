class Tag {
  final String id;
  final String name;
  final int order;

  Tag({required this.id, required this.name, required this.order});

  factory Tag.fromFirestore(String id, Map<String, dynamic> data) {
    return Tag(
      id: id,
      name: data['name'] ?? 'Unnamed',
      order: data['order'] ?? 9999,
    );
  }
}