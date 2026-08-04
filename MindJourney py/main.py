from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String, Text, DateTime
from sqlalchemy.orm import declarative_base, sessionmaker, Session
from datetime import datetime
import uvicorn

import register # Your external router
import chatbot
import dashboard

app = FastAPI(title="Mind Journey API")

# Include Routers
app.include_router(register.router)
app.include_router(chatbot.router)
app.include_router(dashboard.router)

# 1. Database Configuration
# Using mysql+mysqlconnector ensures SQLAlchemy uses your existing driver
DATABASE_URL = "mysql+mysqlconnector://root:@localhost/MindJourney"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# 2. SQLAlchemy Model (Database Table Structure)
class JournalEntry(Base):
    __tablename__ = "journal_entries"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), index=True)
    content = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)

# 3. Pydantic Schema (For API Response Validation)
class JournalResponse(BaseModel):
    id: int
    title: str | None = None
    content: str | None = None
    created_at: datetime | None = None
    
    class Config:
        from_attributes = True # Tells Pydantic to read data from the SQLAlchemy ORM model

# 4. FastAPI Setup
app = FastAPI(title="Mind Journey API")
app.include_router(register.router)

# 5. Database Dependency Injection
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 6. Routes
@app.get("/")
def home():
    return {"message": "MindJourney Python Backend is running!"}

@app.get("/api/journals", response_model=list[JournalResponse])
def get_journals(db: Session = Depends(get_db)):
    try:
        # Use SQLAlchemy to query all entries instead of raw SQL strings
        entries = db.query(JournalEntry).all()
        return entries
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == '__main__':
    uvicorn.run("main:app", host='0.0.0.0', port=5001, reload=True)