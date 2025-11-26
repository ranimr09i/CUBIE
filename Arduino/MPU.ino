
// #include <Wire.h>
// #include <MPU6050.h>
// #include <WiFi.h>
// #include <SPI.h>
// #include <Adafruit_VS1053.h>
// #include <BLEDevice.h>
// #include <BLEServer.h>
// #include <BLEUtils.h>
// #include <BLE2902.h>
// #include <esp_task_wdt.h> // !! مكتبة مهمة لمنع إعادة التشغيل !!

// // ==================================================
// // 1. إعدادات الواي فاي (شبكتك)
// // ==================================================
// const char* ssid = "HUAWEI_E5576_3656";
// const char* password = "3GqA8bGYd3G";
// // const char* ssid = "Salman_4G";
// // const char* password = "0566339996";


// // ==================================================
// // 2. إعدادات أسلاك الصوت
// // ==================================================
// #define VS1053_RESET   23     
// #define VS1053_CS      5      
// #define VS1053_DCS     2      
// #define VS1053_DREQ    27     
// #define VS1053_MOSI    14
// #define VS1053_MISO    19
// #define VS1053_SCK     18

// #define SHUTDOWN_PIN   4 

// // ==================================================
// // 3. كائنات النظام
// // ==================================================
// Adafruit_VS1053 musicPlayer = Adafruit_VS1053(VS1053_RESET, VS1053_CS, VS1053_DCS, VS1053_DREQ);
// WiFiClient client;
// MPU6050 mpu(0x68);

// // متغيرات
// const float LIMIT_DEG = 20.0;
// const float SHAKE_LIMIT_G = 0.7;
// const float ACCEL_SCALE = 16384.0;
// int16_t accelX, accelY, accelZ, gyroX, gyroY, gyroZ;

// bool isQuestionActive = false;
// String mode = "";
// String answer = "";
// bool isPlaying = false;   
// uint8_t mp3buff[32];      

// // ==================================================
// // 4. إعدادات البلوتوث
// // ==================================================
// BLEServer *pServer = NULL;
// BLEService *pService = NULL;
// BLECharacteristic *pCommandCharacteristic = NULL;
// BLECharacteristic *pResponseCharacteristic = NULL;
// bool deviceConnected = false;

// #define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
// #define COMMAND_CHAR_UUID   "beb5483e-36e1-4688-b7f5-ea07361b26a8"
// #define RESPONSE_CHAR_UUID  "c3856242-4f7f-4a6c-b3d4-4a6e43f5a25c"

// // ==================================================
// // دوال المساعدة
// // ==================================================

// void sendBleResponse(String message) {
//   if (deviceConnected && pResponseCharacteristic) {
//     pResponseCharacteristic->setValue(message.c_str());
//     pResponseCharacteristic->notify();
//     Serial.print("BLE >> "); Serial.println(message);
//   }
// }

// void stopAudio() {
//   isPlaying = false;
//   if (client.connected()) {
//     client.stop();
//   }
//   Serial.println("Audio Stopped");
// }

// void parseUrl(String url, String &host, String &path, int &port) {
//   int index = url.indexOf("://");
//   String protocol = "http";
//   if (index != -1) {
//      protocol = url.substring(0, index);
//      url = url.substring(index + 3);
//   }
//   port = 80;
//   if (protocol == "https") port = 443; 

//   index = url.indexOf('/');
//   if (index != -1) {
//     host = url.substring(0, index);
//     path = url.substring(index);
//   } else {
//     host = url;
//     path = "/";
//   }
  
//   index = host.indexOf(':');
//   if(index != -1){
//      port = host.substring(index+1).toInt();
//      host = host.substring(0, index);
//   }
// }

// // دالة التشغيل (المحمية من الانهيار)
// void playFromUrl(String url) {
//   stopAudio(); 
  
//   String host, path;
//   int port;
//   parseUrl(url, host, path, port);

//   Serial.print("Connecting to: "); Serial.println(host);

//   // محاولة الاتصال مع تأخير بسيط
//   if (!client.connect(host.c_str(), port)) {
//     Serial.println("Connection Failed!");
//     sendBleResponse("ERROR:CONNECTION");
//     return;
//   }

//   client.print(String("GET ") + path + " HTTP/1.1\r\n" +
//                "Host: " + host + "\r\n" + 
//                "Connection: close\r\n\r\n");

//   // !! الحلقة الحرجة التي تسبب الانهيار !!
//   // تم تعديلها لتستخدم delay(5) بدلاً من yield() فقط
//   unsigned long timeout = millis();
//   while (client.connected()) {
    
//     // راحة اجبارية 5 مللي ثانية للسماح لـ BTC_TASK بالعمل
//     delay(5); 
    
//     if (client.available()) {
//         String line = client.readStringUntil('\n');
//         if (line == "\r") {
//           Serial.println("✓ Audio Start!");
//           isPlaying = true; 
//           sendBleResponse("AUDIO:PLAYING");
//           break;
//         }
//     }
    
//     if (millis() - timeout > 8000) { // زيادة وقت الانتظار
//       Serial.println("Timeout waiting for response");
//       client.stop();
//       return;
//     }
//   }
// }

// void processBleCommand(String command) {
//   command.trim();
//   Serial.print("CMD << "); Serial.println(command);

//   if (command.startsWith("PLAY:")) {
//     String url = command.substring(5);
//     url.trim();
//     playFromUrl(url);
//   }
//   else if (command == "TEST") {
//     playFromUrl("http://ice1.somafm.com/u80s-128-mp3");
//   }
//   else if (command == "STOP" || command == "STOP_AUDIO") {
//     stopAudio();
//     sendBleResponse("AUDIO:STOPPED");
//   }
//   else if (command.startsWith("START")) {
//     mode = command.substring(5);
//     mode.trim();
//     isQuestionActive = true;
//     answer = "";
//     sendBleResponse("READY:" + mode);
//   }
// }

// // ==================================================
// // دوال الحساسات والبلوتوث
// // ==================================================
// void detectShake() {
//   float acc_g = sqrt((float)accelX*accelX + (float)accelY*accelY + (float)accelZ*accelZ) / ACCEL_SCALE;
//   if (fabs(acc_g - 1.0) > SHAKE_LIMIT_G) {
//     answer = "SHAKE";
//     sendBleResponse("GESTURE:SHAKE");
//     isQuestionActive = false;
//   }
// }

// void detectY() {
//   float angleY = atan2(accelX, sqrt(accelY*accelY + accelZ*accelZ)) * 180.0 / PI;
//   if (angleY > LIMIT_DEG) {
//     answer = "FORWARD";
//     sendBleResponse("GESTURE:FORWARD");
//     isQuestionActive = false;
//   } else if (angleY < -LIMIT_DEG) {
//     answer = "BACK";
//     sendBleResponse("GESTURE:BACK");
//     isQuestionActive = false;
//   }
// }

// void detectZ() {
//   float angleZ = atan2(accelY, accelZ) * 180.0 / PI;
//   if (angleZ > LIMIT_DEG) {
//     answer = "RIGHT";
//     sendBleResponse("GESTURE:RIGHT");
//     isQuestionActive = false;
//   } else if (angleZ < -LIMIT_DEG) {
//     answer = "LEFT";
//     sendBleResponse("GESTURE:LEFT");
//     isQuestionActive = false;
//   }
// }

// class MyServerCallbacks: public BLEServerCallbacks {
//     void onConnect(BLEServer* pServer) {
//       deviceConnected = true;
//       Serial.println("BLE Device Connected");
//     }
//     void onDisconnect(BLEServer* pServer) {
//       deviceConnected = false;
//       BLEDevice::startAdvertising();
//       Serial.println("BLE Disconnected - Advertising");
//     }
// };

// class MyCommandCallbacks: public BLECharacteristicCallbacks {
//     void onWrite(BLECharacteristic *pCharacteristic) {
//       std::string value = pCharacteristic->getValue().c_str();
//       if (value.length() > 0) {
//         processBleCommand(String(value.c_str()));
//       }
//     }
// };

// // ==================================================
// // SETUP
// // ==================================================
// void setup() {
//   Serial.begin(115200);
//   delay(1000);

//   // 1. !! إعداد نظام الحماية Watchdog (الكود الجديد المتوافق مع v3.0+) !!
//   // نقوم بإيقاف المؤقت القديم أولاً ثم نعيد تهيئته بالإعدادات الجديدة (30 ثانية)
//   esp_task_wdt_deinit();
  
//   esp_task_wdt_config_t twdt_config = {
//       .timeout_ms = 30000,      // 30 ثانية
//       .idle_core_mask = (1 << 0), // مراقبة النواة 0 (التي كانت تسبب التعليق)
//       .trigger_panic = false,   // عدم عمل ريستارت فوري
//   };
//   esp_task_wdt_init(&twdt_config);
//   esp_task_wdt_add(NULL); // تسجيل هذه المهمة (loop) في نظام الحماية
  
//   setCpuFrequencyMhz(240);
//   Serial.println("\n╔════ CUBIE ANTI-CRASH v13.1 (Fixed) ════╗");

//   WiFi.setSleep(false); 
  
//   pinMode(SHUTDOWN_PIN, OUTPUT);
//   digitalWrite(SHUTDOWN_PIN, HIGH); 

//   SPI.begin(VS1053_SCK, VS1053_MISO, VS1053_MOSI);

//   Serial.print("Connecting WiFi");
//   WiFi.begin(ssid, password);
//   int retries = 0;
//   while (WiFi.status() != WL_CONNECTED && retries < 20) {
//     delay(500); Serial.print(".");
//     retries++;
//   }
//   if (WiFi.status() == WL_CONNECTED) {
//     Serial.println("\n✓ WiFi Connected");
//     Serial.print("  IP: "); Serial.println(WiFi.localIP());
//   } else {
//     Serial.println("\n✗ WiFi Failed!");
//   }

//   if (!musicPlayer.begin()) {
//      Serial.println("✗ VS1053 not found (Check Wiring)");
//   } else {
//      Serial.println("✓ VS1053 Ready");
//      musicPlayer.setVolume(10, 10); 
//      musicPlayer.sineTest(0x44, 100); 
//   }

//   Wire.begin(21, 22);
//   mpu.initialize();
//   if (mpu.testConnection()) Serial.println("✓ MPU6050 Ready");
//   else Serial.println("✗ MPU6050 Failed");

//   BLEDevice::init("CUBIE");
//   pServer = BLEDevice::createServer();
//   pServer->setCallbacks(new MyServerCallbacks());
  
//   pService = pServer->createService(SERVICE_UUID);
  
//   pCommandCharacteristic = pService->createCharacteristic(
//                              COMMAND_CHAR_UUID,
//                              BLECharacteristic::PROPERTY_WRITE
//                            );
//   pCommandCharacteristic->setCallbacks(new MyCommandCallbacks());

//   pResponseCharacteristic = pService->createCharacteristic(
//                               RESPONSE_CHAR_UUID,
//                               BLECharacteristic::PROPERTY_NOTIFY
//                             );
//   pResponseCharacteristic->addDescriptor(new BLE2902());
  
//   pService->start();
//   BLEDevice::startAdvertising();
//   Serial.println("✓ BLE Advertising");
//   Serial.println("╚════════════════════════════╝");
// }

// // ==================================================
// // LOOP
// // ==================================================
// void loop() {
  
//   // إعادة تعيين مؤقت الحماية في كل دورة (تطعيم الكلب حتى لا يعضنا)
//   esp_task_wdt_reset();

//   // معالجة الصوت
//   if (isPlaying) {
//     if (client.connected() && client.available() > 0) {
      
//       // نقل البيانات (بحد أقصى 2 كيلوبايت في المرة الواحدة)
//       int bytesProcessed = 0;
//       while (client.available() > 0 && musicPlayer.readyForData() && bytesProcessed < 2048) {
//         int bytes = client.read(mp3buff, 32);
//         musicPlayer.playData(mp3buff, bytes);
//         bytesProcessed += bytes;
//       }
      
//     } else {
//       if (!client.connected() && isPlaying) {
//         Serial.println("Stream Ended");
//         stopAudio();
//         sendBleResponse("AUDIO:FINISHED");
//       }
//     }
//   }

//   // معالجة الحساسات
//   if (isQuestionActive && answer == "") {
//     mpu.getMotion6(&accelX, &accelY, &accelZ, &gyroX, &gyroY, &gyroZ);
//     if (mode == "SHAKE") detectShake();
//     else if (mode == "TILTY") detectY();
//     else if (mode == "TILTZ") detectZ();
//   }

//   // تأخير مهم جداً لمنع تعليق البلوتوث
//   delay(5); 
// }



#include <Wire.h>
#include <MPU6050.h>
#include <WiFi.h>
#include <SPI.h>
#include <Adafruit_VS1053.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <esp_task_wdt.h>

// const char* ssid = "Salman_4G";
// const char* password = "0566339996";
const char* ssid = "HUAWEI_E5576_3656";
const char* password = "3GqA8bGYd3G";

#define VS1053_RESET   23     
#define VS1053_CS      5      
#define VS1053_DCS     2      
#define VS1053_DREQ    27     
#define VS1053_MOSI    14
#define VS1053_MISO    19
#define VS1053_SCK     18
#define SHUTDOWN_PIN   4 

Adafruit_VS1053 musicPlayer = Adafruit_VS1053(VS1053_RESET, VS1053_CS, VS1053_DCS, VS1053_DREQ);
WiFiClient client;
MPU6050 mpu(0x68);

const float LIMIT_DEG = 20.0;
const float SHAKE_LIMIT_G = 0.7;
const float ACCEL_SCALE = 16384.0;
int16_t accelX, accelY, accelZ, gyroX, gyroY, gyroZ;

bool isQuestionActive = false;
String mode = "";
String answer = "";
bool isPlaying = false;   
uint8_t mp3buff[32];      

BLEServer *pServer = NULL;
BLEService *pService = NULL;
BLECharacteristic *pCommandCharacteristic = NULL;
BLECharacteristic *pResponseCharacteristic = NULL;
bool deviceConnected = false;

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define COMMAND_CHAR_UUID   "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define RESPONSE_CHAR_UUID  "c3856242-4f7f-4a6c-b3d4-4a6e43f5a25c"

void sendBleResponse(String message) {
  if (deviceConnected && pResponseCharacteristic) {
    pResponseCharacteristic->setValue(message.c_str());
    pResponseCharacteristic->notify();
    Serial.print("BLE >> "); Serial.println(message);
  }
}

void stopAudio() {
  isPlaying = false;
  if (client.connected()) {
    client.stop();
  }
  Serial.println("Audio Stopped");
}

void parseUrl(String url, String &host, String &path, int &port) {
  int index = url.indexOf("://");
  String protocol = "http";
  if (index != -1) {
     protocol = url.substring(0, index);
     url = url.substring(index + 3);
  }
  port = 80;
  if (protocol == "https") port = 443; 

  index = url.indexOf('/');
  if (index != -1) {
    host = url.substring(0, index);
    path = url.substring(index);
  } else {
    host = url;
    path = "/";
  }
  
  index = host.indexOf(':');
  if(index != -1){
     port = host.substring(index+1).toInt();
     host = host.substring(0, index);
  }
}

void playFromUrl(String url) {
  stopAudio(); 
  
  String host, path;
  int port;
  parseUrl(url, host, path, port);

  Serial.print("Connecting to: "); Serial.println(host);

  if (!client.connect(host.c_str(), port)) {
    Serial.println("Connection Failed!");
    sendBleResponse("ERROR:CONNECTION");
    return;
  }

  client.print(String("GET ") + path + " HTTP/1.1\r\n" +
               "Host: " + host + "\r\n" + 
               "Connection: close\r\n\r\n");

  unsigned long timeout = millis();
  while (client.connected()) {
    delay(5); 
    
    if (client.available()) {
        String line = client.readStringUntil('\n');
        if (line == "\r") {
          Serial.println("✓ Audio Start!");
          isPlaying = true; 
          sendBleResponse("AUDIO:PLAYING");
          break;
        }
    }
    
    if (millis() - timeout > 8000) {
      Serial.println("Timeout waiting for response");
      client.stop();
      return;
    }
  }
}

void processBleCommand(String command) {
  command.trim();
  Serial.print("CMD << "); Serial.println(command);

  if (command.startsWith("PLAY:")) {
    String url = command.substring(5);
    url.trim();
    playFromUrl(url);
  }
  else if (command == "TEST") {
    playFromUrl("http://ice1.somafm.com/u80s-128-mp3");
  }
  else if (command == "STOP" || command == "STOP_AUDIO") {
    stopAudio();
    sendBleResponse("AUDIO:STOPPED");
  }
  else if (command.startsWith("START")) {
    mode = command.substring(5);
    mode.trim();
    isQuestionActive = true;
    answer = "";
    sendBleResponse("READY:" + mode);
  }
}

// !! --- التعديل الأساسي: دوال الحساس المحسّنة --- !!

void detectShake() {
  // حساب قوة الهز
  float acc_g = sqrt((float)accelX*accelX + (float)accelY*accelY + (float)accelZ*accelZ) / ACCEL_SCALE;
  
  // فقط إذا كان الهز قوياً بما يكفي
  if (fabs(acc_g - 1.0) > SHAKE_LIMIT_G) {
    answer = "SHAKE";
    sendBleResponse("GESTURE:SHAKE");
    isQuestionActive = false;
  }
}

void detectY() {
  // حساب زاوية الميل الأمامي/الخلفي
  float angleY = atan2(accelX, sqrt(accelY*accelY + accelZ*accelZ)) * 180.0 / PI;
  
  // ⚠️ تجاهل الميل الجانبي (Z) لضمان عدم الخلط
  float angleZ = atan2(accelY, accelZ) * 180.0 / PI;
  if (fabs(angleZ) > LIMIT_DEG) {
    // الطفل يميل جانبياً - تجاهل
    return;
  }
  
  // فقط إذا كان الميل واضحاً للأمام أو الخلف
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
  // حساب زاوية الميل الجانبي (يمين/يسار)
  float angleZ = atan2(accelY, accelZ) * 180.0 / PI;
  
  // ⚠️ تجاهل الميل الأمامي/الخلفي (Y) لضمان عدم الخلط
  float angleY = atan2(accelX, sqrt(accelY*accelY + accelZ*accelZ)) * 180.0 / PI;
  if (fabs(angleY) > LIMIT_DEG) {
    // الطفل يميل أمام/خلف - تجاهل
    return;
  }
  
  // فقط إذا كان الميل واضحاً لليمين أو اليسار
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

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("BLE Device Connected");
    }
    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      BLEDevice::startAdvertising();
      Serial.println("BLE Disconnected - Advertising");
    }
};

class MyCommandCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue().c_str();
      if (value.length() > 0) {
        processBleCommand(String(value.c_str()));
      }
    }
};

void setup() {
  Serial.begin(115200);
  delay(1000);

  esp_task_wdt_deinit();
  
  esp_task_wdt_config_t twdt_config = {
      .timeout_ms = 30000,
      .idle_core_mask = (1 << 0),
      .trigger_panic = false,
  };
  esp_task_wdt_init(&twdt_config);
  esp_task_wdt_add(NULL);
  
  setCpuFrequencyMhz(240);
  Serial.println("\n╔════ CUBIE ANTI-CRASH v13.2 (Fixed Gestures) ════╗");

  WiFi.setSleep(false); 
  
  pinMode(SHUTDOWN_PIN, OUTPUT);
  digitalWrite(SHUTDOWN_PIN, HIGH); 

  SPI.begin(VS1053_SCK, VS1053_MISO, VS1053_MOSI);

  Serial.print("Connecting WiFi");
  WiFi.begin(ssid, password);
  int retries = 0;
  while (WiFi.status() != WL_CONNECTED && retries < 20) {
    delay(500); Serial.print(".");
    retries++;
  }
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✓ WiFi Connected");
    Serial.print("  IP: "); Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n✗ WiFi Failed!");
  }

  if (!musicPlayer.begin()) {
     Serial.println("✗ VS1053 not found (Check Wiring)");
  } else {
     Serial.println("✓ VS1053 Ready");
     musicPlayer.setVolume(10, 10); 
     musicPlayer.sineTest(0x44, 100); 
  }

  Wire.begin(21, 22);
  mpu.initialize();
  if (mpu.testConnection()) Serial.println("✓ MPU6050 Ready");
  else Serial.println("✗ MPU6050 Failed");

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
  Serial.println("✓ BLE Advertising");
  Serial.println("╚════════════════════════════╝");
}

void loop() {
  esp_task_wdt_reset();

  if (isPlaying) {
    if (client.connected() && client.available() > 0) {
      int bytesProcessed = 0;
      while (client.available() > 0 && musicPlayer.readyForData() && bytesProcessed < 2048) {
        int bytes = client.read(mp3buff, 32);
        musicPlayer.playData(mp3buff, bytes);
        bytesProcessed += bytes;
      }
    } else {
      if (!client.connected() && isPlaying) {
        Serial.println("Stream Ended");
        stopAudio();
        sendBleResponse("AUDIO:FINISHED");
      }
    }
  }

  // !! --- معالجة الحساسات مع التحقق الصارم --- !!
  if (isQuestionActive && answer == "") {
    mpu.getMotion6(&accelX, &accelY, &accelZ, &gyroX, &gyroY, &gyroZ);
    
    // تنفيذ الحركة المطلوبة فقط
    if (mode == "SHAKE") {
      detectShake();
    }
    else if (mode == "TILTY") {
      detectY(); // أمام/خلف فقط
    }
    else if (mode == "TILTZ") {
      detectZ(); // يمين/يسار فقط
    }
  }

  delay(5); 
}


// #include <SPI.h>
// #include <Adafruit_VS1053.h>
// #include <WiFi.h>

// // ==========================================
// // 1. إعدادات الواي فاي
// // ==========================================
// const char* ssid = "Salman_4G";
// const char* password = "0566339996";

// // ==========================================
// // 2. إعدادات الأسلاك (توصيلك الخاص)
// // ==========================================
// #define VS1053_RESET   23     
// #define VS1053_CS      5      
// #define VS1053_DCS     2      
// #define VS1053_DREQ    27     
// #define VS1053_MOSI    14
// #define VS1053_MISO    19
// #define VS1053_SCK     18

// Adafruit_VS1053 musicPlayer = Adafruit_VS1053(VS1053_RESET, VS1053_CS, VS1053_DCS, VS1053_DREQ);
// WiFiClient client;

// // رابط البث
// const char* host = "ice1.somafm.com";
// const char* path = "/u80s-128-mp3";
// int port = 80;

// void setup() {
//   Serial.begin(115200);
//   delay(1000);
  
//   // أقصى سرعة للمعالج
//   setCpuFrequencyMhz(240);

//   Serial.println("\n\n╔════ MAX THROUGHPUT v11 ════╗");

//   // 1. منع الواي فاي من النوم نهائياً (أهم سطر للتقطيع)
//   WiFi.setSleep(false); 

//   // 2. إعداد SPI
//   SPI.begin(VS1053_SCK, VS1053_MISO, VS1053_MOSI);

//   // 3. الاتصال بالواي فاي
//   Serial.print("Connecting WiFi");
//   WiFi.begin(ssid, password);
//   while (WiFi.status() != WL_CONNECTED) {
//     delay(500); Serial.print(".");
//   }
//   Serial.println("\n✓ Connected!");

//   // 4. تشغيل القطعة
//   if (!musicPlayer.begin()) { 
//      Serial.println("✗ VS1053 not found");
//      while (1) delay(10);
//   }
//   Serial.println("✓ VS1053 Found!");
  
//   // رفع الصوت لأقصى حد
//   musicPlayer.setVolume(1, 1); // 1 هو أعلى شيء تقريباً
  
//   connectAndPlay();
// }

// void connectAndPlay() {
//     if (client.connected()) client.stop();

//     Serial.print("Connecting to stream...");
//     if (!client.connect(host, port)) {
//       Serial.println("Failed!");
//       return;
//     }
//     Serial.println("Done!");

//     client.print(String("GET ") + path + " HTTP/1.1\r\n" +
//                  "Host: " + host + "\r\n" + 
//                  "Connection: close\r\n\r\n");

//     // تخطي الهيدر
//     unsigned long timeout = millis();
//     while (client.connected()) {
//       String line = client.readStringUntil('\n');
//       if (line == "\r") {
//         Serial.println("✓ Headers Skipped - Audio Start!");
//         break;
//       }
//       if (millis() - timeout > 5000) return;
//     }
// }

// // نستخدم بفر 32 بايت، لكن الطريقة في اللوب هي التي ستتغير
// uint8_t mp3buff[32];

// void loop() {
//   // الشرط: طالما النت متصل + وهناك بيانات قادمة
//   if (client.connected() && client.available() > 0) {
      
//       // !! الاستراتيجية الجديدة: Feed the Beast !!
//       // طالما قطعة الصوت جاهزة لاستقبال المزيد (readyForData)
//       // سنقوم بحشوها بالبيانات فوراً دون انتظار دورة اللوب القادمة
      
//       while (client.available() > 0 && musicPlayer.readyForData()) {
//           // قراءة كمية صغيرة تناسب سرعة النقل
//           int bytes = client.read(mp3buff, 32);
          
//           // إرسال فوري
//           musicPlayer.playData(mp3buff, bytes);
//       }
//   }
  
//   // إعادة الاتصال السريع إذا انقطع
//   if (!client.connected() && WiFi.status() == WL_CONNECTED) {
//       Serial.println("Stream dropped, reconnecting...");
//       connectAndPlay();
//   }
// }

