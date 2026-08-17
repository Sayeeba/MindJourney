import os
import pymysql
import traceback
from typing import List
from dotenv import load_dotenv
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, ConfigDict
from google import genai
from google.genai import types

# Load environment variables
load_dotenv()
def save_chat_to_db(user_id: int, user_msg: str, bot_reply: str):
    try:
        connection = pymysql.connect(
            host='127.0.0.1',
            port=3306,
            user='root',
            password='',
            database='MindJourney',
            cursorclass=pymysql.cursors.DictCursor
        )
        with connection.cursor() as cursor:
            sql = "INSERT INTO chat_history (user_id, user_message, bot_response) VALUES (%s, %s, %s)"
            cursor.execute(sql, (user_id, user_msg, bot_reply))
        connection.commit()
        connection.close()
        print("Successfully saved chat to database!")
    except Exception as e:
        print(f"Database Save Error: {e}")

router = APIRouter(prefix="/api/chat", tags=["ChatBot"])

# Initialize Gemini Client using the new SDK
api_key = os.getenv("GEMINI_API_KEY")
client = genai.Client(api_key=api_key) if api_key else None

SYSTEM_INSTRUCTION = """
You are MindJourney AI, a compassionate, insightful, and supportive emotional well-being companion. 

Your Core Interaction Rules:
1. Active Listening & Open Questions: Always validate the user's feelings first, then gently encourage them to share more by asking an open-ended, non-pressuring question at the end of your response (e.g., "If you feel comfortable, what was going through your mind last night?", "Do you want to talk about what brought those feelings on?").
2. Natural & Human-Like Tone: Speak like a caring, grounded friend. Avoid generic corporate speak, overly formal templates, or forced sympathy. 
3. Maintain Persona Always: NEVER break character or mention backend tech, software, code, servers, or "system hiccups." Even if the user asks about errors, stay in your supportive persona and focus entirely on their well-being.
4. Grounding & Mindfulness: Offer simple grounding techniques (like 5-4-3-2-1 or box breathing) only when the user expresses feeling overwhelmed or out of control.

Safety Boundary:
- You are an empathetic companion, NOT a licensed medical professional or therapist.
- If a user expresses intent for self-harm, suicide, or severe crisis, immediately offer compassionate support alongside standard crisis resources (e.g., 988 Suicide & Crisis Lifeline in the US or global emergency equivalents).
"""

class JournalResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
class MessageContext(BaseModel):
    role: str  # "user" or "model"
    text: str

class ChatRequest(BaseModel):
    user_id: int  
    message: str
    history: List[MessageContext] = []

class ChatResponse(BaseModel):
    reply: str

@router.post("", response_model=ChatResponse)
def chat_with_ai(request: ChatRequest):
    user_msg = request.message.strip()
    
    if not user_msg:
        raise HTTPException(status_code=400, detail="Message content cannot be empty.")

    # Fallback response if GEMINI_API_KEY is not configured
    if not client:
        return {
            "reply": "I'm currently running in offline mode. Please configure GEMINI_API_KEY to unlock full intelligence."
        }

    try:
        # Build conversation history for Gemini
        formatted_contents = []
        for h in request.history:
            formatted_contents.append(
                types.Content(
                    role=h.role,
                    parts=[types.Part.from_text(text=h.text)]
                )
            )
        
        # Ensure history starts with a 'user' turn
        while formatted_contents and formatted_contents[0].role == "model":
            formatted_contents.pop(0)

        # Append latest user input
        formatted_contents.append(
            types.Content(
                role="user",
                parts=[types.Part.from_text(text=user_msg)]
            )
        )

        # Call Gemini Model
        response = client.models.generate_content(
            model="gemini-3.5-flash",
            contents=formatted_contents,
            config=types.GenerateContentConfig(
                system_instruction=SYSTEM_INSTRUCTION,
                temperature=0.7,
                top_p=0.9,
                max_output_tokens=2048,  # Increased limit so text never cuts off
                thinking_config=types.ThinkingConfig(
                    thinking_budget=0    # Disables internal thinking tokens
                ),
                safety_settings=[
                    types.SafetySetting(
                        category="HARM_CATEGORY_DANGEROUS_CONTENT",
                        threshold="BLOCK_NONE"
                    ),
                    types.SafetySetting(
                        category="HARM_CATEGORY_HARASSMENT",
                        threshold="BLOCK_NONE"
                    ),
                    types.SafetySetting(
                        category="HARM_CATEGORY_HATE_SPEECH",
                        threshold="BLOCK_NONE"
                    ),
                    types.SafetySetting(
                        category="HARM_CATEGORY_SEXUALLY_EXPLICIT",
                        threshold="BLOCK_NONE"
                    )
                ]
            )
        )

        # Extract text response, ignoring internal thinking steps
        final_reply = ""
        if response.candidates and response.candidates[0].content.parts:
            for part in response.candidates[0].content.parts:
                text_content = getattr(part, 'text', None)
                if text_content:
                    final_reply += text_content

        # Fallback if text parsing yields empty string
        if not final_reply.strip():
            final_reply = response.text
            # Save both messages to the database at the same time
        save_chat_to_db(user_id=request.user_id, user_msg=user_msg, bot_reply=final_reply.strip())
        
        return {"reply": final_reply.strip()}

    except Exception as e:
        print(f"Gemini API Error: {e}")
        raise HTTPException(status_code=500, detail="Failed to reach MindJourney AI backend.")