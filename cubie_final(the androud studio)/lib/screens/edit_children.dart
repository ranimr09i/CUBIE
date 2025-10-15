import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/child_tile.dart';
import '../routes.dart';
import '../services/children_service.dart';
import '../app_state.dart';

class EditChildrenPage extends StatefulWidget {
  const EditChildrenPage({super.key});

  @override
  State<EditChildrenPage> createState() => _EditChildrenPageState();
}

class _EditChildrenPageState extends State<EditChildrenPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final userID = appState.currentUserID;

    if (userID == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await ChildrenService.getChildren(userID);

      List<Map<String, dynamic>> childrenList = [];

      if (response['children'] != null) {
        for (var child in response['children']) {
          final childMap = <String, dynamic>{};
          child.forEach((key, value) {
            childMap[key.toString()] = value;
          });
          childrenList.add(childMap);
        }
      }

      appState.setChildren(childrenList);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحميل الأطفال: $e')),
      );
    }
  }

  Future<void> _refreshChildren() async {
    await _loadChildren();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ تم تحديث قائمة الأطفال')),
    );
  }

  Future<void> _navigateToEditChild(Map<String, dynamic> child) async {
    final result = await Navigator.pushNamed(
      context,
      Routes.editChild,
      arguments: child,
    );

    if (result == true) {
      await _loadChildren();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final children = appState.children;

    return AppScaffold(
      title: 'تحرير الأطفال',
      showLogo: true,
      centerTitle: false,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              color: const Color(0xff4ab0d1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('عدد الأطفال:', style: TextStyle(color: Colors.white)),
                    Text('${children.length}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: _refreshChildren,
              child: children.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.child_care, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('لا يوجد أطفال', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    Text('أضف طفلاً جديداً', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: children.length,
                itemBuilder: (c, i) {
                  final child = children[i];
                  return ChildTile(
                    name: child['name']?.toString() ?? 'بدون اسم',
                    age: child['age'],
                    gender: child['gender'],
                    onTap: () {},
                    onEdit: () => _navigateToEditChild(child),
                  );
                },
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.pushNamed(context, Routes.addChild);
                if (result == true) {
                  await _loadChildren();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('إضافة طفل'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4ab0d1),
                foregroundColor: const Color(0xff254865),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          )
        ],
      ),
    );
  }
}