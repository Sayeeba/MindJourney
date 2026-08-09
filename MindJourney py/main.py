from dotenv import load_dotenv

load_dotenv()
from typing import Optional
from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String, Text, DateTime
from sqlalchemy.orm import declarative_base, sessionmaker, Session
from datetime import datetime
import uvicorn
import pymysql

# 1. Your external routers
import register 
import chatbot
import dashboard
from login import router as login_router

# 2. Single FastAPI Instance (Declare this ONLY ONCE)
app = FastAPI(title="Mind Journey API")

# 3. Include ALL Routers
app.include_router(register.router)
app.include_router(chatbot.router)
app.include_router(dashboard.router)
app.include_router(login_router)

# 4. Database Configuration
DATABASE_URL = "mysql+mysqlconnector://root:@localhost/MindJourney"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# 5. SQLAlchemy Model
class JournalEntry(Base):
    __tablename__ = "journal_entries"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), index=True)
    content = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)

# 6. Pydantic Schema
class JournalResponse(BaseModel):
    id: int
    title: Optional[str] = None
    content: Optional[str] = None
    created_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# 7. Database Dependency Injection
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 8. Routes
@app.get("/")
def home():
    return {"message": "MindJourney Python Backend is running!"}

@app.get("/api/journals", response_model=list[JournalResponse])
def get_journals(db: Session = Depends(get_db)):
    try:
        entries = db.query(JournalEntry).all()
        return entries
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 9. Run Server (Host 0.0.0.0 for Wi-Fi, Port 8000 to match Swift!)
if __name__ == '__main__':
    uvicorn.run("main:app", host='0.0.0.0', port=8000, reload=True)