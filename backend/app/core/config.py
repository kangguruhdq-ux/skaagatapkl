import os
from typing import List, Union

class Settings:
    PROJECT_NAME: str = "SKAGATA PKL Intelligence"
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = os.getenv("SECRET_KEY", "skagata-super-secret-production-jwt-key-smkn3-yogyakarta")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 1 day
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    _BASE_DIR: str = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    _DB_PATH: str = os.path.join(_BASE_DIR, "skagata_pkl.db").replace("\\", "/")
    DATABASE_URL: str = os.getenv("DATABASE_URL", f"sqlite:///{_DB_PATH}")
    UPLOAD_DIR: str = os.getenv("UPLOAD_DIR", os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "uploads")))
    
    # Geofence settings for SMKN 3 Yogyakarta and Primary DUDI (Telkom Witel Yogyakarta Kotabaru)
    DEFAULT_TELKOM_LAT: float = -7.78542
    DEFAULT_TELKOM_LON: float = 110.37219
    DEFAULT_GEOFENCE_RADIUS: float = 100.0  # meters

    BACKEND_CORS_ORIGINS: List[str] = ["*"]

settings = Settings()
os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
