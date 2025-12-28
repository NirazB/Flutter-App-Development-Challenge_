#include <Arduino.h>
#include <WiFi.h> 
#include <WebServer.h>

#define led_pin 12

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

void setup(){
  Serial.begin(115200);

  pinMode(led_pin, OUTPUT);
  pinMode(BUILTIN_LED, OUTPUT);

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
  server.begin(); 
} 
void loop(){
  server.handleClient(); //listen for client requests 
}