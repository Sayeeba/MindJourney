from fastapi import APIRouter, HTTPException
import mysql.connector
from datetime import datetime
from collections import Counter

router = APIRouter(prefix="/api/dashboard", tags=["Dashboard"])

# MySQL Database Connection Helper
def get_db_connection():
    return mysql.connector.connect(
        host='localhost',
        user='root',
        password='',
        database='MindJourney'
    )

@router.get("/mood-graph/{user_id}")
def get_mood_graph_data(user_id: str):
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Query mood entries chronologically for line/bar charts
        query = """
            SELECT id, mood, timestamp 
            FROM mood_logs 
            WHERE user_id = %s 
            ORDER BY timestamp ASC
        """
        cursor.execute(query, (user_id,))
        rows = cursor.fetchall()
        cursor.close()

        if not rows:
            return {
                "user_id": user_id,
                "total_logs": 0,
                "graph_data": [],
                "mood_counts": {},
                "ai_insight": "No mood logs found. Log your feelings daily on the Home screen to build your emotional pattern graph!"
            }

        # Format timeline entries for charting libraries
        graph_data = [
            {
                "id": row["id"],
                "mood": row["mood"],
                "timestamp": row["timestamp"].strftime("%Y-%m-%d %H:%M") if isinstance(row["timestamp"], datetime) else str(row["timestamp"])
            }
            for row in rows
        ]

        # Calculate frequencies for pie charts / breakdown lists
        mood_list = [row["mood"] for row in rows]
        mood_counts = dict(Counter(mood_list))

        # Generate AI pattern insight based on logged data
        total_logs = len(mood_list)
        most_frequent_mood = max(mood_counts, key=mood_counts.get)
        
        if most_frequent_mood in ["Sad", "Anxious"]:
            ai_insight = (
                f"Across your last {total_logs} logs, your most common state was '{most_frequent_mood}'. "
                "Our pattern detector suggests scheduling a 5-minute guided evening meditation or trying a quiet stay in Safe Haven."
            )
        elif most_frequent_mood in ["Happy", "Calm"]:
            ai_insight = (
                f"Great progress! You've mostly been feeling '{most_frequent_mood}' over your last {total_logs} logs. "
                "Keep continuing your current positive routines and daily reflection!"
            )
        else:
            ai_insight = (
                f"You have logged {total_logs} mood entries with a balanced emotion spectrum. "
                "Writing a quick journal entry can help identify subtle triggers behind your 'Okay' days."
            )

        return {
            "user_id": user_id,
            "total_logs": total_logs,
            "graph_data": graph_data,
            "mood_counts": mood_counts,
            "ai_insight": ai_insight
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn and conn.is_connected():
            conn.close()