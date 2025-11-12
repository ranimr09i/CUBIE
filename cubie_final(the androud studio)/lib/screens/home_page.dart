
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/child_tile.dart';
import '../routes.dart';
import '../services/children_service.dart';
import '../app_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  int selectedIndex = 0;

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
      print('🔄 جلب الأطفال للمستخدم: $userID');
      final response = await ChildrenService.getChildren(userID);

      print('📦 استجابة الباكند كاملة: $response');

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

      print('✅ تم تحميل ${childrenList.length} طفل');

      if (childrenList.isNotEmpty) {
        _selectChild(0, childrenList);
      }

    } catch (e) {
      print('❌ فشل تحميل الأطفال: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحميل الأطفال: $e')),
      );
    }
  }

  void _selectChild(int i, [List<Map<String, dynamic>>? childrenList]) {
    final appState = Provider.of<AppState>(context, listen: false);
    final children = childrenList ?? appState.children;

    if (i >= 0 && i < children.length) { // (تحسين بسيط لمنع الأخطاء)
      setState(() => selectedIndex = i);
      final child = children[i];
      appState.setSelectedChild(child['childID'], child);
      print('✅ تم اختيار الطفل: ${child['name']}');
    }
  }


  Future<void> _refreshChildren() async {
    await _loadChildren();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ تم تحديث قائمة الأطفال')),
    );
  }

  void _handleChildUpdates() {
    final appState = Provider.of<AppState>(context);
    final children = appState.children;

    if (children.isNotEmpty && (selectedIndex >= children.length || appState.selectedChildID == null)) {
      // (تحسين: إذا تم حذف الطفل المختار، اختر أول طفل)
      _selectChild(0, children);
    }
  }


  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    // (تعديل بسيط لضمان عدم حدوث خطأ Index out of range)
    final children = appState.children;
    final selected = (children.isNotEmpty && selectedIndex < children.length)
        ? children[selectedIndex]
        : null;

    _handleChildUpdates();

    return AppScaffold(
      title: 'الصفحة الرئيسية',
      showLogo: true,
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, Routes.settings),
          icon: const Icon(Icons.settings, color: Color(0xff8dd6bb)),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _refreshChildren,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            const SizedBox(height: 12),

            if (selected != null)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: Colors.white,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xff4ab0d1),
                    child: Text(
                      selected['name'] != null && selected['name'].isNotEmpty
                          ? selected['name'][0]
                          : '?',
                      style: const TextStyle(color: Color(0xff254865)),
                    ),
                    radius: 28,
                  ),
                  title: Text(
                      selected['name']?.toString() ?? 'بدون اسم',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff254865))
                  ),
                  // (1) تحديث الـ Subtitle هنا
                  subtitle: Text(
                      'العمر: ${selected['age']?.toString() ?? '0'} • المستوى: ${selected['grade']?.toString() ?? 'KG'}',
                      style: const TextStyle(color: Colors.black54)
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      if (selected['childID'] != null) {
                        Navigator.pushNamed(context, Routes.createStory);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('❌ لم يتم اختيار طفل')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff4ab0d1),
                      foregroundColor: const Color(0xff254865),
                    ),
                    child: const Text('ابدأ قصة'),
                  ),
                ),
              ),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الأطفال', style: TextStyle(fontSize: 16, color: Color(0xff254865))),
                  Text('${children.length} طفل', style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: children.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.child_care, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('لا يوجد أطفال', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    Text('أضف طفلاً جديداً للبدء', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: children.length,
                itemBuilder: (c, i) {
                  final child = children[i];
                  return GestureDetector(
                    onTap: () => _selectChild(i),
                    child: Container(
                      color: i == selectedIndex
                          ? const Color(0xff4ab0d1).withOpacity(0.1)
                          : null,
                      child: ChildTile(
                        name: child['name']?.toString() ?? 'بدون اسم',
                        age: child['age'],
                        gender: child['gender'],
                        grade: child['grade']?.toString(), // (2) تمرير القريد هنا
                        onTap: () => _selectChild(i),
                        onEdit: () => _navigateToEditChild(child),
                      ),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, Routes.connectCube),
                      icon: const Icon(Icons.bluetooth, color: Color(0xff254865)),
                      label: const Text('اتصل بالمكعب',
                          style: TextStyle(color: Color(0xff254865))),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff4ab0d1),
                        foregroundColor: const Color(0xff254865),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () => Navigator.pushNamed(context, Routes.history),
                    icon: const Icon(Icons.history, color: Color(0xff4ab0d1)),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToEditChild(Map<String, dynamic> child) async {
    final result = await Navigator.pushNamed(
      context,
      Routes.editChild,
      arguments: child,
    );

    if (result == true) {
      print('🔄 إعادة تحميل الأطفال بعد التعديل/الحذف');
      await _loadChildren(); // (أفضل أن نعيد التحميل لضمان التزامن)
    }
  }
}