import os
import re
from fastapi import APIRouter, HTTPException, Form, Request
import sqlite3
from db import DB_NAME
from openai import OpenAI
from audio import generate_audio
from fastapi.staticfiles import StaticFiles

chat_router = APIRouter()
client = OpenAI(
    api_key=""
)

# تتبع الأدوار
story_turns = {}

def get_story_length_for_grade(grade_level: str):
    if grade_level == 'KG':
        return "قصيرة جداً (حوالي 40 إلى 60 كلمة)"
    elif grade_level in ['G1', 'G2']:
        return "قصيرة (حوالي 80 إلى 100 كلمة)"
    else:
        return "متوسطة (حوالي 120 كلمة)"

# دالة محسنة لاستخراج التاق حتى لو كان وسط مسافات
def extract_story_and_mode(full_response: str):
    # نبحث عن التاق في أي مكان في آخر النص
    # البحث عن واحد من التاقات المتوقعة
    modes = ["TILTZ", "TILTY", "SHAKE", "FINISH"]
    found_mode = "TILTZ" # الافتراضي في حال عدم العثور على تاق لليمين/اليسار
    
    # تنظيف النص
    clean_response = full_response.strip()
    
    # البحث عن آخر تاق موجود في النص
    matches = re.findall(r"\[(TILTZ|TILTY|SHAKE|FINISH)\]", clean_response.upper())
    
    if matches:
        found_mode = matches[-1] # نأخذ آخر تاق وجدناه
        # نحذف التاق من النص لعرض القصة فقط
        story_part = re.sub(r"\[(TILTZ|TILTY|SHAKE|FINISH)\]", "", clean_response).strip()
        return story_part, found_mode
    
    return clean_response, found_mode

def get_max_turns(age: int):
    if age <= 5: return 3
    elif age <= 8: return 5
    return 7

# دالة لترجمة رد المكعب إلى جملة عربية يفهمها الراوي
def translate_answer_to_context(answer: str):
    answer = answer.upper().strip()
    if "LEFT" in answer:
        return "الطفل قام بإمالة المكعب لليسار (اختار المسار الأيسر)."
    elif "RIGHT" in answer:
        return "الطفل قام بإمالة المكعب لليمين (اختار المسار الأيمن)."
    elif "FRONT" in answer:
        return "الطفل قام بإمالة المكعب للأمام."
    elif "BACK" in answer:
        return "الطفل قام بإمالة المكعب للخلف."
    elif "SHAKE" in answer:
        return "الطفل قام بهز المكعب بقوة."
    else:
        return f"الطفل قام باختيار: {answer}"

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
    c.execute("SELECT name, age, gender, grade FROM children WHERE childID=? AND userID=?", (childID, userID))
    row = c.fetchone()
    if not row:
        conn.close()
        raise HTTPException(status_code=404, detail="Child not found")
    
    name, age, gender, grade = row
    story_length_prompt = get_story_length_for_grade(grade)
    child_info = f"الطفل اسمه {name}، عمره {age}، جنسه {gender}، ومستواه الدراسي {grade}."
    prefs = f"نوع القصة: {genre}؛ وصف إضافي: {description}."
    
    system_prompt = (
        "أنت 'كيوبي'، راوي قصص تفاعلية ذكي للأطفال. تتحدث بالعربية الفصحى البسيطة والممتعة."
        f"بيانات الطفل: {child_info} {prefs}"
    )
    
    # تحسين التعليمات لضمان التطابق بين السؤال والتاق
    user_task_prompt = (
        f"ابدأ القصة بمقدمة مشوقة. الطول المطلوب: {story_length_prompt}.\n"
        "القاعدة الذهبية: يجب أن تنهي هذا الجزء بسؤال يطلب من الطفل القيام بحركة محددة للمتابعة.\n"
        "اختر نوعاً واحداً فقط من الأسئلة التالية وأضف الكود الخاص به في نهاية النص تماماً:\n\n"
        "1. إذا كان السؤال عن اختيار اتجاه (يمين أو يسار): اكتب القصة ثم [TILTZ]\n"
        "2. إذا كان السؤال عن اختيار (أمام أو خلف): اكتب القصة ثم [TILTY]\n"
        "3. إذا كان السؤال يتطلب حركة عشوائية أو مشوقة (مثل: هز الشجرة، اركض): اكتب القصة ثم [SHAKE]\n\n"
        "مثال: '...هل يذهب لليمين نحو الغابة أم لليسار نحو النهر؟' [TILTZ]"
    )

    print("🔄 [OpenAI] Start Story...")
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_task_prompt}
        ]
    )
    
    full_response_text = response.choices[0].message.content
    first_part, question_mode = extract_story_and_mode(full_response_text)

    c.execute("""
        INSERT INTO stories (userID, genre, preferences, prompt, generated_story, audio_path)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (userID, genre, description, user_task_prompt, first_part, None))
    conn.commit()
    story_id = c.lastrowid
    conn.close()

    story_turns[story_id] = {"turns": 1, "max_turns": get_max_turns(age)}
    
    print(f"🎧 [Audio] Generating part 1...")
    audio_path = generate_audio(first_part, userID, story_id, turn=1)
    base_url = str(request.base_url).rstrip("/")
    audio_url = f"{base_url}/audio_files/{userID}/{story_id}/{os.path.basename(audio_path)}"

    return {
        "storyID": story_id, 
        "childID": childID, 
        "text": first_part, 
        "audio_url": audio_url,
        "story_end": False,
        "required_move": question_mode
    }

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

    c.execute("SELECT name, age, gender, grade FROM children WHERE childID=? AND userID=?", (childID, userID))
    child_row = c.fetchone()
    if not child_row:
        conn.close()
        raise HTTPException(status_code=404, detail="Child not found")
        
    name, age, gender, grade = child_row
    story_length_prompt = get_story_length_for_grade(grade)

    if storyID not in story_turns:
        story_turns[storyID] = {"turns": 1, "max_turns": get_max_turns(age)}
    turns_info = story_turns[storyID]
    turns_info["turns"] += 1
    turns, max_turns = turns_info["turns"], turns_info["max_turns"]

    # ترجمة استجابة الطفل للسياق العربي
    child_action_desc = translate_answer_to_context(answer)

    base_system_prompt = (
        "أنت 'كيوبي'، راوي قصص تفاعلية للأطفال."
        f"الطفل: {name}, {age} سنوات."
    )
    
    # تزويد الذكاء الاصطناعي بالسياق الكامل: القصة السابقة + ماذا فعل الطفل بالضبط
    message_history = [
        {"role": "system", "content": base_system_prompt},
        {"role": "assistant", "content": old_story}, # القصة القديمة
        {"role": "user", "content": f"حدث الآن: {child_action_desc}"} # التوضيح بالعربي
    ]

    if turns >= max_turns:
        instruction = (
            f"اكتب خاتمة للقصة ({story_length_prompt}) بناءً على اختيار الطفل الأخير.\n"
            "اجعل النهاية سعيدة ومناسبة.\n"
            "يجب أن ينتهي النص بـ [FINISH] فقط."
        )
        finished = True
    else:
        instruction = (
            f"اكمل القصة بحدث جديد ({story_length_prompt}) يترتب على اختيار الطفل.\n"
            "ثم انهِ الفقرة بسؤال تفاعلي جديد.\n"
            "القواعد:\n"
            "- لسؤال يمين/يسار: انهِ النص بـ [TILTZ]\n"
            "- لسؤال أمام/خلف: انهِ النص بـ [TILTY]\n"
            "- لسؤال هز/حركة: انهِ النص بـ [SHAKE]\n"
            "التزم بوضع الكود الصحيح الذي يطابق سؤالك."
        )
        finished = False
        
    message_history.append({"role": "system", "content": instruction})

    print(f"🔄 [OpenAI] Continue Turn {turns}...")
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=message_history
    )
    
    full_response_text = response.choices[0].message.content
    new_part, question_mode = extract_story_and_mode(full_response_text)
    
    if finished:
        question_mode = "FINISH"

    updated_story = old_story + "\n\n" + new_part
    c.execute("UPDATE stories SET generated_story=? WHERE storyID=?", (updated_story, storyID))
    conn.commit()
    conn.close()

    print(f"🎧 [Audio] Generating Turn {turns}...")
    audio_path = generate_audio(new_part, userID, storyID, turn=turns)
    base_url = str(request.base_url).rstrip("/")
    audio_url = f"{base_url}/audio_files/{userID}/{storyID}/{os.path.basename(audio_path)}"

    return {
        "storyID": storyID, 
        "childID": childID, 
        "text": new_part,
        "audio_url": audio_url,
        "story_end": finished,
        "required_move": question_mode
    }
