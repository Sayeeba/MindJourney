import bcrypt
from fastapi import APIRouter, HTTPException
import mysql.connector
from pydantic import BaseModel

router = APIRouter(prefix="/api", tags=["Authentication"])

def get_db_connection():
    return mysql.connector.connect(
        host="127.0.0.1",
        port=3306,
        user="root",
        password="",
        database="MindJourney",
    )

class RegisterRequest(BaseModel):
    name: str
    email: str
    age: int
    gender: str
    password: str

class LoginRequest(BaseModel):
    email: str
    password: str

def hash_password(password: str) -> str:
    pwd_bytes = password.encode("utf-8")
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(pwd_bytes, salt).decode("utf-8")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(
        plain_password.encode("utf-8"), hashed_password.encode("utf-8")
    )

@router.post("/register")
def register_user(data: RegisterRequest):
    print(f"\n1️⃣ Received registration request for: {data.email}")
    conn = None
    try:
        print("2️⃣ Connecting to MySQL...")
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        print("3️⃣ Checking existing email...")
        cursor.execute("SELECT * FROM users WHERE email = %s", (data.email,))
        if cursor.fetchone():
            print("⚠️ Email already registered.")
            raise HTTPException(
                status_code=400, detail="This email is already registered."
            )

        print("4️⃣ Hashing password...")
        hashed_pwd = hash_password(data.password)

        print("5️⃣ Inserting into database...")
        query = """
            INSERT INTO users (full_name, email, age, gender, password_hash)
            VALUES (%s, %s, %s, %s, %s)
        """
        cursor.execute(
            query, (data.name, data.email, data.age, data.gender, hashed_pwd)
        )
        conn.commit()

        cursor.close()
        print("6️⃣ Registration success!\n")
        return {"message": "User registered successfully"}

    except HTTPException:
        raise
    except Exception as err:
        print(f"\n❌ FAILED AT STEP ABOVE. ERROR DETAILS: {err}\n")
        raise HTTPException(status_code=500, detail=str(err))
    finally:
        if conn and conn.is_connected():
            conn.close()


@router.post("/login")
def login_user(data: LoginRequest):
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("SELECT * FROM users WHERE email = %s", (data.email,))
        user = cursor.fetchone()

        if not user or not verify_password(data.password, user["password_hash"]):
            raise HTTPException(
                status_code=401, detail="Invalid email or password."
            )

        cursor.close()
        return {
            "message": "Login successful",
            "user_id": user["user_id"],
            "name": user["full_name"],
        }

    except HTTPException:
        raise
    except Exception as err:
        print(f"\n❌ BACKEND LOGIN ERROR: {err}\n")
        raise HTTPException(status_code=500, detail=str(err))
    finally:
        if conn and conn.is_connected():
            conn.close()