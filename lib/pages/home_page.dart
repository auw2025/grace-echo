import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firebase_service.dart';
import '../models/tag_group.dart';
import '../models/category_model.dart';
import 'category_page.dart';
import '../providers/settings_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseService _service = FirebaseService();

  /// --- simple 10-minute cache ------------------------------------------------
  Future<List<TagGroup>>? _groupsFuture;
  List<TagGroup>? _groupsCache;
  DateTime? _lastFetch;
  final _cacheDuration = const Duration(minutes: 10);

  Future<List<TagGroup>> _getGroups() async {
    if (_groupsCache != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheDuration) {
      return _groupsCache!;
    }

    final data = await _service.getTagGroups();
    _groupsCache = data;
    _lastFetch = DateTime.now();
    return data;
  }

  @override
  void initState() {
    super.initState();
    _groupsFuture = _getGroups();
  }

  void _forceRefresh() {
    setState(() {
      _groupsFuture = _service.getTagGroups().then((value) {
        _groupsCache = value;
        _lastFetch = DateTime.now();
        return value;
      });
    });
  }

  /* ─────────────────────────────  UI  ───────────────────────────── */

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final bool highContrast = settings.isHighContrast;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grace Abounds'),
        backgroundColor: highContrast ? Colors.black : null,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh,
                color: highContrast ? Colors.white : null),
            tooltip: 'Refresh',
            onPressed: _forceRefresh,
          ),
        ],
      ),
      backgroundColor: highContrast ? Colors.black : Colors.white,
      body: FutureBuilder<List<TagGroup>>(
        future: _groupsFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  highContrast ? Colors.white : Colors.black,
                ),
              ),
            );
          }

          if (snap.hasError) {
            return Center(
              child: Text(
                'Error: ${snap.error}',
                style: TextStyle(
                  color: highContrast ? Colors.white : Colors.black,
                ),
              ),
            );
          }

          final groups = snap.data ?? [];
          if (groups.isEmpty) {
            return Center(
              child: Text(
                'No categories available',
                style: TextStyle(
                  color: highContrast ? Colors.white : Colors.black,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, groupIndex) {
              final TagGroup group = groups[groupIndex];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag header
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      group.tag.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: highContrast ? Colors.white : Colors.blueAccent,
                      ),
                    ),
                  ),
                  // Categories under this tag
                  ...group.categories.map(
                    (Category cat) => Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFF003153)),
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          cat.name,
                          style: TextStyle(
                            color:
                                highContrast ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          '(${cat.passageCount} 章)',
                          style: TextStyle(
                            color: highContrast
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryPage(
                              categoryName: cat.name,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAccessibilityOptionsSheet,
        backgroundColor: highContrast ? Colors.black : null,
        child: Icon(
          Icons.accessibility,
          color: highContrast ? Colors.white : Colors.blueAccent,
        ),
      ),
    );
  }

  /* ───────────────  bottom-sheet with high-contrast switch  ─────────────── */

  void _showAccessibilityOptionsSheet() {
    final settings = context.read<SettingsProvider>();

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('高對比模式', style: TextStyle(fontSize: 16)),
              Switch(
                value: settings.isHighContrast,
                onChanged: settings.toggleHighContrast,
              ),
            ],
          ),
        ),
      ),
    );
  }
}