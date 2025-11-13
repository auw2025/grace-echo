import 'package:flutter/foundation.dart';

/// ---------------------------------------------------------------------------
///  Sub-page support
/// ---------------------------------------------------------------------------

class SubPageOption {
  final String label;
  final int nextIndex;

  SubPageOption({
    required this.label,
    required this.nextIndex,
  });

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

/// ---------------------------------------------------------------------------
///  Main model (unchanged fields + new subPages support)
/// ---------------------------------------------------------------------------

class Passage {
  final String id;
  final String title;
  final String content;
  final String audioUrl;
  final String category;

  /// NEW
  final List<SubPage> subPages;

  bool get hasSubPages => subPages.isNotEmpty;

  Passage({
    required this.id,
    required this.title,
    required this.content,
    required this.audioUrl,
    required this.category,
    this.subPages = const [],
  });

  factory Passage.fromMap(Map<String, dynamic> data, String documentId) {
    return Passage(
      id: documentId,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      audioUrl: data['audioUrl'] ?? '',
      category: data['category'] ?? 'Uncategorized',
      subPages: (data['subPages'] as List? ?? [])
          .map((e) => SubPage.fromMap(e))
          .toList(),
    );
  }
}