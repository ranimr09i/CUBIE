import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_scaffold.dart';
import '../services/children_service.dart';
import '../app_state.dart';

class AddChildPage extends StatefulWidget {
  const AddChildPage({super.key});

  @override
  State<AddChildPage> createState() => _AddChildPageState();
}

class _AddChildPageState extends State<AddChildPage> {
  final _name = TextEditingController();
  int _age = 4;
  String _grade = 'KG';
  String _gender = 'ذكر'; // العرض بالعربي
  bool _isLoading = false;

  final List<int> _ageList = [4, 5, 6, 7, 8, 9, 10, 11, 12];
  final List<String> _gradeLevels = ['KG', 'G1', 'G2', 'G3', 'G4', 'G5', 'G6'];

  Future<void> _addChild() async {
    if (_name.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم الطفل')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final userID = appState.currentUserID;

      if (userID == null) throw Exception('لم يتم تسجيل الدخول');

      // تحويل الجنس للإنجليزية للباك اند
      final genderToSend = _gender == 'ذكر' ? 'Male' : 'Female';

      final response = await ChildrenService.addChild(
        userID,
        _name.text,
        _age,
        genderToSend,
        _grade,
      );

      // تحديث الحالة المحلية
      final newChild = {
        'childID': response['childID'],
        'name': _name.text,
        'age': _age,
        'gender': genderToSend, // حفظ بالإنجليزية ليتوافق مع القراءة
        'grade': _grade,
      };
      appState.addChild(newChild);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم إضافة الطفل بنجاح')),
      );

      Navigator.pop(context, true);

    } catch (e) {
      print('❌ فشل إضافة الطفل: $e');
      String errorMsg = 'فشل إضافة الطفل';
      if (e.toString().contains('422')) errorMsg += ': تأكد من البيانات المدخلة';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'إضافة طفل',
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
                  fillColor: Colors.white,
                    prefixIcon: Icon(Icons.cake, color: Color(0xff4ab0d1))
                ),
                items: _ageList.map((int age) {
                  return DropdownMenuItem<int>(
                    value: age,
                    child: Text('$age سنوات'),
                  );
                }).toList(),
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
                items: _gradeLevels.map((String grade) {
                  return DropdownMenuItem<String>(
                    value: grade,
                    child: Text(grade),

                  );
                }).toList(),
                onChanged: (v) => setState(() => _grade = v ?? 'KG'),
              ),

              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.grey),
                ),
                child: Row(children: [
                  const Icon(Icons.face, color: Color(0xff4ab0d1)),
                  const Text('الجنس:', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _gender,
                    underline: Container(),
                    items: const [
                      DropdownMenuItem(value: 'ذكر', child: Text('👦ذكر')),
                      DropdownMenuItem(value: 'أنثى', child: Text('👧أنثى')),
                    ],
                    onChanged: (v) => setState(() => _gender = v ?? 'ذكر'),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addChild,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff4ab0d1),
                    foregroundColor: const Color(0xff254865),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('إضافة الطفل'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}