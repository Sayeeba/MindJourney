import os
from typing import List
from dotenv import load_dotenv
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, ConfigDict
from google import genai
from google.genai import types

# Load environment variables
load_dotenv()

router = APIRouter(prefix="/api/chat", tags=["ChatBot"])

# Initialize Gemini Client using the new SDK
api_key = os.getenv("GEMINI_API_KEY")
client = genai.Client(api_key=api_key) if api_key else None

SYSTEM_INSTRUCTION = """
You are MindJourney AI, a compassionate, insightful, and supportive emotional well-being companion. 

Your Role:
1. Provide active listening, validation, and emotional support with warmth and empathy.
2. Offer gentle, non-judgmental guidance and reframing techniques when appropriate.
3. Suggest simple, actionable grounding or mindfulness exercises (e.g., box breathing, 5-4-3-2-1 technique, journaling prompts) when users feel overwhelmed.
4. Keep responses grounded, authentic, thoughtful, and tailored to the user's emotional state. Avoid sounding robotic or giving generic corporate advice.

Safety Boundary:
- You are an empathetic companion, NOT a licensed medical professional or therapist.
- If a user expresses intent for self-harm, suicide, or severe crisis, immediately offer compassionate support alongside standard crisis resources (e.g., 988 Suicide & Crisis Lifeline in the US or global emergency equivalents).
"""

class JournalResponse(BaseModel):
    # If you have fields, put them here
    model_config = ConfigDict(from_attributes=True)
    
class MessageContext(BaseModel):
    role: str  # "user" or "model"
    text: str

class ChatRequest(BaseModel):
    user_id: str
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

        # Call Gemini Flash Model 
        response = client.models.generate_content(
            model="gemini-1.5-flash",
            contents=formatted_contents,
            config=types.GenerateContentConfig(
                system_instruction=SYSTEM_INSTRUCTION,
                temperature=0.7,
                top_p=0.9,
                max_output_tokens=800
            )
        )

        return {"reply": response.text}

    except Exception as e:
        print(f"Gemini API Error: {e}")
        raise HTTPException(status_code=500, detail="Failed to reach MindJourney AI backend.")