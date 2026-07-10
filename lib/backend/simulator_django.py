"""Simulator targeted at Django backend endpoints.
Run from project root with venv: .\.venv\Scripts\python.exe .\lib\backend\simulator_django.py
"""
import requests
import time
from datetime import datetime
import random

BASE = "http://127.0.0.1:8001/api"
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
    headers = {}
    import os
    token = os.getenv('DJANGO_TOKEN')
    if token:
        headers['Authorization'] = f'Token {token}'
    try:
        r = requests.post(f"{BASE}/telemetry/", json=payload, timeout=5, headers=headers if headers else None)
        try:
            print("telemetry ->", r.status_code, r.json())
        except Exception:
            print("telemetry ->", r.status_code, r.text)
    except Exception as e:
        print("telemetry error:", e)


def poll_commands():
    import os
    headers = {}
    token = os.getenv('DJANGO_TOKEN')
    if token:
        headers['Authorization'] = f'Token {token}'
    try:
        r = requests.get(f"{BASE}/commands/{SERIAL}/pull/", timeout=5, headers=headers if headers else None)
        if r.status_code == 200:
            cmds = r.json()
            if cmds:
                print("Pulled commands:", cmds)
                # Acknowledge each one
                for c in cmds:
                    ack = {"id": c.get("id"), "status": "done", "acked_at": datetime.utcnow().isoformat()}
                    requests.post(f"{BASE}/commands/{SERIAL}/ack/", json=ack, headers=headers if headers else None)
        else:
            print("poll status", r.status_code)
    except Exception as e:
        print("poll error:", e)


if __name__ == '__main__':
    print("Django Simulator starting. Sending telemetry every 5s and polling commands.")
    while True:
        send_telemetry()
        poll_commands()
        time.sleep(5)
