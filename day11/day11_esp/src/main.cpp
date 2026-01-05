#include <Arduino.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <DHT.h>

// Provide the token generation process info.
#include "addons/TokenHelper.h"
// Provide the RTDB payload printing info.
#include "addons/RTDBHelper.h"

#define led_pin 2
#define dht_pin 4
#define ir_pin 5
#define DHTTYPE DHT11

#define DATABASE_URL "YOUR_FIREBASE_DATABASE_URL" 
#define DATABASE_SECRET "YOUR_FIREBASE_DATABASE_SECRET" 

const char* ssid = "who";
const char* password = "Z1234567890";

DHT dht(dht_pin, DHTTYPE);
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long sendDataPrevMillis = 0;
bool signupOK = false;

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
  Serial.println();
  Serial.print("Connected with IP: ");
  Serial.println(WiFi.localIP());

  config.database_url = DATABASE_URL;
  config.signer.tokens.legacy_token = DATABASE_SECRET;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop() {
  int isObjectDetected = digitalRead(ir_pin);
  bool presence = (isObjectDetected == LOW);
  
  if (presence) {
    digitalWrite(led_pin, HIGH);
    digitalWrite(BUILTIN_LED, HIGH);
  } else {
    digitalWrite(led_pin, LOW);
    digitalWrite(BUILTIN_LED, LOW);
  }

  //Push to Firebase every 5 seconds
  if (Firebase.ready() && (millis() - sendDataPrevMillis > 5000 || sendDataPrevMillis == 0)) {
    sendDataPrevMillis = millis();

    float h = dht.readHumidity();
    float t = dht.readTemperature();

    if (isnan(h) || isnan(t)) {
      Serial.println("Failed to read from DHT sensor!");
    } else {
      // Create a JSON object to send multiple values at once
      FirebaseJson json;
      json.set("temperature", t);
      json.set("humidity", h);
      json.set("presence", presence);
      json.set("timestamp", millis() / 1000);

      Serial.printf("Pushing to Firebase... %s\n", Firebase.RTDB.setJSON(&fbdo, "/sensor_data", &json) ? "OK" : fbdo.errorReason().c_str());
    }
  }
}