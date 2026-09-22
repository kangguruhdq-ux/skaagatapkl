import os
import json
import asyncio
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.core.config import settings
from app.db.session import engine, Base
from app.db.seeds import init_db
from app.api.v1.router import api_router
from app.schemas.common import ApiResponse

# Create all database tables
Base.metadata.create_all(bind=engine)

# SQLite development databases predate some audit/selfie columns. ``create_all``
# does not alter existing tables, so apply additive migrations at startup.
def _migrate_sqlite():
    if engine.url.get_backend_name() != "sqlite":
        return
    additions = {
        "attendance_records": {
            "selfie_url": "VARCHAR(255)",
            "approval_status": "VARCHAR(50) DEFAULT 'PENDING'",
            "verified_by_mentor": "BOOLEAN DEFAULT 0",
        },
    }
    with engine.begin() as conn:
        for table, columns in additions.items():
            existing = {row[1] for row in conn.exec_driver_sql(f"PRAGMA table_info({table})")}
            for column, definition in columns.items():
                if column not in existing:
                    conn.exec_driver_sql(f"ALTER TABLE {table} ADD COLUMN {column} {definition}")

_migrate_sqlite()

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url=f"{settings.API_V1_STR}/docs",
    redoc_url=f"{settings.API_V1_STR}/redoc",
)

# Set all CORS enabled origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_origin_regex=r"^https?:\/\/.*$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static uploads
os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

# Mount API v1 router
app.include_router(api_router, prefix=settings.API_V1_STR)

@app.on_event("startup")
def on_startup():
    init_db()

@app.get("/health", response_model=ApiResponse[dict])
def health_check():
    return ApiResponse(
        success=True,
        data={"status": "healthy", "service": settings.PROJECT_NAME, "version": "2.4.0"},
        message="SKAGATA PKL Intelligence backend service operational."
    )

# WebSocket Connection Manager for Real-Time Telemetry & Alerts
class ConnectionManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)

    async def broadcast(self, message: dict):
        for connection in self.active_connections:
            try:
                await connection.send_text(json.dumps(message))
            except Exception:
                pass

manager = ConnectionManager()

@app.websocket("/api/v1/ws/telemetry")
async def websocket_telemetry_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        # Send initial connected greeting
        await websocket.send_text(json.dumps({
            "type": "CONNECTION_ESTABLISHED",
            "status": "WS LIVE",
            "message": "Terhubung ke Skagata Live Telemetry WebSocket Server"
        }))
        while True:
            data = await websocket.receive_text()
            # Echo or process client ping
            try:
                payload = json.loads(data)
                if payload.get("type") == "PING":
                    await websocket.send_text(json.dumps({"type": "PONG", "status": "WS LIVE"}))
            except Exception:
                pass
    except WebSocketDisconnect:
        manager.disconnect(websocket)

# Mount Flutter Web App build if available
web_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "mobile", "build", "web")
if os.path.exists(web_dir):
    app.mount("/", StaticFiles(directory=web_dir, html=True), name="flutter_web")
