import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firebase_service.dart';
import '../models/tag_group.dart';
import '../models/category_model.dart';
import 'category_page.dart';
import 'passage_page.dart';
import '../providers/settings_provider.dart';
import '../widgets/tag_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseService _service = FirebaseService();

  /* ───────── small in-memory cache ───────── */
  Future<List<TagGroup>>? _groupsFuture;
  List<TagGroup>?        _groupsCache;
  DateTime?              _lastFetch;
  final _cacheDuration = const Duration(minutes: 10);

  Future<List<TagGroup>> _getGroups() async {
    if (_groupsCache != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheDuration) {
      return _groupsCache!;
    }
    final data = await _service.getTagGroups();
    _groupsCache = data;
    _lastFetch   = DateTime.now();
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
        _lastFetch   = DateTime.now();
        return value;
      });
    });
  }

  /* ───────── open either CategoryPage or a direct Passage ───────── */
  Future<void> _handleCategoryTap(TagGroup group, Category cat) async {
    if (!group.tag.skipCategory) {
      // normal flow
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryPage(categoryName: cat.name),
        ),
      );
      return;
    }

    /* direct-to-passage flow */
    final settings      = context.read<SettingsProvider>();
    final bool contrast = settings.isHighContrast;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
              contrast ? Colors.white : Colors.black),
        ),
      ),
    );

    PassagePage? page;

    // 1️⃣ explicit passage id stored on the category
    final id = cat.directPassageId;
    if (id != null && id.isNotEmpty) {
      final p = await _service.getPassageById(id);
      if (p != null) page = PassagePage(passage: p);
    }

    // 2️⃣ fallback → first passage in that category
    if (page == null) {
      final list = await _service.getPassagesForCategory(cat.name);
      if (list.isNotEmpty) page = PassagePage(passage: list.first);
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // remove spinner

    if (page == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('此分類沒有可顯示的章節')),
      );
      return;
    }

    // !! page is guaranteed non-null here
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page!), // ← null-assertion fix
    );
  }

  /* ──────────────────────────── UI ──────────────────────────── */

  @override
  Widget build(BuildContext context) {
    final settings      = context.watch<SettingsProvider>();
    final bool contrast = settings.isHighContrast;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grace Abounds'),
        backgroundColor: contrast ? Colors.black : null,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: contrast ? Colors.white : null),
            onPressed: _forceRefresh,
          ),
        ],
      ),
      backgroundColor: contrast ? Colors.black : Colors.white,
      body: FutureBuilder<List<TagGroup>>(
        future: _groupsFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    contrast ? Colors.white : Colors.black),
              ),
            );
          }
          if (snap.hasError) {
            return Center(
              child: Text('Error: ${snap.error}',
                  style: TextStyle(
                      color: contrast ? Colors.white : Colors.black)),
            );
          }

          final groups = snap.data ?? [];
          if (groups.isEmpty) {
            return Center(
              child: Text('No categories available',
                  style: TextStyle(
                      color: contrast ? Colors.white : Colors.black)),
            );
          }

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, idx) {
              final group = groups[idx];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /* tag header */
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TagWidget(tag: group.tag.name),
                  ),

                  /* category list */
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
                        title: Text(cat.name,
                            style: TextStyle(
                                color:
                                    contrast ? Colors.white : Colors.black)),
                        subtitle: Text('(${cat.passageCount} 章)',
                            style: TextStyle(
                                color: contrast
                                    ? Colors.white70
                                    : Colors.black54)),
                        onTap: () => _handleCategoryTap(group, cat),
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
        backgroundColor: contrast ? Colors.black : null,
        child: Icon(Icons.accessibility,
            color: contrast ? Colors.white : Colors.blueAccent),
      ),
    );
  }

  /* ───────── bottom-sheet: high-contrast toggle ───────── */

  void _showAccessibilityOptionsSheet() {
    final settings = context.read<SettingsProvider>();

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
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