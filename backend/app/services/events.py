import json
from app.models.audit_log import AuditLog
from app.models.notification import NotificationItem


def audit(db, actor, action, module, target_id, metadata=None):
    # Caller commits the event and entity in one transaction.
    db.add(AuditLog(actor_id=actor.id, actor_name=actor.full_name,
        actor_role=actor.role.value, action=action, module=module,
        target_type=module, target_id=str(target_id), description=action,
        metadata_json=json.dumps(metadata or {}, default=str)))


def notify(db, user_id, title, message, route):
    db.add(NotificationItem(user_id=user_id, title=title, message=message,
                            action_route=route, type='info'))
