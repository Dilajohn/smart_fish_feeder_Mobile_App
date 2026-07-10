"""Simple simulator to POST telemetry and poll for commands against the dev scaffold.
Usage: python lib\backend\simulator.py
"""
import requests
import time
from datetime import datetime
import random

BASE = "http://127.0.0.1:8000"
SERIAL = "FEEDER-001"

def send_telemetry():
    payload = {
        "serial": SERIAL,
        "pond_name": "Main Pond",
        "hopper_percent": max(0.0, min(100.0, 70.0 + random.uniform(-5, 2))),
        "water_temp": 25.0 + random.uniform(-1, 1),
        "ph": 7.2 + random.uniform(-0.2, 0.2),
        "wifi_rssi": -50 + random.randint(-5, 2),
        "uptime": int(time.time()) % 100000,
        "timestamp": datetime.utcnow().isoformat()
    }
    try:
        r = requests.post(f"{BASE}/telemetry", json=payload, timeout=5)
        print("telemetry ->", r.status_code, r.json())
    except Exception as e:
        print("telemetry error:", e)

def poll_commands():
    try:
        r = requests.get(f"{BASE}/commands/{SERIAL}/pull", timeout=5)
        if r.status_code == 200:
            cmds = r.json()
            if cmds:
                print("Pulled commands:", cmds)
                # Acknowledge each one
                for c in cmds:
                    ack = {"id": c.get("id"), "status": "done", "acked_at": datetime.utcnow().isoformat()}
                    requests.post(f"{BASE}/commands/{SERIAL}/ack", json=ack)
        else:
            print("poll status", r.status_code)
    except Exception as e:
        print("poll error:", e)

if __name__ == '__main__':
    print("Simulator starting. Sending telemetry every 5s and polling commands.")
    while True:
        send_telemetry()
        poll_commands()
        time.sleep(5)
