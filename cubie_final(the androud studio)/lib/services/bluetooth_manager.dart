// lib/services/bluetooth_manager.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothManager {
  // --- إعداد نمط Singleton ---
  BluetoothManager._privateConstructor();
  static final BluetoothManager instance = BluetoothManager._privateConstructor();

  // --- متغيرات إدارة الاتصال ---
  BluetoothConnection? connection;
  StreamSubscription<Uint8List>? _btSubscription;
  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier(false);
  String? deviceName;

  /// الاتصال بالمكعب
  Future<bool> connect(BluetoothDevice device) async {
    if (isConnectedNotifier.value) return true;
    try {
      connection = await BluetoothConnection.toAddress(device.address);
      deviceName = device.name;
      isConnectedNotifier.value = true;
      print('✅ [BT Manager] تم الاتصال بنجاح بـ: ${device.name}');

      connection!.input?.listen(null, onDone: () {
        _resetConnection();
      });

      return true;
    } catch (e) {
      print('❌ [BT Manager] فشل الاتصال: $e');
      _resetConnection();
      return false;
    }
  }

  /// إرسال أمر نصي إلى المكعب
  void sendMessage(String message) {
    if (!isConnectedNotifier.value || connection == null) {
      print('⚠ [BT Manager] لا يمكن الإرسال، لا يوجد اتصال');
      return;
    }
    connection!.output.add(utf8.encode("$message\r\n"));
    connection!.output.allSent.then((_) {
      print('➡ [BT Manager] تم إرسال الأمر: $message');
    });
  }

  /// الاستماع للجواب القادم من المكعب
  void listenForAnswer(void Function(String answer) onAnswerReceived) {
    if (!isConnectedNotifier.value || connection == null) {
      print('⚠ [BT Manager] لا يمكن الاستماع، لا يوجد اتصال');
      return;
    }
    _btSubscription?.cancel();
    _btSubscription = connection!.input?.listen((Uint8List data) {
      final answer = String.fromCharCodes(data).trim();
      if (answer.isNotEmpty) {
        print('⬅ [BT Manager] تم استلام الجواب: $answer');
        onAnswerReceived(answer);
        _btSubscription?.cancel();
      }
    });
  }

  // =======================================================
  // هذه هي الدالة التي أضفتها أنت، وهي ضرورية ومهمة جدًا
  // =======================================================
  /// قطع الاتصال
  void disconnect() {
    _resetConnection();
  }

  // دالة خاصة لتنظيف كل شيء
  void _resetConnection() {
    _btSubscription?.cancel();
    connection?.dispose();
    connection = null;
    deviceName = null;
    if (isConnectedNotifier.value) {
      isConnectedNotifier.value = false;
    }
    print('🔌 [BT Manager] تم قطع الاتصال وتنظيف الموارد');
  }
}