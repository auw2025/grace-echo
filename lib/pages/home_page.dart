import 'package:flutter/material.dart';
import 'package:grace_echo/services/firebase_service.dart';
import 'package:grace_echo/models/category_model.dart'; // Create this.
import 'category_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseService _firebaseService = FirebaseService();

  // Variables for caching:
  Future<List<Category>>? _categoriesFuture;
  List<Category>? _categoriesCache;
  DateTime? _lastFetchTime;
  final Duration cacheDuration = const Duration(minutes: 10);

  /// Fetch categories using cache logic.
  Future<List<Category>> getCategoriesWithCache() async {
    // If we have cached data and the cache is still valid, return it.
    if (_categoriesCache != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < cacheDuration) {
      return _categoriesCache!;
    }
    // Otherwise, fetch from Firebase.
    List<Category> categories = await _firebaseService.getCategories();
    _categoriesCache = categories;
    _lastFetchTime = DateTime.now();
    return categories;
  }

  @override
  void initState() {
    super.initState();
    // Get categories using the cache logic.
    _categoriesFuture = getCategoriesWithCache();
  }

  void _refreshData() {
    // When refreshing, we force a fetch from Firebase and update the cache.
    setState(() {
      _categoriesFuture = _firebaseService.getCategories().then((categories) {
        _categoriesCache = categories;
        _lastFetchTime = DateTime.now();
        return categories;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grace Abounds'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No categories available'));
          } else {
            final categories = snapshot.data!;
            return ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFF003153)),
                    ),
                  ),
                  child: ListTile(
                    title: Text(category.name),
                    subtitle: Text("(${category.passageCount} 章)"),
                    onTap: () {
                      // Navigate to the CategoryPage for this specific category.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryPage(
                            categoryName: category.name,
                          ),
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
      // Removed the floatingActionButton that contained the microphone record button.
    );
  }
}