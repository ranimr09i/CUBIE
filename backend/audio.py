# import glob
# import os
# import uuid
# from fastapi import APIRouter, HTTPException, Request
# from gtts import gTTS

# audio_router = APIRouter()
# AUDIO_FOLDER = "audio_files"
# os.makedirs(AUDIO_FOLDER, exist_ok=True)

# def generate_audio(text: str, userID: int, storyID: int, turn: int):
#     """
#     توليد ملف صوتي لكل فقرة من القصة وحفظه داخل فولدر القصة.
#     """
#     story_folder = os.path.join(AUDIO_FOLDER, str(userID), str(storyID))
#     os.makedirs(story_folder, exist_ok=True)

#     file_name = f"turn{turn}_{uuid.uuid4().hex}.mp3"
#     path = os.path.join(story_folder, file_name)

#     try:
#         tts = gTTS(text=text, lang="ar")
#         tts.save(path)
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=f"TTS error: {str(e)}")
    
#     return path

# @audio_router.get("/audio/{userID}/{storyID}")
# def get_story_audio(userID: int, storyID: int, request: Request):
#     """
#     ترجع قائمة ملفات الصوت كروابط URL جاهزة للتحميل أو التشغيل.
#     """
#     story_folder = os.path.join(AUDIO_FOLDER, str(userID), str(storyID))
#     if not os.path.exists(story_folder):
#         raise HTTPException(status_code=404, detail="No audio files found")

#     files = sorted(glob.glob(os.path.join(story_folder, "*.mp3")))
#     if not files:
#         raise HTTPException(status_code=404, detail="No audio files found")

#     base_url = str(request.base_url).rstrip("/")
#     return {
#         "audio_files": [
#             f"{base_url}/audio_files/{userID}/{storyID}/{os.path.basename(f)}"
#             for f in files
#         ]
#     }

import glob
import os
import uuid
from fastapi import APIRouter, HTTPException, Request
from openai import OpenAI # تم استبدال gTTS بـ OpenAI

audio_router = APIRouter()
AUDIO_FOLDER = "audio_files"
os.makedirs(AUDIO_FOLDER, exist_ok=True)

# يفضل وضع المفتاح في متغيرات البيئة، أو يمكنك وضعه هنا مؤقتاً
# client = OpenAI(api_key="YOUR_OPENAI_API_KEY") 
# بما أنك تستخدمه في chat.py، سنفترض أن الكلاس OpenAI سيأخذ المفتاح من البيئة أو يمكنك تمريره هنا
client = OpenAI(api_key="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")

def generate_audio(text: str, userID: int, storyID: int, turn: int):
    """
    توليد ملف صوتي باستخدام OpenAI TTS وحفظه داخل مجلد القصة.
    """
    story_folder = os.path.join(AUDIO_FOLDER, str(userID), str(storyID))
    os.makedirs(story_folder, exist_ok=True)

    file_name = f"turn{turn}_{uuid.uuid4().hex}.mp3"
    path = os.path.join(story_folder, file_name)

    try:
        # استخدام نموذج tts-1 للسرعة، أو tts-1-hd للجودة العالية
        # الأصوات المتاحة: alloy, echo, fable, onyx, nova, shimmer
        # nova و shimmer أصوات نسائية وتناسب قصص الأطفال
        # alloy صوت محايد وممتاز
        response = client.audio.speech.create(
            model="tts-1",
            voice="nova", 
            input=text
        )
        
        # حفظ الملف الصوتي
        response.stream_to_file(path)
        
    except Exception as e:
        print(f"Error producing audio: {e}")
        raise HTTPException(status_code=500, detail=f"OpenAI TTS error: {str(e)}")
    
    return path

@audio_router.get("/audio/{userID}/{storyID}")
def get_story_audio(userID: int, storyID: int, request: Request):
    """
    ترجع قائمة ملفات الصوت كروابط URL جاهزة للتحميل أو التشغيل.
    """
    story_folder = os.path.join(AUDIO_FOLDER, str(userID), str(storyID))
    if not os.path.exists(story_folder):
        raise HTTPException(status_code=404, detail="No audio files found")

    # ترتيب الملفات لضمان تشغيل القصة بالتسلسل الصحيح (turn1, turn2...)
    # نحتاج دالة ترتيب مخصصة لأن الترتيب الأبجدي قد يخطئ (turn10 يأتي قبل turn2)
    files = glob.glob(os.path.join(story_folder, "*.mp3"))
    
    # ترتيب الملفات بناءً على رقم الدور المستخرج من اسم الملف
    def get_turn_number(filename):
        basename = os.path.basename(filename)
        try:
            return int(basename.split('_')[0].replace('turn', ''))
        except:
            return 0

    files = sorted(files, key=get_turn_number)

    if not files:
        raise HTTPException(status_code=404, detail="No audio files found")

    base_url = str(request.base_url).rstrip("/")
    return {
        "audio_files": [
            f"{base_url}/audio_files/{userID}/{storyID}/{os.path.basename(f)}"
            for f in files
        ]
    }