// ESP32 full HTTP client stub
// - Stores device token in Preferences
// - Registers device if no token
// - Sends telemetry and polls commands, acknowledging them
// - Minimal JSON parsing without ArduinoJson for simplicity

#include <WiFi.h>
#include <HTTPClient.h>
#include <Preferences.h>

// Configuration - update before upload
const char* WIFI_SSID = "YOUR_SSID";
const char* WIFI_PASS = "YOUR_PASS";
const char* BASE_URL = "http://192.168.1.100:8001"; // change to your host
const char* DEVICE_SERIAL = "FEEDER-002"; // unique serial for this device

Preferences prefs;
String deviceToken;

void setup() {
  Serial.begin(115200);
  delay(1000);
  prefs.begin("sff", false);
  deviceToken = prefs.getString("device_token", "");

  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print('.');
  }
  Serial.println("\nWiFi connected.");

  if (deviceToken.length() == 0) {
    Serial.println("No device token found — registering device...");
    registerDevice();
  } else {
    Serial.println("Loaded device token from preferences.");
  }
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    sendTelemetry();
    pollCommands();
  } else {
    Serial.println("WiFi not connected");
  }
  delay(5000);
}

void registerDevice() {
  HTTPClient http;
  String url = String(BASE_URL) + "/api/devices/register/";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  String body = "{\"serial\": \"" + String(DEVICE_SERIAL) + "\", \"name\": \"ESP32 Feeder\"}";
  int code = http.POST(body);
  if (code == 200 || code == 201) {
    String resp = http.getString();
    Serial.println("Registered: " + resp);
    // Very small parser to find token value in JSON response
    int p = resp.indexOf("\"token\"");
    if (p >= 0) {
      int colon = resp.indexOf(':', p);
      int quote1 = resp.indexOf('"', colon+1);
      int quote2 = resp.indexOf('"', quote1+1);
      if (quote1 >=0 && quote2 > quote1) {
        deviceToken = resp.substring(quote1+1, quote2);
        Serial.println("Device token: " + deviceToken);
        prefs.putString("device_token", deviceToken);
      }
    }
  } else {
    Serial.printf("Register failed: %d\n", code);
  }
  http.end();
}

void sendTelemetry() {
  if (WiFi.status() != WL_CONNECTED) return;
  HTTPClient http;
  String url = String(BASE_URL) + "/api/telemetry/";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  if (deviceToken.length() > 0) http.addHeader("Device-Token", deviceToken);

  float hopper = random(40, 90); // fake
  float temp = 24.0 + random(-5, 5) / 10.0;
  String body = "{\"serial\": \"" + String(DEVICE_SERIAL) + "\", \"hopper_percent\": " + String(hopper) + ", \"water_temp\": " + String(temp) + "}";
  int code = http.POST(body);
  Serial.printf("telemetry -> %d\n", code);
  if (code == 200) {
    Serial.println(http.getString());
  } else {
    Serial.println(http.getString());
  }
  http.end();
}

void pollCommands() {
  if (WiFi.status() != WL_CONNECTED) return;
  HTTPClient http;
  String url = String(BASE_URL) + "/api/commands/" + String(DEVICE_SERIAL) + "/pull/";
  http.begin(url);
  if (deviceToken.length() > 0) http.addHeader("Device-Token", deviceToken);
  int code = http.GET();
  if (code == 200) {
    String resp = http.getString();
    Serial.println("Commands: " + resp);
    // Naive handling: if response contains a command id, acknowledge it
    int idPos = resp.indexOf("\"id\"");
    if (idPos >= 0) {
      int colon = resp.indexOf(':', idPos);
      int q1 = resp.indexOf('"', colon+1);
      int q2 = resp.indexOf('"', q1+1);
      if (q1 >= 0 && q2 > q1) {
        String cmdId = resp.substring(q1+1, q2);
        ackCommand(cmdId);
      }
    }
  } else {
    Serial.printf("poll failed: %d\n", code);
  }
  http.end();
}

void ackCommand(String cmdId) {
  HTTPClient http;
  String url = String(BASE_URL) + "/api/commands/" + String(DEVICE_SERIAL) + "/ack/";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  if (deviceToken.length() > 0) http.addHeader("Device-Token", deviceToken);
  String body = "{\"id\": \"" + cmdId + "\", \"status\": \"done\", \"acked_at\": \"" + String(millis()) + "\"}";
  int code = http.POST(body);
  Serial.printf("ack -> %d for %s\n", code, cmdId.c_str());
  http.end();
}
