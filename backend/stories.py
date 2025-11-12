# import glob, os
# from fastapi import APIRouter, HTTPException
# import sqlite3
# from db import DB_NAME

# stories_router = APIRouter()

# AUDIO_FOLDER = "audio_files"

# def get_story_audio_files(storyID: int):
#     story_folder = os.path.join(AUDIO_FOLDER, str(storyID))
#     if not os.path.exists(story_folder):
#         return []
#     return sorted(glob.glob(os.path.join(story_folder, "turn*.mp3")))

# @stories_router.get("/history/{userID}")
# def story_history(userID: int):
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
#     c.execute("SELECT storyID, genre, preferences, prompt, generated_story FROM stories WHERE userID=?", (userID,))
#     rows = c.fetchall()
#     conn.close()
    
#     stories = []
#     for r in rows:
#         storyID = r[0]
#         audio_files = get_story_audio_files(storyID)
#         stories.append({
#             "storyID": storyID,
#             "genre": r[1],
#             "preferences": r[2],
#             "prompt": r[3],
#             "generated_story": r[4],
#             "audio_files": audio_files
#         })
#     return {"stories": stories}

# @stories_router.get("/replay/{storyID}")
# def replay_story(storyID: int):
#     audio_files = get_story_audio_files(storyID)
#     if not audio_files:
#         raise HTTPException(status_code=404, detail="No audio for this story")

#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
#     c.execute("SELECT generated_story FROM stories WHERE storyID=?", (storyID,))
#     row = c.fetchone()
#     conn.close()
#     if not row:
#         raise HTTPException(status_code=404, detail="Story not found")

#     return {"storyID": storyID, "text": row[0], "audio_files": audio_files}
# (محتوى ملف backend/stories.py المعدل بالكامل)

import glob, os
from fastapi import APIRouter, HTTPException
import sqlite3
from db import DB_NAME, get_user_id_for_story # (1) استيراد الدالة الجديدة

stories_router = APIRouter()

AUDIO_FOLDER = "audio_files"

# (2) تعديل: الدالة صارت تستقبل userID
def get_story_audio_files(userID: int, storyID: int):
    # (3) تعديل: استخدام المسار الصحيح الذي يحتوي على userID
    story_folder = os.path.join(AUDIO_FOLDER, str(userID), str(storyID))
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
        # (4) تعديل: تمرير الـ userID للدالة
        audio_files = get_story_audio_files(userID, storyID)
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
    conn = sqlite3.connect(DB_NAME)
    
    # (5) تعديل: جلب الـ userID أولاً
    userID = get_user_id_for_story(conn, storyID)
    if not userID:
        conn.close()
        raise HTTPException(status_code=404, detail="User for this story not found")

    # (6) تعديل: تمرير الـ userID للدالة
    audio_files = get_story_audio_files(userID, storyID)
    if not audio_files:
        conn.close()
        # هذا هو الخطأ 404 الذي كان يظهر لك
        raise HTTPException(status_code=404, detail="No audio for this story (path issue fixed)")

    c = conn.cursor()
    c.execute("SELECT generated_story FROM stories WHERE storyID=?", (storyID,))
    row = c.fetchone()
    conn.close()
    if not row:
        raise HTTPException(status_code=404, detail="Story not found")

    # (7) إرجاع القصة كاملة (الكود الجديد يفترض إرجاع الأحداث)
    # هذا الرد هو مثال بسيط، كود التطبيق الجديد يتوقع رد مختلف
    # لكن هذا سيحل مشكلة الـ 404 المبدئية
    
    # سنرجع أول ملف صوتي والنص
    # (ملاحظة: كود التطبيق الأخير يتوقع JSON معقد، لكن لنصلح الـ 404 أولاً)
    return {
        "storyID": storyID, 
        "text": row[0], 
        "audio_files": audio_files,
        # (مثال لرد متوافق مع الكود الأخير في story_progress.dart)
        "events": [
            {
                "text": row[0].split("\n\n")[0], # إرجاع الجزء الأول من النص
                "audio_url": audio_files[0], # إرجاع أول ملف صوتي
                "required_move": "TILTZ", # (هذا يجب أن يُحفظ في الداتابيس)
                "story_end": False
            }
        ]
        }