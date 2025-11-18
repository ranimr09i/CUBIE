
# import os
# import re # (1) استيراد مكتبة re
# from fastapi import APIRouter, HTTPException, Form, Request
# import sqlite3
# from db import DB_NAME
# from openai import OpenAI
# from audio import generate_audio
# from fastapi.staticfiles import StaticFiles


# chat_router = APIRouter()
# client = OpenAI(
#  api_key=""
# )

# # in-memory turn tracking (reset on server restart)
# story_turns = {}

# # (2) دالة تحديد طول القصة بناءً على القريد
# def get_story_length_for_grade(grade_level: str):
#     if grade_level == 'KG':
#         return "قصيرة جداً (حوالي 70 إلى 100 كلمة)"
#     elif grade_level == 'G1':
#         return "قصيرة (حوالي 120 إلى 180 كلمة)"
#     elif grade_level == 'G2':
#         return "متوسطة القصر (حوالي 200 إلى 300 كلمة)"
#     elif grade_level == 'G3':
#         return "متوسطة (حوالي 300 إلى 450 كلمة)"
#     elif grade_level == 'G4':
#         return "متوسطة الطول (حوالي 450 إلى 600 كلمة)"
#     elif grade_level == 'G5':
#         return "طويلة (حوالي 600 إلى 800 كلمة)"
#     elif grade_level == 'G6':
#         return "طويلة جداً (حوالي 800 إلى 1000 كلمة)"
#     else:
#         return "متوسطة (حوالي 200 كلمة)" # قيمة افتراضية

# # (3) دالة فصل النص عن أمر الحركة
# def extract_story_and_mode(full_response: str):
#     # البحث عن كود الحركة في نهاية النص
#     mode_match = re.search(r"\[(TILTZ|TILTY|SHAKE|FINISH)\]$", full_response.strip().upper())
    
#     if mode_match:
#         mode = mode_match.group(1) # استخراج الكود (مثل "TILTZ")
#         story_part = full_response[:mode_match.start()].strip() # استخراج النص قبله
#         return story_part, mode
#     else:
#         # إذا لم يجد الكود، يرجع النص كاملاً ويفترض سؤال افتراضي
#         return full_response.strip(), "TILTZ" 

# def get_max_turns(age: int):
#     if age <= 5: return 3
#     elif age <= 8: return 5
#     return 7

# @chat_router.post("/start/")
# def start_story(
#     request: Request,
#     userID: int = Form(...),
#     childID: int = Form(...),
#     genre: str = Form(...),
#     description: str = Form(...)
# ):
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
#     # (4) جلب القريد مع باقي بيانات الطفل
#     c.execute("SELECT name, age, gender, grade FROM children WHERE childID=? AND userID=?", (childID, userID))
#     row = c.fetchone()
#     if not row:
#         conn.close()
#         raise HTTPException(status_code=404, detail="Child not found")
    
#     name, age, gender, grade = row # (5) تم إضافة grade
    
#     # (6) تحديد طول القصة بناءً على القريد
#     story_length_prompt = get_story_length_for_grade(grade)

#     child_info = f"الطفل اسمه {name}، عمره {age}، جنسه {gender}، ومستواه الدراسي {grade}."
#     prefs = f"النوع: {genre}؛ وصف: {description}."
    
#     # (7) تحديث البرومبت (الأمر) لـ GPT
#     system_prompt = (
#         "أنت راوي قصص تفاعلية للأطفال باللغة العربية الفصحى المبسطة. اتبع نبرة لطيفة وواضحة."
#         f"معلومات الطفل: {child_info} {prefs} "
#         f"مهم جداً: يجب أن يكون طول هذا الجزء من القصة {story_length_prompt}."
#         "ابدأ القصة مباشرة. يجب أن ينتهي هذا الجزء بسؤال تفاعلي يطلب من الطفل الاختيار بين ثلاث مسارين (مثل: يمين أو يسار، أو أمام أو خلف)او (هز)."
#         " اسأل سؤالاً مهم جدا جدا ان يكون متواجد لازم ،الأهم: في نهاية ردك، يجب أن تكتب كود الحركة المطلوب بين قوسين مربعين. اختر واحداً فقط:"
#         "[TILTZ] (للاختيار بين يمين ويسار)"
#         "[TILTY] (للاختيار بين أمام وخلف)"
#         "[SHAKE] (للاختيارات العشوائية مثل 'هز المكعب لترى ما سيحدث')"
#         "مثال للرد: '...وجد أمامه بابين، باب أحمر على اليمين وباب أزرق على اليسار. أي باب سيختار؟' [TILTZ]"
#     )


#     response = client.chat.completions.create(
#         model="gpt-4o-mini",
#         messages=[{"role": "system", "content": system_prompt}]
#     )
#     full_response_text = response.choices[0].message.content

#     # (8) فصل النص عن الكود
#     first_part, question_mode = extract_story_and_mode(full_response_text)

#     c.execute("""
#         INSERT INTO stories (userID, genre, preferences, prompt, generated_story, audio_path)
#         VALUES (?, ?, ?, ?, ?, ?)
#     """, (userID, genre, description, "auto-generated", first_part, None)) # نحفظ الجزء الأول فقط
#     conn.commit()
#     story_id = c.lastrowid
#     conn.close()

#     story_turns[story_id] = {"turns": 1, "max_turns": get_max_turns(age)}
    
#     audio_path = generate_audio(first_part, userID, story_id, turn=1)
#     base_url = str(request.base_url).rstrip("/")
#     audio_url = f"{base_url}/audio_files/{userID}/{story_id}/{os.path.basename(audio_path)}"

#     # (9) إرسال question_mode للفرونت إند
#     return {
#         "storyID": story_id, 
#         "childID": childID, 
#         "part": first_part, 
#         "audio_path": audio_url, 
#         "finished": False,
#         "question_mode": question_mode # <-- هذا ضروري للفرونت إند
#     }
    
# @chat_router.post("/continue/")
# def continue_story(
#     request: Request,
#     storyID: int = Form(...),
#     userID: int = Form(...),
#     childID: int = Form(...),
#     answer: str = Form(...) # (10) استقبال الجواب من المكعب (مثل "RIGHT")
# ):
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
#     c.execute("SELECT generated_story FROM stories WHERE storyID=? AND userID=?", (storyID, userID))
#     row = c.fetchone()
#     if not row:
#         conn.close()
#         raise HTTPException(status_code=404, detail="Story not found")
#     old_story = row[0]

#     # (11) جلب القريد والعمر مجدداً
#     c.execute("SELECT name, age, gender, grade FROM children WHERE childID=? AND userID=?", (childID, userID))
#     child_row = c.fetchone()
#     if not child_row:
#         conn.close()
#         raise HTTPException(status_code=404, detail="Child not found")
        
#     name, age, gender, grade = child_row
#     story_length_prompt = get_story_length_for_grade(grade) # (12) تحديد الطول

#     if storyID not in story_turns:
#         story_turns[storyID] = {"turns": 1, "max_turns": get_max_turns(age)}
#     turns_info = story_turns[storyID]
#     turns_info["turns"] += 1
#     turns, max_turns = turns_info["turns"], turns_info["max_turns"]

#     if turns >= max_turns:
#         # (13) برومبت الإنهاء
#         system_prompt = (
#             f"سياق القصة حتى الآن:\n{old_story}\n\n"
#             f"الطفل ({name}, عمره {age}, مستواه {grade}) اختار: \"{answer}\".\n"
#             f"مهم جداً: اكمل القصة بجزء {story_length_prompt}."
#             "انهِ القصة الآن بخاتمة سعيدة ومناسبة. لا تضع أي أسئلة جديدة."
#             "في نهاية الرد، اكتب [FINISH] فقط."
#         )
#         finished = True
#     else:
#         # (14) برومبت الاستمرار
#         system_prompt = (
#             f"سياق القصة حتى الآن:\n{old_story}\n\n"
#             f"الطفل ({name}, عمره {age}, مستواه {grade}) اختار: \"{answer}\".\n"
#             f"مهم جداً: اكمل القصة بجزء {story_length_prompt}."
#             "أكمل القصة بفقرة جديدة، ثم اسأل سؤالاً مهم جدا جدا ان يكون متواجد لازم جديداً بخيارين (يمين/يسار أو أمام/خلف)."
#             "في نهاية ردك، يجب أن تكتب كود الحركة المطلوب: [TILTZ] أو [TILTY] أو [SHAKE]."
#         )
#         finished = False

#     response = client.chat.completions.create(
#         model="gpt-4o-mini",
#         messages=[{"role": "system", "content": system_prompt}]
#     )
#     full_response_text = response.choices[0].message.content

#     new_part, question_mode = extract_story_and_mode(full_response_text)
    
#     if finished:
#         question_mode = "FINISH"

#     updated_story = old_story + "\n\n" + new_part

#     c.execute("UPDATE stories SET generated_story=? WHERE storyID=?", (updated_story, storyID))
#     conn.commit()
#     conn.close()

#     audio_path = generate_audio(new_part, userID, storyID, turn=turns)
#     base_url = str(request.base_url).rstrip("/")
#     # (التعديل الصحيح لـ line 346 in backend/chat.py)
#     audio_url = f"{base_url}/audio_files/{userID}/{storyID}/{os.path.basename(audio_path)}"

#     return {
#         "storyID": storyID, 
#         "childID": childID, 
#         "part": new_part, 
#         "audio_path": audio_url, 
#         "finished": finished,
#         "question_mode": question_mode
#     }

# (ملف backend/chat.py كامل ومعدل)




# ي////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


# import os
# import re
# from fastapi import APIRouter, HTTPException, Form, Request
# import sqlite3
# from db import DB_NAME
# from openai import OpenAI
# from audio import generate_audio
# from fastapi.staticfiles import StaticFiles

# chat_router = APIRouter()
# client = OpenAI(
#     # (ملاحظة: هذا المفتاح ظاهر للجميع، الأفضل تغييره لاحقاً)
#     api_key="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"
# )

# # تتبع الأدوار
# story_turns = {}

# # --- (1. تعديل: رجعنا الدالة حقتك للقريد) ---
# def get_story_length_for_grade(grade_level: str):
#     if grade_level == 'KG':
#         return "قصيرة جداً (حوالي 70 إلى 100 كلمة)"
#     elif grade_level == 'G1':
#         return "قصيرة (حوالي 120 إلى 180 كلمة)"
#     elif grade_level == 'G2':
#         return "متوسطة القصر (حوالي 200 إلى 300 كلمة)"
#     elif grade_level == 'G3':
#         return "متوسطة (حوالي 300 إلى 450 كلمة)"
#     elif grade_level == 'G4':
#         return "متوسطة الطول (حوالي 450 إلى 600 كلمة)"
#     elif grade_level == 'G5':
#         return "طويلة (حوالي 600 إلى 800 كلمة)"
#     elif grade_level == 'G6':
#         return "طويلة جداً (حوالي 800 إلى 1000 كلمة)"
#     else:
#         return "متوسطة (حوالي 200 كلمة)" # قيمة افتراضية
# # --- نهاية التعديل 1 ---

# def extract_story_and_mode(full_response: str):
#     mode_match = re.search(r"\[(TILTZ|TILTY|SHAKE|FINISH)\]$", full_response.strip().upper())
#     if mode_match:
#         mode = mode_match.group(1)
#         story_part = full_response[:mode_match.start()].strip()
#         return story_part, mode
#     else:
#         # (إذا نسي الذكاء الاصطناعي السؤال، نفرض سؤال افتراضي)
#         print("⚠️ [Warning] OpenAI did not return a move code. Defaulting to TILTZ.")
#         return full_response.strip(), "TILTZ" 

# def get_max_turns(age: int):
#     if age <= 5: return 3
#     elif age <= 8: return 5
#     return 7

# @chat_router.post("/start/")
# def start_story(
#     request: Request,
#     userID: int = Form(...),
#     childID: int = Form(...),
#     genre: str = Form(...),
#     description: str = Form(...)
# ):
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
#     c.execute("SELECT name, age, gender, grade FROM children WHERE childID=? AND userID=?", (childID, userID))
#     row = c.fetchone()
#     if not row:
#         conn.close()
#         raise HTTPException(status_code=404, detail="Child not found")
    
#     name, age, gender, grade = row
#     story_length_prompt = get_story_length_for_grade(grade) # <-- (يستخدم الدالة الجديدة)
#     child_info = f"الطفل اسمه {name}، عمره {age}، جنسه {gender}، ومستواه الدراسي {grade}."
#     prefs = f"النوع: {genre}؛ وصف: {description}."
    
#     system_prompt = (
#         "أنت راوي قصص تفاعلية للأطفال باللغة العربية الفصحى المبسطة. اتبع نبرة لطيفة وواضحة."
#         f"معلومات الطفل: {child_info} {prefs}"
#     )
    
#     # --- (2. تعديل: شددنا على ضرورة وجود السؤال) ---
#     user_task_prompt = (
#         f"ابدأ القصة مباشرة. يجب أن يكون طول هذا الجزء من القصة {story_length_prompt}."
#         "مهم جداً: يجب أن ينتهي هذا الجزء بسؤال تفاعلي. هذا السؤال إلزامي (لازم يكون موجود)."
#         "السؤال يطلب من الطفل الاختيار بين مسارين (مثل: يمين أو يسار، أو أمام أو خلف) أو (هز)."
#         "الأهم: في نهاية ردك، يجب أن تكتب كود الحركة المطلوب بين قوسين مربعين. اختر واحداً فقط:"
#         "[TILTZ] (للاختيار بين يمين ويسار)"
#         "[TILTY] (للاختيار بين أمام وخلف)"
#         "[SHAKE] (للاختيارات العشوائية مثل 'هز المكعب لترى ما سيحدث')"
#         "مثال للرد: '...وجد أمامه بابين، باب أحمر على اليمين وباب أزرق على اليسار. أي باب سيختار؟' [TILTZ]"
#     )
#     # --- نهاية التعديل 2 ---

#     print("🔄 [OpenAI] إرسال طلب بدء القصة...")
#     response = client.chat.completions.create(
#         model="gpt-4o-mini",
#         messages=[
#             {"role": "system", "content": system_prompt},
#             {"role": "user", "content": user_task_prompt}
#         ]
#     )
#     print("✅ [OpenAI] استلم الرد الأول.")
    
#     full_response_text = response.choices[0].message.content
#     first_part, question_mode = extract_story_and_mode(full_response_text)

#     c.execute("""
#         INSERT INTO stories (userID, genre, preferences, prompt, generated_story, audio_path)
#         VALUES (?, ?, ?, ?, ?, ?)
#     """, (userID, genre, description, user_task_prompt, first_part, None))
#     conn.commit()
#     story_id = c.lastrowid
#     conn.close()

#     story_turns[story_id] = {"turns": 1, "max_turns": get_max_turns(age)}
    
#     print(f"🎧 [Audio] بدء توليد الصوت للجزء 1...")
#     audio_path = generate_audio(first_part, userID, story_id, turn=1)
#     base_url = str(request.base_url).rstrip("/")
#     audio_url = f"{base_url}/audio_files/{userID}/{story_id}/{os.path.basename(audio_path)}"
#     print(f"✅ [Audio] تم توليد الصوت: {audio_url}")

#     # (مهم جداً) هذا الرد متوافق مع story_progress.dart
#     return {
#         "storyID": story_id, 
#         "childID": childID, 
#         "text": first_part, 
#         "audio_url": audio_url,
#         "story_end": False,
#         "required_move": question_mode
#     }

# @chat_router.post("/continue/")
# def continue_story(
#     request: Request,
#     storyID: int = Form(...),
#     userID: int = Form(...),
#     childID: int = Form(...),
#     answer: str = Form(...)
# ):
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
    
#     c.execute("SELECT generated_story FROM stories WHERE storyID=? AND userID=?", (storyID, userID))
#     row = c.fetchone()
#     if not row:
#         conn.close()
#         raise HTTPException(status_code=404, detail="Story not found")
#     old_story = row[0]

#     c.execute("SELECT name, age, gender, grade FROM children WHERE childID=? AND userID=?", (childID, userID))
#     child_row = c.fetchone()
#     if not child_row:
#         conn.close()
#         raise HTTPException(status_code=404, detail="Child not found")
        
#     name, age, gender, grade = child_row
#     story_length_prompt = get_story_length_for_grade(grade) # <-- (يستخدم الدالة الجديدة)

#     if storyID not in story_turns:
#         story_turns[storyID] = {"turns": 1, "max_turns": get_max_turns(age)}
#     turns_info = story_turns[storyID]
#     turns_info["turns"] += 1
#     turns, max_turns = turns_info["turns"], turns_info["max_turns"]

#     # --- (هذا هو الكود السريع: بناء سجل المحادثة) ---
#     base_system_prompt = (
#         "أنت راوي قصص تفاعلية للأطفال باللغة العربية الفصحى المبسطة."
#         f"معلومات الطفل: {name}, عمره {age}, مستواه {grade}."
#     )
    
#     message_history = [
#         {"role": "system", "content": base_system_prompt},
#         {"role": "assistant", "content": old_story},
#         {"role": "user", "content": f"الطفل اختار: \"{answer}\""}
#     ]

#     # --- (3. تعديل: شددنا على ضرورة وجود السؤال) ---
#     if turns >= max_turns:
#         instruction = (
#             f"مهم جداً: اكمل القصة بجزء {story_length_prompt}."
#             "انهِ القصة الآن بخاتمة سعيدة ومناسبة. لا تضع أي أسئلة جديدة."
#             "في نهاية الرد، اكتب [FINISH] فقط."
#         )
#         finished = True
#     else:
#         instruction = (
#             f"مهم جداً: اكمل القصة بجزء {story_length_prompt}."
#             "أكمل القصة بفقرة جديدة، ثم اسأل سؤالاً جديداً. هذا السؤال إلزامي (لازم يكون موجود)."
#             "السؤال يجب أن يكون بخيارين (يمين/يسار أو أمام/خلف) أو (هز)."
#             "في نهاية ردك، يجب أن تكتب كود الحركة المطلوب: [TILTZ] أو [TILTY] أو [SHAKE]."
#         )
#         finished = False
#     # --- نهاية التعديل 3 ---
        
#     message_history.append({"role": "system", "content": instruction})

#     print(f"🔄 [OpenAI] إرسال طلب تكملة القصة (Turn {turns})...")
#     response = client.chat.completions.create(
#         model="gpt-4o-mini",
#         messages=message_history
#     )
#     print(f"✅ [OpenAI] استلم الرد (Turn {turns}).")

#     full_response_text = response.choices[0].message.content
#     new_part, question_mode = extract_story_and_mode(full_response_text)
    
#     if finished:
#         question_mode = "FINISH"

#     updated_story = old_story + "\n\n" + new_part
#     c.execute("UPDATE stories SET generated_story=? WHERE storyID=?", (updated_story, storyID))
#     conn.commit()
#     conn.close()

#     print(f"🎧 [Audio] بدء توليد الصوت للجزء {turns}...")
#     audio_path = generate_audio(new_part, userID, storyID, turn=turns)
#     base_url = str(request.base_url).rstrip("/")
#     audio_url = f"{base_url}/audio_files/{userID}/{storyID}/{os.path.basename(audio_path)}"
#     print(f"✅ [Audio] تم توليد الصوت: {audio_url}")

#     # (مهم جداً) هذا الرد متوافق مع story_progress.dart
#     return {
#         "storyID": storyID, 
#         "childID": childID, 
#         "text": new_part,
#         "audio_url": audio_url,
#         "story_end": finished,
#         "required_move": question_mode
#     }



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
    api_key="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"
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
