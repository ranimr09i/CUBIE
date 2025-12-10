import glob
import os
import uuid
from fastapi import APIRouter, HTTPException, Request
from openai import OpenAI
from pydub import AudioSegment  

audio_router = APIRouter()
AUDIO_FOLDER = "audio_files"
os.makedirs(AUDIO_FOLDER, exist_ok=True)


client = OpenAI(api_key="")

def generate_audio(text: str, userID: int, storyID: int, turn: int):
    """
    توليد ملف صوتي باستخدام OpenAI TTS، ثم رفع صوته وحفظه.
    """
    story_folder = os.path.join(AUDIO_FOLDER, str(userID), str(storyID))
    os.makedirs(story_folder, exist_ok=True)

    file_name = f"turn{turn}_{uuid.uuid4().hex}.mp3"
    path = os.path.join(story_folder, file_name)


    temp_path = path.replace(".mp3", "_temp.mp3")

    try:
        response = client.audio.speech.create(
            model="tts-1",
            voice="nova", 
            input=text
        )
        

        response.stream_to_file(temp_path)
        

        audio = AudioSegment.from_mp3(temp_path)
        

        louder_audio = audio + 33
        

        louder_audio.export(path, format="mp3")
        

        if os.path.exists(temp_path):
            os.remove(temp_path)
        
    except Exception as e:
        print(f"Error producing audio: {e}")

        if os.path.exists(temp_path):
            os.remove(temp_path)
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


    files = glob.glob(os.path.join(story_folder, "*.mp3"))
    

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
