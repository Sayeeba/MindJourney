from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import os

# Create APIRouter instance
router = APIRouter(prefix="/api/chat", tags=["ChatBot"])

class ChatRequest(BaseModel):
    user_id: str
    message: str

class ChatResponse(BaseModel):
    reply: str

@router.post("", response_model=ChatResponse)
def chat_with_ai(request: ChatRequest):
    user_msg = request.message.strip()
    
    if not user_msg:
        raise HTTPException(status_code=400, detail="Message content cannot be empty.")
    
   
    OPTIONAL: Live OpenAI/LLM API Integration
    Uncomment and set OPENAI_API_KEY environment variable to enable live AI responses.
    
    try:
        import openai
        openai.api_key = os.getenv("OPENAI_API_KEY")
        completion = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[
                {
                    "role": "system",
                    "content": "You are a warm, compassionate mental health chatbot named MindJourney AI. "
                               "Provide supportive, non-judgmental, and encouraging responses."
                 },
                {"role": "user", "content": user_msg}
            ]
       )
         return {"reply": completion.choices[0].message.content}
     except Exception as e:
        pass
   

    Rule-Based Fallback Responses for testing without API keys
    reply = f"Thank you for reaching out and sharing. I hear that you're expressing: '{user_msg}'. Please know that your feelings are completely valid, and you don't have to navigate this alone."
    
    return {"reply": reply}