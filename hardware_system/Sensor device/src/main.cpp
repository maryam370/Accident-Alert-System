#include <MPU6050_light.h>
#include <Wire.h>
#include <WiFi.h>
#include <WebServer.h>
#include <WiFiManager.h>
#include "esp_wifi.h"

MPU6050 mpu(Wire);
const int LED_PIN = 2;

WebServer server(80);
WiFiManager wm;

float roll, pitch, accelTotal;
int accidentFlag = 0;
int isMonitoring = 0;  // 0 = disabled, 1 = enabled
bool mpuActive = false;

void connectToWiFi() {
  Serial.println("📡 Starting WiFi Manager...");
  wm.setConfigPortalBlocking(false);

  if (!wm.getWiFiIsSaved()) {
    Serial.println("❌ No saved WiFi. Starting setup portal...");
    wm.setConfigPortalBlocking(true);
    bool res = wm.autoConnect("ESP32_Setup");

    if (!res) {
      Serial.println("❌ Setup failed or timeout.");
      ESP.restart();
    }
  } else {
    WiFi.begin();
    Serial.println("🔁 Connecting to saved WiFi...");
    while (WiFi.status() != WL_CONNECTED) {
      digitalWrite(LED_PIN, LOW);
      Serial.print(".");
      vTaskDelay(pdMS_TO_TICKS(1000));
      digitalWrite(LED_PIN, HIGH);
      vTaskDelay(pdMS_TO_TICKS(50));
    }

    if (WiFi.status() == WL_CONNECTED) {
      Serial.println("\n✅ Connected!");
      Serial.print("IP: ");
      Serial.println(WiFi.localIP());
    } else {
      Serial.println("\n❌ Could not connect. Will retry silently or reboot.");
    }
  }
}

void setup() {
  Serial.begin(115200);
  Wire.begin();
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  esp_wifi_set_ps(WIFI_PS_MIN_MODEM);
  WiFi.mode(WIFI_STA);
  connectToWiFi();

  server.on("/data", HTTP_GET, []() {
    String json = "{";
    json += "\"roll\":" + String(roll, 2) + ",";
    json += "\"pitch\":" + String(pitch, 2) + ",";
    json += "\"accelTotal\":" + String(accelTotal, 2) + ",";
    json += "\"flag\":" + String(accidentFlag) + ",";
    json += "\"isMonitoring\":" + String(isMonitoring);
    json += "}";
    server.send(200, "application/json", json);
  });

  server.on("/update", HTTP_POST, []() {
    if (server.hasArg("flag")) {
      accidentFlag = server.arg("flag").toInt();
      Serial.println("⚙️ accidentFlag updated: " + String(accidentFlag));
    }
    if (server.hasArg("isMonitoring")) {
      isMonitoring = server.arg("isMonitoring").toInt();
      Serial.println("📲 isMonitoring updated: " + String(isMonitoring));
    }
    server.send(200, "text/plain", "Parameters updated");
  });

  server.on("/reset_wifi", HTTP_GET, []() {
    server.send(200, "text/plain", "Resetting WiFi settings and restarting...");
    delay(1000);
    wm.resetSettings();
    ESP.restart();
  });

  server.onNotFound([]() {
    server.send(404, "text/plain", "404 Not Found");
  });

  server.begin();
}

void loop() {
  server.handleClient();

  if (WiFi.status() != WL_CONNECTED) {
    if (mpuActive) {
      Serial.println("📴 Lost WiFi. Stopping MPU readings.");
      mpuActive = false;
    }

    vTaskDelay(pdMS_TO_TICKS(2000));
    ESP.restart();
    return;
  }

  if (!mpuActive) {
    Serial.println("🔌 Initializing MPU6050...");
    byte status = mpu.begin();
    if (status != 0) {
      Serial.println("MPU error: " + String(status));
      while (1);
    }
    vTaskDelay(pdMS_TO_TICKS(1000));
    mpu.calcOffsets(true, true);
    Serial.println("✅ MPU6500 ready.");
    mpuActive = true;
    digitalWrite(LED_PIN, LOW);
  }

  if (accidentFlag == 1 || isMonitoring == 0) {
    return;  // Stop sensing if frozen or disabled by app
  }

  mpu.update();

  float accelX = mpu.getAccX();
  float accelY = mpu.getAccY();
  float accelZ = mpu.getAccZ();

  roll = atan2(accelY, accelZ) * 180 / PI;
  pitch = atan2(-accelX, sqrt(accelY * accelY + accelZ * accelZ)) * 180 / PI;
  accelTotal = sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ);

  Serial.print("Roll: ");
  Serial.print(roll, 2);
  Serial.print(" | Pitch: ");
  Serial.print(pitch, 2);
  Serial.print(" | AccelTotal: ");
  Serial.println(accelTotal, 2);

  if (abs(roll) > 45 || abs(pitch) > 45 || accelTotal > 2.5) {
    digitalWrite(LED_PIN, HIGH);
    accidentFlag = 1;
    isMonitoring = 0;
    Serial.println("⚠️ Abnormality detected!");
  }

  vTaskDelay(pdMS_TO_TICKS(200));
}
