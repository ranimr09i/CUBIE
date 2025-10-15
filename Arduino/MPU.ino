
// #include <Wire.h>
// #include <MPU6050.h>
// #include "AudioGeneratorMP3.h"
// #include "AudioOutputI2S.h"
// #include "AudioFileSourceSPIFFS.h"
// #include "SPIFFS.h"


// #define RXD2 16
// #define TXD2 17

// // استخدم Serial2 بدال SoftwareSerial
// #define BTSerial Serial2
// HardwareSerial BTSerial(1);


// #define I2S_DOUT 25
// #define I2S_BCLK 27
// #define I2S_LRC  26


// AudioGeneratorMP3 *mp3 = nullptr;
// AudioFileSourceSPIFFS *file = nullptr;
// AudioOutputI2S *out = nullptr;

// bool isAudioPlaying = false;
// String currentAudioFile = "";
// // هاذا هو السنسر بس كامعرف بسيط نستخدمه بدل مانجلس نكتب 
// MPU6050 mpu(0x68);

// // هاذا الي هو الحد للدوران لو الجهاز دار بهاذا القدر فهو يرصد ويتحدد باي جهه
// //يمدي نغيره لو نبي لفه بسيطه او لا 
// const float LIMIT_DEG = 20.0;

// //  هاذا التسارع للهز فايدته انه بس ستخذمه انه يحول البيانات الي جايه من السنسر لوحد 
// //g الجادبيه
// const float ACCEL_SCALE = 16384.0;
// //جاذبيه اذا قللته كل ماكان حساس للهزات 
// const float SHAKE_LIMIT_G = 0.7;

// // هاذا يشوف اذا فيه سوال او لا عشان يبدا يشتغل 
// bool isQuestionActive = false;

// //هاذا المود اذا هو يمين ويسار او ورا وقدام او شيك 
// String mode = "";

// //الجواب يتسجل في الانسر حتى بعدين نستخدمه في البرمت بس للحين ينطبع 
// String answer = "";


// //  // متغيرات لحفظ القيم من السنسر هي فقط لتوضيع ولما اخذها من السنسر 
// //  //بخزنها في هاذي المتغيرات عشان بعدين اقدر اني اقارن فيها واعرف الحركه 
// int16_t accelX, accelY, accelZ; // تسراعه
// int16_t gyroX, gyroY, gyroZ; // جيروسكوب

// void handleBluetoothCommands() {
//   if (BTSerial.available()) {
//     String command = BTSerial.readStringUntil('\n');
//     command.trim();
    
//     if (command.startsWith("PLAY:")) {
//       String audioFile = command.substring(5);
//       playAudioFile(audioFile);
//     }
//     else if (command == "STOP_AUDIO") {
//       stopAudio();
//     }
//     else if (command.startsWith("STORY:")) {
//       String storyText = command.substring(6);
//       Serial.println("📖 القصة المستلمة: " + storyText);
//     }
//   }
// }

// void playFile(const char* filename) {
//   if (mp3 && mp3->isRunning()) {
//     mp3->stop();
//     delete mp3;
//     delete file;
//   }
  
//   file = new AudioFileSourceSPIFFS(filename.c_str());
//   out = new AudioOutputI2S();
//   out->begin();
//   mp3 = new AudioGeneratorMP3();
//   mp3->begin(file, out);
  
//   isAudioPlaying = true;
//   currentAudioFile = filename;
  
//   BTSerial.println("AUDIO:PLAYING:" + filename);
// }

// void stopAudio() {
//   if (mp3 && mp3->isRunning()) {
//     mp3->stop();
//     isAudioPlaying = false;
//     currentAudioFile = "";
//     BTSerial.println("AUDIO:STOPPED");
//   }
// }

// void setup() {
//   //هاذا للعدادات مو مهمه الصدق
//   BTSerial.begin(9600, SERIAL_8N1, RXD2, TXD2);
//   Serial.begin(115200);
//   Wire.begin(21,22);
//   //نشغل السنسر ونختبر الاتصال اذا هو شابك او لا
//   mpu.initialize();
//   if (mpu.testConnection()) {
//     Serial.println("MPU6050 جاهز ✔️");
//   } else {
//     Serial.println("فشل الاتصال ✖️");
//   }

//   if (!SPIFFS.begin(true)) {
//     Serial.println("SPIFFS mount failed!");
//     return;
//   }
//     Serial.println("System Ready. Use START <MODE>");


// }

// void loop() {
//   handleBluetoothCommands();
//   handleSerialCommands();

//   // اذا مافي سوال ولا الجواب فاضي فهاذا يعني مانحتاج السنسر فااطلع 
//   if (!isQuestionActive || answer.length() > 0) {
//     return;
//     }

//   //هاذا يقرا من السنسر  هي تراها مثد جت جاهزه من الايبري حقت كات
//   mpu.getMotion6(&accelX, &accelY, &accelZ, &gyroX, &gyroY, &gyroZ);

//   // شفتو المود هينا يتحدد لو السوال فيه هز هز او يمين يسار ياو او قدام ورا بيتش
//   if (mode == "SHAKE") {
//     detectShake();
//     }
//   else if (mode == "TILTY") {
//     detectY(); //detectPitch();
//     }
//   else if (mode == "TILTZ") {
//     detectZ();
//     }
//     if (mp3 && mp3->isRunning()) {
//       mp3->loop();
//     }

// }


// void handleSerialCommands() {
//   if (Serial.available() == 0) {
//     return;
//   }
//   //رح ياخذ انبت مني اذا ابي ابدا يحسب الاللف واسوي ليست للجواب وكيذا 
//   String cmd = Serial.readStringUntil('\n');
//   cmd.trim();
//   cmd.toUpperCase();

//   if (cmd.startsWith("START")) {
//     mode = cmd.substring(6); // يأخذ tiltZ/tiltY/SHAKE منها يحدد اذا السوال قال يمين ويسار او قدام ورا او هز 
//     isQuestionActive = true; // اول ماسوي ستارت هاذا يعني فيه سوال صح؟ ايه 
//     answer = ""; // هينا يتخزن جوابي 
//     Serial.print("READY: ");
//     Serial.println(mode);
//   } 
//   else if (cmd == "GET") {
//     // لو ابي ارجع وش جوابي كان 
//     Serial.print("ANSWER: ");
//     Serial.println(answer.length() ? answer : "NONE");
//   } 
//   else if (cmd == "RESTART") {
//     // ريستارت يحذف الجواب حقي ويبدا سوال جديد
//     answer = "";
//     isQuestionActive = false;
//     mode = "";
//     Serial.println("ANSWER is reset");
//   }
// }
// void detectShake() {
//   //اول شي للهز نحسب التسارع في كل الاتجاهات 
//   //لو قيمه التسارع هاذي تساوي ١ج فهاذا يعني الجهاز ثابت ماهو جالس ينهز
//   float acc_g = sqrt((float)accelX*accelX + (float)accelY*accelY + (float)accelZ*accelZ) / ACCEL_SCALE;
//   //هينا نقارن القيمه حقت التسارع في كل الاتجاهات اكبر من الحد الي حنا حددنا فاهو جالس ينهز
//   if (fabs(acc_g - 1.0) > SHAKE_LIMIT_G) {
//     answer = "SHAKE";
//     BTSerial.println(answer);
//     Serial.println(acc_g);
//     Serial.println("ANSWER: SHAKE");
//     speakBeep();
//     playFile("/shake.mp3");
//     isQuestionActive = false;
//   }
// }


// void detectY() {
//     // زاوية الميل حول المحور y (Pitch)
//     //يعني قدام او ورا
//     float angleY = atan2(accelX, sqrt(accelY*accelY + accelZ*accelZ)) * 180.0 / PI;
//     //هالقيمه نقارنها بالليمت الي حطيناها نقدرت نغيرها لو نبيه للفه بسيطه او لا
//     //يوضح ترا برسم بياني 
//     if (angleY > LIMIT_DEG) {
//         answer = "FORWARD";
//         BTSerial.println(answer);
//         Serial.println("ANSWER: FORWARD");
//         Serial.println(angleY);
//         playFile("/forward.mp3");
//         isQuestionActive = false;
//     } else if (angleY < -LIMIT_DEG) {
//         answer = "BACK";
//         BTSerial.println(answer);
//         Serial.println("ANSWER: BACK");
//         Serial.println( angleY);
//         playFile("/back.mp3");
//         isQuestionActive = false;
//     }
// }

// void detectZ() {
//     // زاوية الميل حول المحور Z (Roll)
//     float angleZ = atan2(accelY, accelZ) * 180.0 / PI;
//     //لو الزاويه اكبر من الحد في الموجب فهو يمين 
//     if (angleZ > LIMIT_DEG) {
//         answer = "RIGHT";
//         BTSerial.println(answer);
//         Serial.println("ANSWER: RIGHT");
//         Serial.println(angleZ);
//         playFile("/right.mp3");
//         isQuestionActive = false;
//     } else if (angleZ < -LIMIT_DEG) {
//         // لو الزاويه اكبر من الحد في السالب فهو يسار
//         answer = "LEFT";
//         Serial.println("ANSWER: LEFT");
//         BTSerial.println(answer);
//         Serial.println(angleZ);
//         playFile("/left.mp3");
//         isQuestionActive = false;
//     }
// }


#include <Wire.h>
#include <MPU6050.h>
#include "AudioGeneratorMP3.h"
#include "AudioOutputI2S.h"
#include "AudioFileSourceHTTPStream.h"
#include <HardwareSerial.h>

// ==== Bluetooth UART1 ====
#define RXD2 16
#define TXD2 17
HardwareSerial BTSerial(1);

// ==== I2S audio pins ====
#define I2S_DOUT 25
#define I2S_BCLK 27
#define I2S_LRC  26

// ==== Audio objects ====
AudioGeneratorMP3 *mp3 = nullptr;
AudioFileSourceHTTPStream *file = nullptr;
AudioOutputI2S *out = nullptr;

// ==== MPU6050 ====
MPU6050 mpu(0x68);

// ==== Movement detection ====
const float LIMIT_DEG = 20.0;
const float SHAKE_LIMIT_G = 0.7;
const float ACCEL_SCALE = 16384.0;

bool isQuestionActive = false;
String mode = "";
String answer = "";

int16_t accelX, accelY, accelZ;
int16_t gyroX, gyroY, gyroZ;

// ------------------------------------
// Play MP3 from URL
// ------------------------------------
void playFile(String url) {
  if (mp3 && mp3->isRunning()) {
    mp3->stop();
    delete mp3;
    delete file;
  }

  file = new AudioFileSourceHTTPStream(url.c_str());
  out = new AudioOutputI2S();
  out->SetPinout(I2S_BCLK, I2S_LRC, I2S_DOUT);
  out->SetGain(0.5);
  out->begin();

  mp3 = new AudioGeneratorMP3();
  mp3->begin(file, out);

  BTSerial.println("AUDIO:PLAYING:" + url);
  Serial.println("AUDIO:PLAYING:" + url);
}

// ------------------------------------
// Stop audio
// ------------------------------------
void stopAudio() {
  if (mp3 && mp3->isRunning()) {
    mp3->stop();
    BTSerial.println("AUDIO:STOPPED");
    Serial.println("AUDIO:STOPPED");
  }
}

// ------------------------------------
// Handle Bluetooth commands
// ------------------------------------
void handleBluetoothCommands() {
  while (BTSerial.available()) {
    String command = BTSerial.readStringUntil('\n');
    command.trim();

    if (command.startsWith("PLAY:")) {
      String url = command.substring(5);
      playFile(url);
    } 
    else if (command == "STOP_AUDIO") {
      stopAudio();
    }
    else if (command.startsWith("START")) {
      mode = command.substring(5);
      isQuestionActive = true;
      answer = "";
      BTSerial.println("READY:" + mode);
    }
    else if (command == "GET") {
      BTSerial.println("ANSWER:" + answer);
    }
    else if (command == "RESTART") {
      answer = "";
      isQuestionActive = false;
      mode = "";
      BTSerial.println("RESET_DONE");
    }
  }
}
void handleCommands() {
  while (Serial.available()) {
    String command = Serial.readStringUntil('\n');
    command.trim();

    if (command.startsWith("PLAY:")) {
      String url = command.substring(5);
      playFile(url);
    } 
    else if (command == "STOP_AUDIO") {
      stopAudio();
    }
    else if (command.startsWith("START")) {
      mode = command.substring(5);
      isQuestionActive = true;
      answer = "";
      Serial.println("READY:" + mode);
    }
    else if (command == "GET") {
      Serial.println("ANSWER:" + answer);
    }
    else if (command == "RESTART") {
      answer = "";
      isQuestionActive = false;
      mode = "";
      Serial.println("RESET_DONE");
    }
  }
}

// ------------------------------------
// Movement detection
// ------------------------------------
void detectShake() {
  float acc_g = sqrt((float)accelX*accelX + (float)accelY*accelY + (float)accelZ*accelZ) / ACCEL_SCALE;
  
  if (fabs(acc_g - 1.0) > SHAKE_LIMIT_G) {
    answer = "SHAKE";
    Serial.println(answer);
    BTSerial.println(answer);
    isQuestionActive = false;
  }
}

void detectY() {
  float angleY = atan2(accelX, sqrt(accelY*accelY + accelZ*accelZ)) * 180.0 / PI;
  
  if (angleY > LIMIT_DEG) {
    answer = "FORWARD";
    Serial.println(answer);
    BTSerial.println(answer);
    isQuestionActive = false;
  } else if (angleY < -LIMIT_DEG) {
    answer = "BACK";
    Serial.println(answer);
    BTSerial.println(answer);
    isQuestionActive = false;
  }
}

void detectZ() {
  float angleZ = atan2(accelY, accelZ) * 180.0 / PI;
  
  if (angleZ > LIMIT_DEG) {
    answer = "RIGHT";
    Serial.println(answer);
    BTSerial.println(answer);
    isQuestionActive = false;
  } else if (angleZ < -LIMIT_DEG) {
    answer = "LEFT";
    Serial.println(answer);
    BTSerial.println(answer);
    isQuestionActive = false;
  }
}

// ------------------------------------
// Setup
// ------------------------------------
void setup() {
  Serial.begin(115200);
  BTSerial.begin(9600, SERIAL_8N1, RXD2, TXD2);
  Wire.begin(21, 22);
  mpu.initialize();
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

  if (mp3 && mp3->isRunning()) {
    if (!mp3->loop()) {
      mp3->stop();
      Serial.println("AUDIO:FINISHED");
      BTSerial.println("AUDIO:FINISHED");
    }
  }

  delay(50);
}
