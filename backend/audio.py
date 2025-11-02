import glob
import os
import uuid
from fastapi import APIRouter, HTTPException, Request
from gtts import gTTS

audio_router = APIRouter()
AUDIO_FOLDER = "audio_files"
os.makedirs(AUDIO_FOLDER, exist_ok=True)

def generate_audio(text: str, userID: int, storyID: int, turn: int):
    """
    توليد ملف صوتي لكل فقرة من القصة وحفظه داخل فولدر القصة.
    """
    story_folder = os.path.join(AUDIO_FOLDER, str(userID), str(storyID))
    os.makedirs(story_folder, exist_ok=True)

    file_name = f"turn{turn}_{uuid.uuid4().hex}.mp3"
    path = os.path.join(story_folder, file_name)

    try:
        tts = gTTS(text=text, lang="ar")
        tts.save(path)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"TTS error: {str(e)}")
    
    return path

@audio_router.get("/audio/{userID}/{storyID}")
def get_story_audio(userID: int, storyID: int, request: Request):
    """
    ترجع قائمة ملفات الصوت كروابط URL جاهزة للتحميل أو التشغيل.
    """
    story_folder = os.path.join(AUDIO_FOLDER, str(userID), str(storyID))
    if not os.path.exists(story_folder):
        raise HTTPException(status_code=404, detail="No audio files found")

    files = sorted(glob.glob(os.path.join(story_folder, "*.mp3")))
    if not files:
        raise HTTPException(status_code=404, detail="No audio files found")

    base_url = str(request.base_url).rstrip("/")
    return {
        "audio_files": [
            f"{base_url}/audio_files/{userID}/{storyID}/{os.path.basename(f)}"
            for f in files
        ]
    }