import os
import re
from fastapi import APIRouter, HTTPException, Form, Request
import sqlite3
from db import DB_NAME
from openai import OpenAI
from audio import generate_audio

chat_router = APIRouter()

# تأكد من أن مفتاح API الخاص بك يعمل بشكل صحيح
client = OpenAI(api_key="ur key")

# تخزين بيانات الأدوار للقصص النشطة
story_turns = {}

def get_story_config(grade_level: str):
    """
    تحديد إعدادات القصة (عدد الأدوار + كلمات كل دور) بناءً على الصف الدراسي (Grade Level)
    وفقاً للجدول المعياري.
    """
    grade = grade_level.upper().strip()
    
    # القيم المستنتجة من الجدول (Total Words / Estimated Turns)
    if grade == 'KG':
        # Total: 70-100 words
        return {"max_turns": 3, "words_per_turn": "حوالي 70-100 كلمة (بسيط جداً)"}
    
    elif grade == 'G1':
        # Total: 120-180 words
        return {"max_turns": 4, "words_per_turn": "حوالي 120-180 كلمة (جمل قصيرة)"}
    
    elif grade == 'G2':
        # Total: 200-300 words
        return {"max_turns": 4, "words_per_turn": "حوالي 200-300 كلمة"}
    
    elif grade == 'G3':
        # Total: 300-450 words
        return {"max_turns": 5, "words_per_turn": "حوالي 300-450 كلمة"}
    
    elif grade == 'G4':
        # Total: 450-600 words
        return {"max_turns": 5, "words_per_turn": "حوالي 450-600 كلمة (أوصاف أطول)"}
    
    elif grade == 'G5':
        # Total: 600-800 words
        return {"max_turns": 6, "words_per_turn": "حوالي 600-800 كلمة"}
    
    elif grade == 'G6':
        # Total: 800-1000 words
        return {"max_turns": 7, "words_per_turn": "حوالي 800-1000 كلمة (أفكار مجردة)"}
    
    else:
        # Default (Fallback)
        return {"max_turns": 5, "words_per_turn": "حوالي 80 كلمة"}

def extract_story_and_mode(full_response: str):
    modes = ["TILTZ", "TILTY", "SHAKE", "FINISH"]
    found_mode = "TILTZ" # الافتراضي
    
    clean_response = full_response.strip()
    matches = re.findall(r"\[(TILTZ|TILTY|SHAKE|FINISH)\]", clean_response.upper())
    
    if matches:
        found_mode = matches[-1]
        story_part = re.sub(r"\[(TILTZ|TILTY|SHAKE|FINISH)\]", "", clean_response).strip()
        return story_part, found_mode
    
    return clean_response, found_mode

def translate_answer_to_context(answer: str):
    answer = answer.upper().strip()
    if "LEFT" in answer:
        return "الطفل قام بإمالة المكعب لليسار (اختار المسار الأيسر)."
    elif "RIGHT" in answer:
        return "الطفل قام بإمالة المكعب لليمين (اختار المسار الأيمن)."
    elif "FRONT" in answer:
        return "الطفل قام بإمالة المكعب للأمام (اختار التقدم الامام)."
    elif "BACK" in answer:
        return "الطفل قام بإمالة المكعب للخلف (اختار التراجع الخلف)."
    elif "SHAKE" in answer:
        return "الطفل قام بهز المكعب بقوة."
    else:
        return f"الطفل قام باختيار: {answer}"

# أمثلة لتعليم النموذج (Few-Shot) - تم تحديثها لتدعم الحركات المطلوبة فقط
FEW_SHOT_EXAMPLES = [
    {
        "role": "user", 
        "content": "ابدأ القصة. الطفل: أحمد، 5 سنوات (KG). الموضوع: الفضاء."
    },
    {
        "role": "assistant",
        "content": "كان يا ما كان، رائد فضاء صغير اسمه أحمد. ركب صاروخه الفضي وانطلق بسرعة! وفجأة، رأى باب المحطة مغلقاً. يحتاج أحمد لقوتك ليفتحه. هل تساعده؟ هيا، هز المكعب بقوة ليفتح الباب! [SHAKE]"
    },
    {
        "role": "user",
        "content": "اكمل القصة. الطفل قام بـ: هز المكعب."
    },
    {
        "role": "assistant",
        "content": "أحسنت يا بطل! فتح الباب وانطلق أحمد للفضاء. أمامه الآن كوكبان: كوكب أحمر لليمين، وكوكب أزرق لليسار. أين نذهب؟ أمل المكعب لليمين للكوكب الأحمر أو لليسار للكوكب الأزرق! [TILTZ]"
    },
    {
        "role": "user",
        "content": "اكمل القصة. الطفل قام بـ: إمالة المكعب لليمين."
    },
    {
        "role": "assistant",
        "content": "وصل أحمد للكوكب الأحمر ووجد كائناً فضائياً لطيفاً! هل يقترب منه (أمام) أم يبتعد قليلاً (خلف)؟ أمل المكعب للأمام للسلام عليه أو للخلف للمراقبة! [TILTY]"
    }
]

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
    
    # 1. جلب الإعدادات بناءً على الـ Grade
    config = get_story_config(grade)
    max_turns = config["max_turns"]
    words_per_turn = config["words_per_turn"]
    
    child_info = f"الطفل اسمه {name}، عمره {age}، الصف الدراسي {grade}."
    
    system_prompt = (
        "أنت 'كيوبي'، راوي قصص تفاعلية للأطفال. أسلوبك مشوق وبسيط."
        "قوانين صارمة جداً للاستجابة:\n"
        "1. اسرد القصة بالعربية الفصحى السهلة واستخدم اسم الطفل دائماً.\n"
        "2. في نهاية كل رد، اطلب من الطفل *حصراً* تحريك المكعب للمتابعة.\n"
        "3. الممنوعات: لا تطلب من الطفل القفز، الركض، أو التصفيق. التفاعل يكون بالمكعب فقط.\n"
        "4. أنواع التفاعل المسموحة:\n"
        "   - للاختيار بين شيئين (مثل طريقين): اطلب إمالة المكعب (يمين/يسار) واستخدم [TILTZ].\n"
        "   - للتقدم/التراجع أو الهجوم/الدفاع: اطلب إمالة المكعب (أمام/خلف) واستخدم [TILTY].\n"
        "   - للأكشن والطاقة: اطلب هز المكعب واستخدم [SHAKE].\n"
        "5. يجب أن تذكر الحركة المطلوبة بوضوح في النص (مثلاً: 'أمل المكعب للأمام أو الخلف').\n"
        "6. اختم الرد فوراً بالتاق المناسب."
    )
    

    user_task_prompt = (
        f"معلومات الطفل: {child_info}\n"
        f"نوع القصة: {genre}. تفاصيل: {description}.\n"
        f"اكتب بداية القصة (الطول المطلوب: {words_per_turn}).\n"
       "انهِ الفقرة بسؤال يطلب حركة بالمكعب (يمين/يسار، أمام/خلف، أو هز). "
    )

    messages = [{"role": "system", "content": system_prompt}]
    messages.extend(FEW_SHOT_EXAMPLES)
    messages.append({"role": "user", "content": user_task_prompt})

    print(f"🔄 [OpenAI] Start Story (Grade: {grade}, Turns: {max_turns})...")
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=messages,
        temperature=0.6
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

    # تخزين عدد الأدوار المحسوب بناءً على الـ Grade
    story_turns[story_id] = {"turns": 1, "max_turns": max_turns}
    
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
    
    # 2. إعادة جلب الإعدادات للتأكد (أو الاعتماد على story_turns إذا كانت محفوظة في الذاكرة)
    config = get_story_config(grade)
    default_max_turns = config["max_turns"]
    words_per_turn = config["words_per_turn"]

    # إدارة الأدوار
    if storyID not in story_turns:
        # في حال إعادة تشغيل السيرفر وضياع الذاكرة، نعيد الحساب
        story_turns[storyID] = {"turns": 1, "max_turns": default_max_turns}
        
    turns_info = story_turns[storyID]
    turns_info["turns"] += 1
    turns, max_turns = turns_info["turns"], turns_info["max_turns"]

    child_action_desc = translate_answer_to_context(answer)

    system_prompt = (
        f"أنت 'كيوبي'، راوي قصص. الطفل: {name}, {age} سنوات.\n" 
        "قواعد هامة:\n"
        "1. التزم بسياق القصة ولا تكرر المقدمة ولا قصه ال EXAMPLE.\n"
        "2. التفاعل يكون حصراً بالمكعب (تجنب طلب القفز أو الركض).\n"
        "3. الأسئلة تكون: إمالة لليمين/اليسار [TILTZ]، إمالة للأمام/الخلف [TILTY]، هز [SHAKE].\n"
        "4. اذكر الحركة بوضوح في السؤال."
    )


    messages = [{"role": "system", "content": system_prompt}]
    messages.extend(FEW_SHOT_EXAMPLES) 
    messages.append({"role": "assistant", "content": old_story}) 
    
    if turns >= max_turns:
        instruction = (
            f"الطفل قام بـ: {child_action_desc}\n"
            f"لقد وصلنا للنهاية (الدور {turns} من {max_turns}).\n"
            f"اكتب خاتمة جميلة للقصة (الطول: {words_per_turn}).\n"
            "يجب أن ينتهي النص بـ [FINISH] فقط."
        )
        finished = True
    else:
        instruction = (
            f"الحدث السابق: {child_action_desc}\n"
            f"اكمل القصة بحدث جديد (الدور {turns} من {max_turns}). الطول: {words_per_turn}.\n"
            "1. تفاعل مع حركة الطفل.\n"
            "2. اختم بسؤال يتطلب خياراً جديداً بالمكعب (مثال: 'للهرب أمل للأمام، للاختباء أمل للخلف').\n"
            "3. ضع التاق المناسب: [SHAKE] أو [TILTZ] أو [TILTY]."
        )
        finished = False
        
    messages.append({"role": "user", "content": instruction})

    print(f"🔄 [OpenAI] Continue Turn {turns}/{max_turns}...")
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=messages,
        temperature=0.6
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
