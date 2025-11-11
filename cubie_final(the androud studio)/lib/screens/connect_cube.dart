// lib/screens/connect_cube.dart
//
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
// import '../services/bluetooth_manager.dart'; // استيراد المدير الجديد
// import '../widgets/app_scaffold.dart';
//
// class ConnectCubePage extends StatefulWidget {
//   const ConnectCubePage({super.key});
//
//   @override
//   State<ConnectCubePage> createState() => _ConnectCubePageState();
// }
//
// class _ConnectCubePageState extends State<ConnectCubePage> {
//   final btManager = BluetoothManager.instance;
//   StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;
//   List<BluetoothDiscoveryResult> results = [];
//   bool isDiscovering = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _startDiscovery();
//   }
//
//   void _startDiscovery() {
//     setState(() {
//       isDiscovering = true;
//       results.clear();
//     });
//
//     _streamSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
//       // تجنب إضافة أجهزة بدون اسم أو مكررة
//       final existingIndex = results.indexWhere((element) => element.device.address == r.device.address);
//       if (existingIndex < 0 && r.device.name != null) {
//         setState(() {
//           results.add(r);
//         });
//       }
//     });
//
//     _streamSubscription!.onDone(() {
//       setState(() {
//         isDiscovering = false;
//       });
//     });
//   }
//
//   @override
//   void dispose() {
//     _streamSubscription?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AppScaffold(
//       title: 'الاتصال بالمكعب',
//       body: Column(
//         children: [
//           // --- 1. عرض حالة الاتصال الحالية ---
//           ValueListenableBuilder<bool>(
//             valueListenable: btManager.isConnectedNotifier,
//             builder: (context, isConnected, child) {
//               if (isConnected) {
//                 return Container(
//                   color: Colors.green.withOpacity(0.1),
//                   padding: const EdgeInsets.all(12.0),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.check_circle, color: Colors.green),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Text(
//                           'متصل حاليًا بـ: ${btManager.deviceName ?? 'المكعب'}',
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                       TextButton(
//                         onPressed: () => btManager.disconnect(),
//                         child: const Text('قطع الاتصال'),
//                       ),
//                     ],
//                   ),
//                 );
//               }
//               // إذا لم يكن متصلاً، لا تعرض شيئًا
//               return const SizedBox.shrink();
//             },
//           ),
//
//           // --- 2. زر إعادة البحث وحالة البحث ---
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   isDiscovering ? 'جاري البحث عن أجهزة...' : 'الأجهزة المتاحة:',
//                   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 if (isDiscovering)
//                   const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   )
//                 else
//                   IconButton(
//                     icon: const Icon(Icons.refresh),
//                     onPressed: _startDiscovery,
//                   ),
//               ],
//             ),
//           ),
//
//           // --- 3. قائمة الأجهزة التي تم العثور عليها ---
//           Expanded(
//             child: results.isEmpty && !isDiscovering
//                 ? const Center(child: Text('لم يتم العثور على أجهزة.\nتأكد من أن البلوتوث والمكعب يعملان.'))
//                 : ListView.builder(
//               itemCount: results.length,
//               itemBuilder: (BuildContext context, index) {
//                 BluetoothDiscoveryResult result = results[index];
//                 return Card(
//                   margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   child: ListTile(
//                     leading: const Icon(Icons.widgets, color: Color(0xff4ab0d1)),
//                     title: Text(result.device.name ?? 'جهاز غير معروف'),
//                     subtitle: Text(result.device.address),
//                     trailing: ElevatedButton(
//                       child: const Text('اتصال'),
//                       onPressed: () async {
//                         // إيقاف البحث قبل محاولة الاتصال
//                         _streamSubscription?.cancel();
//                         setState(() => isDiscovering = false);
//
//                         bool success = await btManager.connect(result.device);
//                         if (success && mounted) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(content: Text('تم الاتصال بنجاح بـ ${result.device.name}')),
//                           );
//                         } else if (mounted) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(content: Text('فشل الاتصال، حاول مرة أخرى')),
//                           );
//                         }
//                       },
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:provider/provider.dart';
// import '../services/bluetooth_manager.dart';
// import 'dart:async'; // لـ Timer
//
// class ConnectCubeScreen extends StatefulWidget {
//   const ConnectCubeScreen({Key? key}) : super(key: key);
//
//   @override
//   State<ConnectCubeScreen> createState() => _ConnectCubeScreenState();
// }
//
// class _ConnectCubeScreenState extends State<ConnectCubeScreen> {
//   late BluetoothManager _bleManager;
//   Timer? _scanTimer;
//
//   @override
//   void initState() {
//     super.initState();
//     _bleManager = Provider.of<BluetoothManager>(context, listen: false);
//
//     // اطلب تشغيل البلوتوث إذا كان طافياً
//     _bleManager.adapterStateSubscription?.onData((state) {
//       if (state == BluetoothAdapterState.off) {
//         if (mounted) {
//           FlutterBluePlus.turnOn();
//         }
//       }
//     });
//
//     // ابدأ البحث فوراً
//     _startScan();
//   }
//
//   @override
//   void dispose() {
//     _scanTimer?.cancel(); // أوقف التايمر عند الخروج
//     _bleManager.stopScan();
//     super.dispose();
//   }
//
//   void _startScan() {
//     _bleManager.startScan();
//     // إيقاف البحث آلياً بعد 5 ثواني
//     _scanTimer?.cancel();
//     _scanTimer = Timer(Duration(seconds: 5), () {
//       _bleManager.stopScan();
//     });
//   }
//
//   Future<void> _connectToDevice(BluetoothDevice device) async {
//     // أوقف البحث قبل الاتصال
//     _bleManager.stopScan();
//     _scanTimer?.cancel();
//
//     // (عرض مؤشر تحميل أثناء الاتصال)
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => Center(child: CircularProgressIndicator()),
//     );
//
//     try {
//       await _bleManager.connectToDevice(device);
//
//       // بعد الاتصال الناجح، أغلق مؤشر التحميل وارجع للشاشة السابقة
//       if (mounted) {
//         Navigator.pop(context); // لإغلاق مؤشر التحميل
//         Navigator.pop(context); // للرجوع للشاشة السابقة
//       }
//     } catch (e) {
//       // إذا فشل الاتصال
//       if (mounted) {
//         Navigator.pop(context); // لإغلاق مؤشر التحميل
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to connect: $e')),
//         );
//       }
//     }
//   }
//
//   Widget _buildDeviceTile(ScanResult result) {
//     bool isCubie = result.device.platformName.toUpperCase() == "CUBIE";
//
//     return ListTile(
//       title: Text(
//         result.device.platformName.isNotEmpty
//             ? result.device.platformName
//             : 'Unknown Device',
//       ),
//       subtitle: Text(result.device.remoteId.toString()),
//       leading: Icon(
//         isCubie ? Icons.smart_toy : Icons.bluetooth,
//         color: isCubie ? Colors.blue : Colors.grey,
//       ),
//       trailing: Text('${result.rssi} dBm'), // قوة الإشارة
//       onTap: isCubie ? () => _connectToDevice(result.device) : null,
//       enabled: isCubie,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Connect to CUBIE'),
//         actions: [
//           // زر لإعادة البحث
//           Consumer<BluetoothManager>(
//             builder: (context, manager, child) {
//               if (manager.isScanning) {
//                 return Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
//                   ),
//                 );
//               }
//               return IconButton(
//                 icon: Icon(Icons.refresh),
//                 onPressed: _startScan,
//               );
//             },
//           ),
//         ],
//       ),
//       body: Consumer<BluetoothManager>(
//         builder: (context, manager, child) {
//           if (manager.adapterState != BluetoothAdapterState.on) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text('Bluetooth is OFF', style: TextStyle(fontSize: 18, color: Colors.red)),
//                   SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: () => FlutterBluePlus.turnOn(),
//                     child: Text('Turn On Bluetooth'),
//                   )
//                 ],
//               ),
//             );
//           }
//
//           if (manager.scanResults.isEmpty && !manager.isScanning) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text('No devices found.', style: TextStyle(fontSize: 16)),
//                   SizedBox(height: 10),
//                   Text('Tap refresh to scan again.', style: TextStyle(color: Colors.grey)),
//                 ],
//               ),
//             );
//           }
//
//           // عرض الأجهزة التي تم العثور عليها
//           return ListView.builder(
//             itemCount: manager.scanResults.length,
//             itemBuilder: (context, index) {
//               return _buildDeviceTile(manager.scanResults[index]);
//             },
//           );
//         },
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:provider/provider.dart';
// import '../services/bluetooth_manager.dart';
// import 'dart:async'; // لـ Timer
//
// class ConnectCubeScreen extends StatefulWidget {
//   const ConnectCubeScreen({Key? key}) : super(key: key);
//
//   @override
//   State<ConnectCubeScreen> createState() => _ConnectCubeScreenState();
// }
//
// class _ConnectCubeScreenState extends State<ConnectCubeScreen> {
//   late BluetoothManager _bleManager;
//   Timer? _scanTimer;
//
//   @override
//   void initState() {
//     super.initState();
//     _bleManager = Provider.of<BluetoothManager>(context, listen: false);
//
//     // اطلب تشغيل البلوتوث إذا كان طافياً
//     // !! --- (التعديل هنا) --- !!
//     // (تم تغيير الاسم من _adapterStateSubscription إلى adapterStateSubscription)
//     _bleManager.adapterStateSubscription?.onData((state) {
//       // !! --- (نهاية التعديل) --- !!
//       if (state == BluetoothAdapterState.off) {
//         if (mounted) {
//           FlutterBluePlus.turnOn();
//         }
//       }
//     });
//
//     // ابدأ البحث فوراً
//     _startScan();
//   }
//
//   @override
//   void dispose() {
//     _scanTimer?.cancel(); // أوقف التايمر عند الخروج
//     _bleManager.stopScan();
//     super.dispose();
//   }
//
//   void _startScan() {
//     _bleManager.startScan();
//     // إيقاف البحث آلياً بعد 5 ثواني
//     _scanTimer?.cancel();
//     _scanTimer = Timer(Duration(seconds: 5), () {
//       _bleManager.stopScan();
//     });
//   }
//
//   Future<void> _connectToDevice(BluetoothDevice device) async {
//     // أوقف البحث قبل الاتصال
//     _bleManager.stopScan();
//     _scanTimer?.cancel();
//
//     // (عرض مؤشر تحميل أثناء الاتصال)
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => Center(child: CircularProgressIndicator()),
//     );
//
//     try {
//       await _bleManager.connectToDevice(device);
//
//       // بعد الاتصال الناجح، أغلق مؤشر التحميل وارجع للشاشة السابقة
//       if (mounted) {
//         Navigator.pop(context); // لإغلاق مؤشر التحميل
//         Navigator.pop(context); // للرجوع للشاشة السابقة
//       }
//     } catch (e) {
//       // إذا فشل الاتصال
//       if (mounted) {
//         Navigator.pop(context); // لإغلاق مؤشر التحميل
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to connect: $e')),
//         );
//       }
//     }
//   }
//
//   Widget _buildDeviceTile(ScanResult result) {
//     bool isCubie = result.device.platformName.toUpperCase() == "CUBIE";
//
//     return ListTile(
//       title: Text(
//         result.device.platformName.isNotEmpty
//             ? result.device.platformName
//             : 'Unknown Device',
//       ),
//       subtitle: Text(result.device.remoteId.toString()),
//       leading: Icon(
//         isCubie ? Icons.smart_toy : Icons.bluetooth,
//         color: isCubie ? Colors.blue : Colors.grey,
//       ),
//       trailing: Text('${result.rssi} dBm'), // قوة الإشارة
//       onTap: isCubie ? () => _connectToDevice(result.device) : null,
//       enabled: isCubie,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Connect to CUBIE'),
//         actions: [
//           // زر لإعادة البحث
//           Consumer<BluetoothManager>(
//             builder: (context, manager, child) {
//               if (manager.isScanning) {
//                 return Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
//                   ),
//                 );
//               }
//               return IconButton(
//                 icon: Icon(Icons.refresh),
//                 onPressed: _startScan,
//               );
//             },
//           ),
//         ],
//       ),
//       body: Consumer<BluetoothManager>(
//         builder: (context, manager, child) {
//           if (manager.adapterState != BluetoothAdapterState.on) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text('Bluetooth is OFF', style: TextStyle(fontSize: 18, color: Colors.red)),
//                   SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: () => FlutterBluePlus.turnOn(),
//                     child: Text('Turn On Bluetooth'),
//                   )
//                 ],
//               ),
//             );
//           }
//
//           if (manager.scanResults.isEmpty && !manager.isScanning) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text('No devices found.', style: TextStyle(fontSize: 16)),
//                   SizedBox(height: 10),
//                   Text('Tap refresh to scan again.', style: TextStyle(color: Colors.grey)),
//                 ],
//               ),
//             );
//           }
//
//           // عرض الأجهزة التي تم العثور عليها
//           return ListView.builder(
//             itemCount: manager.scanResults.length,
//             itemBuilder: (context, index) {
//               return _buildDeviceTile(manager.scanResults[index]);
//             },
//           );
//         },
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_manager.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart'; // <-- 1. إضافة import للأذونات

class ConnectCubeScreen extends StatefulWidget {
  const ConnectCubeScreen({Key? key}) : super(key: key);

  @override
  State<ConnectCubeScreen> createState() => _ConnectCubeScreenState();
}

class _ConnectCubeScreenState extends State<ConnectCubeScreen> {
  late BluetoothManager _bleManager;
  Timer? _scanTimer;
  String _permissionStatus = "Checking permissions..."; // <-- 2. متغير حالة جديد

  @override
  void initState() {
    super.initState();
    _bleManager = Provider.of<BluetoothManager>(context, listen: false);

    // !! --- (التعديل الرئيسي هنا) --- !!
    _checkPermissionsAndStartScan(); // <-- 3. استدعاء دالة الأذونات الجديدة

    // 4. المستمع أصبح للتحقق من حالة البلوتوث بعد أخذ الإذن
    _bleManager.adapterStateSubscription?.onData((state) {
      if (state == BluetoothAdapterState.off) {
        if (mounted) {
          // اطلب تشغيل البلوتوث (هذا قد لا يعمل دائماً، الأفضل أن يفعله المستخدم)
          FlutterBluePlus.turnOn();
        }
      }
    });
  }

  // !! --- (دالة جديدة: طلب الأذونات) --- !!
  Future<void> _checkPermissionsAndStartScan() async {
    setState(() { _permissionStatus = "Checking permissions..."; });

    // 5. طلب الأذونات
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    // 6. التحقق من أن المستخدم وافق
    if (statuses[Permission.bluetoothScan] == PermissionStatus.granted &&
        statuses[Permission.bluetoothConnect] == PermissionStatus.granted) {

      setState(() { _permissionStatus = "Permissions granted. Starting scan..."; });

      // 7. إذا كان البلوتوث طافي، اطلب تشغيله
      if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.off) {
        try {
          await FlutterBluePlus.turnOn();
        } catch (e) {
          print("Error turning on Bluetooth: $e");
        }
      }

      // 8. ابدأ البحث
      _startScan();

    } else {
      // 9. إذا رفض المستخدم، اعرض رسالة خطأ
      setState(() {
        _permissionStatus = "Bluetooth permissions are required to scan for devices.";
      });
      print("User denied Bluetooth permissions.");
    }
  }
  // !! --- (نهاية الدالة الجديدة) --- !!

  @override
  void dispose() {
    _scanTimer?.cancel();
    _bleManager.stopScan();
    super.dispose();
  }

  void _startScan() {
    _bleManager.startScan();
    _scanTimer?.cancel();
    _scanTimer = Timer(Duration(seconds: 5), () {
      _bleManager.stopScan();
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _bleManager.stopScan();
    _scanTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      await _bleManager.connectToDevice(device);

      if (mounted) {
        Navigator.pop(context); // لإغلاق مؤشر التحميل
        Navigator.pop(context); // للرجوع للشاشة السابقة
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // لإغلاق مؤشر التحميل
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $e')),
        );
      }
    }
  }

  Widget _buildDeviceTile(ScanResult result) {
    bool isCubie = result.device.platformName.toUpperCase() == "CUBIE";

    return ListTile(
      title: Text(
        result.device.platformName.isNotEmpty
            ? result.device.platformName
            : 'Unknown Device',
      ),
      subtitle: Text(result.device.remoteId.toString()),
      leading: Icon(
        isCubie ? Icons.smart_toy : Icons.bluetooth,
        color: isCubie ? Colors.blue : Colors.grey,
      ),
      trailing: Text('${result.rssi} dBm'),
      onTap: isCubie ? () => _connectToDevice(result.device) : null,
      enabled: isCubie,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connect to CUBIE'),
        actions: [
          Consumer<BluetoothManager>(
            builder: (context, manager, child) {
              if (manager.isScanning) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                );
              }
              return IconButton(
                icon: Icon(Icons.refresh),
                // 10. زر التحديث يطلب الأذونات ثم يبحث
                onPressed: _checkPermissionsAndStartScan,
              );
            },
          ),
        ],
      ),
      body: Consumer<BluetoothManager>(
        builder: (context, manager, child) {

          // 11. تعديل الواجهة لتعكس حالة الأذونات وحالة البلوتوث

          if (_permissionStatus.startsWith("Bluetooth permissions are required")) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_permissionStatus, style: TextStyle(fontSize: 18, color: Colors.red), textAlign: TextAlign.center,),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _checkPermissionsAndStartScan, // حاول طلب الإذن مجدداً
                    child: Text('Grant Permissions'),
                  )
                ],
              ),
            );
          }

          if (manager.adapterState == BluetoothAdapterState.off) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Bluetooth is OFF', style: TextStyle(fontSize: 18, color: Colors.red)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => FlutterBluePlus.turnOn(),
                    child: Text('Turn On Bluetooth'),
                  )
                ],
              ),
            );
          }

          if (manager.adapterState != BluetoothAdapterState.on) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(_permissionStatus, style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }

          if (manager.scanResults.isEmpty && !manager.isScanning) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No devices found.', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 10),
                  Text('Tap refresh to scan again.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: manager.scanResults.length,
            itemBuilder: (context, index) {
              return _buildDeviceTile(manager.scanResults[index]);
            },
          );
        },
      ),
    );
  }
}