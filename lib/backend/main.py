"""FastAPI backend scaffold for Smart Fish Feeder
- In-memory stores for ponds, schedules, telemetry, feed logs, and commands
- CORS enabled for local dev (web + emulator)
- Endpoints: /health, /ponds, /schedules, /telemetry, /feed-logs, /commands, /commands/{serial}/pull, /commands/{serial}/ack

This is a development scaffold intended to be swapped for a DB-backed implementation later.
"""
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict, Optional
from datetime import datetime
import uuid

app = FastAPI(title="Smart Fish Feeder API - Dev Scaffold")

# Allow common dev origins (adjust in production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:8000", "http://127.0.0.1:8000", "http://localhost:5173", "*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic models
class Pond(BaseModel):
    id: str
    name: str
    serial: str
    hopper_percent: float = 100.0

class FeedSchedule(BaseModel):
    id: str
    pond_id: str
    cron: Optional[str] = None
    time: Optional[str] = None
    amount_grams: Optional[float] = None

class Telemetry(BaseModel):
    serial: str
    pond_name: Optional[str]
    hopper_percent: Optional[float]
    water_temp: Optional[float]
    ph: Optional[float]
    wifi_rssi: Optional[int]
    uptime: Optional[int]
    timestamp: Optional[datetime]

class FeedLog(BaseModel):
    id: str
    pond_id: str
    serial: str
    amount_grams: float
    timestamp: datetime

class Command(BaseModel):
    id: str
    command: str
    payload: Optional[dict] = {}
    created_at: datetime

class CommandAck(BaseModel):
    id: str
    status: str
    acked_at: datetime

# In-memory stores
ponds: Dict[str, Pond] = {}
schedules: Dict[str, FeedSchedule] = {}
telemetry_store: List[Telemetry] = []
feed_logs: List[FeedLog] = []
# commands per device serial
commands: Dict[str, List[Command]] = {}

# Seed example pond
def seed():
    p = Pond(id="pond1", name="Main Pond", serial="FEEDER-001", hopper_percent=78.0)
    ponds[p.id] = p
    s = FeedSchedule(id="sch1", pond_id=p.id, time="08:00", amount_grams=5.0)
    schedules[s.id] = s

seed()

@app.get("/health")
async def health():
    return {"status": "ok", "time": datetime.utcnow().isoformat()}

@app.get("/ponds", response_model=List[Pond])
async def get_ponds():
    return list(ponds.values())

@app.get("/schedules", response_model=List[FeedSchedule])
async def get_schedules():
    return list(schedules.values())

@app.post("/telemetry")
async def post_telemetry(t: Telemetry):
    t.timestamp = t.timestamp or datetime.utcnow()
    telemetry_store.append(t)
    # update pond hopper if matching serial found
    for p in ponds.values():
        if p.serial == t.serial and t.hopper_percent is not None:
            p.hopper_percent = t.hopper_percent
    return {"status": "received", "timestamp": t.timestamp.isoformat()}

@app.get("/feed-logs", response_model=List[FeedLog])
async def get_feed_logs():
    return feed_logs

@app.post("/feed-logs", response_model=FeedLog)
async def post_feed_log(log: FeedLog):
    feed_logs.append(log)
    return log

@app.post("/commands/{serial}")
async def post_command(serial: str, cmd: Command):
    cmd.created_at = cmd.created_at or datetime.utcnow()
    commands.setdefault(serial, []).append(cmd)
    return {"status": "queued", "id": cmd.id}

@app.get("/commands/{serial}/pull", response_model=List[Command])
async def pull_commands(serial: str):
    # return and clear queue for that device
    q = commands.get(serial, [])
    commands[serial] = []
    return q

@app.post("/commands/{serial}/ack")
async def ack_command(serial: str, ack: CommandAck):
    # In this scaffold, just log the ack (could be extended)
    return {"status": "acknowledged", "id": ack.id}

# Basic admin helper to list telemetry (dev only)
@app.get("/telemetry")
async def list_telemetry(limit: int = 100):
    return telemetry_store[-limit:]

# Simple endpoint to create a new pond (dev)
@app.post("/ponds", response_model=Pond)
async def create_pond(p: Pond):
    if p.id in ponds:
        raise HTTPException(status_code=400, detail="Pond id exists")
    ponds[p.id] = p
    return p

# Provide a minimal run helper if executed directly
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("lib.backend.main:app", host="127.0.0.1", port=8000, reload=True)
