// ============================================================
// Smart Fish Feeder — Data Models
<<<<<<< HEAD
// builtbyokuja · Uganda Tilapia Aquaculture Platform
// ============================================================

=======
// Uganda Tilapia Aquaculture Platform
// ============================================================

import 'package:flutter/material.dart';

>>>>>>> main
class PondModel {
  final int id;
  final String name;
  final String feederSerial;
  final double foodPercent;
  final String nextFeedTime;
  final double waterTemp;
  final bool isOnline;
  final DateTime lastSeen;

  const PondModel({
    required this.id,
    required this.name,
    required this.feederSerial,
    required this.foodPercent,
    required this.nextFeedTime,
    required this.waterTemp,
    required this.isOnline,
    required this.lastSeen,
  });

  bool get isFoodLow => foodPercent < 25.0;

  PondModel copyWith({
    double? foodPercent,
    String? nextFeedTime,
    double? waterTemp,
    bool? isOnline,
  }) {
    return PondModel(
      id: id,
      name: name,
      feederSerial: feederSerial,
      foodPercent: foodPercent ?? this.foodPercent,
      nextFeedTime: nextFeedTime ?? this.nextFeedTime,
      waterTemp: waterTemp ?? this.waterTemp,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen,
    );
  }
}

class FeedSchedule {
  final String id;
  final String pondName;
  final TimeOfDay time;
  final int durationSeconds;
  final double portionGrams;
  final bool isEnabled;
  final List<bool> weekdays; // [Mon, Tue, Wed, Thu, Fri, Sat, Sun]

  const FeedSchedule({
    required this.id,
    required this.pondName,
    required this.time,
    required this.durationSeconds,
    required this.portionGrams,
    required this.isEnabled,
    required this.weekdays,
  });

  String get timeLabel {
<<<<<<< HEAD
    final h = time.hour.toString().padLeft(2, '0');
=======
>>>>>>> main
    final m = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final h12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    return '$h12:$m $period';
  }

  FeedSchedule copyWith({bool? isEnabled}) => FeedSchedule(
        id: id,
        pondName: pondName,
        time: time,
        durationSeconds: durationSeconds,
        portionGrams: portionGrams,
        isEnabled: isEnabled ?? this.isEnabled,
        weekdays: weekdays,
      );
}

class FeedLog {
  final String id;
  final String pondName;
  final DateTime timestamp;
  final double portionGrams;
  final String trigger; // 'scheduled' | 'manual'
  final bool synced;

  const FeedLog({
    required this.id,
    required this.pondName,
    required this.timestamp,
    required this.portionGrams,
    required this.trigger,
    required this.synced,
  });
}

class DeviceInfo {
  final String serial;
  final String pondName;
  final String firmwareVersion;
  final String latestFirmware;
  final double wifiRssi;
  final int pingMs;
  final Duration uptime;
  final Map<String, String> hardwareStatus;
  final bool firmwareUpdateAvailable;

  const DeviceInfo({
    required this.serial,
    required this.pondName,
    required this.firmwareVersion,
    required this.latestFirmware,
    required this.wifiRssi,
    required this.pingMs,
    required this.uptime,
    required this.hardwareStatus,
    required this.firmwareUpdateAvailable,
  });

  String get rssiLabel {
    if (wifiRssi >= -60) return 'Excellent';
    if (wifiRssi >= -70) return 'Good';
    if (wifiRssi >= -80) return 'Fair';
    return 'Weak';
  }

  String get uptimeLabel {
    final d = uptime.inDays;
    final h = uptime.inHours % 24;
    final m = uptime.inMinutes % 60;
    return '${d}d ${h}h ${m}m';
  }
}

class SyncStatusModel {
  final int pendingUploads;
  final int failedRetries;
  final int recoveredEvents;
  final DateTime lastSyncTime;
  final bool eepromHealthy;
  final int eepromUsedBytes;
  final int eepromTotalBytes;

  const SyncStatusModel({
    required this.pendingUploads,
    required this.failedRetries,
    required this.recoveredEvents,
    required this.lastSyncTime,
    required this.eepromHealthy,
    required this.eepromUsedBytes,
    required this.eepromTotalBytes,
  });

  double get eepromFillPercent => eepromUsedBytes / eepromTotalBytes;
}
