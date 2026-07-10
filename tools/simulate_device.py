#!/usr/bin/env python3
"""Simulate a device using Device-Token for auth. Sends telemetry and polls for commands, acknowledging them.
Usage: python tools/simulate_device.py --serial FEEDER-002 --base http://127.0.0.1:8001 --token YOURTOKEN
"""
import requests
import time
import argparse
from datetime import datetime
import random

parser = argparse.ArgumentParser()
parser.add_argument('--serial', required=True)
parser.add_argument('--base', default='http://127.0.0.1:8001')
parser.add_argument('--token', default=None)
args = parser.parse_args()

BASE = args.base.rstrip('/') + '/api'
SERIAL = args.serial
TOKEN = args.token

headers = {'Content-Type':'application/json'}
if TOKEN:
    headers['Device-Token'] = TOKEN


def send_telemetry():
    payload = {
        'serial': SERIAL,
        'pond_name': 'Sim Pond',
        'hopper_percent': max(0.0, min(100.0, 70.0 + random.uniform(-5, 2))),
        'water_temp': 25.0 + random.uniform(-1, 1),
        'ph': 7.2 + random.uniform(-0.2, 0.2),
        'wifi_rssi': -50 + random.randint(-5, 2),
        'uptime': int(time.time()) % 100000,
        'timestamp': datetime.utcnow().isoformat()
    }
    try:
        r = requests.post(f"{BASE}/telemetry/", json=payload, headers=headers, timeout=5)
        print('telemetry ->', r.status_code, r.text)
    except Exception as e:
        print('telemetry error:', e)


def poll_commands():
    try:
        r = requests.get(f"{BASE}/commands/{SERIAL}/pull/", headers=headers, timeout=5)
        if r.status_code == 200:
            cmds = r.json()
            if cmds:
                print('Pulled commands:', cmds)
                for c in cmds:
                    ack = {'id': c.get('id'), 'status': 'done', 'acked_at': datetime.utcnow().isoformat()}
                    requests.post(f"{BASE}/commands/{SERIAL}/ack/", json=ack, headers=headers)
        else:
            print('poll status', r.status_code, r.text)
    except Exception as e:
        print('poll error:', e)


if __name__ == '__main__':
    print('Simulator starting. Sending telemetry every 5s and polling commands.')
    while True:
        send_telemetry()
        poll_commands()
        time.sleep(5)
