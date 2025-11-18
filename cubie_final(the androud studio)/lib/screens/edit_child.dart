
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_scaffold.dart';
import '../services/children_service.dart';
import '../app_state.dart';

class EditChildPage extends StatefulWidget {
  const EditChildPage({super.key});

  @override
  State<EditChildPage> createState() => _EditChildPageState();
}

class _EditChildPageState extends State<EditChildPage> {
  final _name = TextEditingController();
  int _age = 4;
  String _grade = 'KG';
  String _gender = 'ذكر';

  bool _isLoading = false;
  bool _isDeleting = false;
  Map<String, dynamic>? _childData;

  final List<int> _ageList = [4, 5, 6, 7, 8, 9, 10, 11, 12];
  final List<String> _gradeLevels = ['KG', 'G1', 'G2', 'G3', 'G4', 'G5', 'G6'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChildData();
    });
  }

  void _loadChildData() {
    try {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null) {
        final dynamicArgs = args as Map<dynamic, dynamic>;
        final convertedArgs = <String, dynamic>{};
        dynamicArgs.forEach((key, value) {
          convertedArgs[key.toString()] = value;
        });

        setState(() {
          _childData = convertedArgs;
          _name.text = convertedArgs['name']?.toString() ?? '';

          // تحميل العمر والقريد
          _age = convertedArgs['age'] as int? ?? 4;
          if (!_ageList.contains(_age)) _age = 4;

          _grade = convertedArgs['grade']?.toString() ?? 'KG';
          if (!_gradeLevels.contains(_grade)) _grade = 'KG';

          // تحميل الجنس وتحويله للعرض
          final dynamicGender = convertedArgs['gender'];
          if (dynamicGender == 'Male' || dynamicGender == 'ذكر') {
            _gender = 'ذكر';
          } else {
            _gender = 'أنثى';
          }
        });
      }
    } catch (e) {
      print('❌ خطأ في تحميل بيانات الطفل: $e');
    }
  }

  Future<void> _updateChild() async {
    if (_name.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال الاسم')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final childID = _childData!['childID'];
      final childIDInt = childID is int ? childID : int.parse(childID.toString());

      final genderToSend = _gender == 'ذكر' ? 'Male' : 'Female';

      // سيقوم السرفيس بتحويل الأرقام لنصوص، لذا لا تقلق
      await ChildrenService.editChild(
          childIDInt,
          _name.text,
          _age,
          genderToSend,
          _grade
      );

      final appState = Provider.of<AppState>(context, listen: false);
      appState.updateChild(childIDInt, {
        'childID': childIDInt,
        'name': _name.text,
        'age': _age,
        'gender': genderToSend,
        'grade': _grade,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم تحديث الطفل بنجاح')),
      );

      Navigator.pop(context, true);

    } catch (e) {
      print('❌ فشل تحديث الطفل: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التحديث: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteChild() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الطفل'),
        content: const Text('هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    try {
      final childID = _childData!['childID'];
      final childIDInt = childID is int ? childID : int.parse(childID.toString());

      await ChildrenService.deleteChild(childIDInt);

      final appState = Provider.of<AppState>(context, listen: false);
      appState.removeChild(childIDInt);

      Navigator.pop(context, true);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الحذف: $e')),
      );
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_childData == null) return const AppScaffold(title: 'تعديل', body: Center(child: CircularProgressIndicator()));

    return AppScaffold(
      title: 'تعديل الطفل',
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'اسم الطفل',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                      prefixIcon: Icon(Icons.person, color: Color(0xff4ab0d1))
                  )
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                value: _age,
                decoration: const InputDecoration(
                    labelText: 'العمر',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,prefixIcon: Icon(Icons.cake, color: Color(0xff4ab0d1))),

                items: _ageList.map((e) => DropdownMenuItem(value: e, child: Text('$e سنوات'))).toList(),
                onChanged: (v) => setState(() => _age = v ?? 4),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _grade,
                decoration: const InputDecoration(
                    labelText: 'المستوى الدراسي',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.school, color: Color(0xff4ab0d1))
                ),
                items: _gradeLevels.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _grade = v ?? 'KG'),
              ),

              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                child: Row(
                  children: [
                    const Icon(Icons.face, color: Color(0xff4ab0d1)),
                    const Text('الجنس: '),
                    DropdownButton<String>(
                      value: _gender,
                      underline: Container(),
                      items: const [DropdownMenuItem(value: 'ذكر', child: Text('👦ذكر')), DropdownMenuItem(value: 'أنثى', child: Text('👧أنثى'))],
                      onChanged: (v) => setState(() => _gender = v ?? 'ذكر'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateChild,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff4ab0d1), padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading ? const CircularProgressIndicator() : const Text('حفظ التعديلات', style: TextStyle(color: Color(0xff254865))),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isDeleting ? null : _deleteChild,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isDeleting ? const CircularProgressIndicator() : const Text('حذف الطفل', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}