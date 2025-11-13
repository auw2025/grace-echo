class SubPageOption {
  final String label;
  final int nextIndex;           // index inside subPages list

  SubPageOption({required this.label, required this.nextIndex});

  factory SubPageOption.fromMap(Map<String, dynamic> data) {
    return SubPageOption(
      label: data['label'] ?? '',
      nextIndex: data['nextIndex'] ?? 0,
    );
  }
}

class SubPage {
  final int index;
  final String content;
  final String audioUrl;
  final List<SubPageOption> options;

  SubPage({
    required this.index,
    required this.content,
    required this.audioUrl,
    required this.options,
  });

  factory SubPage.fromMap(Map<String, dynamic> data) {
    return SubPage(
      index: data['index'] ?? 0,
      content: data['content'] ?? '',
      audioUrl: data['audioUrl'] ?? '',
      options: (data['options'] as List? ?? [])
          .map((e) => SubPageOption.fromMap(e))
          .toList(),
    );
  }
}