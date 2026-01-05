#include <Arduino.h>
#include <ArduinoJson.h>
#include <WiFi.h> 
#include <WebServer.h>
#include <DHT.h>
#include <ESP32Servo.h>

#define led_pin 2
#define dht_pin 4
#define servo_pin 18
#define ir_pin 5
#define DHTTYPE DHT11
DHT dht(dht_pin, DHTTYPE);

const char* ssid = "who";
const char* password ="Z1234567890";

Servo myServo;

WebServer server(80);

// root
void handleRoot() {
  String jsonResponse = "{";
  jsonResponse += "\"status\": \"ONLINE\",";
  jsonResponse += "\"uptime_seconds\": " + String(millis() / 1000) + ",";
  jsonResponse += "\"device_name\": \"ESP32 DevKit\"";
  jsonResponse += "}";

  server.send(200, "application/json", jsonResponse);
}
// LED ON
void handleLedOn()
{
  digitalWrite(BUILTIN_LED, HIGH);
  digitalWrite(led_pin, HIGH);
  server.send(200, "text/plain", "LED is ON");
}
// LED OFF
void handleLedOff()
{
  digitalWrite(led_pin, LOW);
  digitalWrite(BUILTIN_LED, LOW);
  server.send(200, "text/plain", "LED is OFF");
}
// Read DHT Sensor
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
  // Serial.println(json);
  server.send(200, "application/json", json);
}
// Servo Control
void handleServo(){
  if(server.hasArg("angle")){
    int angle = server.arg("angle").toInt();
    myServo.write(angle);
    server.send(200, "text/plain", "Servo moved to angle: " + String(angle));
  } else {
    server.send(400, "text/plain", "Angle parameter missing");
  }
}
//IR sensor
void handleIRSensor()
{
  int isObjectDetected = digitalRead(ir_pin);
  float temp = dht.readTemperature();
  StaticJsonDocument<200> data;
  // detect presence

  if(isObjectDetected == LOW){
    digitalWrite(led_pin, HIGH); 
    myServo.write(90);
    data["presence"] = true;
    data["led"] = true;
    data["door"] = "OPEN";
    String json;
    serializeJson(data, json);
    server.send(200, "application/json", json);
  } else {
    digitalWrite(led_pin, LOW);
    if (temp > 20) {
      myServo.write(180); // "Ventilation" angle
    } else {
      myServo.write(0);   // Standard Closed
    }
    data["presence"] = false;
    data["led"] = false;
    data["door"] = "CLOSED";
    String json;
    serializeJson(data, json);
    server.send(200, "application/json", json);
  }
  // Serial.println("IR: " + String(isObjectDetected));
}
void setup(){
  Serial.begin(115200);

  pinMode(led_pin, OUTPUT);
  pinMode(BUILTIN_LED, OUTPUT);
  pinMode(dht_pin, INPUT);
  myServo.attach(servo_pin);
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
  server.on("/servo", handleServo); // Servo control link
  server.on("/ir", handleIRSensor); // IR sensor link
  server.begin(); 
} 
void loop(){
  server.handleClient(); //listen for client requests 
}