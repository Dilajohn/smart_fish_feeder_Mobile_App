Smart Fish Feeder — Django backend (dev)

What this contains:
- Django project at backend_django with an `api` app exposing REST endpoints:
  - GET/POST /api/ponds/
  - GET/POST /api/schedules/
  - POST /api/telemetry/
  - GET/POST /api/feed-logs/
  - POST /api/commands/<serial>/
  - GET /api/commands/<serial>/pull/
  - POST /api/commands/<serial>/ack/
- Admin site available at /admin/ (superuser: admin)
- API OpenAPI schema at /api/schema/

Local dev notes:
- Server: python lib/backend_django/manage.py runserver 127.0.0.1:8001
- Uses SQLite by default (lib/backend_django/db.sqlite3). To use Postgres, update DATABASES in settings.py and run migrations.
- Seed data: pond id `pond1` (serial FEEDER-001) and schedule `sch1` were added.

Next steps:
- Auth: DRF Token auth enabled. Obtain a token via POST /api-token-auth/ (username & password) or use the generated admin token in this dev setup.
- Swap SQLite -> Postgres and store credentials securely via environment variables (.env).
- Background worker: a management command run_scheduler exists; a Celery scaffold and task (api.tasks.run_scheduled_feeds) were added — configure CELERY_BROKER_URL and run a worker.
- Add tests and CI integration (GitHub Actions workflow added to repository).

Per-device provisioning & security:
- Added device registration endpoint: POST /api/devices/register/ (returns device token)
- Devices authenticate using header 'Device-Token' for telemetry and command pulls
- Management command rotate_device_tokens to rotate per-device tokens
- Firmware ESP32 stub provided in firmware/esp32_http_stub demonstrating registration, telemetry, and polling

Security notes:
- Rotate Neon DB credentials after initial testing and create dedicated low-privilege DB users.
- Use HTTPS in production and provision per-device tokens securely. Store secrets only in environment variables or a secrets manager.
