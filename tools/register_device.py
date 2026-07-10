#!/usr/bin/env python3
"""Register a device with the Django backend and print the returned token.
Usage: python tools/register_device.py --serial FEEDER-003 --name "Pond 3" --base http://127.0.0.1:8001
"""
import requests
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--serial', required=True)
parser.add_argument('--name', default='ESP32 Feeder')
parser.add_argument('--base', default='http://127.0.0.1:8001')
args = parser.parse_args()

url = args.base.rstrip('/') + '/api/devices/register/'
resp = requests.post(url, json={'serial': args.serial, 'name': args.name}, timeout=5)
try:
    data = resp.json()
except Exception:
    print('Failed to parse response:', resp.text)
    raise SystemExit(1)

if resp.status_code in (200,201):
    print('Device registered:')
    print('  serial:', data.get('serial'))
    print('  token :', data.get('token'))
else:
    print('Registration failed:', resp.status_code, data)
    raise SystemExit(2)
