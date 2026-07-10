#include <WiFi.h>
#include <HTTPClient.h>

// Configuration
const char* WIFI_SSID = "YOUR_SSID";
const char* WIFI_PASS = "YOUR_PASS";
const char* BASE_URL = "http://192.168.1.100:8001"; // change to your host
const char* DEVICE_SERIAL = "FEEDER-001";

String deviceToken = ""; // set after registration

void setup() {
  Serial.begin(115200);
  delay(1000);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print('.');
  }
  Serial.println("\nWiFi connected.");

  // Optionally register device and save token (run once)
  // registerDevice();
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    sendTelemetry();
    pollCommands();
  } else {
    Serial.println("WiFi not connected");
  }
  delay(5000); // 5s
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
    // parse token (simple parsing)
    int p = resp.indexOf("token");
    if (p > 0) {
      int q = resp.indexOf(':', p);
      int s = resp.indexOf('"', q+1);
      int e = resp.indexOf('"', s+1);
      deviceToken = resp.substring(s+1, e);
      Serial.println("Device token: " + deviceToken);
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

  float hopper = random(50, 90); // fake
  String body = "{\"serial\": \"" + String(DEVICE_SERIAL) + "\", \"hopper_percent\": " + String(hopper) + "}";
  int code = http.POST(body);
  Serial.printf("telemetry -> %d\n", code);
  if (code == 200) {
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
    // naive parse to find command id and ack
    // In production, use a JSON parser
  } else {
    Serial.printf("poll failed: %d\n", code);
  }
  http.end();
}