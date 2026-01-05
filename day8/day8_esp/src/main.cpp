#include <Arduino.h>
#include <ArduinoJson.h>
#include <WiFi.h> 
#include <WebServer.h>
#include <DHT.h>

#define led_pin 2
#define dht_pin 4
#define DHTTYPE DHT11
DHT dht(dht_pin, DHTTYPE);

const char* ssid = "who";
const char* password ="Z1234567890";

WebServer server(80);

void handleRoot() {
  String jsonResponse = "{";
  jsonResponse += "\"status\": \"ONLINE\",";
  jsonResponse += "\"uptime_seconds\": " + String(millis() / 1000) + ",";
  jsonResponse += "\"device_name\": \"ESP32 DevKit\"";
  jsonResponse += "}";

  server.send(200, "application/json", jsonResponse);
}

void handleLedOn()
{
  digitalWrite(BUILTIN_LED, HIGH);
  digitalWrite(led_pin, HIGH);
  server.send(200, "text/plain", "LED is ON");
}
void handleLedOff()
{
  digitalWrite(led_pin, LOW);
  digitalWrite(BUILTIN_LED, LOW);
  server.send(200, "text/plain", "LED is OFF");
}
void readDHTSensor(){

  float h = dht.readHumidity();
  float t = dht.readTemperature();

  if (isnan(h) || isnan(t)) {
    server.send(500, "text/plain", "Failed to read from DHT sensor!");
    return;
  }

  StaticJsonDocument<200> doc;
  doc["temperature"] = t;
  doc["humidity"] = h;

  String json;
  serializeJson(doc, json);
  Serial.println(json);
  server.send(200, "application/json", json);
}

void setup(){
  Serial.begin(115200);

  pinMode(led_pin, OUTPUT);
  pinMode(BUILTIN_LED, OUTPUT);
  pinMode(dht_pin, INPUT);
  dht.begin();

  readDHTSensor();

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
  }
  Serial.println("Connected to WiFi");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());

  server.on("/", handleRoot); // root link
  server.on("/on", handleLedOn); // LED ON link
  server.on("/off", handleLedOff); // LED OFF link
  server.on("/dht", readDHTSensor); // DHT sensor link
  server.begin(); 
} 
void loop(){
  server.handleClient(); //listen for client requests 
}