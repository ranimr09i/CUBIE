import os
from fastapi import APIRouter, HTTPException, Form, Request
import sqlite3
from db import DB_NAME
from openai import OpenAI
from audio import generate_audio
from fastapi.staticfiles import StaticFiles


chat_router = APIRouter()
client = OpenAI(
 api_key="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"
)



# in-memory turn tracking (reset on server restart)
story_turns = {}



def get_max_turns(age: int):
    if age <= 5: return 3
    elif age <= 8: return 5
    return 7

@chat_router.post("/start/")
def start_story(
    request: Request,
    userID: int = Form(...),
    childID: int = Form(...),
    genre: str = Form(...),
    description: str = Form(...)
):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute("SELECT name, age, gender FROM children WHERE childID=? AND userID=?", (childID, userID))
    row = c.fetchone()
    if not row:
        conn.close()
        raise HTTPException(status_code=404, detail="Child not found")
    name, age, gender = row

    child_info = f"الطفل اسمه {name}، عمره {age}، جنسه {gender}."
    prefs = f"النوع: {genre}؛ وصف: {description}."
    system_prompt = (
        "أنت راوي قصص للأطفال. اتبع نبرة لطيفة وبسيطة للمستمعين بلغه واضحه للطفل وماتطول هرج تناسب استيعابه من عمر الطفل المذكور. "
        f"معلومات الطفل: {child_info} {prefs} "
        "ابدأ قصة مناسبة للعمر، ثم بعد فقرة قصيرة قدم سؤالًا بسيطًا مع خيارات الحركة: اثنان  فقط وحده اختار( يمين او يسار، امام او خلف , هز)."
    )

    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "system", "content": system_prompt}]
    )
    first_part = response.choices[0].message.content

    c.execute("""
        INSERT INTO stories (userID, genre, preferences, prompt, generated_story, audio_path)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (userID, genre, description, "auto-generated", first_part, None))
    conn.commit()
    story_id = c.lastrowid
    conn.close()

    story_turns[story_id] = {"turns": 1, "max_turns": get_max_turns(age)}
    
    audio_path = generate_audio(first_part, userID, story_id, turn=1)
    base_url = str(request.base_url).rstrip("/")
    audio_url = f"{base_url}/audio_files/{userID}/{story_id}/{os.path.basename(audio_path)}"

    return {"storyID": story_id, "childID": childID, "part": first_part, "audio_path": audio_url, "finished": False}
    
    # # إنشاء ملف الصوت للجزء الأول
    # audio_path = generate_audio(first_part, userID, story_id, turn=1)

    




@chat_router.post("/continue/")
def continue_story(
    request: Request,
    storyID: int = Form(...),
    userID: int = Form(...),
    childID: int = Form(...),
    answer: str = Form(...)
):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute("SELECT generated_story FROM stories WHERE storyID=? AND userID=?", (storyID, userID))
    row = c.fetchone()
    if not row:
        conn.close()
        raise HTTPException(status_code=404, detail="Story not found")
    old_story = row[0]

    c.execute("SELECT name, age, gender FROM children WHERE childID=? AND userID=?", (childID, userID))
    child_row = c.fetchone()
    if not child_row:
        conn.close()
        raise HTTPException(status_code=404, detail="Child not found")
    name, age, gender = child_row

    if storyID not in story_turns:
        story_turns[storyID] = {"turns": 1, "max_turns": get_max_turns(age)}
    turns_info = story_turns[storyID]
    turns_info["turns"] += 1
    turns, max_turns = turns_info["turns"], turns_info["max_turns"]

    if turns >= max_turns:
        system_prompt = (
            f"هذه القصة حتى الآن:\n{old_story}\n\n"
            f"الطفل ({name}, {age}) أجاب: \"{answer}\".\n"
            "انهِ القصة الآن بخاتمة سعيدة مناسبة للأطفال. لا تضع أسئلة جديدة."
        )
        finished = True
    else:
        system_prompt = (
            f"هذه القصة حتى الآن:\n{old_story}\n\n"
            f"الطفل ({name}, {age}) أجاب: \"{answer}\".\n"
            "أكمل القصة بفقرة قصيرة ومبسطة، ثم اسأل سؤالاً جديداً مع خيارات الحركة اثنان فقط وحده اختار( يمين او يسار، امام او خلف , هز)."
        )
        finished = False

    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "system", "content": system_prompt}]
    )
    new_part = response.choices[0].message.content
    updated_story = old_story + "\n\n" + new_part

    c.execute("UPDATE stories SET generated_story=? WHERE storyID=?", (updated_story, storyID))
    conn.commit()
    conn.close()

    # إنشاء ملف الصوت لكل Turn
    audio_path = generate_audio(new_part, userID, storyID, turn=turns)
    base_url = str(request.base_url).rstrip("/")
    audio_url = f"{base_url}/audio_files/{userID}/{storyID}/{os.path.basename(audio_path)}"

    return {"storyID": storyID, "childID": childID, "part": new_part, "audio_path": audio_url, "finished": finished}
