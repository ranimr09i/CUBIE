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


// const char* ssid = "HUAWEI_E5576_3656";
// const char* password = "3GqA8bGYd3G";
const char* ssid = "Salman_4G";
const char* password = "0566339996";


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


const float LIMIT_DEG = 40.0;
const float SHAKE_LIMIT_G = 1.2;
const float MIN_THRESHOLD = 15.0;

const float ACCEL_SCALE = 16384.0;
int16_t accelX, accelY, accelZ, gyroX, gyroY, gyroZ;

bool isQuestionActive = false;
String mode = "";
String answer = "";

bool isPlaying = false;
bool isPaused = false;
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
  isPaused = false;
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
          isPaused = false;
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
  else if (command == "PAUSE") {
    if (isPlaying) {
      isPaused = true;
      Serial.println("Audio Paused");
    }
  }
  else if (command == "RESUME") {
    if (isPlaying && isPaused) {
      isPaused = false;
      Serial.println("Audio Resumed");
    }
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

void playSensorBeep() {
  musicPlayer.sineTest(0x44, 40); 
  musicPlayer.sineTest(0x47, 40); 
  musicPlayer.sineTest(0x4B, 40); 
  musicPlayer.sineTest(0x50, 150);
}


void detectShake() {
  playSensorBeep();
  float acc_g = sqrt((float)accelX*accelX + (float)accelY*accelY + (float)accelZ*accelZ) / ACCEL_SCALE;
  if (fabs(acc_g - 1.0) > SHAKE_LIMIT_G) {
    answer = "SHAKE";
    sendBleResponse("GESTURE:SHAKE");
    isQuestionActive = false;
    Serial.println("SHAKE detected!");
  }
}

void detectY() {
  float angleY = atan2(accelX, sqrt(accelY*accelY + accelZ*accelZ)) * 180.0 / PI;
  float angleZ = atan2(accelY, accelZ) * 180.0 / PI;
  

  if (fabs(angleZ) > MIN_THRESHOLD) {
    Serial.println("Ignoring: Side tilt detected");
    return;
  }
  

  if (fabs(angleY) < MIN_THRESHOLD) {
    return;
  }
  

  if (angleY > LIMIT_DEG) {
    playSensorBeep();
    answer = "FORWARD";
    sendBleResponse("GESTURE:FORWARD");
    isQuestionActive = false;
    Serial.print("FORWARD detected! angleY="); Serial.println(angleY);
  } else if (angleY < -LIMIT_DEG) {
    playSensorBeep();
    answer = "BACK";
    sendBleResponse("GESTURE:BACK");
    isQuestionActive = false;
    Serial.print("BACK detected! angleY="); Serial.println(angleY);
  }
}

void detectZ() {
  float angleZ = atan2(accelY, accelZ) * 180.0 / PI;
  float angleY = atan2(accelX, sqrt(accelY*accelY + accelZ*accelZ)) * 180.0 / PI;
  

  if (fabs(angleY) > MIN_THRESHOLD) {
    Serial.println("Ignoring: Front/Back tilt detected");
    return;
  }
  

  if (fabs(angleZ) < MIN_THRESHOLD) {
    return;
  }


  if (angleZ > LIMIT_DEG) {
    playSensorBeep();
    answer = "RIGHT";
    sendBleResponse("GESTURE:RIGHT");
    isQuestionActive = false;
    Serial.print("RIGHT detected! angleZ="); Serial.println(angleZ);
  } else if (angleZ < -LIMIT_DEG) {
    playSensorBeep();
    answer = "LEFT";
    sendBleResponse("GESTURE:LEFT");
    isQuestionActive = false;
    Serial.print("LEFT detected! angleZ="); Serial.println(angleZ);
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
  Serial.println("\n╔════ CUBIE (Fixed Tilt Detection) ════╗");
  Serial.println("  LIMIT_DEG: 40° (stronger tilt needed)");
  Serial.println("  MIN_THRESHOLD: 15° (ignore small moves)");
  Serial.println("╚══════════════════════════════════════╝");

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
     musicPlayer.setVolume(0, 0); 
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
  pCommandCharacteristic = pService->createCharacteristic(COMMAND_CHAR_UUID, BLECharacteristic::PROPERTY_WRITE);
  pCommandCharacteristic->setCallbacks(new MyCommandCallbacks());
  pResponseCharacteristic = pService->createCharacteristic(RESPONSE_CHAR_UUID, BLECharacteristic::PROPERTY_NOTIFY);
  pResponseCharacteristic->addDescriptor(new BLE2902());
  pService->start();
  BLEDevice::startAdvertising();
  Serial.println("✓ BLE Advertising");
}

void loop() {
  esp_task_wdt_reset();
  
  if (isPlaying) {
    if (client.connected()) {
      if (client.available() > 0) {
        if (!isPaused) {
          int bytesProcessed = 0;
          while (client.available() > 0 && musicPlayer.readyForData() && bytesProcessed < 1024) {
            int bytes = client.read(mp3buff, 32);
            musicPlayer.playData(mp3buff, bytes);
            bytesProcessed += bytes;
          }
        } else {
           delay(10); 
        }
      }
    } else {
      if (isPlaying && !isPaused) {
         Serial.println("Stream Ended");
         stopAudio();
         sendBleResponse("AUDIO:FINISHED");
      }
    }
  }

  if (isQuestionActive && answer == "") {
    mpu.getMotion6(&accelX, &accelY, &accelZ, &gyroX, &gyroY, &gyroZ);
    if (mode == "SHAKE") detectShake();
    else if (mode == "TILTY") detectY();
    else if (mode == "TILTZ") detectZ();
  }

  delay(5);
}