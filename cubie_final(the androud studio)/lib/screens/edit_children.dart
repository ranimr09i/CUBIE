
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
    // تحميل البيانات عند فتح الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChildren();
    });
  }

  Future<void> _loadChildren() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final userID = appState.currentUserID;

    if (userID == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // استدعاء الخدمة لجلب القائمة
      final response = await ChildrenService.getChildren(userID);

      List<Map<String, dynamic>> childrenList = [];

      if (response['children'] != null) {
        for (var child in response['children']) {
          // تحويل البيانات إلى Map لضمان التوافق
          final childMap = <String, dynamic>{
            'childID': child['childID'],
            'name': child['name'],
            'age': child['age'],
            'gender': child['gender'],
            'grade': child['grade'] ?? 'KG', // (مهم جداً) قراءة القريد أو وضع افتراضي
          };
          childrenList.add(childMap);
        }
      }

      // تحديث الحالة العامة للتطبيق
      appState.setChildren(childrenList);

    } catch (e) {
      print('❌ فشل تحميل الأطفال: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحميل القائمة: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToEditChild(Map<String, dynamic> child) async {
    print('Navigating to edit child with data: $child'); // للتأكد من البيانات
    final result = await Navigator.pushNamed(
      context,
      Routes.editChild,
      arguments: child, // تمرير بيانات الطفل كاملة (بما فيها القريد)
    );

    // إذا رجعنا وتم التعديل، نعيد تحميل القائمة
    if (result == true) {
      await _loadChildren();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final children = appState.children;

    return AppScaffold(
      title: 'إدارة الأطفال',
      body: Column(
        children: [
          // بطاقة إحصائية بسيطة
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              elevation: 2,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'عدد الأطفال المسجلين:',
                      style: TextStyle(fontSize: 16, color: Color(0xff254865)),
                    ),
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: const Color(0xff4ab0d1),
                      child: Text(
                        '${children.length}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: _loadChildren,
              child: children.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.child_care, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('لا يوجد أطفال مسجلين',
                        style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: children.length,
                itemBuilder: (ctx, i) {
                  final child = children[i];
                  return ChildTile(
                    name: child['name']?.toString() ?? 'بدون اسم',
                    age: child['age'],
                    gender: child['gender'],
                    grade: child['grade']?.toString(), // عرض القريد
                    onTap: () {}, // لا شيء عند الضغط العادي
                    onEdit: () => _navigateToEditChild(child), // التعديل عند الضغط على زر التعديل
                  );
                },
              ),
            ),
          ),

          // زر الإضافة العائم في الأسفل
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.pushNamed(context, Routes.addChild);
                  if (result == true) {
                    await _loadChildren();
                  }
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('إضافة طفل جديد'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4ab0d1),
                  foregroundColor: const Color(0xff254865),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}