from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel

class AuditLogResponse(BaseModel):
    id: int
    timestamp: datetime
    actor_id: Optional[int] = None
    actor_name: str
    actor_role: str
    action: str
    module: str
    target_type: Optional[str] = None
    target_id: Optional[str] = None
    description: str
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    metadata_json: Optional[str] = None

    class Config:
        from_attributes = True

class AuditLogListResponse(BaseModel):
    items: List[AuditLogResponse]
    total: int
