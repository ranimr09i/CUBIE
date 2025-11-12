// lib/services/bluetooth_manager.dart
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
  StreamSubscription<BluetoothAdapterState>? adapterStateSubscription;

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

  // آخر رد من الحساس
  String _lastSensorResponse = "";

  // --- Getters ---
  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  List<ScanResult> get scanResults => _scanResults;
  BluetoothAdapterState get adapterState => _adapterState;
  String get lastSensorResponse => _lastSensorResponse;

  // (جديد) Getter للتأكد من الجاهزية الحقيقية
  bool get isReady => _isConnected && _commandCharacteristic != null && _responseCharacteristic != null;


  BluetoothManager() {
    // مراقبة حالة البلوتوث في الجوال (شغال/طافي)
    adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (state != BluetoothAdapterState.on) {
        // إذا تم إطفاء البلوتوث، اعتبره غير متصل
        _resetConnectionState(notify: true);
      }
      notifyListeners();
    });
  }

  // --- 1. البحث عن الأجهزة ---
  Future<void> startScan() async {
    if (_isScanning) return;

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
      // (جديد) البحث بالـ Service UUID لفلترة الأجهزة
      await FlutterBluePlus.startScan(
        withServices: [Guid(CUBIE_SERVICE_UUID)],
        timeout: Duration(seconds: 5),
      );

      FlutterBluePlus.scanResults.listen((results) {
        // فلترة النتائج لتجنب التكرار
        final uniqueResults = <String, ScanResult>{};
        for (var r in results) {
          if (r.device.platformName.isNotEmpty) {
            uniqueResults[r.device.remoteId.toString()] = r;
          }
        }
        _scanResults = uniqueResults.values.toList();
        notifyListeners();
      });
    } catch (e) {
      print("Error starting scan: $e");
    } finally {
      // (معدل) إيقاف البحث بعد 5 ثواني
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

  // --- 2. الاتصال وفصل الاتصال (هذا هو الكود الأهم) ---
  /// يتصل بالجهاز وينتظر حتى اكتشاف الخدمات بالكامل
  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_isConnected) return;

    // إيقاف أي مستمع قديم
    await _connectionStateSubscription?.cancel();

    try {
      // --- الخطوة 1: الاتصال ---
      await device.connect(timeout: Duration(seconds: 15));

      _isConnected = true;
      _cubieDevice = device;
      print("✅ [BLE Manager] الخطوة 1: تم الاتصال بـ ${device.platformName}");
      notifyListeners();

      // --- الخطوة 2: اكتشاف الخدمات (أهم خطوة) ---
      // (هذه الدالة ستبحث عن الخصائص وتفعل الإشعارات)
      await _discoverServices();

      // --- الخطوة 3: التحقق من الجاهزية ---
      if (!isReady) {
        // إذا لم نجد الخصائص المطلوبة
        throw Exception("Could not find required CUBIE services/characteristics.");
      }

      // --- الخطوة 4: (جديد) الآن فقط، نبدأ بالاستماع لـ "قطع الاتصال" ---
      _connectionStateSubscription = device.connectionState.listen(_onConnectionStateChanged);

      print("✅ [BLE Manager] الخطوة 2: جاهز لاستقبال الأوامر.");
      notifyListeners(); // إخطار الواجهة بالجاهزية الكاملة

    } catch (e) {
      print("❌ [BLE Manager] فشل أثناء عملية الاتصال واكتشاف الخدمات: $e");
      await device.disconnect(); // تأكد من قطع الاتصال عند الفشل
      _resetConnectionState(notify: true);
      throw e; // إرجاع الخطأ للواجهة (connect_cube.dart)
    }
  }

  Future<void> disconnect() async {
    if (_cubieDevice == null) return;
    try {
      await _cubieDevice!.disconnect();
    } catch (e) {
      print("Error disconnecting: $e");
    }
    // _onConnectionStateChanged سيتولى الباقي
  }

  void _onConnectionStateChanged(BluetoothConnectionState state) {
    if (state == BluetoothConnectionState.disconnected) {
      print("🔌 [BLE Manager] تم قطع الاتصال.");
      _resetConnectionState(notify: true);
    }
  }

  void _resetConnectionState({bool notify = false}) {
    _isConnected = false;
    _cubieDevice = null;
    _commandCharacteristic = null;
    _responseCharacteristic = null;
    _responseSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _responseSubscription = null;
    _connectionStateSubscription = null;

    if (notify) {
      notifyListeners();
    }
  }

  // --- 3. اكتشاف الخدمات (بعد الاتصال) ---
  Future<void> _discoverServices() async {
    if (_cubieDevice == null) return;

    try {
      List<BluetoothService> services = await _cubieDevice!.discoverServices();
      for (var service in services) {
        if (service.uuid == Guid(CUBIE_SERVICE_UUID)) {
          print("ℹ [BLE Manager] تم العثور على خدمة CUBIE!");
          for (var char in service.characteristics) {
            if (char.uuid == Guid(COMMAND_CHAR_UUID)) {
              _commandCharacteristic = char;
              print("ℹ [BLE Manager] تم العثور على خاصية الأوامر (WRITE)");
            }
            if (char.uuid == Guid(RESPONSE_CHAR_UUID)) {
              _responseCharacteristic = char;
              print("ℹ [BLE Manager] تم العثور على خاصية الردود (NOTIFY)");
            }
          }
        }
      }

      // تفعيل الإشعارات بعد العثور على الخاصية
      if (_responseCharacteristic != null) {
        await _setupNotifications();
      }

    } catch (e) {
      print("❌ [BLE Manager] خطأ أثناء اكتشاف الخدمات: $e");
    }
  }

  // --- 4. إعداد استقبال الردود (Notify) ---
  Future<void> _setupNotifications() async {
    if (_responseCharacteristic == null || !_isConnected) return;

    await _responseSubscription?.cancel();
    _responseSubscription = null;

    try {
      await _responseCharacteristic!.setNotifyValue(true);
      _responseSubscription = _responseCharacteristic!.onValueReceived.listen((value) {
        String response = utf8.decode(value);
        print("⬅ [BLE Received] $response");

        _lastSensorResponse = response;
        notifyListeners(); // إخطار الواجهة (مثل شاشة القصة) بالرد الجديد
      });
      print("🔔 [BLE Manager] تم تفعيل استلام الإشعارات.");
    } catch (e) {
      print("❌ [BLE Manager] خطأ في إعداد الإشعارات: $e");
    }
  }

  // --- 5. إرسال الأوامر (Write) ---
  Future<void> sendCommand(String command) async {
    if (!isReady) {
      print("⚠ [BLE Manager] غير متصل أو غير جاهز. لا يمكن إرسال: $command");
      return;
    }

    try {
      List<int> bytes = utf8.encode(command);

      // --- (هذا هو التعديل) ---
      // غيّرنا withoutResponse: true إلى false
      // لأن المكعب يتوقع (Write With Response)
      await _commandCharacteristic!.write(bytes, withoutResponse: false);
      // --- (نهاية التعديل) ---

      print("➡ [BLE Sent] $command");
    } catch (e) {
      print("❌ [BLE Manager] خطأ أثناء إرسال الأمر: $e");
      // (اختياري) يمكنك إظهار الخطأ للمستخدم إذا أردت
      // throw e;
    }
  }

  @override
  void dispose() {
    adapterStateSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _responseSubscription?.cancel();
    if (isConnected) {
      disconnect();
    }
    super.dispose();
  }
}