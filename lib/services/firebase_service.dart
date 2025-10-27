import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../models/passage_model.dart';
import '../models/category_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Fetch list of all passages from Firestore.
  Future<List<Passage>> getPassages() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection('passages').get();
      return querySnapshot.docs.map((doc) {
        return Passage.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Fetch passages for a specific category (assuming each passage document contains a "category" field).
  Future<List<Passage>> getPassagesForCategory(String category) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('passages')
          .where('category', isEqualTo: category)
          .get();
      return querySnapshot.docs.map((doc) {
        return Passage.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Upload an audio file to Firebase Storage and return the download URL.
  Future<String> uploadAudio(File audioFile, String fileName) async {
    try {
      Reference ref = _storage.ref().child('audios').child(fileName);
      UploadTask uploadTask = ref.putFile(audioFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  // Save the new passage (including audioUrl) in Firestore and update the category's passage count.
  // This method assumes that the category document's id is the same as the category name.
  Future<void> addPassage(
      String title, String content, String audioUrl, String category) async {
    try {
      // Create a reference for the new passage document.
      DocumentReference newPassageRef =
          _firestore.collection('passages').doc();

      // Create a reference for the category document.
      DocumentReference categoryRef =
          _firestore.collection('categories').doc(category);

      // Run a Firestore transaction so that inserting the passage and updating the category count happen atomically.
      await _firestore.runTransaction((transaction) async {
        // Set the new passage document.
        transaction.set(newPassageRef, {
          'title': title,
          'content': content,
          'audioUrl': audioUrl,
          'category': category,
        });

        // Update the category's passageCount field by incrementing it.
        transaction.update(categoryRef, {
          'passageCount': FieldValue.increment(1),
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  // Fetch list of categories from Firestore.
  Future<List<Category>> getCategories() async {
  try {
    QuerySnapshot categorySnapshot = await _firestore.collection('categories').get();
    List<Category> categories = [];

    // For each category document, query how many passages have the matching category name.
    for (var doc in categorySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String categoryName = data['name'] ?? 'Unnamed';

      // Query passages for this category.
      QuerySnapshot passageSnapshot = await _firestore
          .collection('passages')
          .where('category', isEqualTo: categoryName)
          .get();

      // Count the passages.
      int passageCount = passageSnapshot.docs.length;
      categories.add(Category(name: categoryName, passageCount: passageCount));
    }
    return categories;
  } catch (e) {
    throw Exception('Error fetching categories: $e');
  }
}
}