// lib/screens/connect_cube.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../services/bluetooth_manager.dart'; // استيراد المدير الجديد
import '../widgets/app_scaffold.dart';

class ConnectCubePage extends StatefulWidget {
  const ConnectCubePage({super.key});

  @override
  State<ConnectCubePage> createState() => _ConnectCubePageState();
}

class _ConnectCubePageState extends State<ConnectCubePage> {
  final btManager = BluetoothManager.instance;
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;
  List<BluetoothDiscoveryResult> results = [];
  bool isDiscovering = false;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  void _startDiscovery() {
    setState(() {
      isDiscovering = true;
      results.clear();
    });

    _streamSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      // تجنب إضافة أجهزة بدون اسم أو مكررة
      final existingIndex = results.indexWhere((element) => element.device.address == r.device.address);
      if (existingIndex < 0 && r.device.name != null) {
        setState(() {
          results.add(r);
        });
      }
    });

    _streamSubscription!.onDone(() {
      setState(() {
        isDiscovering = false;
      });
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'الاتصال بالمكعب',
      body: Column(
        children: [
          // --- 1. عرض حالة الاتصال الحالية ---
          ValueListenableBuilder<bool>(
            valueListenable: btManager.isConnectedNotifier,
            builder: (context, isConnected, child) {
              if (isConnected) {
                return Container(
                  color: Colors.green.withOpacity(0.1),
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'متصل حاليًا بـ: ${btManager.deviceName ?? 'المكعب'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: () => btManager.disconnect(),
                        child: const Text('قطع الاتصال'),
                      ),
                    ],
                  ),
                );
              }
              // إذا لم يكن متصلاً، لا تعرض شيئًا
              return const SizedBox.shrink();
            },
          ),

          // --- 2. زر إعادة البحث وحالة البحث ---
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isDiscovering ? 'جاري البحث عن أجهزة...' : 'الأجهزة المتاحة:',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (isDiscovering)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _startDiscovery,
                  ),
              ],
            ),
          ),

          // --- 3. قائمة الأجهزة التي تم العثور عليها ---
          Expanded(
            child: results.isEmpty && !isDiscovering
                ? const Center(child: Text('لم يتم العثور على أجهزة.\nتأكد من أن البلوتوث والمكعب يعملان.'))
                : ListView.builder(
              itemCount: results.length,
              itemBuilder: (BuildContext context, index) {
                BluetoothDiscoveryResult result = results[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.widgets, color: Color(0xff4ab0d1)),
                    title: Text(result.device.name ?? 'جهاز غير معروف'),
                    subtitle: Text(result.device.address),
                    trailing: ElevatedButton(
                      child: const Text('اتصال'),
                      onPressed: () async {
                        // إيقاف البحث قبل محاولة الاتصال
                        _streamSubscription?.cancel();
                        setState(() => isDiscovering = false);

                        bool success = await btManager.connect(result.device);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تم الاتصال بنجاح بـ ${result.device.name}')),
                          );
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('فشل الاتصال، حاول مرة أخرى')),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}