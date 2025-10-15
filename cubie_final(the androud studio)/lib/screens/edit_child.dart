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
  final _age = TextEditingController();
  String gender = 'ذكر';
  bool _isLoading = false;
  bool _isDeleting = false;
  Map<String, dynamic>? _childData;

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
        print('📝 البيانات المستلمة: $args');

        final dynamicArgs = args as Map<dynamic, dynamic>;
        final convertedArgs = <String, dynamic>{};

        dynamicArgs.forEach((key, value) {
          convertedArgs[key.toString()] = value;
        });

        setState(() {
          _childData = convertedArgs;
          _name.text = convertedArgs['name']?.toString() ?? '';
          _age.text = convertedArgs['age']?.toString() ?? '';

          final dynamicGender = convertedArgs['gender'];
          if (dynamicGender == 'Male' || dynamicGender == 'ذكر') {
            gender = 'ذكر';
          } else if (dynamicGender == 'Female' || dynamicGender == 'أنثى') {
            gender = 'أنثى';
          } else {
            gender = 'ذكر';
          }
        });

        print('✅ بيانات الطفل المحملة: $_childData');
      } else {
        print('⚠️ لم يتم استلام بيانات الطفل');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ لم يتم استلام بيانات الطفل')),
        );
      }
    } catch (e) {
      print('❌ خطأ في تحميل بيانات الطفل: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ خطأ في تحميل بيانات الطفل: $e')),
      );
    }
  }

  Future<void> _updateChild() async {
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

    if (_childData == null || _childData!['childID'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ بيانات الطفل غير صالحة')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final childID = _childData!['childID'];
      print('🔄 تحديث الطفل: $childID');

      await ChildrenService.editChild(
          childID is int ? childID : int.parse(childID.toString()),
          _name.text,
          age,
          gender
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم تحديث الطفل بنجاح')),
      );

      Navigator.pop(context);

    } catch (e) {
      print('❌ فشل تحديث الطفل: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحديث الطفل: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteChild() async {
    if (_childData == null || _childData!['childID'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ بيانات الطفل غير صالحة')),
      );
      return;
    }

    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الطفل'),
        content: Text(
          'هل أنت متأكد من حذف الطفل "${_childData!['name']}"؟\n\nهذا الإجراء لا يمكن التراجع عنه.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: Color(0xff4ab0d1))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmDelete != true) return;

    setState(() => _isDeleting = true);

    try {
      final childID = _childData!['childID'];
      print('🗑️ حذف الطفل: $childID');

      await ChildrenService.deleteChild(
          childID is int ? childID : int.parse(childID.toString())
      );

      final appState = Provider.of<AppState>(context, listen: false);
      appState.removeChild(childID);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم حذف الطفل بنجاح')),
      );

      Navigator.pop(context, true);

    } catch (e) {
      print('❌ فشل حذف الطفل: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل حذف الطفل: $e')),
      );
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  void _showDeleteConfirmation() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'تأكيد الحذف',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 12),
            Text(
              'هل أنت متأكد من حذف الطفل "${_childData!['name']}"؟',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'سيتم حذف جميع البيانات المرتبطة بهذا الطفل ولا يمكن استعادتها.',
              style: TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xff254865),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _deleteChild,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text('حذف', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_childData == null) {
      return AppScaffold(
        title: 'تعديل الطفل',
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري تحميل بيانات الطفل...'),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      title: 'تعديل الطفل',
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            Card(
              color: const Color(0xffe6eceb),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.child_care, color: Color(0xff4ab0d1)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'تعديل بيانات: ${_childData!['name']}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff254865)
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_childData!['childID'] != null)
                      Text(
                        'رقم الطفل: ${_childData!['childID']}',
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'اسم الطفل',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.person, color: Color(0xff4ab0d1)),
                )
            ),
            const SizedBox(height: 12),

            TextField(
                controller: _age,
                decoration: const InputDecoration(
                  labelText: 'العمر',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.cake, color: Color(0xff4ab0d1)),
                ),
                keyboardType: TextInputType.number
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  const Icon(Icons.face, color: Color(0xff4ab0d1)),
                  const SizedBox(width: 12),
                  const Text('الجنس:', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: gender,
                    items: const [
                      DropdownMenuItem(value: 'ذكر', child: Text('👦 ذكر')),
                      DropdownMenuItem(value: 'أنثى', child: Text('👧 أنثى')),
                    ],
                    onChanged: (v) => setState(() => gender = v ?? 'ذكر'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _updateChild,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4ab0d1),
                  foregroundColor: const Color(0xff254865),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: _isLoading
                    ? const Text('جاري الحفظ...')
                    : const Text('حفظ التعديلات', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isDeleting ? null : _showDeleteConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.red.withOpacity(0.3)),
                ),
                icon: _isDeleting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                    : const Icon(Icons.delete_outline),
                label: _isDeleting
                    ? const Text('جاري الحذف...', style: TextStyle(color: Colors.red))
                    : const Text('حذف الطفل', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('العودة دون حفظ', style: TextStyle(color: Colors.black54)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    super.dispose();
  }
}