#include <Arduino.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <DHT.h>

#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

#define led_pin 2
#define dht_pin 4
#define ir_pin 18
#define DHTTYPE DHT11

#define DATABASE_URL "your database url" 
#define DATABASE_SECRET "your database secret" 

const char* ssid = "who";
const char* password = "Z1234567890";

DHT dht(dht_pin, DHTTYPE);  

FirebaseData fbdo;        // For sending (setJSON)
FirebaseData streamData;  // For receiving (Stream)
FirebaseAuth auth;
FirebaseConfig config;

unsigned long sendDataPrevMillis = 0;
bool remoteLedStatus = false;

// Function that runs when you toggle the switch in Flutter
void streamCallback(FirebaseStream data) {
  Serial.printf("Stream update - Path: %s, Type: %s\n", data.dataPath().c_str(), data.dataType().c_str());
  
  String path = data.dataPath();
  
  if (path == "/led_manual" || path == "led_manual") {
    remoteLedStatus = data.boolData();
    Serial.printf("Cloud Command: LED is now %s\n", remoteLedStatus ? "ON" : "OFF");
  }
  else if (path == "/" && data.dataType() == "json") {
    FirebaseJson &json = data.jsonObject();
    FirebaseJsonData result;
    if (json.get(result, "led_manual")) {
      bool newStatus = result.boolValue;
      if (newStatus != remoteLedStatus) {
        remoteLedStatus = newStatus;
        Serial.printf("Cloud Command (from full update): LED is now %s\n", remoteLedStatus ? "ON" : "OFF");
      }
    }
  }
}

void streamTimeoutCallback(bool timeout) {
  if (timeout) Serial.println("Stream timeout, resuming...");
}

void setup() {
  Serial.begin(115200);
  
  pinMode(led_pin, OUTPUT);
  pinMode(BUILTIN_LED, OUTPUT);
  pinMode(ir_pin, INPUT);
  
  dht.begin();

  WiFi.begin(ssid, password);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println("\nConnected with IP: ");
  Serial.println(WiFi.localIP());

  config.database_url = DATABASE_URL;
  config.signer.tokens.legacy_token = DATABASE_SECRET;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  // Increase buffer for SSL stability
  fbdo.setResponseSize(2048);
  streamData.setResponseSize(2048);

  // Start the Stream on the dedicated 'streamData' object
  if (!Firebase.RTDB.beginStream(&streamData, "/sensor_data")) {
    Serial.println("Stream Error: ");
    Serial.println(streamData.errorReason());
  }

  Firebase.RTDB.setStreamCallback(&streamData, streamCallback, streamTimeoutCallback);
}

void loop() {
  bool presence = (digitalRead(ir_pin) == LOW);
  
  //Manual Remote Switch OR IR Sensor
  if (remoteLedStatus || presence) {
    digitalWrite(led_pin, HIGH);
    digitalWrite(BUILTIN_LED, HIGH);
  } else {
    digitalWrite(led_pin, LOW);
    digitalWrite(BUILTIN_LED, LOW);
  }

  // Cloud upload
  if (Firebase.ready() && (millis() - sendDataPrevMillis > 3000 || sendDataPrevMillis == 0)) {
    sendDataPrevMillis = millis();

    float h = dht.readHumidity();
    float t = dht.readTemperature();

    if (isnan(h) || isnan(t)) {
      Serial.println("DHT Sensor Error");
    } else {
      FirebaseJson json;
      json.set("temperature", t);
      json.set("humidity", h);
      json.set("presence", presence);
      json.set("timestamp", millis() / 1000);

      if (Firebase.RTDB.updateNode(&fbdo, "/sensor_data", &json)) {
        Serial.println("Data Pushed to Cloud");
      } else {
        Serial.println("Push Failed: ");
        Serial.println(fbdo.errorReason());
      }
    }
  }
}