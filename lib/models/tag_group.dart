import 'tag_model.dart';
import 'category_model.dart';

class TagGroup {
  final Tag tag;                 // the header
  final List<Category> categories;

  TagGroup({required this.tag, required this.categories});
}