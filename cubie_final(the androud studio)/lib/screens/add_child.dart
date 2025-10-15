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
  final _age = TextEditingController();
  String gender = 'ذكر';
  bool _isLoading = false;

  Future<void> _addChild() async {
    if (_name.text.isEmpty || _age.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول')),
      );
      return;
    }

    final age = int.tryParse(_age.text);
    if (age == null || age < 1 || age > 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('العمر يجب أن يكون بين 1 و 12')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final userID = appState.currentUserID;

      if (userID == null) throw Exception('لم يتم تسجيل الدخول');

      print('🔄 إضافة طفل جديد: ${_name.text}, $age, $gender');

      final response = await ChildrenService.addChild(userID, _name.text, age, gender);

      final newChild = {
        'childID': response['childID'],
        'name': _name.text,
        'age': age,
        'gender': gender == 'ذكر' ? 'Male' : 'Female',
      };
      appState.addChild(newChild);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم إضافة الطفل بنجاح')),
      );

      Navigator.pop(context, true);

    } catch (e) {
      print('❌ فشل إضافة الطفل: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إضافة الطفل: $e')),
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
        child: Column(
          children: [
            TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'اسم الطفل',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                )
            ),
            const SizedBox(height: 8),
            TextField(
                controller: _age,
                decoration: const InputDecoration(
                  labelText: 'العمر',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Text('الجنس:', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: gender,
                items: const [
                  DropdownMenuItem(value: 'ذكر', child: Text('ذكر')),
                  DropdownMenuItem(value: 'أنثى', child: Text('أنثى')),
                ],
                onChanged: (v) => setState(() => gender = v ?? 'ذكر'),
              ),
            ]),
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
    );
  }
}