import glob, os
from fastapi import APIRouter, HTTPException
import sqlite3
from db import DB_NAME

stories_router = APIRouter()

AUDIO_FOLDER = "audio_files"

def get_story_audio_files(storyID: int):
    story_folder = os.path.join(AUDIO_FOLDER, str(storyID))
    if not os.path.exists(story_folder):
        return []
    return sorted(glob.glob(os.path.join(story_folder, "turn*.mp3")))

@stories_router.get("/history/{userID}")
def story_history(userID: int):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute("SELECT storyID, genre, preferences, prompt, generated_story FROM stories WHERE userID=?", (userID,))
    rows = c.fetchall()
    conn.close()
    
    stories = []
    for r in rows:
        storyID = r[0]
        audio_files = get_story_audio_files(storyID)
        stories.append({
            "storyID": storyID,
            "genre": r[1],
            "preferences": r[2],
            "prompt": r[3],
            "generated_story": r[4],
            "audio_files": audio_files
        })
    return {"stories": stories}

@stories_router.get("/replay/{storyID}")
def replay_story(storyID: int):
    audio_files = get_story_audio_files(storyID)
    if not audio_files:
        raise HTTPException(status_code=404, detail="No audio for this story")

    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute("SELECT generated_story FROM stories WHERE storyID=?", (storyID,))
    row = c.fetchone()
    conn.close()
    if not row:
        raise HTTPException(status_code=404, detail="Story not found")

    return {"storyID": storyID, "text": row[0], "audio_files": audio_files}
