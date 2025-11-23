// #include <Wire.h>
// #include <MPU6050.h>
// #include <WiFi.h>

// // --- مكتبات الصوت الجديدة (بديلة ESP8266Audio) ---
// #include "AudioFileSourceHTTPStream.h" // لجلب الصوت من http
// #include "AudioFileSourceBuffer.h"     // لتخزين مؤقت
// #include "AudioGeneratorMP3.h"         // لفك تشفير MP3
// #include "AudioOutputI2S.h"            // لإخراج الصوت للسماعة

// // --- مكتبات البلوتوث الجديدة (BLE) ---
// #include <BLEDevice.h>
// #include <BLEServer.h>
// #include <BLEUtils.h>
// #include <BLE2902.h>

// // ===================================
// // !!      إعدادات الواي فاي      !!
// // ===================================
// const char* ssid = "HUAWEI_E5576_3656";     // (شبكتك)
// const char* password = "3GqA8bGYd3G"; // (شبكتك)
// // ===================================

// // --- منفذ مفتاح الأمان (لحل مشكلة الطاقة) ---
// #define SHUTDOWN_PIN 4 // (P4) موصول بـ SD

// // --- إعدادات السماعة (مطابقة لأسلاكك) ---
// #define I2S_DOUT 25
// #define I2S_BCLK 26
// #define I2S_LRC  27

// // --- إعدادات حساس الحركة ---
// MPU6050 mpu(0x68);
// const float LIMIT_DEG = 20.0;
// const float SHAKE_LIMIT_G = 0.7;
// const float ACCEL_SCALE = 16384.0;
// int16_t accelX, accelY, accelZ, gyroX, gyroY, gyroZ;

// // --- كائنات الصوت (الجديدة) ---
// AudioGeneratorMP3 *mp3;
// AudioFileSourceHTTPStream *file_http;
// AudioFileSourceBuffer *buff;
// AudioOutputI2S *out;

// // --- متغيرات حالة التشغيل ---
// bool isQuestionActive = false;
// String mode = "";
// String answer = "";

// // ===================================
// // !!      إعدادات البلوتوث BLE      !!
// // ===================================
// BLEServer *pServer = NULL;
// BLEService *pService = NULL;
// BLECharacteristic *pCommandCharacteristic = NULL;  // لاستقبال الأوامر (WRITE)
// BLECharacteristic *pResponseCharacteristic = NULL; // لإرسال الردود (NOTIFY)
// bool deviceConnected = false;
// std::string commandValue = "";

// // تعريف UUIDs (أرقام تعريفية فريدة)
// #define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
// #define COMMAND_CHAR_UUID   "beb5483e-36e1-4688-b7f5-ea07361b26a8" // (للاستقبال: START, PLAY)
// #define RESPONSE_CHAR_UUID  "c3856242-4f7f-4a6c-b3d4-4a6e43f5a25c" // (للإرسال: READY, RIGHT, LEFT)


// // ------------------------------------
// // !! دالة إيقاف *كل* الأصوات !!
// // ------------------------------------
// void stopAudio() {
//   if (mp3 && mp3->isRunning()) {
//     mp3->stop();
//     delete mp3;
//     mp3 = nullptr;
//   }
//   if (buff) {
//     buff->close();
//     delete buff;
//     buff = nullptr;
//   }
//   if (file_http) {
//     file_http->close();
//     delete file_http;
//     file_http = nullptr;
//   }
//   if (out) {
//     out->stop();
//     delete out;
//     out = nullptr;
//   }
//   digitalWrite(SHUTDOWN_PIN, HIGH); // "نوّم" السماعة
// }

// // ------------------------------------
// // !! دالة تشغيل القصة (من الإنترنت) !!
// // ------------------------------------
// // (ابحث عن دالة playFileFromURL واستبدلها بهذا الكود)

// void playFileFromURL(const char* url) {
//   stopAudio();
  
//   // إعادة تهيئة الكائنات
//   file_http = new AudioFileSourceHTTPStream(url);
//   buff = new AudioFileSourceBuffer(file_http, 4096); // زيادة البفر قليلاً
//   out = new AudioOutputI2S();
//   out->SetPinout(I2S_BCLK, I2S_LRC, I2S_DOUT); 
//   out->SetGain(0.6); // تعديل مستوى الصوت
  
//   mp3 = new AudioGeneratorMP3();
  
//   // !! التعديل المهم هنا !!
//   // نحاول بدء التشغيل، إذا فشل (بسبب رابط خطأ أو واي فاي) نرسل إنهاء فوراً
//   if (!mp3->begin(buff, out)) {
//     Serial.println("ERROR: Could not start playback (Check URL or WiFi)");
//     stopAudio(); // تنظيف الذاكرة
//     sendBleResponse("AUDIO:FINISHED"); // نخدع التطبيق ليكمل ولا يعلق
//   } else {
//     Serial.println("Playback started...");
//   }
// }

// // ------------------------------------
// // !!    إرسال رد عبر BLE   !!
// // ------------------------------------
// void sendBleResponse(String message) {
//   if (deviceConnected) {
//     pResponseCharacteristic->setValue(message.c_str());
//     pResponseCharacteristic->notify();
//     Serial.print("BLE Notify >> "); // للـ Serial Monitor
//     Serial.println(message);
//   }
// }

// // ------------------------------------
// // !!    معالجة أوامر BLE   !!
// // ------------------------------------
// void processBleCommand(std::string cmd) {
//   String command = String(cmd.c_str());
//   command.trim();
//   command.toUpperCase();
//   Serial.print("BLE Received << "); // للـ Serial Monitor
//   Serial.println(command);

//   // (أمر بدء السؤال)
//   if (command.startsWith("START")) {
//     mode = command.substring(5);
//     mode.trim();
//     isQuestionActive = true;
//     answer = "";
//     sendBleResponse("READY:" + mode); // إرسال جاهزية للتطبيق
//   }
//   // (أمر تشغيل الصوت)
//   else if (command.startsWith("PLAY:")) {
//     String url = command.substring(5);
//     url.trim(); 
//     playFileFromURL(url.c_str());
//   }
//   // (أمر إيقاف الصوت)
//   else if (command == "STOP_AUDIO") {
//     stopAudio();
//   }
// }

// // ------------------------------------
// // دوال رصد الحركة (معدلة لـ BLE)
// // ------------------------------------
// void detectShake() {
//   float acc_g = sqrt((float)accelX*accelX + (float)accelY*accelY + (float)accelZ*accelZ) / ACCEL_SCALE;
//   if (fabs(acc_g - 1.0) > SHAKE_LIMIT_G) {
//     answer = "SHAKE";
//     sendBleResponse(answer); // إرسال الجواب للتطبيق
//     isQuestionActive = false;
//   }
// }
// void detectY() {
//   float angleY = atan2(accelX, sqrt(accelY*accelY + accelZ*accelZ)) * 180.0 / PI;
//   if (angleY > LIMIT_DEG) {
//     answer = "FORWARD";
//     sendBleResponse(answer); // إرسال الجواب للتطبيق
//     isQuestionActive = false;
//   } else if (angleY < -LIMIT_DEG) {
//     answer = "BACK";
//     sendBleResponse(answer); // إرسال الجواب للتطبيق
//     isQuestionActive = false;
//   }
// }
// void detectZ() {
//   float angleZ = atan2(accelY, accelZ) * 180.0 / PI;
//   if (angleZ > LIMIT_DEG) {
//     answer = "RIGHT";
//     sendBleResponse(answer); // إرسال الجواب للتطبيق
//     isQuestionActive = false;
//   } else if (angleZ < -LIMIT_DEG) {
//     answer = "LEFT";
//     sendBleResponse(answer); // إرسال الجواب للتطبيق
//     isQuestionActive = false;
//   }
// }

// // ===================================
// // !!      كلاسات البلوتوث BLE      !!
// // ===================================

// // كلاس للتعامل مع الاتصال (connect/disconnect)
// class MyServerCallbacks: public BLEServerCallbacks {
//     void onConnect(BLEServer* pServer) {
//       deviceConnected = true;
//       Serial.println("Device connected");
//     }

//     void onDisconnect(BLEServer* pServer) {
//       deviceConnected = false;
//       Serial.println("Device disconnected");
//       BLEDevice::startAdvertising(); // ارجع للإعلان عن نفسك
//       Serial.println("Start advertising...");
//     }
// };

// // كلاس للتعامل مع استقبال الأوامر (onWrite)
// class MyCommandCallbacks: public BLECharacteristicCallbacks {
//     void onWrite(BLECharacteristic *pCharacteristic) {
//       std::string value = pCharacteristic->getValue().c_str();
//       if (value.length() > 0) {
//         processBleCommand(value); // استدعاء دالة معالجة الأوامر
//       }
//     }
// };

// // ------------------------------------
// // Setup
// // ------------------------------------
// void setup() {
//   Serial.begin(115200);

//   // --- 1. إعداد مفتاح الأمان (SD Pin) ---
//   pinMode(SHUTDOWN_PIN, OUTPUT);
//   digitalWrite(SHUTDOWN_PIN, HIGH); // "نوّم" السماعة فوراً
//   Serial.println("Amplifier put to sleep immediately.");
  
//   // --- 2. تشغيل البلوتوث BLE (بدلاً من SerialBT) ---
//   Serial.println("Starting BLE...");
//   BLEDevice::init("CUBIE"); // هذا هو الاسم الذي سيظهر في الجوال
  
//   pServer = BLEDevice::createServer();
//   pServer->setCallbacks(new MyServerCallbacks());
  
//   pService = pServer->createService(SERVICE_UUID);
  
//   // إنشاء خاصية استقبال الأوامر (App -> ESP32)
//   pCommandCharacteristic = pService->createCharacteristic(
//                              COMMAND_CHAR_UUID,
//                              BLECharacteristic::PROPERTY_WRITE
//                            );
//   pCommandCharacteristic->setCallbacks(new MyCommandCallbacks());

//   // إنشاء خاصية إرسال الردود (ESP32 -> App)
//   pResponseCharacteristic = pService->createCharacteristic(
//                               RESPONSE_CHAR_UUID,
//                               BLECharacteristic::PROPERTY_NOTIFY
//                             );
//   pResponseCharacteristic->addDescriptor(new BLE2902()); // مهم للإشعارات
  
//   pService->start();
  
//   BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
//   pAdvertising->addServiceUUID(SERVICE_UUID);
//   pAdvertising->setScanResponse(true);
//   pAdvertising->setMinPreferred(0x06); 
//   pAdvertising->setMinPreferred(0x12);
//   BLEDevice::startAdvertising();
//   Serial.println("BLE Advertising started. Waiting for client...");

//   // --- 3. تشغيل حساس الحركة ---
//   Wire.begin(21, 22);
//   mpu.initialize();
//   Serial.println("Testing MPU6050 connection...");
//   if (mpu.testConnection()) {
//     Serial.println("MPU6050 connection successful!");
//     mpu.setSleepEnabled(false);
//   } else {
//     Serial.println("MPU6050 connection failed! Check wiring.");
//   }

//   // --- 4. تشغيل الواي فاي !! ---
//   Serial.print("Connecting to WiFi: ");
//   Serial.println(ssid);
//   WiFi.begin(ssid, password);
//   int wifi_retries = 20;
//   while (WiFi.status() != WL_CONNECTED && wifi_retries > 0) {
//     delay(500);
//     Serial.print(".");
//     wifi_retries--;
//   }

//   if (WiFi.status() != WL_CONNECTED) {
//      Serial.println("");
//      Serial.println("WiFi connection FAILED! Check SSID and Password.");
//   } else {
//     Serial.println("");
//     Serial.println("WiFi connected!");
//     Serial.print("IP address: ");
//     Serial.println(WiFi.localIP());
//   }

//   Serial.println("--- System Ready (WiFi + BLE) ---");
// }

// // ------------------------------------
// // Loop
// // ------------------------------------
// void loop() {
  
//   // لا نحتاج لـ handleBluetoothCommands() هنا
//   // لأن الـ BLE يعمل بالكولباك (onWrite)

//   // رصد الحركة (إذا كان هناك سؤال)
//   if (isQuestionActive && answer.length() == 0) {
//     mpu.getMotion6(&accelX, &accelY, &accelZ, &gyroX, &gyroY, &gyroZ);
//     if (mode == "SHAKE") detectShake();
//     else if (mode == "TILTY") detectY();
//     else if (mode == "TILTZ") detectZ();
//   }

//   // --- سطر مهم لتشغيل صوت الإنترنت ---
//   if (mp3 && mp3->isRunning()) {
//     if (!mp3->loop()) {
//       stopAudio(); // أوقف الصوت عند الانتهاء
//       Serial.println("MP3 Stream Finished.");
//       sendBleResponse("AUDIO:FINISHED");
//     }
//   }
  
//   delay(50);
// }










// #include <Wire.h>
// #include <MPU6050.h>
// #include <WiFi.h>

// // --- مكتبات الصوت ---
// #include "AudioFileSourceHTTPStream.h" 
// #include "AudioFileSourceBuffer.h"     
// #include "AudioGeneratorMP3.h"         
// #include "AudioOutputI2S.h"            

// // --- مكتبات البلوتوث ---
// #include <BLEDevice.h>
// #include <BLEServer.h>
// #include <BLEUtils.h>
// #include <BLE2902.h>

// // ===================================
// // !!      إعدادات الواي فاي      !!
// // ===================================
// const char* ssid = "Salman_4G"; 
// const char* password = "0566339996"; 

// // ===================================
// // !!      إعدادات الهاردوير      !!
// // ===================================
// // ملاحظة: الـ SD Pin يحتاج HIGH ليعمل، و LOW لينطفئ
// #define SHUTDOWN_PIN 4 
// #define I2S_DOUT 25
// #define I2S_BCLK 26
// #define I2S_LRC  27

// // --- إعدادات حساس الحركة ---
// MPU6050 mpu(0x68);
// const float LIMIT_DEG = 20.0;
// const float SHAKE_LIMIT_G = 0.7;
// const float ACCEL_SCALE = 16384.0;
// int16_t accelX, accelY, accelZ, gyroX, gyroY, gyroZ;

// // --- كائنات الصوت ---
// AudioGeneratorMP3 *mp3 = NULL;
// AudioFileSourceHTTPStream *file_http = NULL;
// AudioFileSourceBuffer *buff = NULL;
// AudioOutputI2S *out = NULL;

// // --- متغيرات النظام ---
// bool isQuestionActive = false;
// String mode = "";
// String answer = "";

// // متغيرات جديدة لنقل الأمر من البلوتوث للـ Loop
// bool hasNewCommand = false;
// String pendingCommand = "";

// // ===================================
// // !!      إعدادات البلوتوث BLE      !!
// // ===================================
// BLEServer *pServer = NULL;
// BLEService *pService = NULL;
// BLECharacteristic *pCommandCharacteristic = NULL;
// BLECharacteristic *pResponseCharacteristic = NULL;
// bool deviceConnected = false;

// #define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
// #define COMMAND_CHAR_UUID   "beb5483e-36e1-4688-b7f5-ea07361b26a8"
// #define RESPONSE_CHAR_UUID  "c3856242-4f7f-4a6c-b3d4-4a6e43f5a25c"

// // ------------------------------------
// // !! دالة إيقاف *كل* الأصوات وتنظيف الرام !!
// // ------------------------------------
// void stopAudio() {
//   Serial.println("--- Stopping Audio & Cleaning RAM ---");
  
//   if (mp3) {
//     if (mp3->isRunning()) mp3->stop();
//     delete mp3;
//     mp3 = NULL;
//   }
//   if (buff) {
//     buff->close();
//     delete buff;
//     buff = NULL;
//   }
//   if (file_http) {
//     file_http->close();
//     delete file_http;
//     file_http = NULL;
//   }
//   if (out) {
//     out->stop();
//     delete out;
//     out = NULL;
//   }
  
//   // التعديل: LOW لإطفاء السماعة (وضع النوم)
//   digitalWrite(SHUTDOWN_PIN, LOW); 
  
//   Serial.print("RAM after clean: ");
//   Serial.println(ESP.getFreeHeap());
// }

// // ------------------------------------
// // !! دالة تشغيل القصة (من الإنترنت) !!
// // ------------------------------------
// void playFileFromURL(const char* url) {
//   stopAudio(); // تنظيف أولاً

//   Serial.print("Attempting to play: "); Serial.println(url);
  
//   // تأكدنا من توفر ذاكرة كافية
//   if (ESP.getFreeHeap() < 15000) {
//       Serial.println("CRITICAL: Not enough RAM!");
//       sendBleResponse("ERROR:LOW_RAM");
//       return;
//   }

//   file_http = new AudioFileSourceHTTPStream(url);
  
//   // بفر صغير لتوفير الذاكرة
//   buff = new AudioFileSourceBuffer(file_http, 4096); 
  
//   out = new AudioOutputI2S();
//   out->SetPinout(I2S_BCLK, I2S_LRC, I2S_DOUT);
//   out->SetGain(0.8); // رفعنا الصوت قليلاً

//   mp3 = new AudioGeneratorMP3();

//   // التعديل: HIGH لتشغيل السماعة
//   digitalWrite(SHUTDOWN_PIN, HIGH); 

//   if (!mp3->begin(buff, out)) {
//     Serial.println("ERROR: mp3->begin() failed!");
//     stopAudio(); 
//     sendBleResponse("AUDIO:ERROR");
//   } else {
//     Serial.println("Playback Started!");
//     sendBleResponse("AUDIO:STARTED");
//   }
// }

// // ------------------------------------
// // !!    إرسال رد عبر BLE   !!
// // ------------------------------------
// void sendBleResponse(String message) {
//   if (deviceConnected) {
//     pResponseCharacteristic->setValue(message.c_str());
//     pResponseCharacteristic->notify();
//   }
// }

// // ------------------------------------
// // !!    معالجة الأوامر (تعمل داخل Loop) !!
// // ------------------------------------
// void executeCommand(String command) {
//   Serial.print("Executing Command: "); Serial.println(command);
  
//   String upperCmd = command;
//   upperCmd.toUpperCase();

//   if (upperCmd.startsWith("START")) {
//     mode = upperCmd.substring(5);
//     mode.trim();
//     isQuestionActive = true;
//     answer = "";
//     sendBleResponse("READY:" + mode);
//   }
//   else if (upperCmd.startsWith("PLAY:")) {
//     String url = command.substring(5); 
//     url.trim();
//     playFileFromURL(url.c_str());
//   }
//   else if (upperCmd == "TEST_AUDIO") {
//       Serial.println("Starting Audio Test...");
//       // رابط MP3 بسيط جداً للاختبار
//       playFileFromURL("http://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3");
//   }
//   else if (upperCmd == "STOP_AUDIO") {
//     stopAudio();
//     sendBleResponse("AUDIO:STOPPED");
//   }
// }

// // ------------------------------------
// // دوال رصد الحركة 
// // ------------------------------------
// void detectShake() {
//   float acc_g = sqrt((float)accelX*accelX + (float)accelY*accelY + (float)accelZ*accelZ) / ACCEL_SCALE;
//   if (fabs(acc_g - 1.0) > SHAKE_LIMIT_G) {
//     answer = "SHAKE";
//     sendBleResponse(answer);
//     isQuestionActive = false;
//   }
// }
// void detectY() {
//   float angleY = atan2(accelX, sqrt(accelY*accelY + accelZ*accelZ)) * 180.0 / PI;
//   if (angleY > LIMIT_DEG) {
//     answer = "FORWARD";
//     sendBleResponse(answer);
//     isQuestionActive = false;
//   } else if (angleY < -LIMIT_DEG) {
//     answer = "BACK";
//     sendBleResponse(answer);
//     isQuestionActive = false;
//   }
// }
// void detectZ() {
//   float angleZ = atan2(accelY, accelZ) * 180.0 / PI;
//   if (angleZ > LIMIT_DEG) {
//     answer = "RIGHT";
//     sendBleResponse(answer);
//     isQuestionActive = false;
//   } else if (angleZ < -LIMIT_DEG) {
//     answer = "LEFT";
//     sendBleResponse(answer);
//     isQuestionActive = false;
//   }
// }

// // ===================================
// // !!      كلاسات البلوتوث BLE      !!
// // ===================================
// class MyServerCallbacks: public BLEServerCallbacks {
//     void onConnect(BLEServer* pServer) {
//       deviceConnected = true;
//       Serial.println("Device connected");
//     }
//     void onDisconnect(BLEServer* pServer) {
//       deviceConnected = false;
//       Serial.println("Device disconnected");
//       BLEDevice::startAdvertising(); 
//     }
// };

// // كلاس الاستقبال - تم التعديل ليكون خفيفاً جداً
// class MyCommandCallbacks: public BLECharacteristicCallbacks {
//     void onWrite(BLECharacteristic *pCharacteristic) {
//       std::string value = pCharacteristic->getValue().c_str();
//       if (value.length() > 0) {
//         // لا ننفذ الأمر هنا!! فقط نحفظه
//         pendingCommand = String(value.c_str());
//         // ننظف النص
//         pendingCommand.replace("\n", "");
//         pendingCommand.replace("\r", "");
//         pendingCommand.trim();
        
//         hasNewCommand = true; // نعطي إشارة للـ loop
//       }
//     }
// };

// // ------------------------------------
// // Setup
// // ------------------------------------
// void setup() {
//   Serial.begin(115200);

//   // 1. إيقاف الصوت (LOW = OFF)
//   pinMode(SHUTDOWN_PIN, OUTPUT);
//   digitalWrite(SHUTDOWN_PIN, LOW);
  
//   // 2. تشغيل BLE
//   BLEDevice::init("CUBIE");
//   pServer = BLEDevice::createServer();
//   pServer->setCallbacks(new MyServerCallbacks());
//   pService = pServer->createService(SERVICE_UUID);
  
//   pCommandCharacteristic = pService->createCharacteristic(COMMAND_CHAR_UUID, BLECharacteristic::PROPERTY_WRITE);
//   pCommandCharacteristic->setCallbacks(new MyCommandCallbacks());
//   pResponseCharacteristic = pService->createCharacteristic(RESPONSE_CHAR_UUID, BLECharacteristic::PROPERTY_NOTIFY);
//   pResponseCharacteristic->addDescriptor(new BLE2902());
  
//   pService->start();
//   BLEDevice::startAdvertising();
//   Serial.println("BLE Ready.");

//   // 3. تشغيل الحساس
//   Wire.begin(21, 22);
//   mpu.initialize();
  
//   // 4. واي فاي
//   WiFi.begin(ssid, password);
//   Serial.print("Connecting WiFi");
//   int retry = 0;
//   while (WiFi.status() != WL_CONNECTED && retry < 20) {
//     delay(500);
//     Serial.print(".");
//     retry++;
//   }
//   if(WiFi.status() == WL_CONNECTED) {
//     Serial.println("\nWiFi Connected.");
//   } else {
//     Serial.println("\nWiFi Failed! Audio won't work.");
//   }
  
//   Serial.print("Free Heap at Startup: ");
//   Serial.println(ESP.getFreeHeap());
// }

// // ------------------------------------
// // Loop
// // ------------------------------------
// void loop() {
//   // 1. معالجة الأوامر (هنا يتم التنفيذ الآمن)
//   if (hasNewCommand) {
//     executeCommand(pendingCommand);
//     hasNewCommand = false;
//     pendingCommand = "";
//   }

//   // 2. حلقة الصوت
//   if (mp3 && mp3->isRunning()) {
//     if (!mp3->loop()) {
//       Serial.println("Audio Finished.");
//       stopAudio();
//       sendBleResponse("AUDIO:FINISHED");
//     }
//   }

//   // 3. حلقة الحركة
//   if (isQuestionActive && answer == "") {
//     mpu.getMotion6(&accelX, &accelY, &accelZ, &gyroX, &gyroY, &gyroZ);
//     if (mode == "SHAKE") detectShake();
//     else if (mode == "TILTY") detectY();
//     else if (mode == "TILTZ") detectZ();
//   }
  
//   delay(1); 
// }




// #include <Wire.h>
// #include <MPU6050.h>
// #include <WiFi.h>

// // --- مكتبات الصوت ---
// #include "AudioFileSourceHTTPStream.h" 
// #include "AudioFileSourceBuffer.h"     
// #include "AudioGeneratorMP3.h"         
// #include "AudioOutputI2S.h"            

// #include <BLEDevice.h>
// #include <BLEServer.h>
// #include <BLEUtils.h>
// #include <BLE2902.h>

// // ===================================
// // !!      إعدادات الواي فاي      !!
// // ===================================
// const char* ssid = "Salman_4G"; 
// const char* password = "0566339996"; 

// // ===================================
// // !!      إعدادات الهاردوير      !!
// // ===================================
// #define SHUTDOWN_PIN 4 
// #define I2S_DOUT 25
// #define I2S_BCLK 26
// #define I2S_LRC  27

// // --- إعدادات حساس الحركة ---
// MPU6050 mpu(0x68);
// const float LIMIT_DEG = 20.0;
// const float SHAKE_LIMIT_G = 0.7;
// const float ACCEL_SCALE = 16384.0;
// int16_t accelX, accelY, accelZ, gyroX, gyroY, gyroZ;

// // --- كائنات الصوت ---
// AudioGeneratorMP3 *mp3 = NULL;
// AudioFileSourceHTTPStream *file_http = NULL;
// AudioFileSourceBuffer *buff = NULL;
// AudioOutputI2S *out = NULL;

// // --- متغيرات النظام ---
// bool isQuestionActive = false;
// String mode = "";
// String answer = "";
// bool hasNewCommand = false;
// String pendingCommand = "";

// // ===================================
// // !!      إعدادات البلوتوث BLE      !!
// // ===================================
// BLEServer *pServer = NULL;
// BLEService *pService = NULL;
// BLECharacteristic *pCommandCharacteristic = NULL;
// BLECharacteristic *pResponseCharacteristic = NULL;
// bool deviceConnected = false;

// #define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
// #define COMMAND_CHAR_UUID   "beb5483e-36e1-4688-b7f5-ea07361b26a8"
// #define RESPONSE_CHAR_UUID  "c3856242-4f7f-4a6c-b3d4-4a6e43f5a25c"

// // ------------------------------------
// // !! دالة إيقاف الصوت !!
// // ------------------------------------
// void stopAudio() {
//   if (mp3) { if (mp3->isRunning()) mp3->stop(); delete mp3; mp3 = NULL; }
//   if (buff) { buff->close(); delete buff; buff = NULL; }
//   if (file_http) { file_http->close(); delete file_http; file_http = NULL; }
//   if (out) { out->stop(); delete out; out = NULL; }
//   digitalWrite(SHUTDOWN_PIN, LOW); 
//   Serial.printf("RAM Cleaned: %d bytes free\n", ESP.getFreeHeap());
// }

// // ------------------------------------
// // تشغيل الصوت (النسخة النهائية)
// // ------------------------------------
// void playFileFromURL(const char* url) {
//   stopAudio(); 
//   Serial.println("--------------------------------");
//   Serial.print("Attempting Playback: "); Serial.println(url);

//   file_http = new AudioFileSourceHTTPStream(url);
  
//   // محاولة الاتصال
//   Serial.print("Connecting to server");
//   int t = 0;
//   while (!file_http->isOpen() && t < 15) { 
//       delay(200); t++; Serial.print("."); 
//   }
//   Serial.println();
  
//   if (!file_http->isOpen()) {
//       Serial.println("[ERROR] Connection Failed.");
//       stopAudio();
//       sendBleResponse("ERROR:LINK_DEAD");
//       return;
//   }
//   Serial.println("[OK] Server Connected!");

//   // !! التغيير الجذري هنا !!
//   // رفعنا البفر إلى 16000 بايت (16 كيلو)
//   // هذا سيحل مشكلة "Bad format" الناتجة عن ملفات الصوت ذات المقدمة الطويلة
//   buff = new AudioFileSourceBuffer(file_http, 16000);
  
//   out = new AudioOutputI2S();
//   out->SetPinout(I2S_BCLK, I2S_LRC, I2S_DOUT);
//   out->SetGain(1.0); 

//   mp3 = new AudioGeneratorMP3();
  
//   digitalWrite(SHUTDOWN_PIN, HIGH); 
//   delay(100); 

//   Serial.println("Starting MP3 Decoder...");
//   if (!mp3->begin(buff, out)) {
//     Serial.println("[ERROR] Decode Failed! Buffer might still be too small or format is weird.");
//     stopAudio(); 
//     sendBleResponse("AUDIO:ERROR");
//   } else {
//     Serial.println("[SUCCESS] Playback Started!");
//     sendBleResponse("AUDIO:STARTED");
//   }
// }

// // ------------------------------------
// // بقية الكود
// // ------------------------------------
// void sendBleResponse(String message) {
//   if (deviceConnected) {
//     pResponseCharacteristic->setValue(message.c_str());
//     pResponseCharacteristic->notify();
//   }
// }

// void executeCommand(String command) {
//   Serial.print("CMD: "); Serial.println(command);
  
//   String upperCmd = command;
//   upperCmd.toUpperCase();

//   if (upperCmd == "TEST_AUDIO") {
//       Serial.println("Testing with SoundHelix (Large Buffer Mode)...");
//       // هذا الملف سليم 100% لكن يحتاج بفر كبير
//       playFileFromURL("http://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3");
//   }
//   else if (upperCmd == "STOP_AUDIO") {
//     stopAudio();
//     sendBleResponse("AUDIO:STOPPED");
//   }
//   else if (upperCmd.startsWith("PLAY:")) {
//      String url = command.substring(5);
//      url.trim();
//      playFileFromURL(url.c_str());
//   }
//   else if (upperCmd.startsWith("START")) {
//      mode = upperCmd.substring(5);
//      mode.trim();
//      isQuestionActive = true;
//      answer = "";
//      sendBleResponse("READY:" + mode);
//   }
// }

// void detectShake() {
//   float acc_g = sqrt((float)accelX*accelX + (float)accelY*accelY + (float)accelZ*accelZ) / ACCEL_SCALE;
//   if (fabs(acc_g - 1.0) > SHAKE_LIMIT_G) {
//     answer = "SHAKE";
//     sendBleResponse(answer);
//     isQuestionActive = false;
//   }
// }
// void detectY() {
//   float angleY = atan2(accelX, sqrt(accelY*accelY + accelZ*accelZ)) * 180.0 / PI;
//   if (angleY > LIMIT_DEG) {
//     answer = "FORWARD";
//     sendBleResponse(answer);
//     isQuestionActive = false;
//   } else if (angleY < -LIMIT_DEG) {
//     answer = "BACK";
//     sendBleResponse(answer);
//     isQuestionActive = false;
//   }
// }
// void detectZ() {
//   float angleZ = atan2(accelY, accelZ) * 180.0 / PI;
//   if (angleZ > LIMIT_DEG) {
//     answer = "RIGHT";
//     sendBleResponse(answer);
//     isQuestionActive = false;
//   } else if (angleZ < -LIMIT_DEG) {
//     answer = "LEFT";
//     sendBleResponse(answer);
//     isQuestionActive = false;
//   }
// }

// class MyServerCallbacks: public BLEServerCallbacks {
//     void onConnect(BLEServer* pServer) {
//       deviceConnected = true;
//       Serial.println("Device connected");
//     }
//     void onDisconnect(BLEServer* pServer) {
//       deviceConnected = false;
//       BLEDevice::startAdvertising(); 
//     }
// };

// class MyCommandCallbacks: public BLECharacteristicCallbacks {
//     void onWrite(BLECharacteristic *pCharacteristic) {
//       std::string value = pCharacteristic->getValue().c_str();
//       if (value.length() > 0) {
//         pendingCommand = String(value.c_str());
//         pendingCommand.trim();
//         pendingCommand.replace("\n", "");
//         pendingCommand.replace("\r", "");
//         hasNewCommand = true;
//       }
//     }
// };

// void setup() {
//   Serial.begin(115200);
//   pinMode(SHUTDOWN_PIN, OUTPUT);
//   digitalWrite(SHUTDOWN_PIN, LOW);
  
//   BLEDevice::init("CUBIE");
//   pServer = BLEDevice::createServer();
//   pServer->setCallbacks(new MyServerCallbacks());
//   pService = pServer->createService(SERVICE_UUID);
  
//   pCommandCharacteristic = pService->createCharacteristic(COMMAND_CHAR_UUID, BLECharacteristic::PROPERTY_WRITE);
//   pCommandCharacteristic->setCallbacks(new MyCommandCallbacks());
//   pResponseCharacteristic = pService->createCharacteristic(RESPONSE_CHAR_UUID, BLECharacteristic::PROPERTY_NOTIFY);
//   pResponseCharacteristic->addDescriptor(new BLE2902());
  
//   pService->start();
//   BLEDevice::startAdvertising();

//   Wire.begin(21, 22);
//   mpu.initialize();
  
//   WiFi.begin(ssid, password);
//   Serial.print("WiFi");
//   while (WiFi.status() != WL_CONNECTED) { delay(500); Serial.print("."); }
//   Serial.println(" Connected");
// }

// void loop() {
//   if (hasNewCommand) {
//     executeCommand(pendingCommand);
//     hasNewCommand = false;
//     pendingCommand = "";
//   }

//   if (mp3 && mp3->isRunning()) {
//     if (!mp3->loop()) {
//       stopAudio();
//       sendBleResponse("AUDIO:FINISHED");
//     }
//   }

//   if (isQuestionActive && answer == "") {
//     mpu.getMotion6(&accelX, &accelY, &accelZ, &gyroX, &gyroY, &gyroZ);
//     if (mode == "SHAKE") detectShake();
//     else if (mode == "TILTY") detectY();
//     else if (mode == "TILTZ") detectZ();
//   }
//   delay(1); 
// }



// #include <Wire.h>
// #include <MPU6050.h>
// #include <WiFi.h>

// // --- مكتبات الصوت ---
// #include "AudioFileSourceHTTPStream.h" 
// #include "AudioFileSourceBuffer.h"     
// #include "AudioGeneratorMP3.h"         
// #include "AudioOutputI2S.h"            

// #include <BLEDevice.h>
// #include <BLEServer.h>
// #include <BLEUtils.h>
// #include <BLE2902.h>

// // ===================================
// // !!      إعدادات الواي فاي      !!
// // ===================================
// const char* ssid = "Salman_4G"; 
// const char* password = "0566339996"; 

// // ===================================
// // !!      إعدادات الهاردوير      !!
// // ===================================
// #define SHUTDOWN_PIN 4 
// #define I2S_DOUT 25
// #define I2S_BCLK 26
// #define I2S_LRC  27

// // --- إعدادات حساس الحركة ---
// MPU6050 mpu(0x68);
// const float LIMIT_DEG = 20.0;
// const float SHAKE_LIMIT_G = 0.7;
// const float ACCEL_SCALE = 16384.0;
// int16_t accelX, accelY, accelZ, gyroX, gyroY, gyroZ;

// // --- كائنات الصوت ---
// AudioGeneratorMP3 *mp3 = NULL;
// AudioFileSourceHTTPStream *file_http = NULL;
// AudioFileSourceBuffer *buff = NULL;
// AudioOutputI2S *out = NULL;

// // --- متغيرات النظام ---
// bool isQuestionActive = false;
// String mode = "";
// String answer = "";
// bool hasNewCommand = false;
// String pendingCommand = "";

// // ===================================
// // !!      إعدادات البلوتوث BLE      !!
// // ===================================
// BLEServer *pServer = NULL;
// BLEService *pService = NULL;
// BLECharacteristic *pCommandCharacteristic = NULL;
// BLECharacteristic *pResponseCharacteristic = NULL;
// bool deviceConnected = false;

// #define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
// #define COMMAND_CHAR_UUID   "beb5483e-36e1-4688-b7f5-ea07361b26a8"
// #define RESPONSE_CHAR_UUID  "c3856242-4f7f-4a6c-b3d4-4a6e43f5a25c"

// // ------------------------------------
// // !! دالة إيقاف الصوت !!
// // ------------------------------------
// void stopAudio() {
//   if (mp3) { 
//     if (mp3->isRunning()) mp3->stop(); 
//     delete mp3; 
//     mp3 = NULL; 
//   }
//   if (buff) { 
//     buff->close(); 
//     delete buff; 
//     buff = NULL; 
//   }
//   if (file_http) { 
//     file_http->close(); 
//     delete file_http; 
//     file_http = NULL; 
//   }
//   if (out) { 
//     out->stop(); 
//     delete out; 
//     out = NULL; 
//   }
//   digitalWrite(SHUTDOWN_PIN, LOW); 
//   Serial.printf("RAM Cleaned: %d bytes free\n", ESP.getFreeHeap());
// }

// // ------------------------------------
// // تشغيل الصوت (النسخة المحسنة)
// // ------------------------------------
// void playFileFromURL(const char* url) {
//   stopAudio(); 
  
//   // انتظر قليلاً للسماح بتنظيف الذاكرة
//   delay(100);
  
//   Serial.println("================================");
//   Serial.printf("Free RAM before playback: %d bytes\n", ESP.getFreeHeap());
//   Serial.print("Attempting: "); Serial.println(url);

//   // === الخطوة 1: إنشاء مصدر HTTP ===
//   file_http = new AudioFileSourceHTTPStream(url);
//   if (!file_http) {
//     Serial.println("[ERROR] Failed to create HTTP stream!");
//     sendBleResponse("ERROR:NO_MEMORY");
//     return;
//   }
  
//   // محاولة الاتصال
//   Serial.print("Connecting");
//   int timeout = 0;
//   while (!file_http->isOpen() && timeout < 20) { 
//     delay(250); 
//     timeout++; 
//     Serial.print("."); 
//   }
//   Serial.println();
  
//   if (!file_http->isOpen()) {
//     Serial.println("[ERROR] Connection timeout!");
//     stopAudio();
//     sendBleResponse("ERROR:NO_CONNECTION");
//     return;
//   }
//   Serial.println("[OK] Connected!");

//   // === الخطوة 2: إنشاء البفر (جرب أحجام مختلفة) ===
//   // جرب 8KB أولاً (أفضل للذاكرة)
//   Serial.println("Creating buffer (8192 bytes)...");
//   buff = new AudioFileSourceBuffer(file_http, 8192);
//   if (!buff) {
//     Serial.println("[ERROR] Failed to create buffer!");
//     stopAudio();
//     sendBleResponse("ERROR:NO_BUFFER");
//     return;
//   }
  
//   Serial.printf("Free RAM after buffer: %d bytes\n", ESP.getFreeHeap());

//   // === الخطوة 3: إعداد I2S بشكل صحيح ===
//   out = new AudioOutputI2S(0, 1); // استخدم I2S port 0, DAC mode
//   if (!out) {
//     Serial.println("[ERROR] Failed to create I2S output!");
//     stopAudio();
//     sendBleResponse("ERROR:NO_I2S");
//     return;
//   }
  
//   out->SetPinout(I2S_BCLK, I2S_LRC, I2S_DOUT);
//   out->SetGain(1.0);
//   out->SetOutputModeMono(false); // Stereo
  
//   // === الخطوة 4: إنشاء مفكك MP3 ===
//   mp3 = new AudioGeneratorMP3();
//   if (!mp3) {
//     Serial.println("[ERROR] Failed to create MP3 decoder!");
//     stopAudio();
//     sendBleResponse("ERROR:NO_DECODER");
//     return;
//   }
  
//   // تفعيل السماعة
//   digitalWrite(SHUTDOWN_PIN, HIGH); 
//   delay(150); // زيادة التأخير للسماح للسماعة بالتشغيل

//   // === الخطوة 5: بدء التشغيل ===
//   Serial.println("Starting MP3 playback...");
//   Serial.printf("Free RAM before begin(): %d bytes\n", ESP.getFreeHeap());
  
//   if (!mp3->begin(buff, out)) {
//     Serial.println("╔════════════════════════════════════╗");
//     Serial.println("║  [ERROR] MP3 Decode Failed!        ║");
//     Serial.println("╠════════════════════════════════════╣");
//     Serial.println("║  Possible causes:                  ║");
//     Serial.println("║  1. File format not supported      ║");
//     Serial.println("║  2. Corrupted/incomplete download  ║");
//     Serial.println("║  3. Not a valid MP3 file           ║");
//     Serial.println("║  4. Buffer underrun                ║");
//     Serial.println("╚════════════════════════════════════╝");
    
//     stopAudio(); 
//     sendBleResponse("ERROR:DECODE_FAILED");
//   } else {
//     Serial.println("╔════════════════════════════════════╗");
//     Serial.println("║     [SUCCESS] Playing!             ║");
//     Serial.println("╚════════════════════════════════════╝");
//     Serial.printf("Free RAM during playback: %d bytes\n", ESP.getFreeHeap());
//     sendBleResponse("AUDIO:PLAYING");
//   }
// }

// // ------------------------------------
// // بقية الكود
// // ------------------------------------
// void sendBleResponse(String message) {
//   if (deviceConnected && pResponseCharacteristic) {
//     pResponseCharacteristic->setValue(message.c_str());
//     pResponseCharacteristic->notify();
//     Serial.print("BLE Response: "); Serial.println(message);
//   }
// }

// void executeCommand(String command) {
//   Serial.print("╔═══ CMD: "); Serial.print(command); Serial.println(" ═══╗");
  
//   String upperCmd = command;
//   upperCmd.toUpperCase();

//   if (upperCmd == "TEST_AUDIO") {
//     Serial.println("Testing with known-good MP3...");
//     // جرب هذا الرابط البديل الأخف والأصغر
//     playFileFromURL("http://commondatastorage.googleapis.com/codeskulptor-assets/Epoq-Lepidoptera.ogg");
//   }
//   else if (upperCmd == "TEST_SMALL") {
//     // ملف MP3 صغير جداً للاختبار
//     playFileFromURL("http://www.soundjay.com/button/sounds/button-09.mp3");
//   }
//   else if (upperCmd == "STOP_AUDIO") {
//     stopAudio();
//     sendBleResponse("AUDIO:STOPPED");
//   }
//   else if (upperCmd.startsWith("PLAY:")) {
//     String url = command.substring(5);
//     url.trim();
//     Serial.print("URL to play: "); Serial.println(url);
//     playFileFromURL(url.c_str());
//   }
//   else if (upperCmd.startsWith("START")) {
//     mode = upperCmd.substring(5);
//     mode.trim();
//     isQuestionActive = true;
//     answer = "";
//     sendBleResponse("READY:" + mode);
//   }
//   else if (upperCmd == "STATUS") {
//     Serial.printf("RAM: %d bytes | Connected: %s | Playing: %s\n", 
//                   ESP.getFreeHeap(), 
//                   deviceConnected ? "YES" : "NO",
//                   (mp3 && mp3->isRunning()) ? "YES" : "NO");
//     sendBleResponse("STATUS:OK");
//   }
// }

// void detectShake() {
//   float acc_g = sqrt((float)accelX*accelX + (float)accelY*accelY + (float)accelZ*accelZ) / ACCEL_SCALE;
//   if (fabs(acc_g - 1.0) > SHAKE_LIMIT_G) {
//     answer = "SHAKE";
//     sendBleResponse(answer);
//     isQuestionActive = false;
//   }
// }

// void detectY() {
//   float angleY = atan2(accelX, sqrt(accelY*accelY + accelZ*accelZ)) * 180.0 / PI;
//   if (angleY > LIMIT_DEG) {
//     answer = "FORWARD";
//     sendBleResponse(answer);
//     isQuestionActive = false;
//   } else if (angleY < -LIMIT_DEG) {
//     answer = "BACK";
//     sendBleResponse(answer);
//     isQuestionActive = false;
//   }
// }

// void detectZ() {
//   float angleZ = atan2(accelY, accelZ) * 180.0 / PI;
//   if (angleZ > LIMIT_DEG) {
//     answer = "RIGHT";
//     sendBleResponse(answer);
//     isQuestionActive = false;
//   } else if (angleZ < -LIMIT_DEG) {
//     answer = "LEFT";
//     sendBleResponse(answer);
//     isQuestionActive = false;
//   }
// }

// class MyServerCallbacks: public BLEServerCallbacks {
//     void onConnect(BLEServer* pServer) {
//       deviceConnected = true;
//       Serial.println("╔═════════════════════════╗");
//       Serial.println("║  BLE Device Connected!  ║");
//       Serial.println("╚═════════════════════════╝");
//     }
//     void onDisconnect(BLEServer* pServer) {
//       deviceConnected = false;
//       Serial.println("Device disconnected - restarting advertising");
//       BLEDevice::startAdvertising(); 
//     }
// };

// class MyCommandCallbacks: public BLECharacteristicCallbacks {
//     void onWrite(BLECharacteristic *pCharacteristic) {
//       std::string value = pCharacteristic->getValue().c_str();
//       if (value.length() > 0) {
//         pendingCommand = String(value.c_str());
//         pendingCommand.trim();
//         pendingCommand.replace("\n", "");
//         pendingCommand.replace("\r", "");
//         hasNewCommand = true;
//       }
//     }
// };

// void setup() {
//   Serial.begin(115200);
//   delay(1000);
  
//   Serial.println("╔══════════════════════════════╗");
//   Serial.println("║      CUBIE Starting...       ║");
//   Serial.println("╚══════════════════════════════╝");
  
//   pinMode(SHUTDOWN_PIN, OUTPUT);
//   digitalWrite(SHUTDOWN_PIN, LOW);
  
//   // === BLE Setup ===
//   Serial.println("Initializing BLE...");
//   BLEDevice::init("CUBIE");
//   pServer = BLEDevice::createServer();
//   pServer->setCallbacks(new MyServerCallbacks());
//   pService = pServer->createService(SERVICE_UUID);
  
//   pCommandCharacteristic = pService->createCharacteristic(
//     COMMAND_CHAR_UUID, 
//     BLECharacteristic::PROPERTY_WRITE
//   );
//   pCommandCharacteristic->setCallbacks(new MyCommandCallbacks());
  
//   pResponseCharacteristic = pService->createCharacteristic(
//     RESPONSE_CHAR_UUID, 
//     BLECharacteristic::PROPERTY_NOTIFY
//   );
//   pResponseCharacteristic->addDescriptor(new BLE2902());
  
//   pService->start();
//   BLEDevice::startAdvertising();
//   Serial.println("✓ BLE Ready");

//   // === MPU6050 Setup ===
//   Serial.println("Initializing MPU6050...");
//   Wire.begin(21, 22);
//   mpu.initialize();
//   Serial.println(mpu.testConnection() ? "✓ MPU6050 OK" : "✗ MPU6050 Failed");
  
//   // === WiFi Setup ===
//   Serial.print("Connecting to WiFi");
//   WiFi.begin(ssid, password);
//   int wifi_tries = 0;
//   while (WiFi.status() != WL_CONNECTED && wifi_tries < 40) { 
//     delay(500); 
//     Serial.print("."); 
//     wifi_tries++;
//   }
  
//   if (WiFi.status() == WL_CONNECTED) {
//     Serial.println("\n✓ WiFi Connected");
//     Serial.print("IP: "); Serial.println(WiFi.localIP());
//   } else {
//     Serial.println("\n✗ WiFi Failed!");
//   }
  
//   Serial.println("╔══════════════════════════════╗");
//   Serial.println("║      System Ready! 🚀        ║");
//   Serial.println("╚══════════════════════════════╝");
//   Serial.printf("Free RAM: %d bytes\n\n", ESP.getFreeHeap());
// }

// void loop() {
//   // معالجة الأوامر الواردة
//   if (hasNewCommand) {
//     executeCommand(pendingCommand);
//     hasNewCommand = false;
//     pendingCommand = "";
//   }

//   // تحديث تشغيل الصوت
//   if (mp3 && mp3->isRunning()) {
//     if (!mp3->loop()) {
//       Serial.println("Audio finished naturally");
//       stopAudio();
//       sendBleResponse("AUDIO:FINISHED");
//     }
//   }

//   //
//   // كشف الحركة
//   if (isQuestionActive && answer == "") {
//     mpu.getMotion6(&accelX, &accelY, &accelZ, &gyroX, &gyroY, &gyroZ);
//     if (mode == "SHAKE") detectShake();
//     else if (mode == "TILTY") detectY();
//     else if (mode == "TILTZ") detectZ();
//   }
  
//   delay(1); 
// }



// #include <Wire.h>
// #include <MPU6050.h>
// #include <WiFi.h>

// // --- مكتبات الصوت ---
// #include "AudioFileSourceHTTPStream.h" 
// #include "AudioFileSourceBuffer.h"     
// #include "AudioGeneratorMP3.h"         
// #include "AudioOutputI2S.h"            

// #include <BLEDevice.h>
// #include <BLEServer.h>
// #include <BLEUtils.h>
// #include <BLE2902.h>

// // ===================================
// // !!      إعدادات الواي فاي      !!
// // ===================================
// const char* ssid = "Salman_4G"; 
// const char* password = "0566339996"; 

// // ===================================
// // !!      إعدادات الهاردوير      !!
// // ===================================
// #define SHUTDOWN_PIN 4 
// #define I2S_DOUT 25
// #define I2S_BCLK 26
// #define I2S_LRC  27

// // --- إعدادات حساس الحركة ---
// MPU6050 mpu(0x68);
// const float LIMIT_DEG = 20.0;
// const float SHAKE_LIMIT_G = 0.7;
// const float ACCEL_SCALE = 16384.0;
// int16_t accelX, accelY, accelZ, gyroX, gyroY, gyroZ;

// // --- كائنات الصوت ---
// AudioGeneratorMP3 *mp3 = NULL;
// AudioFileSourceHTTPStream *file_http = NULL;
// AudioFileSourceBuffer *buff = NULL;
// AudioOutputI2S *out = NULL;

// // --- متغيرات النظام ---
// bool isQuestionActive = false;
// String mode = "";
// String answer = "";
// bool hasNewCommand = false;
// String pendingCommand = "";

// // ===================================
// // !!      إعدادات البلوتوث BLE      !!
// // ===================================
// BLEServer *pServer = NULL;
// BLEService *pService = NULL;
// BLECharacteristic *pCommandCharacteristic = NULL;
// BLECharacteristic *pResponseCharacteristic = NULL;
// bool deviceConnected = false;

// #define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
// #define COMMAND_CHAR_UUID   "beb5483e-36e1-4688-b7f5-ea07361b26a8"
// #define RESPONSE_CHAR_UUID  "c3856242-4f7f-4a6c-b3d4-4a6e43f5a25c"

// // ------------------------------------
// // !! دالة إيقاف الصوت !!
// // ------------------------------------
// void stopAudio() {
//   if (mp3) { 
//     if (mp3->isRunning()) mp3->stop(); 
//     delete mp3; 
//     mp3 = NULL; 
//   }
//   if (buff) { 
//     buff->close(); 
//     delete buff; 
//     buff = NULL; 
//   }
//   if (file_http) { 
//     file_http->close(); 
//     delete file_http; 
//     file_http = NULL; 
//   }
//   if (out) { 
//     out->stop(); 
//     delete out; 
//     out = NULL; 
//   }
//   digitalWrite(SHUTDOWN_PIN, LOW); 
//   Serial.printf("RAM Cleaned: %d bytes free\n", ESP.getFreeHeap());
// }

// // ------------------------------------
// // تشغيل الصوت (النسخة المحسنة)
// // ------------------------------------
// void playFileFromURL(const char* url) {
//   stopAudio(); 
  
//   // انتظر قليلاً للسماح بتنظيف الذاكرة
//   delay(100);
  
//   Serial.println("================================");
//   Serial.printf("Free RAM before playback: %d bytes\n", ESP.getFreeHeap());
//   Serial.print("Attempting: "); Serial.println(url);

//   // === الخطوة 1: إنشاء مصدر HTTP ===
//   file_http = new AudioFileSourceHTTPStream(url);
//   if (!file_http) {
//     Serial.println("[ERROR] Failed to create HTTP stream!");
//     sendBleResponse("ERROR:NO_MEMORY");
//     return;
//   }
  
//   // محاولة الاتصال
//   Serial.print("Connecting");
//   int timeout = 0;
//   while (!file_http->isOpen() && timeout < 20) { 
//     delay(250); 
//     timeout++; 
//     Serial.print("."); 
//   }
//   Serial.println();
  
//   if (!file_http->isOpen()) {
//     Serial.println("[ERROR] Connection timeout!");
//     stopAudio();
//     sendBleResponse("ERROR:NO_CONNECTION");
//     return;
//   }
//   Serial.println("[OK] Connected!");

//   // === الخطوة 2: إنشاء البفر (جرب أحجام مختلفة) ===
//   // جرب 8KB أولاً (أفضل للذاكرة)
//   Serial.println("Creating buffer (8192 bytes)...");
//   buff = new AudioFileSourceBuffer(file_http, 8192);
//   if (!buff) {
//     Serial.println("[ERROR] Failed to create buffer!");
//     stopAudio();
//     sendBleResponse("ERROR:NO_BUFFER");
//     return;
//   }
  
//   Serial.printf("Free RAM after buffer: %d bytes\n", ESP.getFreeHeap());

//   // === الخطوة 3: إعداد I2S بشكل صحيح ===
//   out = new AudioOutputI2S(0, 1); // استخدم I2S port 0, DAC mode
//   if (!out) {
//     Serial.println("[ERROR] Failed to create I2S output!");
//     stopAudio();
//     sendBleResponse("ERROR:NO_I2S");
//     return;
//   }
  
//   out->SetPinout(I2S_BCLK, I2S_LRC, I2S_DOUT);
//   out->SetGain(1.0);
//   out->SetOutputModeMono(false); // Stereo
  
//   // === الخطوة 4: إنشاء مفكك MP3 ===
//   mp3 = new AudioGeneratorMP3();
//   if (!mp3) {
//     Serial.println("[ERROR] Failed to create MP3 decoder!");
//     stopAudio();
//     sendBleResponse("ERROR:NO_DECODER");
//     return;
//   }
  
//   // تفعيل السماعة
//   digitalWrite(SHUTDOWN_PIN, HIGH); 
//   delay(150); // زيادة التأخير للسماح للسماعة بالتشغيل

//   // === الخطوة 5: بدء التشغيل ===
//   Serial.println("Starting MP3 playback...");
//   Serial.printf("Free RAM before begin(): %d bytes\n", ESP.getFreeHeap());
  
//   if (!mp3->begin(buff, out)) {
//     Serial.println("╔════════════════════════════════════╗");
//     Serial.println("║  [ERROR] MP3 Decode Failed!        ║");
//     Serial.println("╠════════════════════════════════════╣");
//     Serial.println("║  Possible causes:                  ║");
//     Serial.println("║  1. File format not supported      ║");
//     Serial.println("║  2. Corrupted/incomplete download  ║");
//     Serial.println("║  3. Not a valid MP3 file           ║");
//     Serial.println("║  4. Buffer underrun                ║");
//     Serial.println("╚════════════════════════════════════╝");
    
//     stopAudio(); 
//     sendBleResponse("ERROR:DECODE_FAILED");
//   } else {
//     Serial.println("╔════════════════════════════════════╗");
//     Serial.println("║     [SUCCESS] Playing!             ║");
//     Serial.println("╚════════════════════════════════════╝");
//     Serial.printf("Free RAM during playback: %d bytes\n", ESP.getFreeHeap());
//     sendBleResponse("AUDIO:PLAYING");
//   }
// }

// // ------------------------------------
// // بقية الكود
// // ------------------------------------
// void sendBleResponse(String message) {
//   if (deviceConnected && pResponseCharacteristic) {
//     pResponseCharacteristic->setValue(message.c_str());
//     pResponseCharacteristic->notify();
//     Serial.print("BLE Response: "); Serial.println(message);
//   }
// }

// void executeCommand(String command) {
//   Serial.print("╔═══ CMD: "); Serial.print(command); Serial.println(" ═══╗");
  
//   String upperCmd = command;
//   upperCmd.toUpperCase();

//   if (upperCmd == "TEST_AUDIO") {
//     Serial.println("Testing with SoundHelix MP3...");
//     playFileFromURL("http://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3");
//   }
//   else if (upperCmd == "TEST_SMALL") {
//     // ملف MP3 صغير جداً للاختبار (266 KB)
//     playFileFromURL("http://commondatastorage.googleapis.com/codeskulptor-demos/DDR_assets/Kangaroo_MusiQue_-_The_Neverwritten_Role_Playing_Game.mp3");
//   }
//   else if (upperCmd == "TEST_TINY") {
//     // ملف صوتي صغير جداً جداً للاختبار
//     playFileFromURL("http://www.soundjay.com/button/sounds/button-09.mp3");
//   }
//   else if (upperCmd == "STOP_AUDIO") {
//     stopAudio();
//     sendBleResponse("AUDIO:STOPPED");
//   }
//   else if (upperCmd.startsWith("PLAY:")) {
//     String url = command.substring(5);
//     url.trim();
//     Serial.print("URL to play: "); Serial.println(url);
//     playFileFromURL(url.c_str());
//   }
//   else if (upperCmd.startsWith("START")) {
//     mode = upperCmd.substring(5);
//     mode.trim();
//     isQuestionActive = true;
//     answer = "";
//     sendBleResponse("READY:" + mode);
//   }
//   else if (upperCmd == "STATUS") {
//     Serial.printf("RAM: %d bytes | Connected: %s | Playing: %s\n", 
//                   ESP.getFreeHeap(), 
//                   deviceConnected ? "YES" : "NO",
//                   (mp3 && mp3->isRunning()) ? "YES" : "NO");
//     sendBleResponse("STATUS:OK");
//   }
// }

// void detectShake() {
//   float acc_g = sqrt((float)accelX*accelX + (float)accelY*accelY + (float)accelZ*accelZ) / ACCEL_SCALE;
//   if (fabs(acc_g - 1.0) > SHAKE_LIMIT_G) {
//     answer = "SHAKE";
//     sendBleResponse(answer);
//     isQuestionActive = false;
//   }
// }

// void detectY() {
//   float angleY = atan2(accelX, sqrt(accelY*accelY + accelZ*accelZ)) * 180.0 / PI;
//   if (angleY > LIMIT_DEG) {
//     answer = "FORWARD";
//     sendBleResponse(answer);
//     isQuestionActive = false;
//   } else if (angleY < -LIMIT_DEG) {
//     answer = "BACK";
//     sendBleResponse(answer);
//     isQuestionActive = false;
//   }
// }

// void detectZ() {
//   float angleZ = atan2(accelY, accelZ) * 180.0 / PI;
//   if (angleZ > LIMIT_DEG) {
//     answer = "RIGHT";
//     sendBleResponse(answer);
//     isQuestionActive = false;
//   } else if (angleZ < -LIMIT_DEG) {
//     answer = "LEFT";
//     sendBleResponse(answer);
//     isQuestionActive = false;
//   }
// }

// class MyServerCallbacks: public BLEServerCallbacks {
//     void onConnect(BLEServer* pServer) {
//       deviceConnected = true;
//       Serial.println("╔═════════════════════════╗");
//       Serial.println("║  BLE Device Connected!  ║");
//       Serial.println("╚═════════════════════════╝");
//     }
//     void onDisconnect(BLEServer* pServer) {
//       deviceConnected = false;
//       Serial.println("Device disconnected - restarting advertising");
//       BLEDevice::startAdvertising(); 
//     }
// };

// class MyCommandCallbacks: public BLECharacteristicCallbacks {
//     void onWrite(BLECharacteristic *pCharacteristic) {
//       std::string value = pCharacteristic->getValue().c_str();
//       if (value.length() > 0) {
//         pendingCommand = String(value.c_str());
//         pendingCommand.trim();
//         pendingCommand.replace("\n", "");
//         pendingCommand.replace("\r", "");
//         hasNewCommand = true;
//       }
//     }
// };

// void setup() {
//   Serial.begin(115200);
//   delay(1000);
  
//   Serial.println("╔══════════════════════════════╗");
//   Serial.println("║      CUBIE Starting...       ║");
//   Serial.println("╚══════════════════════════════╝");
  
//   pinMode(SHUTDOWN_PIN, OUTPUT);
//   digitalWrite(SHUTDOWN_PIN, LOW);
  
//   // === BLE Setup ===
//   Serial.println("Initializing BLE...");
//   BLEDevice::init("CUBIE");
//   pServer = BLEDevice::createServer();
//   pServer->setCallbacks(new MyServerCallbacks());
//   pService = pServer->createService(SERVICE_UUID);
  
//   pCommandCharacteristic = pService->createCharacteristic(
//     COMMAND_CHAR_UUID, 
//     BLECharacteristic::PROPERTY_WRITE
//   );
//   pCommandCharacteristic->setCallbacks(new MyCommandCallbacks());
  
//   pResponseCharacteristic = pService->createCharacteristic(
//     RESPONSE_CHAR_UUID, 
//     BLECharacteristic::PROPERTY_NOTIFY
//   );
//   pResponseCharacteristic->addDescriptor(new BLE2902());
  
//   pService->start();
//   BLEDevice::startAdvertising();
//   Serial.println("✓ BLE Ready");

//   // === MPU6050 Setup ===
//   Serial.println("Initializing MPU6050...");
//   Wire.begin(21, 22);
//   mpu.initialize();
//   Serial.println(mpu.testConnection() ? "✓ MPU6050 OK" : "✗ MPU6050 Failed");
  
//   // === WiFi Setup ===
//   Serial.print("Connecting to WiFi");
//   WiFi.begin(ssid, password);
//   int wifi_tries = 0;
//   while (WiFi.status() != WL_CONNECTED && wifi_tries < 40) { 
//     delay(500); 
//     Serial.print("."); 
//     wifi_tries++;
//   }
  
//   if (WiFi.status() == WL_CONNECTED) {
//     Serial.println("\n✓ WiFi Connected");
//     Serial.print("IP: "); Serial.println(WiFi.localIP());
//   } else {
//     Serial.println("\n✗ WiFi Failed!");
//   }
  
//   Serial.println("╔══════════════════════════════╗");
//   Serial.println("║      System Ready! 🚀        ║");
//   Serial.println("╚══════════════════════════════╝");
//   Serial.printf("Free RAM: %d bytes\n\n", ESP.getFreeHeap());
// }

// void loop() {
//   // معالجة الأوامر الواردة
//   if (hasNewCommand) {
//     executeCommand(pendingCommand);
//     hasNewCommand = false;
//     pendingCommand = "";
//   }

//   // تحديث تشغيل الصوت
//   if (mp3 && mp3->isRunning()) {
//     if (!mp3->loop()) {
//       Serial.println("Audio finished naturally");
//       stopAudio();
//       sendBleResponse("AUDIO:FINISHED");
//     }
//   }

//   // كشف الحركة
//   if (isQuestionActive && answer == "") {
//     mpu.getMotion6(&accelX, &accelY, &accelZ, &gyroX, &gyroY, &gyroZ);
//     if (mode == "SHAKE") detectShake();
//     else if (mode == "TILTY") detectY();
//     else if (mode == "TILTZ") detectZ();
//   }
  
//   delay(1); 
// }












// #include <Wire.h>
// #include <MPU6050.h>
// #include <WiFi.h>

// // --- مكتبات الصوت ---
// #include "AudioFileSourceHTTPStream.h" 
// #include "AudioFileSourceBuffer.h"     
// #include "AudioGeneratorMP3.h"         
// #include "AudioOutputI2S.h"            

// #include <BLEDevice.h>
// #include <BLEServer.h>
// #include <BLEUtils.h>
// #include <BLE2902.h>

// // ===================================
// // !!      إعدادات الواي فاي      !!
// // ===================================
// const char* ssid = "Salman_4G"; 
// const char* password = "0566339996"; 

// // ===================================
// // !!      إعدادات الهاردوير      !!
// // ===================================
// #define SHUTDOWN_PIN 4 
// #define I2S_DOUT 25
// #define I2S_BCLK 26
// #define I2S_LRC  27

// // --- إعدادات حساس الحركة ---
// MPU6050 mpu(0x68);
// const float LIMIT_DEG = 20.0;
// const float SHAKE_LIMIT_G = 0.7;
// const float ACCEL_SCALE = 16384.0;
// int16_t accelX, accelY, accelZ, gyroX, gyroY, gyroZ;

// // --- كائنات الصوت ---
// AudioGeneratorMP3 *mp3 = NULL;
// AudioFileSourceHTTPStream *file_http = NULL;
// AudioFileSourceBuffer *buff = NULL;
// AudioOutputI2S *out = NULL;

// // --- متغيرات النظام ---
// bool isQuestionActive = false;
// String mode = "";
// String answer = "";
// bool hasNewCommand = false;
// String pendingCommand = "";

// // ===================================
// // !!      إعدادات البلوتوث BLE      !!
// // ===================================
// BLEServer *pServer = NULL;
// BLEService *pService = NULL;
// BLECharacteristic *pCommandCharacteristic = NULL;
// BLECharacteristic *pResponseCharacteristic = NULL;
// bool deviceConnected = false;

// #define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
// #define COMMAND_CHAR_UUID   "beb5483e-36e1-4688-b7f5-ea07361b26a8"
// #define RESPONSE_CHAR_UUID  "c3856242-4f7f-4a6c-b3d4-4a6e43f5a25c"

// // ------------------------------------
// // !! دالة إيقاف الصوت المحسّنة !!
// // ------------------------------------
// void stopAudio() {
//   Serial.println("→ Stopping audio...");
  
//   // إيقاف المكبر أولاً
//   digitalWrite(SHUTDOWN_PIN, LOW); 
//   delay(50);
  
//   // تنظيف MP3 Decoder
//   if (mp3) { 
//     if (mp3->isRunning()) {
//       mp3->stop(); 
//     }
//     delete mp3; 
//     mp3 = NULL; 
//   }
  
//   // تنظيف Buffer
//   if (buff) { 
//     buff->close(); 
//     delete buff; 
//     buff = NULL; 
//   }
  
//   // تنظيف HTTP Stream
//   if (file_http) { 
//     file_http->close(); 
//     delete file_http; 
//     file_http = NULL; 
//   }
  
//   // تنظيف I2S Output
//   if (out) { 
//     out->stop();
//     delete out; 
//     out = NULL; 
//   }
  
//   delay(150); // وقت إضافي للتنظيف الكامل
//   Serial.printf("✓ RAM Freed: %d bytes\n", ESP.getFreeHeap());
// }

// // ------------------------------------
// // !! الحل الجديد - بدون Buffer أولاً !!
// // ------------------------------------
// void playFileFromURL_NoBuff(const char* url) {
//   stopAudio();
//   delay(300); // وقت كافٍ للتنظيف
  
//   Serial.println("\n╔═══════════════════════════════════╗");
//   Serial.println("║   Playing WITHOUT Buffer          ║");
//   Serial.println("╚═══════════════════════════════════╝");
//   Serial.printf("Free RAM: %d bytes\n", ESP.getFreeHeap());
//   Serial.print("URL: "); Serial.println(url);
//   Serial.println();

//   // === إنشاء HTTP Stream ===
//   file_http = new AudioFileSourceHTTPStream(url);
//   if (!file_http) {
//     Serial.println("✗ Failed to create HTTP stream");
//     sendBleResponse("ERROR:NO_MEMORY");
//     return;
//   }
  
//   Serial.print("Connecting");
//   int timeout = 0;
//   while (!file_http->isOpen() && timeout < 30) { 
//     delay(250); 
//     timeout++; 
//     Serial.print("."); 
//   }
//   Serial.println();
  
//   if (!file_http->isOpen()) {
//     Serial.println("✗ Connection timeout");
//     stopAudio();
//     sendBleResponse("ERROR:CONNECTION_TIMEOUT");
//     return;
//   }
//   Serial.println("✓ Connected to server!");

//   // === إنشاء I2S Output ===
//   out = new AudioOutputI2S(0, AudioOutputI2S::EXTERNAL_I2S);
//   if (!out) {
//     Serial.println("✗ Failed to create I2S");
//     stopAudio();
//     sendBleResponse("ERROR:I2S_FAILED");
//     return;
//   }
  
//   out->SetPinout(I2S_BCLK, I2S_LRC, I2S_DOUT);
//   out->SetGain(1.0);
//   Serial.println("✓ I2S configured");

//   // === إنشاء MP3 Decoder ===
//   mp3 = new AudioGeneratorMP3();
//   if (!mp3) {
//     Serial.println("✗ Failed to create MP3 decoder");
//     stopAudio();
//     sendBleResponse("ERROR:DECODER_FAILED");
//     return;
//   }
//   Serial.println("✓ MP3 decoder ready");
  
//   // تشغيل المكبر
//   digitalWrite(SHUTDOWN_PIN, HIGH); 
//   delay(200);
//   Serial.println("✓ Amplifier ON");

//   // === بدء التشغيل مباشرة بدون Buffer ===
//   Serial.println("\n→ Starting playback (no buffer)...");
//   Serial.printf("Free RAM: %d bytes\n", ESP.getFreeHeap());
  
//   if (mp3->begin(file_http, out)) {
//     Serial.println("\n╔═══════════════════════════════════╗");
//     Serial.println("║   ✓✓✓ SUCCESS! PLAYING! ✓✓✓      ║");
//     Serial.println("╚═══════════════════════════════════╝\n");
//     sendBleResponse("AUDIO:PLAYING");
//   } else {
//     Serial.println("\n╔═══════════════════════════════════╗");
//     Serial.println("║   ✗ FAILED - See details below    ║");
//     Serial.println("╚═══════════════════════════════════╝");
//     Serial.println("This means the MP3 library has issues.");
//     Serial.println("Solutions:");
//     Serial.println("1. Update ESP8266Audio library");
//     Serial.println("2. Check I2S wiring");
//     Serial.println("3. Try: Tools → Partition Scheme → Huge APP\n");
//     stopAudio();
//     sendBleResponse("ERROR:PLAYBACK_FAILED");
//   }
// }

// // ------------------------------------
// // !! النسخة مع Buffer (إذا احتجتها) !!
// // ------------------------------------
// void playFileFromURL_WithBuff(const char* url) {
//   stopAudio();
//   delay(300);
  
//   Serial.println("\n╔═══════════════════════════════════╗");
//   Serial.println("║   Playing WITH Buffer (16KB)      ║");
//   Serial.println("╚═══════════════════════════════════╝");
//   Serial.printf("Free RAM: %d bytes\n", ESP.getFreeHeap());
//   Serial.print("URL: "); Serial.println(url);

//   // HTTP Stream
//   file_http = new AudioFileSourceHTTPStream(url);
//   if (!file_http) {
//     Serial.println("✗ HTTP stream creation failed");
//     sendBleResponse("ERROR:NO_MEMORY");
//     return;
//   }
  
//   Serial.print("Connecting");
//   int t = 0;
//   while (!file_http->isOpen() && t < 30) { 
//     delay(250); 
//     t++; 
//     Serial.print("."); 
//   }
//   Serial.println();
  
//   if (!file_http->isOpen()) {
//     Serial.println("✗ Connection failed");
//     stopAudio();
//     sendBleResponse("ERROR:NO_CONNECTION");
//     return;
//   }
//   Serial.println("✓ Connected!");

//   // Buffer كبير
//   Serial.println("Creating 16KB buffer...");
//   buff = new AudioFileSourceBuffer(file_http, 16384);
//   if (!buff) {
//     Serial.println("✗ Buffer creation failed");
//     stopAudio();
//     sendBleResponse("ERROR:NO_BUFFER");
//     return;
//   }
  
//   // انتظر ملء Buffer
//   Serial.print("Pre-buffering");
//   for(int i = 0; i < 15; i++) {
//     delay(100);
//     Serial.print(".");
//   }
//   Serial.println(" Done!");
//   Serial.printf("Free RAM: %d bytes\n", ESP.getFreeHeap());

//   // I2S
//   out = new AudioOutputI2S(0, AudioOutputI2S::EXTERNAL_I2S);
//   if (!out) {
//     Serial.println("✗ I2S failed");
//     stopAudio();
//     sendBleResponse("ERROR:I2S");
//     return;
//   }
  
//   out->SetPinout(I2S_BCLK, I2S_LRC, I2S_DOUT);
//   out->SetGain(1.0);
//   Serial.println("✓ I2S ready");

//   // MP3
//   mp3 = new AudioGeneratorMP3();
//   if (!mp3) {
//     Serial.println("✗ Decoder failed");
//     stopAudio();
//     sendBleResponse("ERROR:DECODER");
//     return;
//   }
  
//   digitalWrite(SHUTDOWN_PIN, HIGH);
//   delay(200);
  
//   Serial.println("→ Starting...");
//   if (mp3->begin(buff, out)) {
//     Serial.println("✓✓✓ PLAYING WITH BUFFER! ✓✓✓");
//     sendBleResponse("AUDIO:PLAYING_BUFFERED");
//   } else {
//     Serial.println("✗ Playback failed");
//     stopAudio();
//     sendBleResponse("ERROR:DECODE");
//   }
// }

// // ------------------------------------
// // اختبار السماعة/المكبر
// // ------------------------------------
// void testAmplifier() {
//   Serial.println("\n╔═══════════════════════════════════╗");
//   Serial.println("║   Testing Amplifier (5 seconds)   ║");
//   Serial.println("╚═══════════════════════════════════╝");
//   Serial.println("Listen for a 'pop' or noise...\n");
  
//   digitalWrite(SHUTDOWN_PIN, HIGH);
//   sendBleResponse("AMP:ON");
  
//   for(int i = 5; i > 0; i--) {
//     Serial.printf("  %d...\n", i);
//     delay(1000);
//   }
  
//   digitalWrite(SHUTDOWN_PIN, LOW);
//   sendBleResponse("AMP:OFF");
//   Serial.println("✓ Test complete\n");
// }

// // ------------------------------------
// // إرسال رسالة BLE
// // ------------------------------------
// void sendBleResponse(String message) {
//   if (deviceConnected && pResponseCharacteristic) {
//     pResponseCharacteristic->setValue(message.c_str());
//     pResponseCharacteristic->notify();
//     Serial.print("  → BLE: "); Serial.println(message);
//   }
// }

// // ------------------------------------
// // تنفيذ الأوامر
// // ------------------------------------
// void executeCommand(String command) {
//   Serial.println("\n╔═══════════════════════════════════╗");
//   Serial.print("║  CMD: "); 
//   Serial.print(command);
//   for(int i = command.length(); i < 27; i++) Serial.print(" ");
//   Serial.println("║");
//   Serial.println("╚═══════════════════════════════════╝");
  
//   String upperCmd = command;
//   upperCmd.toUpperCase();

//   // === أوامر التشغيل ===
//   if (upperCmd == "TEST1") {
//     Serial.println("Test 1: Tiny MP3 (no buffer)");
//     playFileFromURL_NoBuff("http://www.soundjay.com/button/sounds/button-09.mp3");
//   }
//   else if (upperCmd == "TEST2") {
//     Serial.println("Test 2: Small MP3 (no buffer)");
//     playFileFromURL_NoBuff("http://commondatastorage.googleapis.com/codeskulptor-demos/DDR_assets/Kangaroo_MusiQue_-_The_Neverwritten_Role_Playing_Game.mp3");
//   }
//   else if (upperCmd == "TEST3") {
//     Serial.println("Test 3: Full MP3 (no buffer)");
//     playFileFromURL_NoBuff("http://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3");
//   }
//   else if (upperCmd == "TEST_BUFF") {
//     Serial.println("Test: With 16KB buffer");
//     playFileFromURL_WithBuff("http://www.soundjay.com/button/sounds/button-09.mp3");
//   }
//   else if (upperCmd == "TEST_AMP") {
//     testAmplifier();
//   }
//   else if (upperCmd == "STOP") {
//     stopAudio();
//     sendBleResponse("AUDIO:STOPPED");
//   }
  
//   // === تشغيل رابط مخصص ===
//   else if (upperCmd.startsWith("PLAY:")) {
//     String url = command.substring(5);
//     url.trim();
//     Serial.print("Custom URL: "); Serial.println(url);
//     playFileFromURL_NoBuff(url.c_str());
//   }
//   else if (upperCmd.startsWith("PLAYBUFF:")) {
//     String url = command.substring(9);
//     url.trim();
//     Serial.print("Custom URL (buffered): "); Serial.println(url);
//     playFileFromURL_WithBuff(url.c_str());
//   }
  
//   // === أوامر الحساس ===
//   else if (upperCmd.startsWith("START")) {
//     mode = upperCmd.substring(5);
//     mode.trim();
//     isQuestionActive = true;
//     answer = "";
//     Serial.print("Mode activated: "); Serial.println(mode);
//     sendBleResponse("READY:" + mode);
//   }
  
//   // === أوامر النظام ===
//   else if (upperCmd == "STATUS") {
//     Serial.println("\n=== SYSTEM STATUS ===");
//     Serial.printf("RAM Free: %d bytes\n", ESP.getFreeHeap());
//     Serial.printf("WiFi: %s\n", WiFi.status() == WL_CONNECTED ? "Connected" : "Disconnected");
//     Serial.printf("WiFi IP: %s\n", WiFi.localIP().toString().c_str());
//     Serial.printf("BLE: %s\n", deviceConnected ? "Connected" : "Disconnected");
//     Serial.printf("Audio: %s\n", (mp3 && mp3->isRunning()) ? "Playing" : "Idle");
//     Serial.printf("MPU6050: %s\n", mpu.testConnection() ? "OK" : "Failed");
//     Serial.println("=====================\n");
//     sendBleResponse("STATUS:OK");
//   }
//   else if (upperCmd == "REBOOT") {
//     Serial.println("Rebooting in 2 seconds...");
//     sendBleResponse("SYSTEM:REBOOTING");
//     delay(2000);
//     ESP.restart();
//   }
//   else if (upperCmd == "HELP") {
//     Serial.println("\n=== AVAILABLE COMMANDS ===");
//     Serial.println("TEST1       - Tiny MP3 (no buffer)");
//     Serial.println("TEST2       - Small MP3 (no buffer)");
//     Serial.println("TEST3       - Full MP3 (no buffer)");
//     Serial.println("TEST_BUFF   - Test with buffer");
//     Serial.println("TEST_AMP    - Test amplifier");
//     Serial.println("PLAY:url    - Play custom MP3");
//     Serial.println("PLAYBUFF:url- Play with buffer");
//     Serial.println("STOP        - Stop audio");
//     Serial.println("STARTSHAKE  - Activate shake mode");
//     Serial.println("STARTTILTY  - Activate tilt Y");
//     Serial.println("STARTTILTZ  - Activate tilt Z");
//     Serial.println("STATUS      - System status");
//     Serial.println("REBOOT      - Restart ESP32");
//     Serial.println("HELP        - This list");
//     Serial.println("==========================\n");
//     sendBleResponse("HELP:SENT");
//   }
//   else {
//     Serial.println("Unknown command. Send 'HELP' for list.");
//     sendBleResponse("ERROR:UNKNOWN_CMD");
//   }
// }

// // ------------------------------------
// // كشف الحركة
// // ------------------------------------
// void detectShake() {
//   float acc_g = sqrt((float)accelX*accelX + (float)accelY*accelY + (float)accelZ*accelZ) / ACCEL_SCALE;
//   if (fabs(acc_g - 1.0) > SHAKE_LIMIT_G) {
//     answer = "SHAKE";
//     sendBleResponse("GESTURE:SHAKE");
//     isQuestionActive = false;
//     Serial.println("→ Detected: SHAKE");
//   }
// }

// void detectY() {
//   float angleY = atan2(accelX, sqrt(accelY*accelY + accelZ*accelZ)) * 180.0 / PI;
//   if (angleY > LIMIT_DEG) {
//     answer = "FORWARD";
//     sendBleResponse("GESTURE:FORWARD");
//     isQuestionActive = false;
//     Serial.println("→ Detected: FORWARD");
//   } else if (angleY < -LIMIT_DEG) {
//     answer = "BACK";
//     sendBleResponse("GESTURE:BACK");
//     isQuestionActive = false;
//     Serial.println("→ Detected: BACK");
//   }
// }

// void detectZ() {
//   float angleZ = atan2(accelY, accelZ) * 180.0 / PI;
//   if (angleZ > LIMIT_DEG) {
//     answer = "RIGHT";
//     sendBleResponse("GESTURE:RIGHT");
//     isQuestionActive = false;
//     Serial.println("→ Detected: RIGHT");
//   } else if (angleZ < -LIMIT_DEG) {
//     answer = "LEFT";
//     sendBleResponse("GESTURE:LEFT");
//     isQuestionActive = false;
//     Serial.println("→ Detected: LEFT");
//   }
// }

// // ------------------------------------
// // BLE Callbacks
// // ------------------------------------
// class MyServerCallbacks: public BLEServerCallbacks {
//     void onConnect(BLEServer* pServer) {
//       deviceConnected = true;
//       Serial.println("\n╔═════════════════════════╗");
//       Serial.println("║  ✓ BLE Connected!       ║");
//       Serial.println("╚═════════════════════════╝\n");
//     }
//     void onDisconnect(BLEServer* pServer) {
//       deviceConnected = false;
//       Serial.println("\n✗ BLE Disconnected - Advertising...\n");
//       BLEDevice::startAdvertising(); 
//     }
// };

// class MyCommandCallbacks: public BLECharacteristicCallbacks {
//     void onWrite(BLECharacteristic *pCharacteristic) {
//       std::string value = pCharacteristic->getValue().c_str();
//       if (value.length() > 0) {
//         pendingCommand = String(value.c_str());
//         pendingCommand.trim();
//         pendingCommand.replace("\n", "");
//         pendingCommand.replace("\r", "");
//         hasNewCommand = true;
//       }
//     }
// };

// // ====================================
// // !!           SETUP                !!
// // ====================================
// void setup() {
//   Serial.begin(115200);
//   delay(1500);
  
//   Serial.println("\n\n");
//   Serial.println("╔════════════════════════════════════╗");
//   Serial.println("║                                    ║");
//   Serial.println("║      🎵 CUBIE Audio System 🎵      ║");
//   Serial.println("║           Version 3.0              ║");
//   Serial.println("║                                    ║");
//   Serial.println("╚════════════════════════════════════╝\n");
  
//   pinMode(SHUTDOWN_PIN, OUTPUT);
//   digitalWrite(SHUTDOWN_PIN, LOW);
  
//   // === BLE Setup ===
//   Serial.println("→ Initializing BLE...");
//   BLEDevice::init("CUBIE");
//   pServer = BLEDevice::createServer();
//   pServer->setCallbacks(new MyServerCallbacks());
//   pService = pServer->createService(SERVICE_UUID);
  
//   pCommandCharacteristic = pService->createCharacteristic(
//     COMMAND_CHAR_UUID, 
//     BLECharacteristic::PROPERTY_WRITE
//   );
//   pCommandCharacteristic->setCallbacks(new MyCommandCallbacks());
  
//   pResponseCharacteristic = pService->createCharacteristic(
//     RESPONSE_CHAR_UUID, 
//     BLECharacteristic::PROPERTY_NOTIFY
//   );
//   pResponseCharacteristic->addDescriptor(new BLE2902());
  
//   pService->start();
//   BLEDevice::startAdvertising();
//   Serial.println("  ✓ BLE: Ready\n");

//   // === MPU6050 Setup ===
//   Serial.println("→ Initializing MPU6050...");
//   Wire.begin(21, 22);
//   mpu.initialize();
//   if (mpu.testConnection()) {
//     Serial.println("  ✓ MPU6050: Connected\n");
//   } else {
//     Serial.println("  ✗ MPU6050: Failed!\n");
//   }
  
//   // === WiFi Setup ===
//   Serial.print("→ Connecting to WiFi");
//   WiFi.begin(ssid, password);
//   int wifi_attempts = 0;
//   while (WiFi.status() != WL_CONNECTED && wifi_attempts < 50) { 
//     delay(500); 
//     Serial.print("."); 
//     wifi_attempts++;
//   }
//   Serial.println();
  
//   if (WiFi.status() == WL_CONNECTED) {
//     Serial.println("  ✓ WiFi: Connected");
//     Serial.print("  IP Address: "); 
//     Serial.println(WiFi.localIP());
//   } else {
//     Serial.println("  ✗ WiFi: Failed to connect!");
//   }
  
//   Serial.println("\n╔════════════════════════════════════╗");
//   Serial.println("║     ✓✓✓ SYSTEM READY! ✓✓✓         ║");
//   Serial.println("╚════════════════════════════════════╝");
//   Serial.printf("\nFree RAM: %d bytes\n", ESP.getFreeHeap());
//   Serial.println("\nSend 'HELP' command for available commands\n");
//   Serial.println("Quick start: Send 'TEST1' to test audio\n");
//   Serial.println("═══════════════════════════════════════\n");
// }

// // ====================================
// // !!           LOOP                 !!
// // ====================================
// void loop() {
//   // معالجة الأوامر
//   if (hasNewCommand) {
//     executeCommand(pendingCommand);
//     hasNewCommand = false;
//     pendingCommand = "";
//   }

//   // تحديث تشغيل الصوت
//   if (mp3 && mp3->isRunning()) {
//     if (!mp3->loop()) {
//       Serial.println("\n♪ Audio finished naturally\n");
//       stopAudio();
//       sendBleResponse("AUDIO:FINISHED");
//     }
//   }

//   // كشف الحركة
//   if (isQuestionActive && answer == "") {
//     mpu.getMotion6(&accelX, &accelY, &accelZ, &gyroX, &gyroY, &gyroZ);
//     if (mode == "SHAKE") detectShake();
//     else if (mode == "TILTY") detectY();
//     else if (mode == "TILTZ") detectZ();
//   }
  
//   delay(1); 
// }


// #include <Wire.h>
// #include <MPU6050.h>
// #include <WiFi.h>

// // مكتبات الصوت
// #include "AudioFileSourceHTTPStream.h" 
// #include "AudioFileSourceBuffer.h"     
// #include "AudioGeneratorMP3.h"         
// #include "AudioOutputI2S.h"

// #include <BLEDevice.h>
// #include <BLEServer.h>
// #include <BLEUtils.h>
// #include <BLE2902.h>

// // ===================================
// // !!      إعدادات الواي فاي      !!
// // ===================================
// const char* ssid = "Salman_4G"; 
// const char* password = "0566339996"; 

// // ===================================
// // !!      إعدادات الهاردوير      !!
// // ===================================
// #define SHUTDOWN_PIN 4 
// #define I2S_DOUT 25
// #define I2S_BCLK 26
// #define I2S_LRC  27

// // إعدادات حساس الحركة
// MPU6050 mpu(0x68);
// const float LIMIT_DEG = 20.0;
// const float SHAKE_LIMIT_G = 0.7;
// const float ACCEL_SCALE = 16384.0;
// int16_t accelX, accelY, accelZ, gyroX, gyroY, gyroZ;

// // كائنات الصوت
// AudioGeneratorMP3 *mp3 = NULL;
// AudioFileSourceHTTPStream *file_http = NULL;
// AudioFileSourceBuffer *buff = NULL;
// AudioOutputI2S *out = NULL;

// // متغيرات النظام
// bool isQuestionActive = false;
// String mode = "";
// String answer = "";
// bool hasNewCommand = false;
// String pendingCommand = "";

// // إعدادات البلوتوث
// BLEServer *pServer = NULL;
// BLEService *pService = NULL;
// BLECharacteristic *pCommandCharacteristic = NULL;
// BLECharacteristic *pResponseCharacteristic = NULL;
// bool deviceConnected = false;

// #define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
// #define COMMAND_CHAR_UUID   "beb5483e-36e1-4688-b7f5-ea07361b26a8"
// #define RESPONSE_CHAR_UUID  "c3856242-4f7f-4a6c-b3d4-4a6e43f5a25c"

// // ===================================
// // إرسال رسالة BLE (تعريف مبكر)
// // ===================================
// void sendBleResponse(String message) {
//   if (deviceConnected && pResponseCharacteristic) {
//     pResponseCharacteristic->setValue(message.c_str());
//     pResponseCharacteristic->notify();
//     Serial.print("  → BLE: "); Serial.println(message);
//   }
// }

// // ===================================
// // دالة إيقاف الصوت
// // ===================================
// void stopAudio() {
//   Serial.println("→ Stopping audio...");
  
//   digitalWrite(SHUTDOWN_PIN, LOW);
//   delay(100);
  
//   if (mp3) { 
//     if (mp3->isRunning()) mp3->stop(); 
//     delete mp3; 
//     mp3 = NULL; 
//   }
//   if (buff) { 
//     buff->close(); 
//     delete buff; 
//     buff = NULL; 
//   }
//   if (file_http) { 
//     file_http->close(); 
//     delete file_http; 
//     file_http = NULL; 
//   }
//   if (out) { 
//     out->stop();
//     delete out; 
//     out = NULL; 
//   }
  
//   delay(200);
  
//   // إعادة تفعيل BLE
//   BLEDevice::startAdvertising();
  
//   Serial.printf("✓ Memory freed: %d bytes\n\n", ESP.getFreeHeap());
// }

// // ===================================
// // الحل النهائي - تشغيل MP3 من URL
// // ===================================
// void playMP3FromURL(const char* url) {
//   stopAudio();
//   delay(300);
  
//   Serial.println("╔════════════════════════════════════╗");
//   Serial.println("║      Playing MP3 from URL          ║");
//   Serial.println("╚════════════════════════════════════╝");
//   Serial.printf("Initial RAM: %d bytes\n", ESP.getFreeHeap());
//   Serial.print("URL: "); Serial.println(url);
//   Serial.println();
  
//   // !! تحرير ذاكرة مؤقتة - إيقاف BLE أثناء التشغيل !!
//   if (deviceConnected) {
//     Serial.println("→ Pausing BLE to free memory...");
//     BLEDevice::stopAdvertising();
//     delay(100);
//   }

//   // === الخطوة 1: HTTP Stream ===
//   Serial.println("→ Creating HTTP stream...");
//   file_http = new AudioFileSourceHTTPStream(url);
//   if (!file_http) {
//     Serial.println("✗ Failed - Out of memory");
//     sendBleResponse("ERROR:NO_MEMORY");
//     BLEDevice::startAdvertising();
//     return;
//   }

//   // الاتصال بالسيرفر
//   Serial.print("→ Connecting");
//   int timeout = 0;
//   while (!file_http->isOpen() && timeout < 40) { 
//     delay(200); 
//     timeout++; 
//     Serial.print("."); 
//   }
//   Serial.println();
  
//   if (!file_http->isOpen()) {
//     Serial.println("✗ Connection timeout!");
//     Serial.println("  Check: WiFi, URL, or server status");
//     stopAudio();
//     sendBleResponse("ERROR:CONNECTION_FAILED");
//     BLEDevice::startAdvertising();
//     return;
//   }
//   Serial.println("✓ Connected to server!");
//   Serial.printf("  RAM after connection: %d bytes\n", ESP.getFreeHeap());

//   // === الخطوة 2: Buffer ===
//   // استخدام buffer أصغر لتوفير ذاكرة كافية لـ I2S DMA
//   Serial.println("→ Creating buffer (4KB)...");
//   buff = new AudioFileSourceBuffer(file_http, 4096); // 4KB buffer - كافٍ ومقتصد
//   if (!buff) {
//     Serial.println("✗ Buffer creation failed");
//     stopAudio();
//     sendBleResponse("ERROR:BUFFER_FAILED");
//     return;
//   }
  
//   // ملء البفر مسبقاً
//   Serial.print("→ Pre-buffering");
//   for(int i = 0; i < 8; i++) {
//     delay(50);
//     Serial.print(".");
//   }
//   Serial.println(" Done!");
//   Serial.printf("  RAM after buffer: %d bytes\n", ESP.getFreeHeap());
  
//   // تأكد من وجود ذاكرة كافية
//   if (ESP.getFreeHeap() < 30000) {
//     Serial.println("✗ Not enough RAM for I2S DMA!");
//     Serial.println("  Need at least 30KB free");
//     stopAudio();
//     sendBleResponse("ERROR:LOW_MEMORY");
//     return;
//   }

//   // === الخطوة 3: I2S Output ===
//   Serial.println("→ Configuring I2S...");
  
//   // !! تقليل DMA buffers لتوفير الذاكرة !!
//   out = new AudioOutputI2S(0, 0); // استخدام internal DAC بدلاً من external
//   if (!out) {
//     Serial.println("✗ I2S creation failed");
//     stopAudio();
//     sendBleResponse("ERROR:I2S_FAILED");
//     return;
//   }
  
//   // الإعداد الصحيح
//   out->SetPinout(I2S_BCLK, I2S_LRC, I2S_DOUT);
//   out->SetOutputModeMono(false);  // Stereo
//   out->SetGain(0.7);              // حجم معتدل
  
//   // *** تم حذف SetBufferSize لحل مشكلة الـ Compilation ***
  
//   Serial.println("✓ I2S configured");
//   Serial.printf("  RAM before begin: %d bytes\n", ESP.getFreeHeap());

//   // === الخطوة 4: MP3 Decoder ===
//   Serial.println("→ Creating MP3 decoder...");
//   mp3 = new AudioGeneratorMP3();
//   if (!mp3) {
//     Serial.println("✗ Decoder creation failed");
//     stopAudio();
//     sendBleResponse("ERROR:DECODER_FAILED");
//     return;
//   }
//   Serial.println("✓ Decoder ready");
  
//   // تشغيل المكبر
//   digitalWrite(SHUTDOWN_PIN, HIGH);
//   delay(200);
//   Serial.println("✓ Amplifier ON");

//   // === الخطوة 5: البدء ===
//   Serial.println("\n→ Starting MP3 playback...");
//   Serial.printf("  Final RAM: %d bytes\n", ESP.getFreeHeap());
  
//   // !! المحاولة مع معالجة أفضل !!
//   bool started = mp3->begin(buff, out);
  
//   if (!started) {
//     Serial.println("\n╔════════════════════════════════════╗");
//     Serial.println("║  ✗✗✗ DECODE FAILED ✗✗✗             ║");
//     Serial.println("╠════════════════════════════════════╣");
//     Serial.println("║  Possible Solutions:               ║");
//     Serial.println("║                                    ║");
//     Serial.println("║  1. Tools → Partition Scheme       ║");
//     Serial.println("║     → Huge APP (3MB)               ║");
//     Serial.println("║                                    ║");
//     Serial.println("║  2. Update ESP8266Audio library    ║");
//     Serial.println("║     to version 1.9.7               ║");
//     Serial.println("║                                    ║");
//     Serial.println("║  3. Check MP3 file format:         ║");
//     Serial.println("║     - Must be standard MP3         ║");
//     Serial.println("║     - Not AAC or M4A               ║");
//     Serial.println("║     - Sample rate: 44100Hz         ║");
//     Serial.println("║     - Bitrate: 128kbps max         ║");
//     Serial.println("║                                    ║");
//     Serial.println("║  4. Test with small file first     ║");
//     Serial.println("║                                    ║");
//     Serial.println("╚════════════════════════════════════╝\n");
    
//     stopAudio();
//     sendBleResponse("ERROR:PLAYBACK_FAILED");
//     return;
//   }
  
//   // نجح!
//   Serial.println("\n╔════════════════════════════════════╗");
//   Serial.println("║  ✓✓✓ SUCCESS! PLAYING! ✓✓✓         ║");
//   Serial.println("╚════════════════════════════════════╝\n");
//   sendBleResponse("AUDIO:PLAYING");
// }

// // ===================================
// // تنفيذ الأوامر
// // ===================================
// void executeCommand(String command) {
//   Serial.println("\n╔════════════════════════════════════╗");
//   Serial.print("║  COMMAND: ");
//   Serial.print(command);
//   for(int i = command.length(); i < 24; i++) Serial.print(" ");
//   Serial.println("║");
//   Serial.println("╚════════════════════════════════════╝");
  
//   String upperCmd = command;
//   upperCmd.toUpperCase();

//   // === أوامر التشغيل ===
//   if (upperCmd == "TEST") {
//     Serial.println("Testing with small MP3...");
//     playMP3FromURL("http://www.soundjay.com/button/sounds/button-09.mp3");
//   }
//   else if (upperCmd == "TEST2") {
//     Serial.println("Testing with medium MP3...");
//     playMP3FromURL("http://commondatastorage.googleapis.com/codeskulptor-demos/DDR_assets/Kangaroo_MusiQue_-_The_Neverwritten_Role_Playing_Game.mp3");
//   }
//   else if (upperCmd == "STOP") {
//     stopAudio();
//     sendBleResponse("AUDIO:STOPPED");
//   }
  
//   // === تشغيل رابط مخصص ===
//   else if (upperCmd.startsWith("PLAY:")) {
//     String url = command.substring(5);
//     url.trim();
//     Serial.print("Custom URL: "); Serial.println(url);
//     playMP3FromURL(url.c_str());
//   }
  
//   // === أوامر الحساس ===
//   else if (upperCmd.startsWith("START")) {
//     mode = upperCmd.substring(5);
//     mode.trim();
//     isQuestionActive = true;
//     answer = "";
//     Serial.print("Sensor mode: "); Serial.println(mode);
//     sendBleResponse("READY:" + mode);
//   }
  
//   // === أوامر النظام ===
//   else if (upperCmd == "STATUS") {
//     Serial.println("\n=== SYSTEM STATUS ===");
//     Serial.printf("Free RAM: %d bytes\n", ESP.getFreeHeap());
//     Serial.printf("WiFi: %s (%s)\n", 
//                   WiFi.status() == WL_CONNECTED ? "Connected" : "Disconnected",
//                   WiFi.localIP().toString().c_str());
//     Serial.printf("BLE: %s\n", deviceConnected ? "Connected" : "Disconnected");
//     Serial.printf("Audio: %s\n", (mp3 && mp3->isRunning()) ? "Playing" : "Idle");
//     Serial.printf("MPU6050: %s\n", mpu.testConnection() ? "OK" : "Failed");
//     Serial.println("=====================\n");
//     sendBleResponse("STATUS:OK");
//   }
//   else if (upperCmd == "REBOOT") {
//     Serial.println("Rebooting in 2 seconds...");
//     sendBleResponse("REBOOTING");
//     delay(2000);
//     ESP.restart();
//   }
//   else if (upperCmd == "HELP") {
//     Serial.println("\n=== COMMANDS ===");
//     Serial.println("TEST        - Test small MP3");
//     Serial.println("TEST2       - Test medium MP3");
//     Serial.println("PLAY:url    - Play from URL");
//     Serial.println("STOP        - Stop playback");
//     Serial.println("STARTSHAKE  - Shake detection");
//     Serial.println("STARTTILTY  - Tilt Y detection");
//     Serial.println("STARTTILTZ  - Tilt Z detection");
//     Serial.println("STATUS      - System info");
//     Serial.println("REBOOT      - Restart ESP32");
//     Serial.println("HELP        - This list");
//     Serial.println("================\n");
//     sendBleResponse("HELP:OK");
//   }
//   else {
//     Serial.println("Unknown command. Type HELP");
//     sendBleResponse("ERROR:UNKNOWN");
//   }
// }

// // ===================================
// // كشف الحركة
// // ===================================
// void detectShake() {
//   float acc_g = sqrt((float)accelX*accelX + (float)accelY*accelY + (float)accelZ*accelZ) / ACCEL_SCALE;
//   if (fabs(acc_g - 1.0) > SHAKE_LIMIT_G) {
//     answer = "SHAKE";
//     sendBleResponse("GESTURE:SHAKE");
//     isQuestionActive = false;
//     Serial.println("→ Detected: SHAKE");
//   }
// }

// void detectY() {
//   float angleY = atan2(accelX, sqrt(accelY*accelY + accelZ*accelZ)) * 180.0 / PI;
//   if (angleY > LIMIT_DEG) {
//     answer = "FORWARD";
//     sendBleResponse("GESTURE:FORWARD");
//     isQuestionActive = false;
//     Serial.println("→ Detected: FORWARD");
//   } else if (angleY < -LIMIT_DEG) {
//     answer = "BACK";
//     sendBleResponse("GESTURE:BACK");
//     isQuestionActive = false;
//     Serial.println("→ Detected: BACK");
//   }
// }

// void detectZ() {
//   float angleZ = atan2(accelY, accelZ) * 180.0 / PI;
//   if (angleZ > LIMIT_DEG) {
//     answer = "RIGHT";
//     sendBleResponse("GESTURE:RIGHT");
//     isQuestionActive = false;
//     Serial.println("→ Detected: RIGHT");
//   } else if (angleZ < -LIMIT_DEG) {
//     answer = "LEFT";
//     sendBleResponse("GESTURE:LEFT");
//     isQuestionActive = false;
//     Serial.println("→ Detected: LEFT");
//   }
// }

// // ===================================
// // BLE Callbacks
// // ===================================
// class MyServerCallbacks: public BLEServerCallbacks {
//     void onConnect(BLEServer* pServer) {
//       deviceConnected = true;
//       Serial.println("\n╔═══════════════════╗");
//       Serial.println("║  ✓ BLE Connected  ║");
//       Serial.println("╚═══════════════════╝\n");
//     }
//     void onDisconnect(BLEServer* pServer) {
//       deviceConnected = false;
//       Serial.println("\n✗ BLE Disconnected\n");
//       BLEDevice::startAdvertising();
//     }
// };

// class MyCommandCallbacks: public BLECharacteristicCallbacks {
//     void onWrite(BLECharacteristic *pCharacteristic) {
//       std::string value = pCharacteristic->getValue().c_str();
//       if (value.length() > 0) {
//         pendingCommand = String(value.c_str());
//         pendingCommand.trim();
//         pendingCommand.replace("\n", "");
//         pendingCommand.replace("\r", "");
//         hasNewCommand = true;
//       }
//     }
// };

// // ===================================
// // SETUP
// // ===================================
// void setup() {
//   Serial.begin(115200);
//   delay(2000);
  
//   Serial.println("\n\n");
//   Serial.println("╔════════════════════════════════════╗");
//   Serial.println("║                                    ║");
//   Serial.println("║      🎵 CUBIE Audio System 🎵        ║");
//   Serial.println("║        Final Solution v5.0         ║");
//   Serial.println("║                                    ║");
//   Serial.println("╚════════════════════════════════════╝\n");
  
//   pinMode(SHUTDOWN_PIN, OUTPUT);
//   digitalWrite(SHUTDOWN_PIN, LOW);
  
//   // BLE
//   Serial.println("→ BLE...");
//   BLEDevice::init("CUBIE");
//   pServer = BLEDevice::createServer();
//   pServer->setCallbacks(new MyServerCallbacks());
//   pService = pServer->createService(SERVICE_UUID);
  
//   pCommandCharacteristic = pService->createCharacteristic(
//     COMMAND_CHAR_UUID, 
//     BLECharacteristic::PROPERTY_WRITE
//   );
//   pCommandCharacteristic->setCallbacks(new MyCommandCallbacks());
  
//   pResponseCharacteristic = pService->createCharacteristic(
//     RESPONSE_CHAR_UUID, 
//     BLECharacteristic::PROPERTY_NOTIFY
//   );
//   pResponseCharacteristic->addDescriptor(new BLE2902());
  
//   pService->start();
//   BLEDevice::startAdvertising();
//   Serial.println("  ✓ Ready\n");

//   // MPU6050
//   Serial.println("→ MPU6050...");
//   Wire.begin(21, 22);
//   mpu.initialize();
//   Serial.println(mpu.testConnection() ? "  ✓ OK\n" : "  ✗ Failed\n");
  
//   // WiFi
//   Serial.print("→ WiFi");
//   WiFi.begin(ssid, password);
//   int tries = 0;
//   while (WiFi.status() != WL_CONNECTED && tries < 60) { 
//     delay(500); 
//     Serial.print("."); 
//     tries++;
//   }
//   Serial.println();
  
//   if (WiFi.status() == WL_CONNECTED) {
//     Serial.println("  ✓ Connected");
//     Serial.print("  IP: "); Serial.println(WiFi.localIP());
//   } else {
//     Serial.println("  ✗ Failed!");
//   }
  
//   Serial.println("\n╔════════════════════════════════════╗");
//   Serial.println("║        ✓ SYSTEM READY! ✓           ║");
//   Serial.println("╚════════════════════════════════════╝");
//   Serial.printf("\nFree RAM: %d bytes\n", ESP.getFreeHeap());
//   Serial.println("\n📌 IMPORTANT:");
//   Serial.println("   If audio fails, set:");
//   Serial.println("   Tools → Partition Scheme");
//   Serial.println("   → Huge APP (3MB No OTA)\n");
//   Serial.println("Commands: TEST, PLAY:url, STOP, HELP\n");
//   Serial.println("════════════════════════════════════\n");
// }

// // ===================================
// // LOOP
// // ===================================
// void loop() {
//   if (hasNewCommand) {
//     executeCommand(pendingCommand);
//     hasNewCommand = false;
//     pendingCommand = "";
//   }

//   if (mp3 && mp3->isRunning()) {
//     if (!mp3->loop()) {
//       Serial.println("\n♪ Audio finished\n");
//       stopAudio();
//       sendBleResponse("AUDIO:FINISHED");
//     }
//   }

//   if (isQuestionActive && answer == "") {
//     mpu.getMotion6(&accelX, &accelY, &accelZ, &gyroX, &gyroY, &gyroZ);
//     if (mode == "SHAKE") detectShake();
//     else if (mode == "TILTY") detectY();
//     else if (mode == "TILTZ") detectZ();
//   }
  
//   delay(1); 
// }

#include <Wire.h>
#include <MPU6050.h>
#include <WiFi.h>
#include "esp_bt_main.h"
#include "esp_bt_device.h"
#include "AudioFileSourceHTTPStream.h" 
#include "AudioFileSourceBuffer.h"     
#include "AudioGeneratorMP3.h"         
#include "AudioOutputI2S.h"
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// ===================================
// !!      إعدادات الواي فاي      !!
// ===================================
const char* ssid = "Salman_4G"; 
const char* password = "0566339996"; 

// ===================================
// !!      إعدادات الهاردوير      !!
// ===================================
#define SHUTDOWN_PIN 4 
#define I2S_DOUT 25
#define I2S_BCLK 26
#define I2S_LRC  27

MPU6050 mpu(0x68);
const float LIMIT_DEG = 20.0;
const float SHAKE_LIMIT_G = 0.7;
const float ACCEL_SCALE = 16384.0;
int16_t accelX, accelY, accelZ, gyroX, gyroY, gyroZ;

// كائنات الصوت
AudioGeneratorMP3 *mp3 = NULL;
AudioFileSourceHTTPStream *file_http = NULL;
AudioFileSourceBuffer *buff = NULL;
AudioOutputI2S *out = NULL;

bool isQuestionActive = false;
String mode = "";
String answer = "";
bool hasNewCommand = false;
String pendingCommand = "";

// إعدادات البلوتوث
BLEServer *pServer = NULL;
BLEService *pService = NULL;
BLECharacteristic *pCommandCharacteristic = NULL;
BLECharacteristic *pResponseCharacteristic = NULL;
bool deviceConnected = false;

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define COMMAND_CHAR_UUID   "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define RESPONSE_CHAR_UUID  "c3856242-4f7f-4a6c-b3d4-4a6e43f5a25c"

// ===================================
// إرسال رسالة BLE
// ===================================
void sendBleResponse(String message) {
  if (deviceConnected && pResponseCharacteristic) {
    pResponseCharacteristic->setValue(message.c_str());
    pResponseCharacteristic->notify();
    Serial.print("  → BLE: "); Serial.println(message);
  }
}

// ===================================
// دالة إيقاف الصوت المحسّنة
// ===================================
void stopAudio() {
  Serial.println("→ Stopping audio safely...");
  
  // !! الترتيب مهم جداً !!
  // 1. إيقاف التشغيل أولاً
  if (mp3 && mp3->isRunning()) {
    mp3->stop();
  }
  
  // 2. الانتظار قليلاً للتأكد من توقف كل العمليات
  delay(100);
  
  // 3. حذف الكائنات بالترتيب الصحيح
  if (mp3) { delete mp3; mp3 = NULL; }
  if (buff) { buff->close(); delete buff; buff = NULL; }
  if (file_http) { file_http->close(); delete file_http; file_http = NULL; }
  if (out) { out->stop(); delete out; out = NULL; }
  
  // 4. إطفاء المكبر
  digitalWrite(SHUTDOWN_PIN, LOW);
  
  // 5. تنظيف إضافي للذاكرة
  delay(200);
  
  Serial.printf("✓ RAM: %d bytes free\n", ESP.getFreeHeap());
}

// ===================================
// !! الحل الجذري - Progressive Streaming !!
// ===================================
void playMP3FromURL(const char* url) {
  stopAudio();
  delay(200);
  
  Serial.println("╔════════════════════════════════════╗");
  Serial.println("║   🔧 FIXED PLAYBACK (v5.1) 🔧      ║");
  Serial.println("╚════════════════════════════════════╝");
  
  // 1. رفع سرعة المعالج لمعالجة البيانات بسرعة
  setCpuFrequencyMhz(240);

  // 2. المصدر (الإنترنت)
  file_http = new AudioFileSourceHTTPStream(url);
  if (!file_http) { sendBleResponse("ERROR:STREAM"); return; }

  // 3. البفر (Buffer)
  // نستخدم 4KB لأنه الحجم الذي اشتغل معك سابقاً بدون انهيار
  Serial.println("→ Buffer: 4KB");
  buff = new AudioFileSourceBuffer(file_http, 4096);
  if (!buff) { stopAudio(); sendBleResponse("ERROR:BUFFER"); return; }

  // 4. إعداد I2S (تم تصحيح الخطأ هنا)
  Serial.println("→ I2S: External DAC Mode");
  out = new AudioOutputI2S(0, AudioOutputI2S::EXTERNAL_I2S);
  
  // تعيين الأرجل (تأكدي أن الأسلاك موصلة بهذه الأرجل فعلياً)
  // BCLK=26, LRC=27, DOUT=25
  out->SetPinout(I2S_BCLK, I2S_LRC, I2S_DOUT);
  
  // خفضنا الصوت جداً (10%) لتجربة صفاء الصوت
  // إذا كان "طزززز" عالياً جداً، فهذا يعني أن المكبر يشتغل بأقصى طاقة (Gain Error)
  out->SetGain(0.10);

  // 5. المشغل
  mp3 = new AudioGeneratorMP3();
  
  // 6. تشغيل الأمبليفاير (إعادة تعيين الكهرباء)
  digitalWrite(SHUTDOWN_PIN, LOW); 
  delay(50);
  digitalWrite(SHUTDOWN_PIN, HIGH);
  delay(100);

  Serial.println("→ Starting...");
  
  if (!mp3->begin(buff, out)) {
    Serial.println("✗ Decode Failed");
    stopAudio();
    sendBleResponse("ERROR:DECODE");
    return;
  }
  
  Serial.println("✓ Playing...");
  sendBleResponse("AUDIO:PLAYING");
}

// ===================================
// تنفيذ الأوامر
// ===================================
void executeCommand(String command) {
  Serial.println("\n╔════════════════════════════════════╗");
  Serial.print("║  CMD: ");
  Serial.print(command);
  for(int i = command.length(); i < 28; i++) Serial.print(" ");
  Serial.println("║");
  Serial.println("╚════════════════════════════════════╝");
  
  String upperCmd = command;
  upperCmd.toUpperCase();

  // === أوامر الاختبار ===
  if (upperCmd == "TEST") {
    Serial.println("🧪 Test: Tiny MP3 file");
    playMP3FromURL("http://www.soundjay.com/button/sounds/button-09.mp3");
  }
  else if (upperCmd == "TEST2") {
    Serial.println("🧪 Test: Medium MP3 file");
    playMP3FromURL("http://commondatastorage.googleapis.com/codeskulptor-demos/DDR_assets/Kangaroo_MusiQue_-_The_Neverwritten_Role_Playing_Game.mp3");
  }
  else if (upperCmd == "TEST3") {
    Serial.println("🧪 Test: Full MP3 (SoundHelix)");
    playMP3FromURL("http://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3");
  }
  else if (upperCmd == "STOP") {
    stopAudio();
    sendBleResponse("AUDIO:STOPPED");
  }
  
  // === تشغيل رابط مخصص ===
  else if (upperCmd.startsWith("PLAY:")) {
    String url = command.substring(5);
    url.trim();
    Serial.print("Custom URL: "); Serial.println(url);
    playMP3FromURL(url.c_str());
  }
  
  // === أوامر الحساس ===
  else if (upperCmd.startsWith("START")) {
    mode = upperCmd.substring(5);
    mode.trim();
    isQuestionActive = true;
    answer = "";
    Serial.print("Sensor mode: "); Serial.println(mode);
    sendBleResponse("READY:" + mode);
  }
  
  // === أوامر النظام ===
  else if (upperCmd == "STATUS") {
    Serial.println("\n╔════════ SYSTEM STATUS ════════╗");
    Serial.printf("║ RAM Free: %d bytes         \n", ESP.getFreeHeap());
    Serial.printf("║ WiFi: %s                   \n", WiFi.status() == WL_CONNECTED ? "Connected ✓" : "Disconnected ✗");
    if (WiFi.status() == WL_CONNECTED) {
      Serial.print("║ IP: "); Serial.println(WiFi.localIP());
    }
    Serial.printf("║ BLE: %s                    \n", deviceConnected ? "Connected ✓" : "Disconnected ✗");
    Serial.printf("║ Audio: %s                  \n", (mp3 && mp3->isRunning()) ? "Playing ♪" : "Idle");
    Serial.printf("║ MPU6050: %s                \n", mpu.testConnection() ? "OK ✓" : "Failed ✗");
    Serial.println("╚═══════════════════════════════╝\n");
    sendBleResponse("STATUS:OK");
  }
  else if (upperCmd == "REBOOT") {
    Serial.println("Rebooting...");
    sendBleResponse("REBOOTING");
    delay(1000);
    ESP.restart();
  }
  else if (upperCmd == "HELP") {
    Serial.println("\n╔═══════ COMMANDS ═══════╗");
    Serial.println("║ TEST       - Test small MP3");
    Serial.println("║ TEST2      - Test medium MP3");
    Serial.println("║ TEST3      - Test full MP3");
    Serial.println("║ PLAY:url   - Play from URL");
    Serial.println("║ STOP       - Stop playback");
    Serial.println("║ STATUS     - System info");
    Serial.println("║ REBOOT     - Restart");
    Serial.println("║ HELP       - This list");
    Serial.println("╚════════════════════════╝\n");
    sendBleResponse("HELP:OK");
  }
  else {
    Serial.println("❓ Unknown command");
    sendBleResponse("ERROR:UNKNOWN");
  }
}

// ===================================
// كشف الحركة
// ===================================
void detectShake() {
  float acc_g = sqrt((float)accelX*accelX + (float)accelY*accelY + (float)accelZ*accelZ) / ACCEL_SCALE;
  if (fabs(acc_g - 1.0) > SHAKE_LIMIT_G) {
    answer = "SHAKE";
    sendBleResponse("GESTURE:SHAKE");
    isQuestionActive = false;
  }
}

void detectY() {
  float angleY = atan2(accelX, sqrt(accelY*accelY + accelZ*accelZ)) * 180.0 / PI;
  if (angleY > LIMIT_DEG) {
    answer = "FORWARD";
    sendBleResponse("GESTURE:FORWARD");
    isQuestionActive = false;
  } else if (angleY < -LIMIT_DEG) {
    answer = "BACK";
    sendBleResponse("GESTURE:BACK");
    isQuestionActive = false;
  }
}

void detectZ() {
  float angleZ = atan2(accelY, accelZ) * 180.0 / PI;
  if (angleZ > LIMIT_DEG) {
    answer = "RIGHT";
    sendBleResponse("GESTURE:RIGHT");
    isQuestionActive = false;
  } else if (angleZ < -LIMIT_DEG) {
    answer = "LEFT";
    sendBleResponse("GESTURE:LEFT");
    isQuestionActive = false;
  }
}

// ===================================
// BLE Callbacks
// ===================================
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("\n╔═══════════════════╗");
      Serial.println("║  ✓ BLE Connected  ║");
      Serial.println("╚═══════════════════╝\n");
    }
    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("\n✗ BLE Disconnected\n");
      BLEDevice::startAdvertising();
    }
};

class MyCommandCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue().c_str();
      if (value.length() > 0) {
        pendingCommand = String(value.c_str());
        pendingCommand.trim();
        pendingCommand.replace("\n", "");
        pendingCommand.replace("\r", "");
        hasNewCommand = true;
      }
    }
};

// ===================================
// SETUP
// ===================================
void setup() {
  Serial.begin(115200);
  delay(2000);

  Serial.println("\n\n╔════ SYSTEM START ════╗");
  
  // 1. !! الخطوة السحرية: تحرير ذاكرة البلوتوث الكلاسيكي لتوفير الرام !!
  // هذا السطر يجب أن يكون قبل BLEDevice::init
  esp_bt_controller_mem_release(ESP_BT_MODE_CLASSIC_BT);

  pinMode(SHUTDOWN_PIN, OUTPUT);
  digitalWrite(SHUTDOWN_PIN, LOW);
  
  // BLE Init
  Serial.println("→ Initializing BLE...");
  BLEDevice::init("CUBIE");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  pService = pServer->createService(SERVICE_UUID);
  
  pCommandCharacteristic = pService->createCharacteristic(
    COMMAND_CHAR_UUID, 
    BLECharacteristic::PROPERTY_WRITE
  );
  pCommandCharacteristic->setCallbacks(new MyCommandCallbacks());
  
  pResponseCharacteristic = pService->createCharacteristic(
    RESPONSE_CHAR_UUID, 
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pResponseCharacteristic->addDescriptor(new BLE2902());
  
  pService->start();
  BLEDevice::startAdvertising();
  Serial.println("  ✓ BLE Ready");

  // MPU6050
  Wire.begin(21, 22);
  mpu.initialize();
  
  // WiFi
  Serial.print("→ Connecting WiFi");
  WiFi.begin(ssid, password);
  int tries = 0;
  while (WiFi.status() != WL_CONNECTED && tries < 20) { // قللت المحاولات لتسريع الإقلاع
    delay(500); 
    Serial.print("."); 
    tries++;
  }
  Serial.println();
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("  ✓ WiFi Connected");
  } else {
    Serial.println("  ✗ WiFi Failed");
  }

  Serial.printf("\n🚀 Free RAM after setup: %d bytes (Should be > 60000)\n", ESP.getFreeHeap());
}

// ===================================
// LOOP
// ===================================
void loop() {
  if (hasNewCommand) {
    executeCommand(pendingCommand);
    hasNewCommand = false;
    pendingCommand = "";
  }

  if (mp3 && mp3->isRunning()) {
    if (!mp3->loop()) {
      Serial.println("\n♪ Audio finished\n");
      stopAudio();
      sendBleResponse("AUDIO:FINISHED");
    }
  }

  if (isQuestionActive && answer == "") {
    mpu.getMotion6(&accelX, &accelY, &accelZ, &gyroX, &gyroY, &gyroZ);
    if (mode == "SHAKE") detectShake();
    else if (mode == "TILTY") detectY();
    else if (mode == "TILTZ") detectZ();
  }
  
  delay(1); 
}



//////////////////////////////////////////////////////////////
// #include <Wire.h>
// #include <MPU6050.h>
// #include <WiFi.h>
// #include "AudioLogger.h"
// #include "AudioFileSourceHTTPStream.h"
// #include "AudioFileSourceBuffer.h"
// #include "AudioGeneratorMP3.h"
// #include "AudioOutputI2S.h"
// #include <BLEDevice.h>
// #include <BLEServer.h>
// #include <BLEUtils.h>
// #include <BLE2902.h>

// // ===================================
// // إعدادات الواي فاي
// // ===================================
// const char* ssid = "HUAWEI_E5576_3656";    
// const char* password = "3GqA8bGYd3G"; 

// #define SHUTDOWN_PIN 4 
// #define I2S_DOUT 25
// #define I2S_BCLK 26
// #define I2S_LRC  27

// MPU6050 mpu(0x68);
// const float LIMIT_DEG = 25.0;
// const float SHAKE_LIMIT_G = 1.5;
// const float ACCEL_SCALE = 16384.0;
// int16_t accelX, accelY, accelZ, gyroX, gyroY, gyroZ;

// AudioGeneratorMP3 *mp3;
// AudioFileSourceHTTPStream *file_http;
// AudioFileSourceBuffer *buff;
// AudioOutputI2S *out;

// bool isQuestionActive = false;
// String activeMode = "";
// BLEServer *pServer = NULL;
// BLEService *pService = NULL;
// BLECharacteristic *pCommandCharacteristic = NULL;
// BLECharacteristic *pResponseCharacteristic = NULL;
// bool deviceConnected = false;

// #define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
// #define COMMAND_CHAR_UUID   "beb5483e-36e1-4688-b7f5-ea07361b26a8"
// #define RESPONSE_CHAR_UUID  "c3856242-4f7f-4a6c-b3d4-4a6e43f5a25c"

// void sendBleResponse(String message) {
//   if (deviceConnected) {
//     pResponseCharacteristic->setValue(message.c_str());
//     pResponseCharacteristic->notify();
//     Serial.print("BLE Notify >> "); Serial.println(message);
//   }
// }

// void stopAudio() {
//   if (mp3) { 
//     if (mp3->isRunning()) mp3->stop(); 
//     delete mp3; mp3 = nullptr; 
//   }
//   if (buff) { buff->close(); delete buff; buff = nullptr; }
//   if (file_http) { file_http->close(); delete file_http; file_http = nullptr; }
//   if (out) { out->stop(); delete out; out = nullptr; }
//   digitalWrite(SHUTDOWN_PIN, LOW); 
// }

// void playFileFromURL(const char* url) {
//   stopAudio();
  
//   Serial.println("---------------------------");
//   Serial.print("Playing: "); Serial.println(url);
  
//   // 1. إنشاء المصدر (بدون بفر في البداية)
//   file_http = new AudioFileSourceHTTPStream(url);
  
//   // 2. بفر صغير جداً (1024 بايت) لإنقاذ الرام
//   // هذا قد يسبب تقطيع بسيط لكنه سيسمح للصوت بالبدء
//   buff = new AudioFileSourceBuffer(file_http, 1024); 
  
//   out = new AudioOutputI2S();
//   out->SetPinout(I2S_BCLK, I2S_LRC, I2S_DOUT); 
//   out->SetGain(0.8); 
  
//   mp3 = new AudioGeneratorMP3();
  
//   digitalWrite(SHUTDOWN_PIN, HIGH); 

//   // محاولة التشغيل
//   if (!mp3->begin(buff, out)) {
//     Serial.printf("ERROR: Failed to start MP3. Free Heap: %d\n", ESP.getFreeHeap());
//     stopAudio();
//     sendBleResponse("AUDIO:FINISHED"); 
//   } else {
//     Serial.println("Playback started...");
//   }
// }

// void handleSensors() {
//   if (!isQuestionActive) return;
//   mpu.getMotion6(&accelX, &accelY, &accelZ, &gyroX, &gyroY, &gyroZ);
//   String detected = "";

//   if (activeMode == "SHAKE") {
//     float acc_g = sqrt((float)accelX*accelX + (float)accelY*accelY + (float)accelZ*accelZ) / ACCEL_SCALE;
//     if (fabs(acc_g - 1.0) > 0.8) detected = "SHAKE";
//   }
//   else if (activeMode == "TILTY") {
//     float angleY = atan2(accelX, sqrt(accelY*accelY + accelZ*accelZ)) * 180.0 / PI;
//     if (angleY > LIMIT_DEG) detected = "FORWARD";
//     else if (angleY < -LIMIT_DEG) detected = "BACK";
//   }
//   else if (activeMode == "TILTZ") {
//     float angleZ = atan2(accelY, accelZ) * 180.0 / PI; 
//     if (angleZ > LIMIT_DEG) detected = "RIGHT";
//     else if (angleZ < -LIMIT_DEG) detected = "LEFT";
//   }

//   if (detected != "") {
//     sendBleResponse(detected);
//     isQuestionActive = false;
//     activeMode = "";
//     Serial.print("Action Detected: "); Serial.println(detected);
//   }
// }

// void processBleCommand(std::string cmd) {
//   String command = String(cmd.c_str());
//   command.trim();
//   Serial.print("BLE Received << "); Serial.println(command);

//   if (command.startsWith("START")) {
//     activeMode = command.substring(6); 
//     activeMode.trim();
//     isQuestionActive = true;
//     sendBleResponse("READY:" + activeMode);
//   }
//   else if (command.startsWith("PLAY:")) {
//     isQuestionActive = false; 
//     String url = command.substring(5);
//     // كود الاختبار للاطمئنان
//     if (url.indexOf("TEST") >= 0) {
//        url = "http://www.kozco.com/tech/piano2-cool.mp3";
//     }
//     playFileFromURL(url.c_str());
//   }
//   else if (command == "STOP_AUDIO") {
//     stopAudio();
//     sendBleResponse("AUDIO:FINISHED");
//   }
// }

// class MyCommandCallbacks: public BLECharacteristicCallbacks {
//     void onWrite(BLECharacteristic *pCharacteristic) {
//       std::string value = pCharacteristic->getValue().c_str();
//       if (value.length() > 0) processBleCommand(value);
//     }
// };

// class MyServerCallbacks: public BLEServerCallbacks {
//     void onConnect(BLEServer* pServer) {
//       deviceConnected = true;
//       Serial.println("Device connected");
//     }
//     void onDisconnect(BLEServer* pServer) {
//       deviceConnected = false;
//       BLEDevice::startAdvertising();
//       Serial.println("Device disconnected");
//     }
// };

// void setup() {
//   Serial.begin(115200);
//   // تم إيقاف اللوجر لتوفير القليل من الذاكرة
//   // AudioLogger::instance().begin(Serial, AudioLogger::Info); 

//   pinMode(SHUTDOWN_PIN, OUTPUT);
//   digitalWrite(SHUTDOWN_PIN, LOW); 

//   // 1. تشغيل الواي فاي أولاً
//   WiFi.begin(ssid, password);
//   while (WiFi.status() != WL_CONNECTED) { delay(500); Serial.print("."); }
//   Serial.println("\nWiFi Connected");
//   WiFi.setSleep(false);

//   // 2. تشغيل البلوتوث
//   BLEDevice::init("CUBIE");
//   pServer = BLEDevice::createServer();
//   pServer->setCallbacks(new MyServerCallbacks());
//   pService = pServer->createService(SERVICE_UUID);
//   pCommandCharacteristic = pService->createCharacteristic(COMMAND_CHAR_UUID, BLECharacteristic::PROPERTY_WRITE);
//   pCommandCharacteristic->setCallbacks(new MyCommandCallbacks());
//   pResponseCharacteristic = pService->createCharacteristic(RESPONSE_CHAR_UUID, BLECharacteristic::PROPERTY_NOTIFY);
//   pResponseCharacteristic->addDescriptor(new BLE2902());
//   pService->start();
//   BLEDevice::getAdvertising()->addServiceUUID(SERVICE_UUID);
//   BLEDevice::startAdvertising();
//   Serial.println("BLE Ready.");

//   // 3. الحساس
//   Wire.begin(21, 22);
//   mpu.initialize();
// }

// void loop() {
//   if (mp3 && mp3->isRunning()) {
//     if (!mp3->loop()) {
//       stopAudio();
//       Serial.println("MP3 Done");
//       sendBleResponse("AUDIO:FINISHED");
//     }
//   } else {
//     handleSensors();
//   }
//   delay(10);
// }


// #include <Wire.h>
// #include <MPU6050.h>
// #include <WiFi.h>

// #include "AudioFileSourceHTTPStream.h"
// #include "AudioFileSourceBuffer.h"
// #include "AudioGeneratorMP3.h"
// #include "AudioOutputI2S.h"

// #include <BLEDevice.h>
// #include <BLEServer.h>
// #include <BLEUtils.h>
// #include <BLE2902.h>

// // ===================================
// // إعدادات شبكتك (تأكد منها)
// // ===================================
// const char* ssid = "HUAWEI_E5576_3656";    
// const char* password = "3GqA8bGYd3G"; 

// #define SHUTDOWN_PIN 4 
// #define I2S_DOUT 25
// #define I2S_BCLK 26
// #define I2S_LRC  27

// MPU6050 mpu(0x68);
// const float LIMIT_DEG = 25.0; // رفعت الزاوية قليلاً لتجنب الأخطاء
// const float SHAKE_LIMIT_G = 1.5; // رفعت حد الهز ليكون أصعب (مقصود)
// const float ACCEL_SCALE = 16384.0;
// int16_t accelX, accelY, accelZ, gyroX, gyroY, gyroZ;

// AudioGeneratorMP3 *mp3;
// AudioFileSourceHTTPStream *file_http;
// AudioFileSourceBuffer *buff;
// AudioOutputI2S *out;

// bool isQuestionActive = false;
// String activeMode = "";
// String answer = "";

// BLEServer *pServer = NULL;
// BLEService *pService = NULL;
// BLECharacteristic *pCommandCharacteristic = NULL;
// BLECharacteristic *pResponseCharacteristic = NULL;
// bool deviceConnected = false;

// #define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
// #define COMMAND_CHAR_UUID   "beb5483e-36e1-4688-b7f5-ea07361b26a8"
// #define RESPONSE_CHAR_UUID  "c3856242-4f7f-4a6c-b3d4-4a6e43f5a25c"

// void sendBleResponse(String message) {
//   if (deviceConnected) {
//     pResponseCharacteristic->setValue(message.c_str());
//     pResponseCharacteristic->notify();
//     Serial.print("BLE Notify >> "); Serial.println(message);
//   }
// }

// void stopAudio() {
//   if (mp3 && mp3->isRunning()) {
//     mp3->stop(); delete mp3; mp3 = nullptr;
//   }
//   if (buff) { buff->close(); delete buff; buff = nullptr; }
//   if (file_http) { file_http->close(); delete file_http; file_http = nullptr; }
//   if (out) { out->stop(); delete out; out = nullptr; }
//   digitalWrite(SHUTDOWN_PIN, LOW); 
// }

// // void playFileFromURL(const char* url) {
// //   stopAudio();
  
// //   file_http = new AudioFileSourceHTTPStream(url);
// //   buff = new AudioFileSourceBuffer(file_http, 4096);
// //   out = new AudioOutputI2S();
// //   out->SetPinout(I2S_BCLK, I2S_LRC, I2S_DOUT); 
// //   out->SetGain(0.8); 
  
// //   mp3 = new AudioGeneratorMP3();
  
// //   Serial.print("Playing: "); Serial.println(url);
// //   digitalWrite(SHUTDOWN_PIN, HIGH); // تشغيل السماعة

// //   if (!mp3->begin(buff, out)) {
// //     Serial.println("ERROR: Playback failed! Sending FINISHED to unblock app.");
// //     stopAudio();
// //     sendBleResponse("AUDIO:FINISHED"); // مهم جداً لعدم تعليق التطبيق
// //   } else {
// //     Serial.println("Playback started...");
// //   }
// // }
// void playFileFromURL(const char* url) {
//   stopAudio();
  
//   Serial.println("---------------------------");
//   Serial.print("Free Heap before playing: "); 
//   Serial.println(ESP.getFreeHeap()); // طباعة الذاكرة المتاحة للتأكد
  
//   Serial.print("Attempting to play: "); Serial.println(url);

//   file_http = new AudioFileSourceHTTPStream(url);
  
//   // !! تقليل البفر من 4096 إلى 2048 لتوفير الذاكرة !!
//   buff = new AudioFileSourceBuffer(file_http, 4096); 
  
//   out = new AudioOutputI2S();
//   out->SetPinout(I2S_BCLK, I2S_LRC, I2S_DOUT); 
//   out->SetGain(0.8); // مستوى الصوت
  
//   mp3 = new AudioGeneratorMP3();
  
//   digitalWrite(SHUTDOWN_PIN, HIGH); // تشغيل الامبليفاير

//   // محاولة البدء مع طباعة السبب إذا فشل
//   if (!mp3->begin(buff, out)) {
//     Serial.println("CRITICAL ERROR: mp3->begin() returned false!");
//     Serial.println("Causes: 1. URL unreachable, 2. Out of RAM, 3. Bad MP3 format");
//     stopAudio();
//     sendBleResponse("AUDIO:FINISHED"); 
//   } else {
//     Serial.println("Playback started successfully!");
//   }
// }

// void handleSensors() {
//   if (!isQuestionActive) return;

//   mpu.getMotion6(&accelX, &accelY, &accelZ, &gyroX, &gyroY, &gyroZ);
//   String detected = "";

//   // منطق صارم: افصل الحركات تماماً
//   if (activeMode == "SHAKE") {
//     float acc_g = sqrt((float)accelX*accelX + (float)accelY*accelY + (float)accelZ*accelZ) / ACCEL_SCALE;
//     // نحسب الفرق عن الجاذبية (1G)
//     if (fabs(acc_g - 1.0) > 0.8) { // 0.8 يعني هز قوي
//       detected = "SHAKE";
//     }
//   }
//   else if (activeMode == "TILTY") {
//     // نحسب زاوية الميل للأمام والخلف فقط
//     float angleY = atan2(accelX, sqrt(accelY*accelY + accelZ*accelZ)) * 180.0 / PI;
//     if (angleY > LIMIT_DEG) detected = "FORWARD";
//     else if (angleY < -LIMIT_DEG) detected = "BACK";
//   }
//   else if (activeMode == "TILTZ") {
//     // نحسب زاوية الميل يمين ويسار فقط
//     // ملاحظة: قد تحتاج لتبديل accelY و accelX حسب تركيب الشريحة
//     float angleZ = atan2(accelY, accelZ) * 180.0 / PI; 
//     if (angleZ > LIMIT_DEG) detected = "RIGHT";
//     else if (angleZ < -LIMIT_DEG) detected = "LEFT";
//   }

//   if (detected != "") {
//     sendBleResponse(detected);
//     isQuestionActive = false; // قفل الحساس بعد الإجابة
//     activeMode = "";
//     Serial.print("Action Detected: "); Serial.println(detected);
//   }
// }

// void processBleCommand(std::string cmd) {
//   String command = String(cmd.c_str());
//   command.trim();
//   Serial.print("BLE Received << "); Serial.println(command);

//   if (command.startsWith("START")) {
//     activeMode = command.substring(6); 
//     activeMode.trim();
//     isQuestionActive = true;
//     sendBleResponse("READY:" + activeMode);
//   }
//   else if (command.startsWith("PLAY:")) {
//     isQuestionActive = false; // تأكد ان الحساس طافي
//     String url = command.substring(5);
//     if (url.indexOf("TEST") >= 0) {
//        url = "http://www.kozco.com/tech/piano2-cool.mp3"; // ملف بيانو قصير للاختبار
//     }
//     playFileFromURL(url.c_str());
//   }
//   else if (command == "STOP_AUDIO") {
//     stopAudio();
//     sendBleResponse("AUDIO:FINISHED");
//   }
// }

// class MyCommandCallbacks: public BLECharacteristicCallbacks {
//     void onWrite(BLECharacteristic *pCharacteristic) {
//       std::string value = pCharacteristic->getValue().c_str();
//       if (value.length() > 0) processBleCommand(value);
//     }
// };

// class MyServerCallbacks: public BLEServerCallbacks {
//     void onConnect(BLEServer* pServer) {
//       deviceConnected = true;
//       Serial.println("Device connected");
//     }
//     void onDisconnect(BLEServer* pServer) {
//       deviceConnected = false;
//       BLEDevice::startAdvertising();
//       Serial.println("Device disconnected");
//     }
// };

// void setup() {
//   Serial.begin(115200);

//   pinMode(SHUTDOWN_PIN, OUTPUT);
//   digitalWrite(SHUTDOWN_PIN, LOW); // إطفاء السماعة

//   // BLE Init
//   BLEDevice::init("CUBIE");
//   pServer = BLEDevice::createServer();
//   pServer->setCallbacks(new MyServerCallbacks());
//   pService = pServer->createService(SERVICE_UUID);
//   pCommandCharacteristic = pService->createCharacteristic(COMMAND_CHAR_UUID, BLECharacteristic::PROPERTY_WRITE);
//   pCommandCharacteristic->setCallbacks(new MyCommandCallbacks());
//   pResponseCharacteristic = pService->createCharacteristic(RESPONSE_CHAR_UUID, BLECharacteristic::PROPERTY_NOTIFY);
//   pResponseCharacteristic->addDescriptor(new BLE2902());
//   pService->start();
//   BLEDevice::getAdvertising()->addServiceUUID(SERVICE_UUID);
//   BLEDevice::startAdvertising();
//   Serial.println("BLE Ready.");

//   // MPU Init
//   Wire.begin(21, 22);
//   mpu.initialize();
//   Serial.println(mpu.testConnection() ? "MPU Connected" : "MPU Failed");

//   // WiFi Init
//   WiFi.begin(ssid, password);
//   while (WiFi.status() != WL_CONNECTED) { delay(500); Serial.print("."); }
//   Serial.println("\nWiFi Connected: " + WiFi.localIP().toString());
//   WiFi.setSleep(false);
// }

// void loop() {
//   // التعامل مع تشغيل الصوت
//   if (mp3 && mp3->isRunning()) {
//     if (!mp3->loop()) {
//       stopAudio();
//       Serial.println("MP3 Done");
//       sendBleResponse("AUDIO:FINISHED");
//     }
//   } else {
//     // فقط شغل الحساس اذا الصوت طافي
//     handleSensors();
//   }
//   delay(10);
// }





// #include "driver/i2s.h"
// #include <math.h>

// // --- إعدادات الأسلاك ---
// #define I2S_DOUT      25
// #define I2S_BCLK      26
// #define I2S_LRC       27
// #define SHUTDOWN_PIN  4

// // --- إعدادات الصوت ---
// #define SAMPLE_RATE   44100
// #define MASTER_VOL    1800   // حجم متوسط لتجنب الإزعاج
// #define TEMPO_MOD     1.1    // معدل سرعة العزف (أكبر = أبطأ)

// // --- ترددات النوتات (Octave 3 & 4 - المجال "القروسطي") ---
// #define NOTE_B2  123
// #define NOTE_C3  131
// #define NOTE_D3  147
// #define NOTE_E3  165
// #define NOTE_F3  175
// #define NOTE_FS3 185
// #define NOTE_G3  196
// #define NOTE_A3  220
// #define NOTE_B3  247
// #define NOTE_C4  262
// #define NOTE_D4  294
// #define NOTE_E4  330
// #define NOTE_FS4 370
// #define NOTE_G4  392
// #define REST     0

// // هيكل النوتة
// struct MelodyNote {
//   int note;
//   int duration; // بالمللي ثانية
// };


// MelodyNote song[] = {

//   {NOTE_E3, 400}, {NOTE_B2, 400}, {NOTE_E3, 800},
//   {NOTE_G3, 400}, {NOTE_FS3, 400}, {NOTE_D3, 800},
  
//   {NOTE_E3, 400}, {NOTE_G3, 400}, {NOTE_B3, 400}, {NOTE_A3, 400},
//   {NOTE_G3, 400}, {NOTE_FS3, 400}, {NOTE_E3, 800},
//   {REST, 400},


//   {NOTE_A3, 300}, {NOTE_B3, 300}, {NOTE_C4, 600},
//   {NOTE_B3, 300}, {NOTE_A3, 300}, {NOTE_G3, 600},
  
//   {NOTE_FS3, 300}, {NOTE_G3, 300}, {NOTE_A3, 300}, {NOTE_G3, 300},
//   {NOTE_FS3, 300}, {NOTE_D3, 300}, {NOTE_E3, 900},
//   {REST, 500},


//   {NOTE_E4, 400}, {NOTE_D4, 400}, {NOTE_B3, 600},
//   {NOTE_C4, 200}, {NOTE_B3, 200}, {NOTE_A3, 600},
  
//   {NOTE_G3, 300}, {NOTE_A3, 300}, {NOTE_B3, 600},
//   {NOTE_A3, 300}, {NOTE_G3, 300}, {NOTE_FS3, 600},
  

//   {NOTE_E3, 800}, {NOTE_B2, 800}, {NOTE_E3, 1200},
//   {REST, 1000}
// };

// int songLength = sizeof(song) / sizeof(song[0]);

// void setup() {
//   Serial.begin(115200);
  
//   pinMode(SHUTDOWN_PIN, OUTPUT);
//   digitalWrite(SHUTDOWN_PIN, HIGH);

//   // إعداد I2S القياسي
//   i2s_config_t i2s_config = {
//     .mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_TX),
//     .sample_rate = SAMPLE_RATE,
//     .bits_per_sample = I2S_BITS_PER_SAMPLE_16BIT,
//     .channel_format = I2S_CHANNEL_FMT_RIGHT_LEFT,
//     .communication_format = I2S_COMM_FORMAT_I2S,
//     .intr_alloc_flags = 0,
//     .dma_buf_count = 8,
//     .dma_buf_len = 64,
//     .use_apll = false
//   };

//   i2s_pin_config_t pin_config = {
//     .bck_io_num = I2S_BCLK,
//     .ws_io_num = I2S_LRC,
//     .data_out_num = I2S_DOUT,
//     .data_in_num = I2S_PIN_NO_CHANGE
//   };

//   i2s_driver_install(I2S_NUM_0, &i2s_config, 0, NULL);
//   i2s_set_pin(I2S_NUM_0, &pin_config);
//   i2s_zero_dma_buffer(I2S_NUM_0);
// }

// // دالة عزف النوتة بأسلوب "المزمار" (Soft Attack/Decay)
// void playPipeSound(int freq, int durationMs) {
//   // تعديل السرعة بناءً على المتغير
//   int actualDuration = durationMs * TEMPO_MOD;

//   if (freq == 0) {
//     // كود الصمت (Rest)
//     size_t bytes_written;
//     int16_t silence[128] = {0}; 
//     int num_samples = (SAMPLE_RATE * actualDuration) / 1000;
//     int samples_sent = 0;
//     while(samples_sent < num_samples) {
//        i2s_write(I2S_NUM_0, silence, sizeof(silence), &bytes_written, portMAX_DELAY);
//        samples_sent += 64;
//     }
//     return;
//   }

//   int samples_per_cycle = SAMPLE_RATE / freq;
//   int half_cycle = samples_per_cycle / 2;
//   long total_samples = (SAMPLE_RATE * actualDuration) / 1000;
  
//   int16_t buffer[128]; 
//   long samples_generated = 0;
//   int waveform_pos = 0;
  
//   // مغلف الصوت (Envelope) لمحاكاة النفخ
//   float current_vol = 0; 
//   // اجعل الهجوم (بداية الصوت) بطيئاً قليلاً ليعطي شعور "الناي"
//   float attack_step = (float)MASTER_VOL / 1500.0; 
//   float release_step = (float)MASTER_VOL / 1500.0;

//   while (samples_generated < total_samples) {
//     for (int i = 0; i < 128; i += 2) {
      
//       // منطق الـ Soft Flute Envelope
//       if (samples_generated < 2000) { 
//          // بداية ناعمة (Slow Attack)
//          if(current_vol < MASTER_VOL) current_vol += attack_step;
//       } 
//       else if (samples_generated > total_samples - 2000) {
//          // نهاية ناعمة (Slow Release)
//          if(current_vol > 0) current_vol -= release_step;
//       }
//       else {
//          current_vol = MASTER_VOL;
//       }

//       // توليد موجة مربعة "Square Wave" ولكن التحكم بالحجم يعطيها طابعاً ناعماً
//       int16_t val = (waveform_pos < half_cycle) ? (int)current_vol : -(int)current_vol;
      
//       buffer[i] = val;
//       buffer[i+1] = val;
      
//       waveform_pos++;
//       if (waveform_pos >= samples_per_cycle) waveform_pos = 0;
//       samples_generated++;
//     }
    
//     size_t bytes_written;
//     i2s_write(I2S_NUM_0, buffer, sizeof(buffer), &bytes_written, portMAX_DELAY);
//   }
// }

// void loop() {

//   for (int i = 0; i < songLength; i++) {
//     playPipeSound(song[i].note, song[i].duration);
    
//     delay(5); 
//   }
  

//   delay(2000);
// }