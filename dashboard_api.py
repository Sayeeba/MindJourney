from fastapi import APIRouter

from api_common import database, rows

router = APIRouter(prefix="/api/dashboard", tags=["Dashboard"])


@router.get("/mood-graph/{user_id}")
def dashboard(user_id: int):
    with database() as db:
        logs = rows(db.execute(
            "SELECT id, mood, timestamp FROM mood_logs WHERE user_id = ? ORDER BY timestamp ASC",
            (user_id,),
        ))
    counts = {}
    for item in logs:
        counts[item["mood"]] = counts.get(item["mood"], 0) + 1
    insight = "No mood logs recorded yet. Start with a quick check-in on Home."
    if logs:
        insight = f"You have logged {len(logs)} check-ins. Your most frequent mood is {max(counts, key=counts.get)}."
    return {"user_id": str(user_id), "total_logs": len(logs), "graph_data": logs, "mood_counts": counts, "ai_insight": insight}
