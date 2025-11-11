// // lib/services/bluetooth_manager.dart
//
// import 'dart:async';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
//
// class BluetoothManager {
//   // --- إعداد نمط Singleton ---
//   BluetoothManager._privateConstructor();
//   static final BluetoothManager instance = BluetoothManager._privateConstructor();
//
//   // --- متغيرات إدارة الاتصال ---
//   BluetoothConnection? connection;
//   StreamSubscription<Uint8List>? _btSubscription;
//   final ValueNotifier<bool> isConnectedNotifier = ValueNotifier(false);
//   String? deviceName;
//
//   /// الاتصال بالمكعب
//   Future<bool> connect(BluetoothDevice device) async {
//     if (isConnectedNotifier.value) return true;
//     try {
//       connection = await BluetoothConnection.toAddress(device.address);
//       deviceName = device.name;
//       isConnectedNotifier.value = true;
//       print('✅ [BT Manager] تم الاتصال بنجاح بـ: ${device.name}');
//
//       connection!.input?.listen(null, onDone: () {
//         _resetConnection();
//       });
//
//       return true;
//     } catch (e) {
//       print('❌ [BT Manager] فشل الاتصال: $e');
//       _resetConnection();
//       return false;
//     }
//   }
//
//   /// إرسال أمر نصي إلى المكعب
//   void sendMessage(String message) {
//     if (!isConnectedNotifier.value || connection == null) {
//       print('⚠ [BT Manager] لا يمكن الإرسال، لا يوجد اتصال');
//       return;
//     }
//     connection!.output.add(utf8.encode("$message\r\n"));
//     connection!.output.allSent.then((_) {
//       print('➡ [BT Manager] تم إرسال الأمر: $message');
//     });
//   }
//
//   /// الاستماع للجواب القادم من المكعب
//   void listenForAnswer(void Function(String answer) onAnswerReceived) {
//     if (!isConnectedNotifier.value || connection == null) {
//       print('⚠ [BT Manager] لا يمكن الاستماع، لا يوجد اتصال');
//       return;
//     }
//     _btSubscription?.cancel();
//     _btSubscription = connection!.input?.listen((Uint8List data) {
//       final answer = String.fromCharCodes(data).trim();
//       if (answer.isNotEmpty) {
//         print('⬅ [BT Manager] تم استلام الجواب: $answer');
//         onAnswerReceived(answer);
//         _btSubscription?.cancel();
//       }
//     });
//   }
//
//   // =======================================================
//   // هذه هي الدالة التي أضفتها أنت، وهي ضرورية ومهمة جدًا
//   // =======================================================
//   /// قطع الاتصال
//   void disconnect() {
//     _resetConnection();
//   }
//
//   // دالة خاصة لتنظيف كل شيء
//   void _resetConnection() {
//     _btSubscription?.cancel();
//     connection?.dispose();
//     connection = null;
//     deviceName = null;
//     if (isConnectedNotifier.value) {
//       isConnectedNotifier.value = false;
//     }
//     print('🔌 [BT Manager] تم قطع الاتصال وتنظيف الموارد');
//   }
// }
// lib/services/bluetooth_manager.dart

// import 'dart:async';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
//
// class BluetoothManager {
//   // --- إعداد نمط Singleton ---
//   BluetoothManager._privateConstructor();
//   static final BluetoothManager instance = BluetoothManager._privateConstructor();
//
//   // --- متغيرات إدارة الاتصال ---
//   BluetoothConnection? connection;
//   StreamSubscription<Uint8List>? _btSubscription;
//   final ValueNotifier<bool> isConnectedNotifier = ValueNotifier(false);
//   String? deviceName;
//
//   // (1) --- الإضافة الأولى: مخزن مؤقت للبيانات ---
//   String _buffer = '';
//
//   /// الاتصال بالمكعب
//   Future<bool> connect(BluetoothDevice device) async {
//     if (isConnectedNotifier.value) return true;
//     try {
//       connection = await BluetoothConnection.toAddress(device.address);
//       deviceName = device.name;
//       isConnectedNotifier.value = true;
//       print('✅ [BT Manager] تم الاتصال بنجاح بـ: ${device.name}');
//
//       connection!.input?.listen(null, onDone: () {
//         _resetConnection();
//       });
//
//       return true;
//     } catch (e) {
//       print('❌ [BT Manager] فشل الاتصال: $e');
//       _resetConnection();
//       return false;
//     }
//   }
//
//   /// إرسال أمر نصي إلى المكعب
//   void sendMessage(String message) {
//     if (!isConnectedNotifier.value || connection == null) {
//       print('⚠ [BT Manager] لا يمكن الإرسال، لا يوجد اتصال');
//       return;
//     }
//     // (تأكد من إرسال سطر جديد ليتوافق مع readStringUntil في الأردوينو)
//     connection!.output.add(utf8.encode("$message\r\n"));
//     connection!.output.allSent.then((_) {
//       print('➡ [BT Manager] تم إرسال الأمر: $message');
//     });
//   }
//
//   /// الاستماع للجواب القادم من المكعب
//   void listenForAnswer(void Function(String answer) onAnswerReceived) {
//     if (!isConnectedNotifier.value || connection == null) {
//       print('⚠ [BT Manager] لا يمكن الاستماع، لا يوجد اتصال');
//       return;
//     }
//     _btSubscription?.cancel(); // إلغاء أي مستمع قديم
//     _buffer = ''; // (2) تصفير المخزن المؤقت مع كل سؤال جديد
//
//     _btSubscription = connection!.input?.listen((Uint8List data) {
//
//       // (3) إضافة البيانات القادمة إلى المخزن المؤقت
//       _buffer += String.fromCharCodes(data);
//
//       // (4) التحقق إذا كان المخزن يحتوي على "سطر جديد" (علامة نهاية الأمر)
//       if (_buffer.contains('\n')) {
//         // (5) تقسيم المخزن عند علامة السطر الجديد
//         final parts = _buffer.split('\n');
//         final answer = parts.first.trim().toUpperCase(); // (6) الجواب هو الجزء الأول (النظيف)
//         _buffer = parts.sublist(1).join('\n'); // (7) الاحتفاظ بالباقي في المخزن (لأوامر مستقبلية)
//
//         if (answer.isNotEmpty) {
//           print('⬅ [BT Manager] تم استلام الجواب الكامل: $answer');
//           onAnswerReceived(answer); // (8) إرسال الجواب الكامل
//           _btSubscription?.cancel(); // (9) إلغاء الاستماع (لهذا السؤال فقط)
//         }
//       }
//     });
//   }
//
//   /// قطع الاتصال
//   void disconnect() {
//     _resetConnection();
//   }
//
//   // دالة خاصة لتنظيف كل شيء
//   void _resetConnection() {
//     _btSubscription?.cancel();
//     connection?.dispose();
//     connection = null;
//     deviceName = null;
//     if (isConnectedNotifier.value) {
//       isConnectedNotifier.value = false;
//     }
//     _buffer = ''; // (10) تصفير المخزن عند قطع الاتصال
//     print('🔌 [BT Manager] تم قطع الاتصال وتنظيف الموارد');
//   }
// }
// lib/services/bluetooth_manager.dart

// import 'dart:async';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
//
// class BluetoothManager {
//   // --- إعداد نمط Singleton ---
//   BluetoothManager._privateConstructor();
//   static final BluetoothManager instance = BluetoothManager._privateConstructor();
//
//   // --- متغيرات إدارة الاتصال ---
//   BluetoothConnection? connection;
//   StreamSubscription<Uint8List>? _btSubscription;
//   final ValueNotifier<bool> isConnectedNotifier = ValueNotifier(false);
//   String? deviceName;
//
//   String _buffer = '';
//
//   /// الاتصال بالمكعب
//   Future<bool> connect(BluetoothDevice device) async {
//     if (isConnectedNotifier.value) return true;
//     try {
//       connection = await BluetoothConnection.toAddress(device.address);
//       deviceName = device.name;
//       isConnectedNotifier.value = true;
//       print('✅ [BT Manager] تم الاتصال بنجاح بـ: ${device.name}');
//
//       connection!.input?.listen(null, onDone: () {
//         _resetConnection();
//       });
//
//       return true;
//     } catch (e) {
//       print('❌ [BT Manager] فشل الاتصال: $e');
//       _resetConnection();
//       return false;
//     }
//   }
//
//   /// إرسال أمر نصي إلى المكعب
//   void sendMessage(String message) {
//     if (!isConnectedNotifier.value || connection == null) {
//       print('⚠ [BT Manager] لا يمكن الإرسال، لا يوجد اتصال');
//       return;
//     }
//     connection!.output.add(utf8.encode("$message\r\n"));
//     connection!.output.allSent.then((_) {
//       print('➡ [BT Manager] تم إرسال الأمر: $message');
//     });
//   }
//
//   /// (1) تعديل: الدالة الآن تلغي أي استماع قديم فقط
//   /// ستبقى تستمع وترسل كل سطر تتلقاه إلى onAnswerReceived
//   void listenForAnswer(void Function(String answer) onAnswerReceived) {
//     if (!isConnectedNotifier.value || connection == null) {
//       print('⚠ [BT Manager] لا يمكن الاستماع، لا يوجد اتصال');
//       return;
//     }
//     _btSubscription?.cancel(); // إلغاء أي مستمع قديم
//     _buffer = ''; // تصفير المخزن المؤقت مع كل سؤال جديد
//
//     _btSubscription = connection!.input?.listen((Uint8List data) {
//       _buffer += String.fromCharCodes(data);
//
//       // (2) تعديل: معالجة كل الأسطر المكتملة في البافر
//       while (_buffer.contains('\n')) {
//         final parts = _buffer.split('\n');
//         // (3) نأخذ أول سطر مكتمل وننظفه
//         final answer = parts.first.trim().toUpperCase();
//         // (4) نحتفظ بالباقي في المخزن (قد تكون رسالة ناقصة أو رسالة تالية)
//         _buffer = parts.sublist(1).join('\n');
//
//         if (answer.isNotEmpty) {
//           print('⬅ [BT Manager] تم استلام سطر: $answer');
//           onAnswerReceived(answer); // (5) إرسال كل سطر مستلم
//
//           // (6) !! تم حذف إلغاء الاشتراك من هنا !!
//           // سيبقى الاشتراك فعالاً لاستلام رسالة الحركة
//         }
//       }
//     });
//   }
//
//   // (7) إضافة دالة جديدة لإلغاء الاستماع يدويًا
//   // سنستدعيها من story_progress.dart
//   void stopListening() {
//     _btSubscription?.cancel();
//     _btSubscription = null;
//     _buffer = '';
//     print('🔇 [BT Manager] تم إيقاف الاستماع للردود');
//   }
//
//   /// قطع الاتصال
//   void disconnect() {
//     _resetConnection();
//   }
//
//   // دالة خاصة لتنظيف كل شيء
//   void _resetConnection() {
//     stopListening(); // (8) التأكد من إيقاف الاستماع عند قطع الاتصال
//     connection?.dispose();
//     connection = null;
//     deviceName = null;
//     if (isConnectedNotifier.value) {
//       isConnectedNotifier.value = false;
//     }
//     _buffer = '';
//     print('🔌 [BT Manager] تم قطع الاتصال وتنظيف الموارد');
//   }
// }
// import 'dart:async';
// import 'dart:convert'; // لإرسال الأوامر كـ bytes
// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
//
// class BluetoothManager extends ChangeNotifier {
//   // UUIDs (يجب أن تطابق 100% ما في كود MPU.ino)
//   static const String CUBIE_SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
//   static const String COMMAND_CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8"; // (WRITE)
//   static const String RESPONSE_CHAR_UUID = "c3856242-4f7f-4a6c-b3d4-4a6e43f5a25c"; // (NOTIFY)
//
//   // حالة البلوتوث
//   BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
//   StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
//
//   // حالة الاتصال
//   bool _isConnected = false;
//   BluetoothDevice? _cubieDevice;
//   StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
//
//   // الخصائص (Channels)
//   BluetoothCharacteristic? _commandCharacteristic;
//   BluetoothCharacteristic? _responseCharacteristic;
//   StreamSubscription<List<int>>? _responseSubscription;
//
//   // نتائج البحث
//   List<ScanResult> _scanResults = [];
//   bool _isScanning = false;
//
//   // آخر رد من الحساس (هذا هو المتغير الأهم)
//   String _lastSensorResponse = "";
//
//   // --- Getters ---
//   bool get isConnected => _isConnected;
//   bool get isScanning => _isScanning;
//   List<ScanResult> get scanResults => _scanResults;
//   BluetoothAdapterState get adapterState => _adapterState;
//   String get lastSensorResponse => _lastSensorResponse;
//
//   BluetoothManager() {
//     // مراقبة حالة البلوتوث في الجوال (شغال/طافي)
//     _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
//       _adapterState = state;
//       if (state != BluetoothAdapterState.on) {
//         _isConnected = false;
//         _cubieDevice = null;
//       }
//       notifyListeners();
//     });
//   }
//
//   // --- 1. البحث عن الأجهزة ---
//   Future<void> startScan() async {
//     if (_isScanning) return;
//
//     // اطلب تشغيل البلوتوث إذا كان طافياً
//     if (_adapterState != BluetoothAdapterState.on) {
//       try {
//         await FlutterBluePlus.turnOn();
//       } catch (e) {
//         print("Error turning on Bluetooth: $e");
//       }
//     }
//
//     _scanResults.clear();
//     _isScanning = true;
//     notifyListeners();
//
//     try {
//       // ابدأ البحث
//       await FlutterBluePlus.startScan(timeout: Duration(seconds: 5));
//
//       // استمع لنتائج البحث
//       FlutterBluePlus.scanResults.listen((results) {
//         // فلترة النتائج لتجنب التكرار وعرض الأجهزة التي لها اسم فقط
//         _scanResults = results
//             .where((r) => r.device.platformName.isNotEmpty)
//             .toList();
//         notifyListeners();
//       });
//     } catch (e) {
//       print("Error starting scan: $e");
//     } finally {
//       // أوقف البحث بعد 5 ثواني
//       await Future.delayed(Duration(seconds: 5));
//       stopScan();
//     }
//   }
//
//   Future<void> stopScan() async {
//     if (!_isScanning) return;
//     try {
//       await FlutterBluePlus.stopScan();
//     } catch (e) {
//       print("Error stopping scan: $e");
//     }
//     _isScanning = false;
//     notifyListeners();
//   }
//
//   // --- 2. الاتصال وفصل الاتصال ---
//   Future<void> connectToDevice(BluetoothDevice device) async {
//     if (_isConnected) return;
//
//     try {
//       // مراقبة حالة الاتصال
//       _connectionStateSubscription = device.connectionState.listen(_onConnectionStateChanged);
//
//       await device.connect(timeout: Duration(seconds: 15));
//       _cubieDevice = device;
//
//     } catch (e) {
//       print("Error connecting to device: $e");
//       _connectionStateSubscription?.cancel();
//     }
//   }
//
//   Future<void> disconnect() async {
//     if (_cubieDevice == null) return;
//
//     try {
//       await _cubieDevice!.disconnect();
//     } catch (e) {
//       print("Error disconnecting: $e");
//     } finally {
//       // سيتم تحديث الحالة عبر _onConnectionStateChanged
//     }
//   }
//
//   void _onConnectionStateChanged(BluetoothConnectionState state) {
//     if (state == BluetoothConnectionState.connected) {
//       _isConnected = true;
//       print("BLE Manager: Connected to ${_cubieDevice!.platformName}");
//       // إذا اتصلنا، ابدأ بالبحث عن الخدمات والخصائص
//       _discoverServices();
//     } else if (state == BluetoothConnectionState.disconnected) {
//       _isConnected = false;
//       _cubieDevice = null;
//       _commandCharacteristic = null;
//       _responseCharacteristic = null;
//       _responseSubscription?.cancel();
//       _connectionStateSubscription?.cancel();
//       print("BLE Manager: Disconnected");
//     }
//     notifyListeners();
//   }
//
//   // --- 3. اكتشاف الخدمات (بعد الاتصال) ---
//   Future<void> _discoverServices() async {
//     if (_cubieDevice == null) return;
//
//     try {
//       List<BluetoothService> services = await _cubieDevice!.discoverServices();
//       for (var service in services) {
//         // هل هذه هي خدمة CUBIE؟
//         if (service.uuid == Guid(CUBIE_SERVICE_UUID)) {
//           print("BLE Manager: Found CUBIE Service!");
//           for (var char in service.characteristics) {
//             // هل هذه خاصية الأوامر؟
//             if (char.uuid == Guid(COMMAND_CHAR_UUID)) {
//               _commandCharacteristic = char;
//               print("BLE Manager: Found Command Characteristic (WRITE)");
//             }
//             // هل هذه خاصية الردود؟
//             if (char.uuid == Guid(RESPONSE_CHAR_UUID)) {
//               _responseCharacteristic = char;
//               print("BLE Manager: Found Response Characteristic (NOTIFY)");
//               // !! أهم خطوة: الاشتراك في الإشعارات (Listen) !!
//               _setupNotifications();
//             }
//           }
//         }
//       }
//     } catch (e) {
//       print("Error discovering services: $e");
//     }
//   }
//
//   // --- 4. إعداد استقبال الردود (Notify) ---
//   Future<void> _setupNotifications() async {
//     if (_responseCharacteristic == null) return;
//
//     try {
//       // تفعيل الإشعارات
//       await _responseCharacteristic!.setNotifyValue(true);
//       // الاستماع للردود القادمة
//       _responseSubscription = _responseCharacteristic!.onValueReceived.listen((value) {
//         // تحويل الـ bytes إلى String
//         String response = utf8.decode(value);
//         print("BLE Received << $response");
//
//         // تحديث الحالة ليتم استخدامها في شاشة القصة
//         _lastSensorResponse = response;
//         notifyListeners(); // إخطار الواجهة (مثل شاشة القصة) بالرد الجديد
//       });
//     } catch (e) {
//       print("Error setting up notifications: $e");
//     }
//   }
//
//   // --- 5. إرسال الأوامر (Write) ---
//   Future<void> sendCommand(String command) async {
//     if (_commandCharacteristic == null || !_isConnected) {
//       print("BLE Manager: Not connected or command characteristic not found.");
//       return;
//     }
//
//     try {
//       // تحويل الأمر (String) إلى (List<int>)
//       List<int> bytes = utf8.encode(command);
//       // إرسال الأمر (بدون انتظار رد)
//       await _commandCharacteristic!.write(bytes, withoutResponse: true);
//       print("BLE Sent >> $command");
//     } catch (e) {
//       print("Error sending command: $e");
//     }
//   }
//
//   @override
//   void dispose() {
//     _adapterStateSubscription?.cancel();
//     _connectionStateSubscription?.cancel();
//     _responseSubscription?.cancel();
//     disconnect();
//     super.dispose();
//   }
// }
import 'dart:async';
import 'dart:convert'; // لإرسال الأوامر كـ bytes
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothManager extends ChangeNotifier {
  // UUIDs (يجب أن تطابق 100% ما في كود MPU.ino)
  static const String CUBIE_SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String COMMAND_CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8"; // (WRITE)
  static const String RESPONSE_CHAR_UUID = "c3856242-4f7f-4a6c-b3d4-4a6e43f5a25c"; // (NOTIFY)

  // حالة البلوتوث
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  // !! --- (التعديل هنا) --- !!
  // (تم جعله public ليتمكن connect_cube.dart من الوصول إليه)
  StreamSubscription<BluetoothAdapterState>? adapterStateSubscription;
  // !! --- (نهاية التعديل) --- !!

  // حالة الاتصال
  bool _isConnected = false;
  BluetoothDevice? _cubieDevice;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

  // الخصائص (Channels)
  BluetoothCharacteristic? _commandCharacteristic;
  BluetoothCharacteristic? _responseCharacteristic;
  StreamSubscription<List<int>>? _responseSubscription;

  // نتائج البحث
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;

  // آخر رد من الحساس (هذا هو المتغير الأهم)
  String _lastSensorResponse = "";

  // --- Getters ---
  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  List<ScanResult> get scanResults => _scanResults;
  BluetoothAdapterState get adapterState => _adapterState;
  String get lastSensorResponse => _lastSensorResponse;

  BluetoothManager() {
    // مراقبة حالة البلوتوث في الجوال (شغال/طافي)
    adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (state != BluetoothAdapterState.on) {
        _isConnected = false;
        _cubieDevice = null;
      }
      notifyListeners();
    });
  }

  // --- 1. البحث عن الأجهزة ---
  Future<void> startScan() async {
    if (_isScanning) return;

    // اطلب تشغيل البلوتوث إذا كان طافياً
    if (_adapterState != BluetoothAdapterState.on) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (e) {
        print("Error turning on Bluetooth: $e");
      }
    }

    _scanResults.clear();
    _isScanning = true;
    notifyListeners();

    try {
      // ابدأ البحث
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

      // استمع لنتائج البحث
      FlutterBluePlus.scanResults.listen((results) {
        // فلترة النتائج لتجنب التكرار وعرض الأجهزة التي لها اسم فقط
        _scanResults = results
            .where((r) => r.device.platformName.isNotEmpty)
            .toList();
        notifyListeners();
      });
    } catch (e) {
      print("Error starting scan: $e");
    } finally {
      // أوقف البحث بعد 5 ثواني
      await Future.delayed(Duration(seconds: 5));
      stopScan();
    }
  }

  Future<void> stopScan() async {
    if (!_isScanning) return;
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print("Error stopping scan: $e");
    }
    _isScanning = false;
    notifyListeners();
  }

  // --- 2. الاتصال وفصل الاتصال ---
  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_isConnected) return;

    try {
      // مراقبة حالة الاتصال
      _connectionStateSubscription = device.connectionState.listen(_onConnectionStateChanged);

      await device.connect(timeout: Duration(seconds: 15));
      _cubieDevice = device;

    } catch (e) {
      print("Error connecting to device: $e");
      _connectionStateSubscription?.cancel();
    }
  }

  Future<void> disconnect() async {
    if (_cubieDevice == null) return;

    try {
      await _cubieDevice!.disconnect();
    } catch (e) {
      print("Error disconnecting: $e");
    } finally {
      // سيتم تحديث الحالة عبر _onConnectionStateChanged
    }
  }

  void _onConnectionStateChanged(BluetoothConnectionState state) {
    if (state == BluetoothConnectionState.connected) {
      _isConnected = true;
      print("BLE Manager: Connected to ${_cubieDevice!.platformName}");
      // إذا اتصلنا، ابدأ بالبحث عن الخدمات والخصائص
      _discoverServices();
    } else if (state == BluetoothConnectionState.disconnected) {
      _isConnected = false;
      _cubieDevice = null;
      _commandCharacteristic = null;
      _responseCharacteristic = null;
      _responseSubscription?.cancel();
      _connectionStateSubscription?.cancel();
      print("BLE Manager: Disconnected");
    }
    notifyListeners();
  }

  // --- 3. اكتشاف الخدمات (بعد الاتصال) ---
  Future<void> _discoverServices() async {
    if (_cubieDevice == null) return;

    try {
      List<BluetoothService> services = await _cubieDevice!.discoverServices();
      for (var service in services) {
        // هل هذه هي خدمة CUBIE؟
        if (service.uuid == Guid(CUBIE_SERVICE_UUID)) {
          print("BLE Manager: Found CUBIE Service!");
          for (var char in service.characteristics) {
            // هل هذه خاصية الأوامر؟
            if (char.uuid == Guid(COMMAND_CHAR_UUID)) {
              _commandCharacteristic = char;
              print("BLE Manager: Found Command Characteristic (WRITE)");
            }
            // هل هذه خاصية الردود؟
            if (char.uuid == Guid(RESPONSE_CHAR_UUID)) {
              _responseCharacteristic = char;
              print("BLE Manager: Found Response Characteristic (NOTIFY)");
              // !! أهم خطوة: الاشتراك في الإشعارات (Listen) !!
              _setupNotifications();
            }
          }
        }
      }
    } catch (e) {
      print("Error discovering services: $e");
    }
  }

  // --- 4. إعداد استقبال الردود (Notify) ---
  Future<void> _setupNotifications() async {
    if (_responseCharacteristic == null) return;

    try {
      // تفعيل الإشعارات
      await _responseCharacteristic!.setNotifyValue(true);
      // الاستماع للردود القادمة
      _responseSubscription = _responseCharacteristic!.onValueReceived.listen((value) {
        // تحويل الـ bytes إلى String
        String response = utf8.decode(value);
        print("BLE Received << $response");

        // تحديث الحالة ليتم استخدامها في شاشة القصة
        _lastSensorResponse = response;
        notifyListeners(); // إخطار الواجهة (مثل شاشة القصة) بالرد الجديد
      });
    } catch (e) {
      print("Error setting up notifications: $e");
    }
  }

  // --- 5. إرسال الأوامر (Write) ---
  Future<void> sendCommand(String command) async {
    if (_commandCharacteristic == null || !_isConnected) {
      print("BLE Manager: Not connected or command characteristic not found.");
      return;
    }

    try {
      // تحويل الأمر (String) إلى (List<int>)
      List<int> bytes = utf8.encode(command);
      // إرسال الأمر (بدون انتظار رد)
      await _commandCharacteristic!.write(bytes, withoutResponse: true);
      print("BLE Sent >> $command");
    } catch (e) {
      print("Error sending command: $e");
    }
  }

  @override
  void dispose() {
    adapterStateSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _responseSubscription?.cancel();
    disconnect();
    super.dispose();
  }
}