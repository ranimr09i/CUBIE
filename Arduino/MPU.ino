







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




#include <Wire.h>
#include <MPU6050.h>
#include <WiFi.h>

#include "AudioFileSourceHTTPStream.h"
#include "AudioFileSourceBuffer.h"
#include "AudioGeneratorMP3.h"
#include "AudioOutputI2S.h"

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// ===================================
// إعدادات شبكتك (تأكد منها)
// ===================================
const char* ssid = "HUAWEI_E5576_3656";    
const char* password = "3GqA8bGYd3G"; 

#define SHUTDOWN_PIN 4 
#define I2S_DOUT 25
#define I2S_BCLK 26
#define I2S_LRC  27

MPU6050 mpu(0x68);
const float LIMIT_DEG = 25.0; // رفعت الزاوية قليلاً لتجنب الأخطاء
const float SHAKE_LIMIT_G = 1.5; // رفعت حد الهز ليكون أصعب (مقصود)
const float ACCEL_SCALE = 16384.0;
int16_t accelX, accelY, accelZ, gyroX, gyroY, gyroZ;

AudioGeneratorMP3 *mp3;
AudioFileSourceHTTPStream *file_http;
AudioFileSourceBuffer *buff;
AudioOutputI2S *out;

bool isQuestionActive = false;
String activeMode = "";
String answer = "";

BLEServer *pServer = NULL;
BLEService *pService = NULL;
BLECharacteristic *pCommandCharacteristic = NULL;
BLECharacteristic *pResponseCharacteristic = NULL;
bool deviceConnected = false;

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define COMMAND_CHAR_UUID   "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define RESPONSE_CHAR_UUID  "c3856242-4f7f-4a6c-b3d4-4a6e43f5a25c"

void sendBleResponse(String message) {
  if (deviceConnected) {
    pResponseCharacteristic->setValue(message.c_str());
    pResponseCharacteristic->notify();
    Serial.print("BLE Notify >> "); Serial.println(message);
  }
}

void stopAudio() {
  if (mp3 && mp3->isRunning()) {
    mp3->stop(); delete mp3; mp3 = nullptr;
  }
  if (buff) { buff->close(); delete buff; buff = nullptr; }
  if (file_http) { file_http->close(); delete file_http; file_http = nullptr; }
  if (out) { out->stop(); delete out; out = nullptr; }
  digitalWrite(SHUTDOWN_PIN, HIGH); 
}

void playFileFromURL(const char* url) {
  stopAudio();
  
  file_http = new AudioFileSourceHTTPStream(url);
  buff = new AudioFileSourceBuffer(file_http, 4096);
  out = new AudioOutputI2S();
  out->SetPinout(I2S_BCLK, I2S_LRC, I2S_DOUT); 
  out->SetGain(0.8); 
  
  mp3 = new AudioGeneratorMP3();
  
  Serial.print("Playing: "); Serial.println(url);
  digitalWrite(SHUTDOWN_PIN, LOW); // تشغيل السماعة

  if (!mp3->begin(buff, out)) {
    Serial.println("ERROR: Playback failed! Sending FINISHED to unblock app.");
    stopAudio();
    sendBleResponse("AUDIO:FINISHED"); // مهم جداً لعدم تعليق التطبيق
  } else {
    Serial.println("Playback started...");
  }
}

void handleSensors() {
  if (!isQuestionActive) return;

  mpu.getMotion6(&accelX, &accelY, &accelZ, &gyroX, &gyroY, &gyroZ);
  String detected = "";

  // منطق صارم: افصل الحركات تماماً
  if (activeMode == "SHAKE") {
    float acc_g = sqrt((float)accelX*accelX + (float)accelY*accelY + (float)accelZ*accelZ) / ACCEL_SCALE;
    // نحسب الفرق عن الجاذبية (1G)
    if (fabs(acc_g - 1.0) > 0.8) { // 0.8 يعني هز قوي
      detected = "SHAKE";
    }
  }
  else if (activeMode == "TILTY") {
    // نحسب زاوية الميل للأمام والخلف فقط
    float angleY = atan2(accelX, sqrt(accelY*accelY + accelZ*accelZ)) * 180.0 / PI;
    if (angleY > LIMIT_DEG) detected = "FORWARD";
    else if (angleY < -LIMIT_DEG) detected = "BACK";
  }
  else if (activeMode == "TILTZ") {
    // نحسب زاوية الميل يمين ويسار فقط
    // ملاحظة: قد تحتاج لتبديل accelY و accelX حسب تركيب الشريحة
    float angleZ = atan2(accelY, accelZ) * 180.0 / PI; 
    if (angleZ > LIMIT_DEG) detected = "RIGHT";
    else if (angleZ < -LIMIT_DEG) detected = "LEFT";
  }

  if (detected != "") {
    sendBleResponse(detected);
    isQuestionActive = false; // قفل الحساس بعد الإجابة
    activeMode = "";
    Serial.print("Action Detected: "); Serial.println(detected);
  }
}

void processBleCommand(std::string cmd) {
  String command = String(cmd.c_str());
  command.trim();
  Serial.print("BLE Received << "); Serial.println(command);

  if (command.startsWith("START")) {
    activeMode = command.substring(6); 
    activeMode.trim();
    isQuestionActive = true;
    sendBleResponse("READY:" + activeMode);
  }
  else if (command.startsWith("PLAY:")) {
    isQuestionActive = false; // تأكد ان الحساس طافي
    String url = command.substring(5);
    playFileFromURL(url.c_str());
  }
  else if (command == "STOP_AUDIO") {
    stopAudio();
    sendBleResponse("AUDIO:FINISHED");
  }
}

class MyCommandCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue().c_str();
      if (value.length() > 0) processBleCommand(value);
    }
};

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("Device connected");
    }
    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      BLEDevice::startAdvertising();
      Serial.println("Device disconnected");
    }
};

void setup() {
  Serial.begin(115200);
  pinMode(SHUTDOWN_PIN, OUTPUT);
  digitalWrite(SHUTDOWN_PIN, HIGH); // إطفاء السماعة

  // BLE Init
  BLEDevice::init("CUBIE");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  pService = pServer->createService(SERVICE_UUID);
  pCommandCharacteristic = pService->createCharacteristic(COMMAND_CHAR_UUID, BLECharacteristic::PROPERTY_WRITE);
  pCommandCharacteristic->setCallbacks(new MyCommandCallbacks());
  pResponseCharacteristic = pService->createCharacteristic(RESPONSE_CHAR_UUID, BLECharacteristic::PROPERTY_NOTIFY);
  pResponseCharacteristic->addDescriptor(new BLE2902());
  pService->start();
  BLEDevice::getAdvertising()->addServiceUUID(SERVICE_UUID);
  BLEDevice::startAdvertising();
  Serial.println("BLE Ready.");

  // MPU Init
  Wire.begin(21, 22);
  mpu.initialize();
  Serial.println(mpu.testConnection() ? "MPU Connected" : "MPU Failed");

  // WiFi Init
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) { delay(500); Serial.print("."); }
  Serial.println("\nWiFi Connected: " + WiFi.localIP().toString());
}

void loop() {
  // التعامل مع تشغيل الصوت
  if (mp3 && mp3->isRunning()) {
    if (!mp3->loop()) {
      stopAudio();
      Serial.println("MP3 Done");
      sendBleResponse("AUDIO:FINISHED");
    }
  } else {
    // فقط شغل الحساس اذا الصوت طافي
    handleSensors();
  }
  delay(10);
}





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