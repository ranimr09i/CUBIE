// lib/screens/connect_cube.dart
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_manager.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/app_scaffold.dart'; // (تأكد من وجود هذا الملف)


class ConnectCubeScreen extends StatefulWidget {
  const ConnectCubeScreen({Key? key}) : super(key: key);

  @override
  State<ConnectCubeScreen> createState() => _ConnectCubeScreenState();
}

class _ConnectCubeScreenState extends State<ConnectCubeScreen> {
  late BluetoothManager _bleManager;
  String _permissionStatus = "Checking permissions...";

  @override
  void initState() {
    super.initState();
    _bleManager = Provider.of<BluetoothManager>(context, listen: false);
    _checkPermissionsAndStartScan();

    // مستمع لحالة البلوتوث لطلب التشغيل
    _bleManager.adapterStateSubscription?.onData((state) {
      if (state == BluetoothAdapterState.off) {
        if (mounted) {
          // محاولة تشغيل البلوتوث تلقائياً إذا كان مطفأ
          try {
            FlutterBluePlus.turnOn();
          } catch (e) {
            print("Failed to turn on Bluetooth automatically: $e");
          }
        }
      }
    });
  }

  Future<void> _checkPermissionsAndStartScan() async {
    setState(() { _permissionStatus = "Checking permissions..."; });

    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise, // (إضافة) بعض الأجهزة تطلبه للبحث
      Permission.locationWhenInUse, // (إضافة) ضروري للبحث عن البلوتوث
    ].request();

    if (statuses[Permission.bluetoothScan] == PermissionStatus.granted &&
        statuses[Permission.bluetoothConnect] == PermissionStatus.granted &&
        statuses[Permission.locationWhenInUse] == PermissionStatus.granted) {

      setState(() { _permissionStatus = "Permissions granted. Starting scan..."; });

      if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.off) {
        try {
          await FlutterBluePlus.turnOn();
        } catch (e) {
          print("Error turning on Bluetooth: $e");
        }
      }

      // الانتظار لحظة قبل بدء البحث
      await Future.delayed(Duration(milliseconds: 500));
      _startScan();

    } else {
      setState(() {
        _permissionStatus = "Bluetooth and Location permissions are required to scan for devices.";
      });
      print("User denied permissions.");
    }
  }

  @override
  void dispose() {
    _bleManager.stopScan();
    super.dispose();
  }

  void _startScan() {
    _bleManager.startScan();
  }

  // (معدل) هذه الدالة الآن تعالج الأخطاء وتنتظر الجاهزية
  Future<void> _connectToDevice(BluetoothDevice device) async {
    _bleManager.stopScan();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      // (مهم) هذه الدالة في الـ Manager
      // لن تنتهي إلا عند الجاهزية الكاملة
      await _bleManager.connectToDevice(device);

      if (mounted) {
        Navigator.pop(context); // لإغلاق مؤشر التحميل
        Navigator.pop(context); // للرجوع للشاشة السابقة (home_page)
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // لإغلاق مؤشر التحميل
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $e')),
        );
        _startScan(); // (جديد) أعد البحث إذا فشل الاتصال
      }
    }
  }

  Widget _buildDeviceTile(ScanResult result) {
    // الفلترة بالاسم هنا أصبحت ثانوية، لأن البحث يتم بالـ UUID
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
        color: isCubie ? Color(0xff4ab0d1) : Colors.grey,
      ),
      trailing: Text('${result.rssi} dBm'),
      onTap: () => _connectToDevice(result.device), // (معدل) اسمح بالاتصال بأي جهاز يظهر
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold( // (استخدام AppScaffold الخاص بك)
      title: 'Connect to CUBIE',
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
              onPressed: _checkPermissionsAndStartScan,
            );
          },
        ),
      ],
      body: Consumer<BluetoothManager>(
        builder: (context, manager, child) {

          if (_permissionStatus.startsWith("Bluetooth and Location")) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_permissionStatus, style: TextStyle(fontSize: 18, color: Colors.red), textAlign: TextAlign.center,),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: openAppSettings, // (جديد) اطلب منه فتح الإعدادات
                      child: Text('Open Settings'),
                    )
                  ],
                ),
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
                    onPressed: () async {
                      try {
                        await FlutterBluePlus.turnOn();
                      } catch (e) {
                        print("Error turning on Bluetooth: $e");
                      }
                    },
                    child: Text('Turn On Bluetooth'),
                  )
                ],
              ),
            );
          }

          if (manager.adapterState != BluetoothAdapterState.on && !manager.isScanning) {
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