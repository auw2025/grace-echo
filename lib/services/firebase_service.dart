// firebase_service.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/passage_model.dart';
import '../models/category_model.dart';
import '../models/tag_model.dart';          // NEW
import '../models/tag_group.dart';         // NEW (see below)

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage   = FirebaseStorage.instance;

  /* ───────────────────────  PASSAGES  ─────────────────────── */

  Future<List<Passage>> getPassages() async {
    try {
      final qs = await _firestore.collection('passages').get();
      return qs.docs
          .map((d) => Passage.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
    } catch (_) {
      rethrow;
    }
  }

  Future<List<Passage>> getPassagesForCategory(String categoryName) async {
    try {
      final qs = await _firestore
          .collection('passages')
          .where('category', isEqualTo: categoryName)
          .get();
      return qs.docs
          .map((d) => Passage.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
    } catch (_) {
      rethrow;
    }
  }

  Future<String> uploadAudio(File audioFile, String fileName) async {
    try {
      final ref        = _storage.ref().child('audios').child(fileName);
      final snapshot   = await ref.putFile(audioFile);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (_) {
      rethrow;
    }
  }

  /// Insert a passage and increment passageCount on its category (transaction).
  Future<void> addPassage(
    String title,
    String content,
    String audioUrl,
    String categoryName,
  ) async {
    try {
      final newPassageRef = _firestore.collection('passages').doc();
      final categoryRef   = _firestore.collection('categories').doc(categoryName);

      await _firestore.runTransaction((tx) async {
        tx.set(newPassageRef, {
          'title'   : title,
          'content' : content,
          'audioUrl': audioUrl,
          'category': categoryName,
        });
        tx.update(categoryRef, {
          'passageCount': FieldValue.increment(1),
        });
      });
    } catch (_) {
      rethrow;
    }
  }

  /* ───────────────────────  TAGS  ─────────────────────── */

  Future<List<Tag>> getTags() async {
    try {
      final qs = await _firestore.collection('tags').get();
      return qs.docs
          .map((d) => Tag.fromFirestore(d.id, d.data()))
          .toList();
    } catch (_) {
      rethrow;
    }
  }

  /* ───────────────────────  CATEGORIES  ─────────────────────── */

  /// Fetch all categories.  Each document **must** contain a
  /// `name` and `tagId` field, and optionally a stored `passageCount`.
  Future<List<Category>> getCategories() async {
    try {
      final qs = await _firestore.collection('categories').get();
      final List<Category> list = [];

      for (final doc in qs.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // If you trust the stored passageCount simply read it:
        final storedCount = data['passageCount'];

        // otherwise, compute it like before (slower):
        final passageSnapshot = storedCount == null
            ? await _firestore
                .collection('passages')
                .where('category', isEqualTo: data['name'])
                .get()
            : null;

        list.add(
          Category(
            id           : doc.id,
            name         : data['name'] ?? 'Unnamed',
            passageCount : storedCount ?? passageSnapshot!.docs.length,
            tagId        : data['tagId'],                // NEW
          ),
        );
      }
      return list;
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  /* ───────────────────────  GROUPS (Tags + Categories)  ─────────────────────── */

  /// Convenience method that joins tags + categories and
  /// returns them ready for the HomePage.
  Future<List<TagGroup>> getTagGroups() async {
    final tags       = await getTags();
    final categories = await getCategories();

    // Build a map tagId -> Tag
    final tagMap = {for (final t in tags) t.id: t};

    // Group categories under their tagId
    final Map<String, List<Category>> buckets = {};
    for (final c in categories) {
      if (!tagMap.containsKey(c.tagId)) continue;  // ignore orphans
      buckets.putIfAbsent(c.tagId, () => []).add(c);
    }

    // Build TagGroup list
    final groups = buckets.entries
        .map((e) => TagGroup(tag: tagMap[e.key]!, categories: e.value))
        .toList()
      ..sort((a, b) => a.tag.order.compareTo(b.tag.order)); // by order field

    return groups;
  }
}