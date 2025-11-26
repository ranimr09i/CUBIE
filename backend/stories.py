
# import glob, os
# from fastapi import APIRouter, HTTPException
# import sqlite3
# from db import DB_NAME, get_user_id_for_story # (1) استيراد الدالة الجديدة

# stories_router = APIRouter()

# AUDIO_FOLDER = "audio_files"

# # (2) تعديل: الدالة صارت تستقبل userID
# def get_story_audio_files(userID: int, storyID: int):
#     # (3) تعديل: استخدام المسار الصحيح الذي يحتوي على userID
#     story_folder = os.path.join(AUDIO_FOLDER, str(userID), str(storyID))
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
#         # (4) تعديل: تمرير الـ userID للدالة
#         audio_files = get_story_audio_files(userID, storyID)
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
#     conn = sqlite3.connect(DB_NAME)
    
#     # (5) تعديل: جلب الـ userID أولاً
#     userID = get_user_id_for_story(conn, storyID)
#     if not userID:
#         conn.close()
#         raise HTTPException(status_code=404, detail="User for this story not found")

#     # (6) تعديل: تمرير الـ userID للدالة
#     audio_files = get_story_audio_files(userID, storyID)
#     if not audio_files:
#         conn.close()
#         # هذا هو الخطأ 404 الذي كان يظهر لك
#         raise HTTPException(status_code=404, detail="No audio for this story (path issue fixed)")

#     c = conn.cursor()
#     c.execute("SELECT generated_story FROM stories WHERE storyID=?", (storyID,))
#     row = c.fetchone()
#     conn.close()
#     if not row:
#         raise HTTPException(status_code=404, detail="Story not found")

#     # (7) إرجاع القصة كاملة (الكود الجديد يفترض إرجاع الأحداث)
#     # هذا الرد هو مثال بسيط، كود التطبيق الجديد يتوقع رد مختلف
#     # لكن هذا سيحل مشكلة الـ 404 المبدئية
    
#     # سنرجع أول ملف صوتي والنص
#     # (ملاحظة: كود التطبيق الأخير يتوقع JSON معقد، لكن لنصلح الـ 404 أولاً)
#     return {
#         "storyID": storyID, 
#         "text": row[0], 
#         "audio_files": audio_files,
#         # (مثال لرد متوافق مع الكود الأخير في story_progress.dart)
#         "events": [
#             {
#                 "text": row[0].split("\n\n")[0], # إرجاع الجزء الأول من النص
#                 "audio_url": audio_files[0], # إرجاع أول ملف صوتي
#                 "required_move": "TILTZ", # (هذا يجب أن يُحفظ في الداتابيس)
#                 "story_end": False
#             }
#         ]
#         }
import glob, os
from fastapi import APIRouter, HTTPException, Request
import sqlite3
from db import DB_NAME, get_user_id_for_story

stories_router = APIRouter()

AUDIO_FOLDER = "audio_files"

def get_story_audio_files(userID: int, storyID: int):
    """
    جلب جميع ملفات الصوت للقصة (مرتبة حسب رقم الدور)
    """
    story_folder = os.path.join(AUDIO_FOLDER, str(userID), str(storyID))
    if not os.path.exists(story_folder):
        return []
    
    files = glob.glob(os.path.join(story_folder, "turn*.mp3"))
    
    # ترتيب الملفات حسب رقم الدور
    def get_turn_number(filename):
        basename = os.path.basename(filename)
        try:
            return int(basename.split('_')[0].replace('turn', ''))
        except:
            return 0
    
    return sorted(files, key=get_turn_number)

@stories_router.get("/history/{userID}")
def story_history(userID: int, request: Request):
    """
    جلب تاريخ القصص مع روابط الصوت الكاملة
    """
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute("SELECT storyID, genre, preferences, prompt, generated_story FROM stories WHERE userID=?", (userID,))
    rows = c.fetchall()
    conn.close()
    
    base_url = str(request.base_url).rstrip("/")
    stories = []
    
    for r in rows:
        storyID = r[0]
        audio_files = get_story_audio_files(userID, storyID)
        
        # تحويل المسارات المحلية إلى URLs
        audio_urls = [
            f"{base_url}/audio_files/{userID}/{storyID}/{os.path.basename(f)}"
            for f in audio_files
        ]
        
        stories.append({
            "storyID": storyID,
            "genre": r[1],
            "preferences": r[2],
            "prompt": r[3],
            "generated_story": r[4],
            "audio_files": audio_urls  # روابط جاهزة للاستخدام
        })
    
    return {"stories": stories}

@stories_router.get("/replay/{storyID}")
def replay_story(storyID: int, request: Request):
    """
    إرجاع جميع أحداث القصة مع الصوت (للتشغيل المباشر أو التاريخ)
    """
    conn = sqlite3.connect(DB_NAME)
    
    # جلب userID
    userID = get_user_id_for_story(conn, storyID)
    if not userID:
        conn.close()
        raise HTTPException(status_code=404, detail="User for this story not found")
    
    # جلب نص القصة
    c = conn.cursor()
    c.execute("SELECT generated_story, genre FROM stories WHERE storyID=?", (storyID,))
    row = c.fetchone()
    conn.close()
    
    if not row:
        raise HTTPException(status_code=404, detail="Story not found")
    
    full_story_text = row[0]
    genre = row[1]
    
    # جلب ملفات الصوت
    audio_files = get_story_audio_files(userID, storyID)
    
    if not audio_files:
        raise HTTPException(status_code=404, detail="No audio files found for this story")
    
    # تقسيم النص إلى أجزاء (بناءً على الفقرات)
    story_parts = [part.strip() for part in full_story_text.split('\n\n') if part.strip()]
    
    # التأكد من تطابق عدد الأجزاء مع عدد ملفات الصوت
    # (إذا كان هناك اختلاف، نستخدم العدد الأقل)
    num_events = min(len(story_parts), len(audio_files))
    
    base_url = str(request.base_url).rstrip("/")
    events = []
    
    for i in range(num_events):
        audio_url = f"{base_url}/audio_files/{userID}/{storyID}/{os.path.basename(audio_files[i])}"
        
        # تحديد نوع الحركة المطلوبة (افتراضياً)
        # (يمكنك تحسين هذا بحفظ نوع الحركة في قاعدة البيانات)
        required_move = "NONE" if i == num_events - 1 else "TILTZ"
        
        events.append({
            "text": story_parts[i],
            "audio_url": audio_url,
            "required_move": required_move,
            "story_end": (i == num_events - 1)
        })
    
    return {
        "storyID": storyID,
        "genre": genre,
        "events": events
    }