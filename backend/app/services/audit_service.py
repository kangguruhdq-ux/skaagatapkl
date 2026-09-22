import json
from typing import Optional, Any
from sqlalchemy.orm import Session
from app.models.audit_log import AuditLog

def log_activity(
    db: Session,
    actor_id: Optional[int],
    actor_name: str,
    actor_role: str,
    action: str,
    module: str,
    description: str,
    target_type: Optional[str] = None,
    target_id: Optional[str] = None,
    ip_address: Optional[str] = None,
    user_agent: Optional[str] = None,
    metadata: Optional[dict[str, Any]] = None
) -> AuditLog:
    entry = AuditLog(
        actor_id=actor_id,
        actor_name=actor_name,
        actor_role=actor_role,
        action=action,
        module=module,
        description=description,
        target_type=target_type,
        target_id=str(target_id) if target_id is not None else None,
        ip_address=ip_address,
        user_agent=user_agent,
        metadata_json=json.dumps(metadata) if metadata else None,
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry
