import 'package:flutter/material.dart';
import 'package:grace_echo/models/passage_model.dart';
import 'package:grace_echo/services/firebase_service.dart';
import 'passage_page.dart';

class CategoryPage extends StatefulWidget {
  final String categoryName;

  const CategoryPage({Key? key, required this.categoryName})
      : super(key: key);

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Passage>> _passagesFuture;

  @override
  void initState() {
    super.initState();
    // Fetch passages for the given category.
    _passagesFuture =
        _firebaseService.getPassagesForCategory(widget.categoryName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Category: ${widget.categoryName}'),
      ),
      body: FutureBuilder<List<Passage>>(
        future: _passagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No passages in this category.'));
          } else {
            final passages = snapshot.data!;
            return ListView.builder(
              itemCount: passages.length,
              itemBuilder: (context, index) {
                final passage = passages[index];
                return Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFF003153)),
                      bottom: BorderSide(color: Color(0xFF003153)),
                    ),
                  ),
                  child: ListTile(
                    title: Text(passage.title),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PassagePage(passage: passage),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}