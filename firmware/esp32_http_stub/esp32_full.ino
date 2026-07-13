// ============================================================
// Smart Fish Feeder — ESP32 Firmware
// Communicates with Django backend over WiFi.
//
// Flow:
//   1. On first boot, registers with backend → receives device token
//   2. Every 5 s: sends telemetry (food level, water temp, RSSI)
//   3. Every 5 s: polls for pending commands (feed_now, firmware_update, sync)
//   4. On command received: executes it, sends ACK to backend
//
// Backend base URL: http://<your-server-ip>:8000/api/v1
// ============================================================

#include <WiFi.h>
#include <HTTPClient.h>
#include <Preferences.h>

// ── Configuration — update before flashing ────────────────
const char* WIFI_SSID     = "YOUR_WIFI_SSID";
const char* WIFI_PASS     = "YOUR_WIFI_PASSWORD";
// Replace with your server LAN IP or domain. Port 8000 is Django's default.
const char* BASE_URL      = "http://192.168.1.100:8000/api/v1";
const char* DEVICE_SERIAL = "SFF-001-KLA";   // Must match a DeviceInfo serial on the server
const char* DEVICE_NAME   = "Feeder Node 1";

// ── Globals ────────────────────────────────────────────────
Preferences prefs;
String deviceToken;   // Stored in NVS after first registration

// ── Sensor pin stubs (replace with real pins) ─────────────
// #define TRIG_PIN 5
// #define ECHO_PIN 18
// #define TEMP_PIN 4

// ==========================================================
void setup() {
  Serial.begin(115200);
  delay(1000);

  // Load stored device token from NVS
  prefs.begin("sff", false);
  deviceToken = prefs.getString("device_token", "");

  // Connect to WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.print("Connecting to WiFi");
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print('.');
    attempts++;
  }
  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf("\nConnected. IP: %s\n", WiFi.localIP().toString().c_str());
  } else {
    Serial.println("\nWiFi failed — running offline (RTC fallback).");
    return;
  }

  // Register with backend if no token stored
  if (deviceToken.length() == 0) {
    Serial.println("No device token — registering with backend...");
    registerDevice();
  } else {
    Serial.printf("Loaded token from NVS: %s...\n", deviceToken.substring(0, 8).c_str());
  }
}

// ==========================================================
void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    sendTelemetry();
    pollCommands();
  } else {
    Serial.println("WiFi disconnected — attempting reconnect...");
    WiFi.reconnect();
  }
  delay(5000);
}

// ==========================================================
// Step 1: Register device and obtain a device token
// POST /api/v1/devices/register/
// ==========================================================
void registerDevice() {
  HTTPClient http;
  String url = String(BASE_URL) + "/devices/register/";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");

  String body = "{\"serial\": \"" + String(DEVICE_SERIAL) + "\", \"name\": \"" + String(DEVICE_NAME) + "\"}";
  int code = http.POST(body);

  if (code == 200 || code == 201) {
    String resp = http.getString();
    Serial.println("Register response: " + resp);

    // Parse "token" from JSON response manually (no ArduinoJson dependency)
    deviceToken = extractJsonString(resp, "token");
    if (deviceToken.length() > 0) {
      prefs.putString("device_token", deviceToken);
      Serial.printf("Device registered. Token stored (%d chars).\n", deviceToken.length());
    } else {
      Serial.println("ERROR: Could not parse token from register response.");
    }
  } else {
    Serial.printf("Register failed — HTTP %d: %s\n", code, http.getString().c_str());
  }
  http.end();
}

// ==========================================================
// Step 2: Send sensor telemetry to backend
// POST /api/v1/telemetry/
// Fields match Django TelemetrySerializer:
//   device_serial, food_level_pct, water_temp, wifi_rssi
// Auth: Device-Token header
// ==========================================================
void sendTelemetry() {
  if (deviceToken.length() == 0) return;

  HTTPClient http;
  String url = String(BASE_URL) + "/telemetry/";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Device-Token", deviceToken);

  // Replace with real sensor readings
  float foodLevelPct = readFoodLevel();   // 0.0 – 100.0
  float waterTemp    = readWaterTemp();   // degrees Celsius
  int   wifiRssi     = WiFi.RSSI();

  String body = "{\"device_serial\": \"" + String(DEVICE_SERIAL) + "\""
              + ", \"food_level_pct\": " + String(foodLevelPct, 1)
              + ", \"water_temp\": " + String(waterTemp, 1)
              + ", \"wifi_rssi\": " + String(wifiRssi)
              + "}";

  int code = http.POST(body);
  Serial.printf("Telemetry → HTTP %d  food=%.1f%%  temp=%.1f°C  rssi=%d\n",
                code, foodLevelPct, waterTemp, wifiRssi);
  http.end();
}

// ==========================================================
// Step 3: Poll backend for pending commands
// GET /api/v1/devices/{serial}/poll/
// Auth: Device-Token header
// ==========================================================
void pollCommands() {
  if (deviceToken.length() == 0) return;

  HTTPClient http;
  String url = String(BASE_URL) + "/devices/" + String(DEVICE_SERIAL) + "/poll/";
  http.begin(url);
  http.addHeader("Device-Token", deviceToken);

  int code = http.GET();
  if (code == 200) {
    String resp = http.getString();
    if (resp.length() > 2) {   // non-empty array "[]"
      Serial.println("Pending commands: " + resp);
      // Process first command found in response
      processCommand(resp);
    }
  } else if (code == 401) {
    Serial.println("Device-Token rejected — re-registering...");
    deviceToken = "";
    prefs.remove("device_token");
    registerDevice();
  } else {
    Serial.printf("Poll → HTTP %d\n", code);
  }
  http.end();
}

// ==========================================================
// Process a command JSON array and execute first command
// ==========================================================
void processCommand(String jsonArray) {
  // Extract command id and type from first element
  String cmdId   = extractJsonString(jsonArray, "id");
  String cmdType = extractJsonString(jsonArray, "command_type");

  if (cmdId.length() == 0) return;

  Serial.printf("Executing command: %s (id=%s)\n", cmdType.c_str(), cmdId.c_str());

  if (cmdType == "feed_now") {
    executeFeedNow(jsonArray);
  } else if (cmdType == "firmware_update") {
    Serial.println("Firmware update requested — implement OTA here.");
  } else if (cmdType == "sync") {
    Serial.println("EEPROM sync requested — uploading offline events.");
    // TODO: read EEPROM feed log and POST each unsent entry to /feed-logs/
  }

  // ACK the command regardless of type
  ackCommand(cmdId);
}

// ==========================================================
// Execute a feed_now command — run servo
// ==========================================================
void executeFeedNow(String cmdJson) {
  // Extract portion_grams from payload (default 120)
  String portionStr = extractJsonString(cmdJson, "portion_grams");
  int portionGrams  = portionStr.length() > 0 ? portionStr.toInt() : 120;
  int durationMs    = (portionGrams * 1000) / 15;  // ~15 g/s servo rate

  Serial.printf("Feeding %d g (servo for %d ms)...\n", portionGrams, durationMs);

  // Replace with real servo control:
  // servo.write(90);
  // delay(durationMs);
  // servo.write(0);
  delay(durationMs);

  Serial.println("Feed complete.");
}

// ==========================================================
// Step 4: Acknowledge command execution
// POST /api/v1/commands/{id}/ack/
// Auth: Device-Token header
// ==========================================================
void ackCommand(String cmdId) {
  if (deviceToken.length() == 0 || cmdId.length() == 0) return;

  HTTPClient http;
  // Command IDs from DRF are integers
  String url = String(BASE_URL) + "/commands/" + cmdId + "/ack/";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Device-Token", deviceToken);

  // Empty body is fine — the server just marks the command as delivered
  int code = http.POST("{}");
  Serial.printf("ACK command %s → HTTP %d\n", cmdId.c_str(), code);
  http.end();
}

// ==========================================================
// Sensor stubs — replace with real hardware reads
// ==========================================================
float readFoodLevel() {
  // Ultrasonic sensor (HC-SR04 / JSN-SR04T) → distance → % full
  // Example: full at 5 cm, empty at 30 cm → linear map
  // float distance = measureUltrasonic();
  // return constrain(map(distance, 30, 5, 0, 100), 0.0, 100.0);
  return random(40, 90);  // stub
}

float readWaterTemp() {
  // DS18B20 OneWire sensor
  // sensors.requestTemperatures();
  // return sensors.getTempCByIndex(0);
  return 24.0 + (random(-10, 10) / 10.0);  // stub
}

// ==========================================================
// Minimal JSON string extractor (no external library needed)
// Finds: "key": "value"  or  "key": number
// ==========================================================
String extractJsonString(String json, String key) {
  String searchKey = "\"" + key + "\"";
  int keyPos = json.indexOf(searchKey);
  if (keyPos < 0) return "";

  int colonPos = json.indexOf(':', keyPos + searchKey.length());
  if (colonPos < 0) return "";

  // Skip whitespace
  int valStart = colonPos + 1;
  while (valStart < json.length() && json[valStart] == ' ') valStart++;

  if (json[valStart] == '"') {
    // String value
    int end = json.indexOf('"', valStart + 1);
    if (end < 0) return "";
    return json.substring(valStart + 1, end);
  } else {
    // Numeric value
    int end = valStart;
    while (end < json.length() && json[end] != ',' && json[end] != '}' && json[end] != ']') end++;
    return json.substring(valStart, end);
  }
}
