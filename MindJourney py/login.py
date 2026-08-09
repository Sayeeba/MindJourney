from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import pymysql
import bcrypt

# Set the prefix so the route automatically becomes /api/login
router = APIRouter(prefix="/api", tags=["Auth"])

class LoginRequest(BaseModel):
    email: str
    password: str

@router.post("/login")
def login_user(request: LoginRequest):
    try:
        connection = pymysql.connect(
            host='localhost',
            user='root',         
            password='',         
            database='MindJourney', 
            cursorclass=pymysql.cursors.DictCursor
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database connection failed: {str(e)}")

    try:
        with connection.cursor() as cursor:
            sql = "SELECT user_id, full_name, password_hash FROM users WHERE email = %s"
            cursor.execute(sql, (request.email,))
            user = cursor.fetchone()

            if not user:
                raise HTTPException(status_code=401, detail="Invalid email or password.")

            # DEBUG STATEMENTS
            print(f"DEBUG - Email provided: '{request.email}'")
            print(f"DEBUG - Hash from DB: {user['password_hash']}")
            print(f"DEBUG - Hash Length: {len(user['password_hash'])}")

            plain_password_bytes = request.password.encode('utf-8')
            hashed_password_bytes = user['password_hash'].encode('utf-8')
            
            if bcrypt.checkpw(plain_password_bytes, hashed_password_bytes):
                return {
                    "status": "success", 
                    "user_id": user['user_id'],
                    "full_name": user['full_name']
                }
            else:
                raise HTTPException(status_code=401, detail="Invalid email or password.")
                
    finally:
        connection.close()