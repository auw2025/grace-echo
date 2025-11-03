// lib/services/firebase_service.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/passage_model.dart';
import '../models/category_model.dart';
import '../models/tag_model.dart';
import '../models/tag_group.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage   _storage   = FirebaseStorage.instance;

  /* ────────────────────────  PASSAGES  ──────────────────────── */

  Future<List<Passage>> getPassages() async {
    final qs = await _firestore.collection('passages').get();
    return qs.docs
        .map((d) => Passage.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  Future<List<Passage>> getPassagesForCategory(String categoryName) async {
    final qs = await _firestore
        .collection('passages')
        .where('category', isEqualTo: categoryName)
        .get();
    return qs.docs
        .map((d) => Passage.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  Future<Passage?> getPassageById(String passageId) async {
    final doc =
        await _firestore.collection('passages').doc(passageId).get();
    if (!doc.exists) return null;
    return Passage.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// still useful in other screens – left here unchanged
  Future<Passage?> getFirstPassageForTag(String tagId) async {
    final catSnap = await _firestore
        .collection('categories')
        .where('tagId', isEqualTo: tagId)
        .get();

    if (catSnap.docs.isEmpty) return null;

    final List<String> catNames =
        catSnap.docs.map((d) => d.data()['name'] as String).toList();

    final passSnap = await _firestore
        .collection('passages')
        .where('category', whereIn: catNames.take(10).toList())
        .orderBy('title')
        .limit(1)
        .get();

    if (passSnap.docs.isEmpty) return null;
    final doc = passSnap.docs.first;
    return Passage.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<String> uploadAudio(File audioFile, String fileName) async {
    final ref      = _storage.ref().child('audios').child(fileName);
    final snapshot = await ref.putFile(audioFile);
    return snapshot.ref.getDownloadURL();
  }

  Future<void> addPassage(
    String title,
    String content,
    String audioUrl,
    String categoryName,
  ) async {
    final newPassageRef = _firestore.collection('passages').doc();
    final categoryRef   =
        _firestore.collection('categories').doc(categoryName);

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
  }

  /* ───────────────────────────  TAGS  ─────────────────────────── */

  Future<List<Tag>> getTags() async {
    final qs = await _firestore.collection('tags').get();
    return qs.docs
        .map((d) => Tag.fromFirestore(d.id, d.data()))
        .toList();
  }

  /* ────────────────────────  CATEGORIES  ──────────────────────── */

  Future<List<Category>> getCategories() async {
    final qs = await _firestore.collection('categories').get();
    final List<Category> list = [];

    for (final doc in qs.docs) {
      final data = doc.data() as Map<String, dynamic>;

      final storedCount = data['passageCount'];
      final passageSnapshot = storedCount == null
          ? await _firestore
              .collection('passages')
              .where('category', isEqualTo: data['name'])
              .get()
          : null;

      list.add(
        Category(
          id             : doc.id,
          name           : data['name'] ?? 'Unnamed',
          passageCount   : storedCount ?? passageSnapshot!.docs.length,
          tagId          : data['tagId'],
          directPassageId: data['directPassageId'], // ← NEW
        ),
      );
    }
    return list;
  }

  /* ──────────────────────  TAG-GROUPS  ────────────────────── */

  Future<List<TagGroup>> getTagGroups() async {
    final tags       = await getTags();
    final categories = await getCategories();

    final tagMap = {for (final t in tags) t.id: t};

    final Map<String, List<Category>> buckets = {};
    for (final c in categories) {
      if (!tagMap.containsKey(c.tagId)) continue;
      buckets.putIfAbsent(c.tagId, () => []).add(c);
    }

    final groups = buckets.entries
        .map((e) => TagGroup(tag: tagMap[e.key]!, categories: e.value))
        .toList()
      ..sort((a, b) => a.tag.order.compareTo(b.tag.order));

    return groups;
  }
}