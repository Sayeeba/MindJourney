from fastapi import APIRouter, HTTPException

from activities_api import JoinRequest, SERVICES, activities
from api_common import database

router = APIRouter(prefix="/api/community-service", tags=["Community Service"])


@router.get("/{user_id}")
def community_service(user_id: int):
    return activities(SERVICES, "service_signups", user_id)


@router.post("/{service_id}/join")
def join_service(service_id: str, payload: JoinRequest):
    if service_id not in {service["id"] for service in SERVICES}:
        raise HTTPException(404, "Opportunity not found")
    with database() as db:
        db.execute("INSERT OR IGNORE INTO service_signups (user_id, service_id) VALUES (?, ?)", (payload.user_id, service_id))
    return {"message": "You're signed up to help"}
