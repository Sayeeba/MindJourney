from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from api_common import database, rows

router = APIRouter(prefix="/api/emergency", tags=["Emergency Services"])
EMERGENCY_SERVICES = [
    {"name": "National emergency", "number": "999", "description": "Police, fire, and ambulance emergency response in Bangladesh."},
    {"name": "Kaan Pete Roi", "number": "09612-119911", "description": "Emotional support helpline. Check availability before calling."},
]


class EmergencyContactRequest(BaseModel):
    user_id: int
    name: str = Field(min_length=1)
    relationship: str = Field(min_length=1)
    phone: str = Field(min_length=3)


@router.get("/{user_id}")
def emergency(user_id: int):
    with database() as db:
        contacts = rows(db.execute("SELECT contact_id, name, relationship, phone FROM emergency_contacts WHERE user_id = ? ORDER BY contact_id DESC", (user_id,)))
    return {"services": EMERGENCY_SERVICES, "contacts": contacts}


@router.post("/contacts")
def emergency_contact(payload: EmergencyContactRequest):
    with database() as db:
        if db.execute("SELECT 1 FROM users WHERE user_id = ?", (payload.user_id,)).fetchone() is None:
            raise HTTPException(404, "User not found")
        cursor = db.execute("INSERT INTO emergency_contacts (user_id, name, relationship, phone) VALUES (?, ?, ?, ?)", (payload.user_id, payload.name.strip(), payload.relationship.strip(), payload.phone.strip()))
    return {"message": "Emergency contact saved", "id": cursor.lastrowid}
