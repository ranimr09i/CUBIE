// #include <Wire.h>
// #include <MPU6050.h>
// #include "BluetoothSerial.h" // للبلوتوث

// // --- !! إضافة مكتبات الواي فاي !! ---
// #include <WiFi.h>

// // --- !! مكتبات الصوت !! ---
// #include "AudioOutputI2S.h"
// #include "AudioFileSourceHTTPStream.h" // <-- لبث الصوت من الإنترنت
// #include "AudioGeneratorMP3.h"         // <-- لتشغيل الـ MP3
// #include "AudioGeneratorRTTTL.h"       // <-- !! لإصوات التست "طن طن" !!
// #include "AudioFileSourceRTTTL.h"      // <-- !! لملف التست "طن طن" !!

// // ===================================
// // !!      إعدادات الواي فاي      !!
// // !! (ضع اسم وباسورد شبكتك هنا) !!
// // ===================================
// const char* ssid = "YOUR_WIFI_NAME";     // <-- !! غيّر هذا !!
// const char* password = "YOUR_WIFI_PASSWORD"; // <-- !! غيّر هذا !!
// // ===================================

// // --- منفذ مفتاح الأمان (لحل مشكلة الطاقة) ---
// #define SHUTDOWN_PIN 4 // (P4) موصول بـ SD

// // --- إعدادات البلوتوث ---
// BluetoothSerial SerialBT;

// // --- إعدادات السماعة (مطابقة لأسلاكك) ---
// #define I2S_DOUT 25
// #define I2S_BCLK 26
// #define I2S_LRC  27

// // --- كائنات الصوت (للقصص من الإنترنت) ---
// AudioGeneratorMP3 *mp3 = nullptr;
// AudioFileSourceHTTPStream *file_http = nullptr;
// AudioOutputI2S *out = nullptr;

// // --- كائنات الصوت (للتست "طن طن") ---
// AudioGeneratorRTTTL *rtttl = nullptr;
// AudioFileSourceRTTTL *file_rtttl = nullptr;
// // هذا هو كود صوت "طن طن"
// const char* beep_rtttl = "Beep:d=4,o=5,b=140:8a,8a";

// // --- إعدادات حساس الحركة ---
// MPU6050 mpu(0x68);
// const float LIMIT_DEG = 20.0;
// const float SHAKE_LIMIT_G = 0.7;
// const float ACCEL_SCALE = 16384.0;
// int16_t accelX, accelY, accelZ, gyroX, gyroY, gyroZ;

// // --- متغيرات حالة التشغيل ---
// bool isQuestionActive = false;
// String mode = "";
// String answer = "";
// bool isTestMode = false; // للتفريق بين التست والبلوتوث

// // ------------------------------------
// // !! دالة إيقاف *كل* الأصوات !!
// // ------------------------------------
// void stopAudio() {
//   // 1. أوقف مشغل MP3 (الإنترنت)
//   if (mp3) { 
//     if (mp3->isRunning()) mp3->stop();
//     delete mp3; mp3 = nullptr;
//   }
//   if (file_http) {
//     delete file_http; file_http = nullptr;
//   }

//   // 2. أوقف مشغل "طن طن" (التست)
//   if (rtttl) {
//     if (rtttl->isRunning()) rtttl->stop();
//     delete rtttl; rtttl = nullptr;
//   }
//   if (file_rtttl) {
//     delete file_rtttl; file_rtttl = nullptr;
//   }
  
//   // 3. أوقف مخرج الصوت الرئيسي
//   if (out) {
//     out->stop();
//     delete out; out = nullptr;
//   }
  
//   // 4. "نوّم" السماعة لتوفير الطاقة
//   digitalWrite(SHUTDOWN_PIN, HIGH); // HIGH = Shutdown ON (Sleep)
// }

// // ------------------------------------
// // !! 1. دالة تشغيل صوت التست "طن طن" !!
// // ------------------------------------
// void playTestBeep() {
//   stopAudio(); // أوقف أي شيء شغال

//   digitalWrite(SHUTDOWN_PIN, LOW); // "أيقظ" السماعة
//   delay(10); 
//   Serial.println("Amplifier is WOKE. Playing test beep...");

//   file_rtttl = new AudioFileSourceRTTTL(beep_rtttl);
//   out = new AudioOutputI2S();
//   out->SetPinout(I2S_BCLK, I2S_LRC, I2S_DOUT); 
//   out->begin();
//   rtttl = new AudioGeneratorRTTTL();
//   rtttl->begin(file_rtttl, out);
// }

// // ------------------------------------
// // !! 2. دالة تشغيل القصة (من الإنترنت) !!
// // ------------------------------------
// void playFileFromURL(String url) {
//   stopAudio(); // أوقف أي شيء شغال

//   digitalWrite(SHUTDOWN_PIN, LOW); // "أيقظ" السماعة
//   delay(10); 
//   Serial.println("Amplifier is WOKE. Playing from URL...");
//   Serial.println(url);

//   file_http = new AudioFileSourceHTTPStream(url.c_str());
//   out = new AudioOutputI2S();
//   out->SetPinout(I2S_BCLK, I2S_LRC, I2S_DOUT); 
//   out->begin();
  
//   mp3 = new AudioGeneratorMP3();
//   mp3->begin(file_http, out);
// }

// // ------------------------------------
// // التعامل مع أوامر البلوتوث (من التطبيق)
// // ------------------------------------
// void handleBluetoothCommands() {
//   while (SerialBT.available()) { 
//     String command = SerialBT.readStringUntil('\n');
//     command.trim();
//     command.toUpperCase(); // <-- حول الأمر إلى حروف كبيرة لضمان التطابق

//     // الأمر الأساسي لبدء السؤال
//     if (command.startsWith("START")) {
//       isTestMode = false; // هذا أمر حقيقي من التطبيق
//       mode = command.substring(5);
//       mode.trim();
//       isQuestionActive = true;
//       answer = "";
//       SerialBT.println("READY:" + mode); 
//       Serial.println("READY:" + mode); 
//     }
//     // الأمر الجديد لتشغيل قصة من الإنترنت
//     else if (command.startsWith("PLAY:")) {
//       String url = command.substring(5);
//       url.trim(); // نظف الرابط
//       playFileFromURL(url);
//     }
//     // أمر إيقاف الصوت من التطبيق
//     else if (command == "STOP_AUDIO") {
//       stopAudio();
//     }
//   }
// }

// // ------------------------------------
// // التعامل مع أوامر السيريال (للتست)
// // ------------------------------------
// void handleCommands() {
//   while (Serial.available()) {
//     String command = Serial.readStringUntil('\n');
//     command.trim();
//     command.toUpperCase();

//     // تست حركة
//     if (command.startsWith("START")) {
//       isTestMode = true; // هذا أمر تست من السيريال
//       mode = command.substring(5);
//       mode.trim();
//       isQuestionActive = true;
//       answer = "";
//       Serial.println("READY (Test Mode):" + mode);
//     }
//     // !! [تم التعديل] تست صوت "طن طن" !!
//     else if (command == "PLAYTEST") {
//       Serial.println("Playing test sound...");
//       playTestBeep(); // <-- يشغل صوت "طن طن"
//     }
//     // تست صوت من رابط (اختياري)
//     else if (command.startsWith("PLAY:")) {
//       String url = command.substring(5);
//       url.trim();
//       playFileFromURL(url);
//     }
//   }
// }

// // ------------------------------------
// // دوال رصد الحركة (مع تعديل صوت التست)
// // ------------------------------------
// void detectShake() {
//   float acc_g = sqrt((float)accelX*accelX + (float)accelY*accelY + (float)accelZ*accelZ) / ACCEL_SCALE;
//   if (fabs(acc_g - 1.0) > SHAKE_LIMIT_G) {
//     answer = "SHAKE";
//     Serial.println(answer);
//     SerialBT.println(answer);
//     isQuestionActive = false;
//     if (isTestMode) playTestBeep(); // !! يشغل "طن طن" !!
//   }
// }
// void detectY() {
//   float angleY = atan2(accelX, sqrt(accelY*accelY + accelZ*accelZ)) * 180.0 / PI;
//   if (angleY > LIMIT_DEG) {
//     answer = "FORWARD";
//     Serial.println(answer);
//     SerialBT.println(answer);
//     isQuestionActive = false;
//     if (isTestMode) playTestBeep(); // !! يشغل "طن طن" !!
//   } else if (angleY < -LIMIT_DEG) {
//     answer = "BACK";
//     Serial.println(answer);
//     SerialBT.println(answer);
//     isQuestionActive = false;
//     if (isTestMode) playTestBeep(); // !! يشغل "طن طن" !!
//   }
// }
// void detectZ() {
//   float angleZ = atan2(accelY, accelZ) * 180.0 / PI;
//   if (angleZ > LIMIT_DEG) {
//     answer = "RIGHT";
//     Serial.println(answer);
//     SerialBT.println(answer);
//     isQuestionActive = false;
//     if (isTestMode) playTestBeep(); // !! يشغل "طن طن" !!
//   } else if (angleZ < -LIMIT_DEG) {
//     answer = "LEFT";
//     Serial.println(answer);
//     SerialBT.println(answer);
//     isQuestionActive = false;
//     if (isTestMode) playTestBeep(); // !! يشغل "طن طن" !!
//   }
// }

// // ------------------------------------
// // Setup
// // ------------------------------------
// void setup() {
//   Serial.begin(115200);

//   // --- 1. إعداد مفتاح الأمان (SD Pin) ---
//   pinMode(SHUTDOWN_PIN, OUTPUT);
//   digitalWrite(SHUTDOWN_PIN, HIGH); // "نوّم" السماعة فوراً
//   Serial.println("Amplifier put to sleep immediately.");
  
//   // --- 2. تشغيل البلوتوث ---
//   SerialBT.begin("CUBIE"); 
//   Serial.println("Cube is ready for Bluetooth connection...");

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
//   while (WiFi.status() != WL_CONNECTED) {
//     delay(500);
//     Serial.print(".");
//   }
//   Serial.println("");
//   Serial.println("WiFi connected!");
//   Serial.print("IP address: ");
//   Serial.println(WiFi.localIP());

//   Serial.println("--- System Ready ---");
// }

// // ------------------------------------
// // Loop
// // ------------------------------------
// void loop() {
//   handleCommands(); // استقبال أوامر من السيريال
//   handleBluetoothCommands(); // استقبال أوامر من الجوال

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
//       SerialBT.println("AUDIO:FINISHED");
//     }
//   }

//   // --- سطر مهم لتشغيل صوت "طن طن" ---
//   if (rtttl && rtttl->isRunning()) {
//     if (!rtttl->loop()) {
//       stopAudio(); // أوقف الصوت عند الانتهاء
//       Serial.println("Test Beep Finished.");
//     }
//   }

//   delay(50);
// }









////////
#include <Wire.h>
#include <MPU6050.h>
#include "BluetoothSerial.h" // للبلوتوث
#include <WiFi.h>              // للواي فاي

// --- !! مكتبات الصوت (للإنترنت فقط) !! ---
#include "AudioOutputI2S.h"
#include "AudioFileSourceHTTPStream.h" // <-- لبث الصوت من الإنترنت
#include "AudioGeneratorMP3.h"         // <-- لتشغيل الـ MP3

// (تم حذف جميع مكتبات RTTTL المسببة للمشكلة)

// ===================================
// !!      إعدادات الواي فاي      !!
// (ضع اسم وباسورد شبكتك هنا)
// ===================================
const char* ssid = "Salman_4G";     // <-- !! غيّر هذا !!
const char* password = "0566339996"; // <-- !! غيّر هذا !!
// ===================================

// --- رابط MP3 للتست (بديل الطن طن) ---
const char* test_url = "http://ia800208.us.archive.org/4/items/testmp3testfile/mpthreetest.mp3";

// --- منفذ مفتاح الأمان (لحل مشكلة الطاقة) ---
#define SHUTDOWN_PIN 4 // (P4) موصول بـ SD

// --- إعدادات البلوتوث ---
BluetoothSerial SerialBT;

// --- إعدادات السماعة (مطابقة لأسلاكك) ---
#define I2S_DOUT 25
#define I2S_BCLK 26
#define I2S_LRC  27

// --- كائنات الصوت (للقصص من الإنترنت) ---
AudioGeneratorMP3 *mp3 = nullptr;
AudioFileSourceHTTPStream *file_http = nullptr;
AudioOutputI2S *out = nullptr;

// --- إعدادات حساس الحركة ---
MPU6050 mpu(0x68);
const float LIMIT_DEG = 20.0;
const float SHAKE_LIMIT_G = 0.7;
const float ACCEL_SCALE = 16384.0;
int16_t accelX, accelY, accelZ, gyroX, gyroY, gyroZ;

// --- متغيرات حالة التشغيل ---
bool isQuestionActive = false;
String mode = "";
String answer = "";
bool isTestMode = false;

// ------------------------------------
// !! دالة إيقاف *كل* الأصوات !!
// ------------------------------------
void stopAudio() {
  if (mp3) { 
    if (mp3->isRunning()) mp3->stop();
    delete mp3; mp3 = nullptr;
  }
  if (file_http) {
    delete file_http; file_http = nullptr;
  }
  if (out) {
    out->stop();
    delete out; out = nullptr;
  }
  digitalWrite(SHUTDOWN_PIN, HIGH); // "نوّم" السماعة
}

// ------------------------------------
// !! دالة تشغيل القصة (من الإنترنت) !!
// ------------------------------------
void playFileFromURL(const char* url) {
  stopAudio(); // أوقف أي شيء شغال

  digitalWrite(SHUTDOWN_PIN, LOW); // "أيقظ" السماعة
  delay(10); 
  Serial.println("Amplifier is WOKE. Playing from URL...");
  Serial.println(url);

  file_http = new AudioFileSourceHTTPStream(url);
  
  // !! ================== [الحل هنا] ================== !!
  // نخبره بألا يستخدم الذاكرة السريعة (DMA)
  out = new AudioOutputI2S(0, false); // (port 0, use_dma = false)
  // !! =============================================== !!
  
  out->SetPinout(I2S_BCLK, I2S_LRC, I2S_DOUT); 
  out->begin();
  
  mp3 = new AudioGeneratorMP3();
  mp3->begin(file_http, out);
}

// ------------------------------------
// التعامل مع أوامر البلوتوث (من التطبيق)
// ------------------------------------
void handleBluetoothCommands() {
  while (SerialBT.available()) { 
    String command = SerialBT.readStringUntil('\n');
    command.trim();
    command.toUpperCase(); 

    if (command.startsWith("START")) {
      isTestMode = false;
      mode = command.substring(5);
      mode.trim();
      isQuestionActive = true;
      answer = "";
      SerialBT.println("READY:" + mode); 
      Serial.println("READY:" + mode); 
    }
    else if (command.startsWith("PLAY:")) {
      String url = command.substring(5);
      url.trim(); 
      playFileFromURL(url.c_str());
    }
    else if (command == "STOP_AUDIO") {
      stopAudio();
    }
  }
}

// ------------------------------------
// التعامل مع أوامر السيريال (للتست)
// ------------------------------------
void handleCommands() {
  while (Serial.available()) {
    String command = Serial.readStringUntil('\n');
    command.trim();
    command.toUpperCase();

    if (command.startsWith("START")) {
      isTestMode = true; 
      mode = command.substring(5);
      mode.trim();
      isQuestionActive = true;
      answer = "";
      Serial.println("READY (Test Mode):" + mode);
    }
    // !! [تم التعديل] تست الصوت !!
    else if (command == "PLAYTEST") {
      Serial.println("Playing test sound from URL...");
      playFileFromURL(test_url); // <-- يشغل ملف MP3 من الإنترنت
    }
  }
}

// ------------------------------------
// دوال رصد الحركة
// ------------------------------------
void detectShake() {
  float acc_g = sqrt((float)accelX*accelX + (float)accelY*accelY + (float)accelZ*accelZ) / ACCEL_SCALE;
  if (fabs(acc_g - 1.0) > SHAKE_LIMIT_G) {
    answer = "SHAKE";
    Serial.println(answer);
    SerialBT.println(answer);
    isQuestionActive = false;
    if (isTestMode) playFileFromURL(test_url); // !! يشغل تست الإنترنت !!
  }
}
void detectY() {
  float angleY = atan2(accelX, sqrt(accelY*accelY + accelZ*accelZ)) * 180.0 / PI;
  if (angleY > LIMIT_DEG) {
    answer = "FORWARD";
    Serial.println(answer);
    SerialBT.println(answer);
    isQuestionActive = false;
    if (isTestMode) playFileFromURL(test_url); // !! يشغل تست الإنترنت !!
  } else if (angleY < -LIMIT_DEG) {
    answer = "BACK";
    Serial.println(answer);
    SerialBT.println(answer);
    isQuestionActive = false;
    if (isTestMode) playFileFromURL(test_url); // !! يشغل تست الإنترنت !!
  }
}
void detectZ() {
  float angleZ = atan2(accelY, accelZ) * 180.0 / PI;
  if (angleZ > LIMIT_DEG) {
    answer = "RIGHT";
    Serial.println(answer);
    SerialBT.println(answer);
    isQuestionActive = false;
    if (isTestMode) playFileFromURL(test_url); // !! يشغل تست الإنترنت !!
  } else if (angleZ < -LIMIT_DEG) {
    answer = "LEFT";
    Serial.println(answer);
    SerialBT.println(answer);
    isQuestionActive = false;
    if (isTestMode) playFileFromURL(test_url); // !! يشغل تست الإنترنت !!
  }
}

// ------------------------------------
// Setup
// ------------------------------------
void setup() {
  Serial.begin(115200);

  // --- 1. إعداد مفتاح الأمان (SD Pin) ---
  pinMode(SHUTDOWN_PIN, OUTPUT);
  digitalWrite(SHUTDOWN_PIN, HIGH); // "نوّم" السماعة فوراً
  Serial.println("Amplifier put to sleep immediately.");
  
  // --- 2. تشغيل البلوتوث ---
  SerialBT.begin("CUBIE"); 
  Serial.println("Cube is ready for Bluetooth connection...");

  // --- 3. تشغيل حساس الحركة ---
  Wire.begin(21, 22);
  mpu.initialize();
  Serial.println("Testing MPU6050 connection...");
  if (mpu.testConnection()) {
    Serial.println("MPU6050 connection successful!");
    mpu.setSleepEnabled(false);
  } else {
    Serial.println("MPU6050 connection failed! Check wiring.");
  }

  // --- 4. تشغيل الواي فاي !! ---
  Serial.print("Connecting to WiFi: ");
  Serial.println(ssid);
  WiFi.begin(ssid, password);
  int wifi_retries = 20;
  while (WiFi.status() != WL_CONNECTED && wifi_retries > 0) {
    delay(500);
    Serial.print(".");
    wifi_retries--;
  }

  if (WiFi.status() != WL_CONNECTED) {
     Serial.println("");
     Serial.println("WiFi connection FAILED! Check SSID and Password.");
     // يمكنك أن تقرر ماذا تفعل هنا، مثلاً التوقف
  } else {
    Serial.println("");
    Serial.println("WiFi connected!");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
  }

  Serial.println("--- System Ready ---");
}

// ------------------------------------
// Loop
// ------------------------------------
void loop() {
  handleCommands(); 
  handleBluetoothCommands(); 

  if (isQuestionActive && answer.length() == 0) {
    mpu.getMotion6(&accelX, &accelY, &accelZ, &gyroX, &gyroY, &gyroZ);
    if (mode == "SHAKE") detectShake();
    else if (mode == "TILTY") detectY();
    else if (mode == "TILTZ") detectZ();
  }

  // --- سطر مهم لتشغيل صوت الإنترنت ---
  if (mp3 && mp3->isRunning()) {
    if (!mp3->loop()) {
      stopAudio(); // أوقف الصوت عند الانتهاء
      Serial.println("MP3 Stream Finished.");
      SerialBT.println("AUDIO:FINISHED");
    }
  }
  
  delay(50);
}
/////////

// /*
//  * كود اختبار السماعة MAX98357A البسيط جداً
//  * (لا يحتاج مكتبة ESP8266Audio)
//  */

// // ===================================
// // !!      تأكد من أسلاكك هنا      !!
// // ===================================
// // هذا الكود يتجاهل BCLK و LRC لأنه يولد موجة بسيطة
// #define I2S_DOUT 25      // (P25) - هذا هو السلك الوحيد الذي نحتاجه للصوت
// #define SHUTDOWN_PIN 4   // (P4) - سلك مفتاح الأمان
// // ===================================

// // لإعدادات النغمة (Tone)
// #include "driver/i2s.h"

// // ------------------------------------
// // Setup
// // ------------------------------------
// void setup() {
//   Serial.begin(115200);
//   Serial.println("--- Super Simple Speaker Test (No Libs) ---");

//   // --- 1. "أيقظ" السماعة ---
//   pinMode(SHUTDOWN_PIN, OUTPUT);
//   digitalWrite(SHUTDOWN_PIN, LOW); // LOW = Wake up
//   Serial.println("Amplifier is WOKE.");
  
//   // --- 2. إعداد منفذ I2S (الصوت) يدوياً ---
//   Serial.println("Configuring I2S port...");
  
//   // هذا هو الإعداد اليدوي لمكتبة I2S المدمجة
//   i2s_config_t i2s_config = {
//       .mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_TX), // إرسال فقط
//       .sample_rate = 44100,
//       .bits_per_sample = I2S_BITS_PER_SAMPLE_16BIT,   
//       .channel_format = I2S_CHANNEL_FMT_RIGHT_LEFT,     // 2 channels
//       .communication_format = I2S_COMM_FORMAT_STAND_I2S,
//       .intr_alloc_flags = 0,                             // 0 = default interrupt priority
//       .dma_buf_count = 8,
//       .dma_buf_len = 64,
//       .use_apll = false                                  // عدم استخدام APLL
//   };
  
//   // هذه هي الأسلاك
//   i2s_pin_config_t pin_config = {
//       .bck_io_num = 26,   // (P26) - BCLK
//       .ws_io_num = 27,    // (P27) - LRC
//       .data_out_num = 25, // (P25) - DOUT
//       .data_in_num = I2S_PIN_NO_CHANGE // لا نستقبل صوت
//   };

//   // تثبيت الدرايفر
//   i2s_driver_install((i2s_port_t)0, &i2s_config, 0, NULL);
//   i2s_set_pin((i2s_port_t)0, &pin_config);
  
//   Serial.println("I2S Configured. Playing tone...");
  
//   // تشغيل نغمة "بيييب" بتردد 440 هرتز
//   i2s_set_sample_rates((i2s_port_t)0, 22050); // خفض السرعة للنغمة
//   i2s_zero_dma_buffer((i2s_port_t)0); // تنظيف البافر
  
//   // تشغيل نغمة مدمجة (موجة مربعة)
//   // هذا الأمر سيجعل السماعة تصدر صوت "بييييب"
//   i2s_start((i2s_port_t)0);
  
//   // كود توليد النغمة
//   // (هذا الجزء تقني، لا يهمك، هو فقط يولد صوت "بيييب")
//   static const int SAMPLE_RATE = 22050;
//   static const int TONE_FREQ = 440; // نغمة 440 هرتز
//   static const int SAMPLES_PER_PERIOD = SAMPLE_RATE / TONE_FREQ;
//   static const int BUFFER_SIZE = 128;
//   int16_t samples[BUFFER_SIZE];
  
//   for(int i=0; i<BUFFER_SIZE; i+=2) {
//     if (i % SAMPLES_PER_PERIOD < SAMPLES_PER_PERIOD / 2) {
//       samples[i] = 5000;   // صوت مرتفع (يمين)
//       samples[i+1] = 5000; // صوت مرتفع (يسار)
//     } else {
//       samples[i] = -5000;  // صوت منخفض (يمين)
//       samples[i+1] = -5000; // صوت منخفض (يسار)
//     }
//   }

//   // أرسل النغمة للسماعة بشكل مستمر
//   size_t bytes_written = 0;
//   while(true) {
//     i2s_write((i2s_port_t)0, &samples, sizeof(samples), &bytes_written, portMAX_DELAY);
//   }
// }

// // ------------------------------------
// // Loop (لن نصل إليه أبداً)
// // ------------------------------------
// void loop() {
//   delay(1000);
// }