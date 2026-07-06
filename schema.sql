-- ============================================================================
-- Smart Fish Feeder — PostgreSQL Database Schema
-- Built for Group 21 · Makerere University
--
-- SECURITY ADVISORY (Endpoint Security & Least Privilege):
-- 1. DO NOT use the superuser account ('postgres') in the mobile application.
-- 2. Create a dedicated database user for the mobile app (e.g. 'fish_farmer').
-- 3. Grant ONLY SELECT, INSERT, and UPDATE permissions to that user:
--    GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO fish_farmer;
-- 4. In production, ensure PostgreSQL is configured to require SSL (sslMode = SslMode.require)
--    and configure your firewall/pg_hba.conf to only allow authenticated client IPs.
-- ============================================================================

-- Drop tables if they exist (for clean re-run)
-- DROP TABLE IF EXISTS sync_status CASCADE;
-- DROP TABLE IF EXISTS device_info CASCADE;
-- DROP TABLE IF EXISTS feed_logs CASCADE;
-- DROP TABLE IF EXISTS feed_schedules CASCADE;
-- DROP TABLE IF EXISTS ponds CASCADE;

-- 1. Create Ponds Table
CREATE TABLE IF NOT EXISTS ponds (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    feeder_serial VARCHAR(50) NOT NULL,
    food_percent INTEGER NOT NULL DEFAULT 100 CHECK (food_percent >= 0 AND food_percent <= 100),
    next_feed_time VARCHAR(20) DEFAULT 'Offline',
    water_temp DOUBLE PRECISION NOT NULL DEFAULT 25.0,
    is_online BOOLEAN NOT NULL DEFAULT FALSE,
    last_seen TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexing for speed
CREATE INDEX IF NOT EXISTS idx_ponds_name ON ponds(name);

-- 2. Create Feed Schedules Table
CREATE TABLE IF NOT EXISTS feed_schedules (
    id VARCHAR(50) PRIMARY KEY,
    pond_name VARCHAR(100) NOT NULL REFERENCES ponds(name) ON DELETE CASCADE,
    hour INTEGER NOT NULL CHECK (hour >= 0 AND hour <= 23),
    minute INTEGER NOT NULL CHECK (minute >= 0 AND minute <= 59),
    duration_seconds INTEGER NOT NULL CHECK (duration_seconds > 0),
    portion_grams INTEGER NOT NULL CHECK (portion_grams > 0),
    is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    weekdays BOOLEAN[] NOT NULL DEFAULT ARRAY[TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE]
);

-- 3. Create Feed Logs Table
CREATE TABLE IF NOT EXISTS feed_logs (
    id VARCHAR(50) PRIMARY KEY,
    pond_name VARCHAR(100) NOT NULL,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    portion_grams DOUBLE PRECISION NOT NULL CHECK (portion_grams >= 0.0),
    trigger_type VARCHAR(20) NOT NULL CHECK (trigger_type IN ('scheduled', 'manual')),
    synced BOOLEAN NOT NULL DEFAULT TRUE
);

-- Index logs for quick dashboard lists
CREATE INDEX IF NOT EXISTS idx_feed_logs_timestamp ON feed_logs(timestamp DESC);

-- 4. Create Device Info Table
CREATE TABLE IF NOT EXISTS device_info (
    serial VARCHAR(50) PRIMARY KEY,
    pond_name VARCHAR(100) NOT NULL,
    firmware_version VARCHAR(20) NOT NULL,
    latest_firmware VARCHAR(20) NOT NULL,
    wifi_rssi INTEGER NOT NULL,
    ping_ms INTEGER NOT NULL,
    uptime_seconds BIGINT NOT NULL CHECK (uptime_seconds >= 0),
    hardware_status JSONB NOT NULL,
    firmware_update_available BOOLEAN NOT NULL DEFAULT FALSE
);

-- 5. Create Sync Status Table
CREATE TABLE IF NOT EXISTS sync_status (
    id SERIAL PRIMARY KEY,
    pending_uploads INTEGER NOT NULL DEFAULT 0,
    failed_retries INTEGER NOT NULL DEFAULT 0,
    recovered_events INTEGER NOT NULL DEFAULT 0,
    last_sync_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    eeprom_healthy BOOLEAN NOT NULL DEFAULT TRUE,
    eeprom_used_bytes INTEGER NOT NULL DEFAULT 0,
    eeprom_total_bytes INTEGER NOT NULL DEFAULT 4096
);

-- ============================================================================
-- Populate Default Records (Simulating initial Tilapia farm state)
-- ============================================================================

-- 1. Default Ponds
INSERT INTO ponds (id, name, feeder_serial, food_percent, next_feed_time, water_temp, is_online, last_seen) VALUES
(1, 'Pond A', 'SFF-001-KLA', 67, '12:00 PM', 24.0, TRUE, NOW() - INTERVAL '30 seconds'),
(2, 'Pond B', 'SFF-002-KLA', 0, 'Offline', 0.0, FALSE, NOW() - INTERVAL '8 hours'),
(3, 'Pond C', 'SFF-003-KLA', 19, '5:00 PM', 23.0, TRUE, NOW() - INTERVAL '2 minutes')
ON CONFLICT (id) DO UPDATE SET
    feeder_serial = EXCLUDED.feeder_serial,
    food_percent = EXCLUDED.food_percent,
    next_feed_time = EXCLUDED.next_feed_time,
    water_temp = EXCLUDED.water_temp,
    is_online = EXCLUDED.is_online,
    last_seen = EXCLUDED.last_seen;

-- 2. Default Schedules
INSERT INTO feed_schedules (id, pond_name, hour, minute, duration_seconds, portion_grams, is_enabled, weekdays) VALUES
('sch-001', 'Pond A', 6, 0, 8, 120, TRUE, ARRAY[TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE]),
('sch-002', 'Pond A', 12, 0, 10, 150, TRUE, ARRAY[TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE]),
('sch-003', 'Pond A', 17, 0, 8, 120, FALSE, ARRAY[TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE]),
('sch-004', 'Pond C', 17, 0, 6, 90, TRUE, ARRAY[TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE])
ON CONFLICT (id) DO UPDATE SET
    hour = EXCLUDED.hour,
    minute = EXCLUDED.minute,
    duration_seconds = EXCLUDED.duration_seconds,
    portion_grams = EXCLUDED.portion_grams,
    is_enabled = EXCLUDED.is_enabled,
    weekdays = EXCLUDED.weekdays;

-- 3. Default Feed Logs
INSERT INTO feed_logs (id, pond_name, timestamp, portion_grams, trigger_type, synced) VALUES
('log-1', 'Pond A', NOW() - INTERVAL '1 hour 15 minutes', 120.0, 'scheduled', TRUE),
('log-2', 'Pond A', NOW() - INTERVAL '7 hours', 150.0, 'scheduled', TRUE),
('log-3', 'Pond C', NOW() - INTERVAL '2 hours', 90.0, 'manual', TRUE),
('log-4', 'Pond A', NOW() - INTERVAL '1 day 1 hour', 120.0, 'scheduled', FALSE),
('log-5', 'Pond C', NOW() - INTERVAL '1 day 5 hours', 90.0, 'scheduled', TRUE)
ON CONFLICT (id) DO NOTHING;

-- 4. Default Device Info
INSERT INTO device_info (serial, pond_name, firmware_version, latest_firmware, wifi_rssi, ping_ms, uptime_seconds, hardware_status, firmware_update_available) VALUES
('SFF-001-KLA', 'Pond A', 'v1.2.4', 'v1.3.0', -61, 142, 310942, '{"Servo Feed Motor": "OK", "Ultrasonic Depth Sensor": "OK", "DS3231 RTC Clock": "Synced", "EEPROM Memory Log": "Written", "ESP8266 WiFi Antenna": "Connected"}'::jsonb, TRUE)
ON CONFLICT (serial) DO UPDATE SET
    pond_name = EXCLUDED.pond_name,
    firmware_version = EXCLUDED.firmware_version,
    latest_firmware = EXCLUDED.latest_firmware,
    wifi_rssi = EXCLUDED.wifi_rssi,
    ping_ms = EXCLUDED.ping_ms,
    uptime_seconds = EXCLUDED.uptime_seconds,
    hardware_status = EXCLUDED.hardware_status,
    firmware_update_available = EXCLUDED.firmware_update_available;

-- 5. Default Sync Status
INSERT INTO sync_status (id, pending_uploads, failed_retries, recovered_events, last_sync_time, eeprom_healthy, eeprom_used_bytes, eeprom_total_bytes) VALUES
(1, 3, 1, 2, NOW() - INTERVAL '4 minutes', TRUE, 3071, 4096)
ON CONFLICT (id) DO UPDATE SET
    pending_uploads = EXCLUDED.pending_uploads,
    failed_retries = EXCLUDED.failed_retries,
    recovered_events = EXCLUDED.recovered_events,
    last_sync_time = EXCLUDED.last_sync_time,
    eeprom_healthy = EXCLUDED.eeprom_healthy,
    eeprom_used_bytes = EXCLUDED.eeprom_used_bytes,
    eeprom_total_bytes = EXCLUDED.eeprom_total_bytes;
