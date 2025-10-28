class Passage {
  final String id;
  final String title;
  final String content;
  final String audioUrl;
  final String category;

  Passage({
    required this.id,
    required this.title,
    required this.content,
    required this.audioUrl,
    required this.category
  });

  // Create a factory constructor to parse data from Firestore
  factory Passage.fromMap(Map<String, dynamic> data, String documentId) {
    return Passage(
      id: documentId,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      audioUrl: data['audioUrl'] ?? '',
      category: data['category'] ?? 'Uncategorized',
    );
  }
}