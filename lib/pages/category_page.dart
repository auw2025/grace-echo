import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grace_echo/models/passage_model.dart';
import 'package:grace_echo/services/firebase_service.dart';
import 'passage_page.dart';
import 'package:grace_echo/providers/settings_provider.dart';

class CategoryPage extends StatefulWidget {
  final String categoryName;

  const CategoryPage({Key? key, required this.categoryName}) : super(key: key);

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
    _passagesFuture = _firebaseService.getPassagesForCategory(widget.categoryName);
  }

  void _refreshData() {
    setState(() {
      // Re-fetch passages for the given category.
      _passagesFuture = _firebaseService.getPassagesForCategory(widget.categoryName);
    });
  }

  /// Shows a bottom sheet with accessibility options (only high contrast switch).
  void _showAccessibilityOptionsSheet() {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // High contrast mode toggle row.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "高對比模式",
                          style: TextStyle(fontSize: 16.0),
                        ),
                        Consumer<SettingsProvider>(
                          builder: (context, settings, child) {
                            return Switch(
                              value: settings.isHighContrast,
                              onChanged: (value) {
                                settingsProvider.toggleHighContrast(value);
                                setModalState(() {});
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access the global high contrast setting.
    final settings = Provider.of<SettingsProvider>(context);
    final bool isHighContrast = settings.isHighContrast;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
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
      body: FutureBuilder<List<Passage>>(
        future: _passagesFuture,
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
                'No passages in this category.',
                style: TextStyle(color: isHighContrast ? Colors.white : Colors.black),
              ),
            );
          } else {
            final passages = snapshot.data!;
            return ListView.builder(
              itemCount: passages.length,
              itemBuilder: (context, index) {
                final passage = passages[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFF003153)),
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      passage.title,
                      style: TextStyle(
                        color: isHighContrast ? Colors.white : Colors.black,
                      ),
                    ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAccessibilityOptionsSheet,
        backgroundColor: isHighContrast ? Colors.black : null,
        child: Icon(
          Icons.accessibility,
          color: isHighContrast ? Colors.white : Colors.blueAccent,
        ),
      ),
    );
  }
}