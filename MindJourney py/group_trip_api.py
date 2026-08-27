from fastapi import APIRouter, HTTPException

from activities_api import JoinRequest, TRIPS, activities
from api_common import database

router = APIRouter(prefix="/api/trips", tags=["Group Trips"])


@router.get("/{user_id}")
def trips(user_id: int):
    return activities(TRIPS, "trip_rsvps", user_id)


@router.post("/{trip_id}/join")
def join_trip(trip_id: str, payload: JoinRequest):
    if trip_id not in {trip["id"] for trip in TRIPS}:
        raise HTTPException(404, "Trip not found")
    with database() as db:
        db.execute("INSERT OR IGNORE INTO trip_rsvps (user_id, trip_id) VALUES (?, ?)", (payload.user_id, trip_id))
    return {"message": "You're on the trip list"}
