import os
import re
import random
from fastapi import APIRouter, HTTPException, Form, Request
import sqlite3
from db import DB_NAME
from openai import OpenAI
from audio import generate_audio

chat_router = APIRouter()

client = OpenAI(api_key="ur key")

story_turns = {}

def get_story_config(grade_level: str):
    grade = grade_level.upper().strip()
    configs = {
        'KG': {'max_turns': 3, 'total_words': '70-100', 'words_per_turn': 30, 'duration': '1-2 دقائق', 'skills': 'تحديد الأشياء', 'question_type': 'أسئلة بسيطة'},
        'G1': {'max_turns': 4, 'total_words': '120-180', 'words_per_turn': 40, 'duration': '2-3 دقائق', 'skills': 'فهم جمل قصيرة', 'question_type': 'فهم مباشر'},
        'G2': {'max_turns': 4, 'total_words': '200-300', 'words_per_turn': 60, 'duration': '3-4 دقائق', 'skills': 'السبب والنتيجة', 'question_type': 'لماذا/ماذا'},
        'G3': {'max_turns': 5, 'total_words': '300-450', 'words_per_turn': 80, 'duration': '4-5 دقائق', 'skills': 'متابعة الأحداث', 'question_type': 'استنتاج بسيط'},
        'G4': {'max_turns': 5, 'total_words': '450-600', 'words_per_turn': 110, 'duration': '5-6 دقائق', 'skills': 'أوصاف أطول', 'question_type': 'مقارنة'},
        'G5': {'max_turns': 6, 'total_words': '600-800', 'words_per_turn': 130, 'duration': '6-7 دقائق', 'skills': 'أفكار رئيسية', 'question_type': 'أسئلة مفتوحة'},
        'G6': {'max_turns': 7, 'total_words': '800-1000', 'words_per_turn': 140, 'duration': '7-8 دقائق', 'skills': 'أفكار مجردة', 'question_type': 'استنتاج متقدم'}
    }
    return configs.get(grade, configs['G3'])

def extract_story_and_mode(full_response: str):
    modes = ["TILTZ", "TILTY", "SHAKE", "FINISH"]
    found_mode = None
    clean_response = full_response.strip()
    matches = re.findall(r"\[(TILTZ|TILTY|SHAKE|FINISH)\]", clean_response.upper())
    if matches:
        found_mode = matches[-1]
        story_part = re.sub(r"\[(TILTZ|TILTY|SHAKE|FINISH)\]", "", clean_response, flags=re.IGNORECASE).strip()
        return story_part, found_mode
    return clean_response, found_mode

def translate_answer_to_context(answer: str):
    answer = answer.upper().strip()
    if "LEFT" in answer: return "اختار اليسار"
    elif "RIGHT" in answer: return "اختار اليمين"
    elif "FORWARD" in answer or "FRONT" in answer: return "اختار الأمام"
    elif "BACK" in answer: return "اختار الخلف"
    elif "SHAKE" in answer: return "قام بهز المكعب بقوة"
    else: return f"قام بـ: {answer}"

# ---------------------------------------------------------
# START STORY
# ---------------------------------------------------------
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
    config = get_story_config(grade)
    
    # اختيار عشوائي للحركة الأولى
    first_turn_mode = random.choice(["TILTZ", "TILTY"]) 

    # تحديد تعليمات السؤال بناءً على الحركة
    if first_turn_mode == 'TILTZ':
        question_instruction = """يجب أن تختم النص بسؤال واضح جداً يطلب من الطفل إمالة المكعب لليمين أو اليسار.
        صيغة الجملة الأخيرة (إجبارية): "يا ترى، هل [الفعل الأول]؟ أمل المكعب لليمين! أم [الفعل الثاني]؟ أمل المكعب لليسار!"
        استبدل [الفعل الأول] و [الفعل الثاني] بأحداث القصة."""
    else: # TILTY
        question_instruction = """يجب أن تختم النص بسؤال واضح جداً يطلب من الطفل إمالة المكعب للأمام أو الخلف.
        صيغة الجملة الأخيرة (إجبارية): "يا ترى، هل [الفعل الأول]؟ أمل المكعب للأمام! أم [الفعل الثاني]؟ أمل المكعب للخلف!"
        استبدل [الفعل الأول] و [الفعل الثاني] بأحداث القصة."""

    system_prompt = f"""أنت 'كيوبي'، راوي قصص تفاعلي للأطفال.
الطفل: {name} ({age} سنوات).
مهمتك: كتابة (الجزء 1 فقط) من قصة مشوقة جداً.

⚠️ تعليمات صارمة:
1. الطول: حوالي {config['words_per_turn']} كلمة.
2. لا تنهي القصة الآن أبداً.
3. {question_instruction}
4. لا تضع نقاط (...) في النص النهائي، املأها بالكلام المناسب.

في نهاية الرد، ضع التاق: [{first_turn_mode}]"""

    user_task_prompt = f"""القصة عن: {description}. النوع: {genre}.
ابدأ السرد الآن."""

    messages = [{"role": "system", "content": system_prompt}, {"role": "user", "content": user_task_prompt}]

    print(f"🔄 [OpenAI] Start Story. Mode: {first_turn_mode}")
    
    final_text = ""
    final_mode = first_turn_mode

    for _ in range(3):
        try:
            response = client.chat.completions.create(
                model="gpt-4o-mini",
                messages=messages,
                temperature=0.6,  # رفعنا الحرارة قليلاً ليتجرأ على تعبئة الفراغات
                top_p=0.9,
                max_tokens=450
            )
            full_text = response.choices[0].message.content
            text_part, mode = extract_story_and_mode(full_text)
            
            # التحقق من عدم وجود ... التي تدل على النسخ
            if mode and "..." not in text_part[-50:]: 
                final_text = text_part
                final_mode = mode
                break
        except Exception as e:
            print(f"Error: {e}")

    if not final_text:
        final_text = full_text
        final_mode = first_turn_mode

    text_to_save = final_text + f" [{final_mode}]"
    c.execute("INSERT INTO stories (userID, genre, preferences, prompt, generated_story, audio_path) VALUES (?, ?, ?, ?, ?, ?)", 
              (userID, genre, description, user_task_prompt, text_to_save, None))
    conn.commit()
    story_id = c.lastrowid
    conn.close()

    story_turns[story_id] = {"turns": 1, "max_turns": config['max_turns']}
    
    print(f"🎧 Generating Audio...")
    audio_path = generate_audio(final_text, userID, story_id, turn=1)
    base_url = str(request.base_url).rstrip("/")
    audio_url = f"{base_url}/audio_files/{userID}/{story_id}/{os.path.basename(audio_path)}"

    return {
        "storyID": story_id, "childID": childID, "text": final_text, 
        "audio_url": audio_url, "story_end": False, "required_move": final_mode
    }

# ---------------------------------------------------------
# CONTINUE STORY
# ---------------------------------------------------------
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
    name, age, gender, grade = child_row
    config = get_story_config(grade)

    if storyID not in story_turns:
        current_turns = len(re.findall(r"\[(TILTZ|TILTY|SHAKE)\]", old_story))
        if current_turns == 0: current_turns = 1
        story_turns[storyID] = {"turns": current_turns, "max_turns": config['max_turns']}
        
    turns_info = story_turns[storyID]
    turns_info["turns"] += 1
    current_turn = turns_info["turns"]
    max_turns = turns_info["max_turns"]

    child_action = translate_answer_to_context(answer)
    
    is_finish = False
    next_mode = "TILTZ"
    
    if current_turn >= max_turns:
        is_finish = True
        next_mode = "FINISH"
        instruction = f"الطفل قرر: {child_action}. اكتب نهاية سعيدة للقصة ({config['words_per_turn']} كلمة). انتهِ بـ [FINISH]."
    else:
        possible_modes = ["TILTZ", "TILTY", "SHAKE"]
        # منطق التنوع
        last_matches = re.findall(r"\[(TILTZ|TILTY|SHAKE)\]", old_story)
        if last_matches:
            last_mode = last_matches[-1]
            if last_mode in possible_modes and len(possible_modes) > 1:
                if random.random() > 0.3: possible_modes.remove(last_mode)
        
        next_mode = random.choice(possible_modes)

        # تعليمات محددة جداً لكل نوع حركة لتجنب الـ "..."
        if next_mode == "TILTZ":
            action_instruction = "في نهاية النص، اسأل الطفل: 'هل تريد [الخيار 1]؟ أمل المكعب لليمين! أم تريد [الخيار 2]؟ أمل المكعب لليسار!' (عبئ الخيارات من أحداث القصة)."
        elif next_mode == "TILTY":
            action_instruction = "في نهاية النص، اسأل الطفل: 'هل تود [الخيار 1]؟ أمل المكعب للأمام! أم تفضل [الخيار 2]؟ أمل المكعب للخلف!' (عبئ الخيارات من أحداث القصة)."
        else: # SHAKE
            action_instruction = "في نهاية النص، اطلب من الطفل المساعدة بحدث قوي. قل له: 'بسرعة! هز المكعب بقوة لكي [الحدث المطلوب]!'."

        instruction = f"""الحدث السابق: {child_action}.
أكمل القصة (الجزء {current_turn}).
⚠️ تعليمات السؤال:
1. اخلق موقفاً يتطلب الحركة: [{next_mode}].
2. {action_instruction}
3. لا تستخدم (...) ولا تكتب 'مثال'. اكتب الجملة كاملة وواضحة للطفل.
ختم الرد بالتاق [{next_mode}]."""

    messages = [
        {"role": "system", "content": f"أنت راوي قصص اسمه كيوبي. الطفل: {name}."},
        {"role": "assistant", "content": old_story},
        {"role": "user", "content": instruction}
    ]

    print(f"🔄 [OpenAI] Continue Turn {current_turn}. Mode: {next_mode}")

    final_new_part = ""
    final_new_mode = next_mode

    for _ in range(3):
        try:
            response = client.chat.completions.create(
                model="gpt-4o-mini",
                messages=messages,
                temperature=0.7, # حرارة تسمح بالإبداع في السؤال
                max_tokens=450
            )
            text = response.choices[0].message.content
            part, mode = extract_story_and_mode(text)
            
            # تحقق سريع أن النص لا يحتوي على قوالب فارغة
            if "..." not in part[-50:]:
                if is_finish and (mode == "FINISH" or "النهاية" in part):
                    final_new_part = part
                    final_new_mode = "FINISH"
                    break
                elif not is_finish and mode == next_mode:
                    final_new_part = part
                    final_new_mode = mode
                    break
        except:
            continue

    if not final_new_part:
        final_new_part = text
        if not is_finish and "[" not in final_new_part: final_new_part += f" [{next_mode}]"

    text_with_tag = final_new_part + (f" [{final_new_mode}]" if f"[{final_new_mode}]" not in final_new_part else "")
    updated_story = old_story + "\n\n" + text_with_tag
    c.execute("UPDATE stories SET generated_story=? WHERE storyID=?", (updated_story, storyID))
    conn.commit()
    conn.close()

    clean_text_for_audio, _ = extract_story_and_mode(final_new_part)
    print(f"🎧 Generating Audio Turn {current_turn}...")
    audio_path = generate_audio(clean_text_for_audio, userID, storyID, turn=current_turn)
    base_url = str(request.base_url).rstrip("/")
    audio_url = f"{base_url}/audio_files/{userID}/{storyID}/{os.path.basename(audio_path)}"

    return {
        "storyID": storyID, "childID": childID, "text": clean_text_for_audio, 
        "audio_url": audio_url, "story_end": is_finish, "required_move": final_new_mode
    }
