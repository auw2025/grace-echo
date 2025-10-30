import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grace_echo/services/firebase_service.dart';
import 'package:grace_echo/models/category_model.dart'; // Make sure this file exists.
import 'category_page.dart';
import 'package:grace_echo/providers/settings_provider.dart';

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
    // Access the global high contrast setting.
    final settings = Provider.of<SettingsProvider>(context);
    final bool isHighContrast = settings.isHighContrast;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grace Abounds'),
        backgroundColor: isHighContrast ? Colors.black : null,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: isHighContrast ? Colors.white : null),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: isHighContrast ? Colors.black : Colors.white,
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isHighContrast ? Colors.white : Colors.black,
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: isHighContrast ? Colors.white : Colors.black),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No categories available',
                style: TextStyle(color: isHighContrast ? Colors.white : Colors.black),
              ),
            );
          } else {
            final categories = snapshot.data!;
            return ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFF003153)),
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      category.name,
                      style: TextStyle(
                        color: isHighContrast ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      "(${category.passageCount} 章)",
                      style: TextStyle(
                        color: isHighContrast ? Colors.white70 : Colors.black54,
                      ),
                    ),
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
    );
  }
}