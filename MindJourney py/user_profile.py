from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from sqlalchemy import create_engine, Column, Integer, String, DateTime
from sqlalchemy.orm import declarative_base, sessionmaker

router = APIRouter()

# Setup Database connection (Matching your main.py setup)
DATABASE_URL = "mysql+mysqlconnector://root:@localhost/MindJourney"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Define the User model for the database table
class User(Base):
    __tablename__ = "users"
    user_id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String)
    email = Column(String)
    age = Column(Integer)
    gender = Column(String)
    created_at = Column(DateTime)

# Dependency to get the DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/api/profile/{user_id}")
def get_profile(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == user_id).first()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Format the joined date nicely (e.g., "August 2026")
    joined_date = user.created_at.strftime("%B %Y") if user.created_at else "Unknown"
    
    return {
        "full_name": user.full_name,
        "email": user.email,
        "age": user.age if user.age else 0,
        "gender": user.gender if user.gender else "Unknown",
        "joined_date": joined_date
    }