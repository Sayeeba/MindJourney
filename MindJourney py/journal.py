from datetime import datetime
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict
from sqlalchemy import create_engine, Column, Integer, String, Text, DateTime
from sqlalchemy.orm import declarative_base, sessionmaker, Session

router = APIRouter(prefix="/api", tags=["App Backend"])

# 1. Database Connection (XAMPP MySQL)
DATABASE_URL = "mysql+mysqlconnector://root:@localhost/MindJourney"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# 2. Database Model
class DBJournalEntry(Base):
    __tablename__ = "journal_entries"

    id = Column("journal_id", Integer, primary_key=True, index=True)
    user_id = Column("user_id", Integer, index=True)
    title = Column(String(255), index=True)
    content = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)

# 3. Pydantic Schemas (user_id changed from str to int)
class JournalCreate(BaseModel):
    user_id: int
    title: str
    content: str

class JournalResponse(BaseModel):
    id: int
    user_id: int
    title: str
    content: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class InsightResponse(BaseModel):
    title: str
    message: str
    button_title: str
    action_type: str

# 4. Database Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 5. Insight Endpoint (Fixes 404 error from HomeView)
@router.get("/home/insight/{user_id}", response_model=InsightResponse)
def get_user_insight(user_id: int):
    return {
        "title": "✨ Pattern Detected",
        "message": "Based on your recent entries, you have been tracking your thoughts consistently!",
        "button_title": "Try a Meditation",
        "action_type": "meditation"
    }

# 6. Journal Endpoints
@router.post("/journal", response_model=JournalResponse)
def create_journal(entry: JournalCreate, db: Session = Depends(get_db)):
    try:
        new_entry = DBJournalEntry(
            user_id=entry.user_id,
            title=entry.title,
            content=entry.content
        )
        db.add(new_entry)
        db.commit()
        db.refresh(new_entry)
        return new_entry
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/journal", response_model=List[JournalResponse])
def get_all_journals(db: Session = Depends(get_db)):
    return db.query(DBJournalEntry).order_by(DBJournalEntry.created_at.desc()).all()

@router.get("/journal/{user_id}", response_model=List[JournalResponse])
def get_user_journals(user_id: int, db: Session = Depends(get_db)):
    return db.query(DBJournalEntry).filter(DBJournalEntry.user_id == user_id).order_by(DBJournalEntry.created_at.desc()).all()